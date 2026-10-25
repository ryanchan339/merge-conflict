extends RefCounted
## The exact GDScript shown in-game is compiled and exercised by the preview and tests.

static func settings(flags: Dictionary) -> Dictionary:
	var patched: bool = bool(flags.get("sandbox_patch", false))
	var clear: bool = bool(flags.get("clear_prompt", false)) or patched
	var strategy: String = str(flags.get("lab_strategy", "request_guard"))
	if strategy not in ["request_guard", "upsert", "disabled"]:
		strategy = "request_guard"
	return {"guest_guard":bool(flags.get("lab_guest_guard", clear)), "write_target":str(flags.get("lab_write_target", "favorites" if clear else "orders")), "deduplicate":bool(flags.get("lab_deduplicate", patched)), "strategy":strategy}

static func source(config: Dictionary) -> String:
	var code := "extends RefCounted\n\nvar favorites: Array[String] = []\nvar orders: Array[String] = []\nvar seen_requests: Array[String] = []\n\nfunc save_favorite(user_id: String, drink: String, request_id: String) -> Dictionary:\n"
	var strategy: String = str(config.get("strategy", "request_guard"))
	if strategy == "disabled":
		code += "\t# Temporary release flag: preserve checkout while Save is repaired.\n\treturn {\"status\": \"unavailable\", \"charged\": 0}\n"
		return code
	if bool(config.get("guest_guard", false)):
		code += "\tif user_id.is_empty():\n\t\treturn {\"status\": \"sign_in\", \"charged\": 0}\n"
	if strategy == "upsert":
		code += "\t# Store each favorite once, even when a retry has a new request ID.\n\tif favorites.has(drink):\n\t\treturn {\"status\": \"already_saved\", \"charged\": 0}\n"
	elif bool(config.get("deduplicate", false)):
		code += "\tif seen_requests.has(request_id):\n\t\treturn {\"status\": \"already_saved\", \"charged\": 0}\n\tseen_requests.append(request_id)\n"
	var target: String = str(config.get("write_target", "orders"))
	# The editor offers only these two collections; keep generated code well formed.
	if target not in ["favorites", "orders"]:
		target = "orders"
	code += "\t" + target + ".append(drink)\n"
	code += "\treturn {\"status\": \"" + ("saved" if target == "favorites" else "ordered") + "\", \"charged\": " + ("0" if target == "favorites" else "4") + "}\n"
	return code

static func program(config: Dictionary) -> RefCounted:
	var script := GDScript.new()
	script.source_code = source(config)
	if script.reload() != OK:
		return null
	return script.new()

static func test_source() -> String:
	return """extends RefCounted

func test_member(app: RefCounted) -> Dictionary:
    var response = app.save_favorite("intern", "flat_white", "req-1")
    return report(app, response.charged, 1)

func test_guest(app: RefCounted) -> Dictionary:
    var response = app.save_favorite("", "flat_white", "req-1")
    var result = report(app, response.charged, 0)
    result.passed = result.passed and response.status == "sign_in"
    return result

func test_double(app: RefCounted) -> Dictionary:
    var first = app.save_favorite("intern", "flat_white", "req-1")
    var second = app.save_favorite("intern", "flat_white", "req-1")
    return report(app, first.charged + second.charged, 1)

func report(app: RefCounted, charged: int, expected_count: int) -> Dictionary:
    var favorites = app.favorites.size()
    var orders = app.orders.size()
    return {
        "passed": favorites == expected_count and orders == 0 and charged == 0,
        "expected": "favorites=%d, orders=0, charged=$0" % expected_count,
        "actual": "favorites=%d, orders=%d, charged=$%d" % [favorites, orders, charged]
    }
"""

static func suite(config: Dictionary) -> Array[Dictionary]:
	var results: Array[Dictionary] = []
	var test_script := GDScript.new()
	test_script.source_code = test_source()
	if test_script.reload() != OK:
		return [{"case":"compile", "passed":false, "expected":"Tests compile", "actual":"Test compile error"}]
	var tester: RefCounted = test_script.new()
	for scenario: String in ["member", "guest", "double"]:
		var app := program(config)
		if app == null:
			results.append({"case":scenario,"passed":false,"expected":"Code compiles", "actual":"Compile error"})
			continue
		var result: Dictionary = tester.call("test_" + scenario, app)
		result["case"] = scenario
		results.append(result)
	return results

static func investigation() -> Dictionary:
	return {
		"ticket":{
			"id":"SB-104", "title":"Save sometimes buys two coffees", "reporter":"Sam",
			"body":"I tapped Save twice on the kitchenette tablet. It printed two receipts and charged $8. I only wanted to remember a flat white. It happens with a signed-in account, and a guest can trigger it too.",
			"acceptance":["Save remembers a drink without placing an order.", "Guests are asked to sign in before writing anything.", "Retrying one request must not create a second favorite or charge."]
		},
		"reproduction":["Use a signed-in tablet session.", "Tap Save twice quickly for Flat white.", "Compare favorites, orders, and the receipts."],
		"clues":[
			{"id":"receipt", "title":"Two coffee receipts", "type":"receipt", "line":8, "text":"11:16:02  Order #2041  Flat white  $4.00\n11:16:02  Order #2042  Flat white  $4.00\nTotal charged: $8.00\nBoth receipts came from tapping Save, not Place order.", "evidence":"Save reached the purchase path twice."},
			{"id":"log", "title":"Repeated request in the log", "type":"log", "line":7, "text":"11:16:02.110  request=req-104  user=intern  action=save_favorite\n11:16:02.124  request=req-104  user=intern  action=save_favorite\n11:16:02.125  favorites=0  orders=2  charged=$8\nThe tablet retried the SAME request; the server treated it as new work.", "evidence":"A retry reused req-104, but there is no repeated-request guard."},
			{"id":"history", "title":"Archived CR #99 · Original Save shortcut", "type":"cr", "line":8, "text":"Production v1 · favorites.gd:8\n+ orders.append(drink)\nMaya: ‘This is the ordering collection. The ticket only asks to remember a favorite.’\nThe draft has no check for a request that was already handled.", "evidence":"The CR writes to orders instead of favorites."},
			{"id":"maya", "title":"Maya's requirements note", "type":"message", "line":7, "text":"Save should remember one favorite, charge nobody, and ask guests to sign in. For retries, you can guard the request ID or make the favorite write itself idempotent. If the demo is too close, disable Save temporarily and keep ordering available.", "evidence":"There are two complete fixes and a safe temporary fallback."}
		],
		"root_cause":"The Save handler calls orders.append(drink), and repeated requests have no guard. One retry therefore creates two paid orders. Guests also need an early sign-in check.",
		"suspect_line":8
	}

static func release_check(config: Dictionary) -> Dictionary:
	var checks: Array[Dictionary] = suite(config)
	var all_pass: bool = checks.size() == 3
	for check: Dictionary in checks:
		all_pass = all_pass and bool(check.get("passed", false))
	if str(config.get("strategy", "request_guard")) == "disabled":
		var app := program(config)
		var safe_disabled: bool = app != null
		if app != null:
			for user: String in ["intern", "", "intern"]:
				var response: Dictionary = app.save_favorite(user, "flat_white", "release-probe")
				safe_disabled = safe_disabled and response.get("status", "") == "unavailable" and int(response.get("charged", -1)) == 0
			safe_disabled = safe_disabled and app.get("favorites").is_empty() and app.get("orders").is_empty()
		return {"ready":safe_disabled, "safe":safe_disabled, "mode":"disabled" if safe_disabled else "blocked", "reason":"Save is temporarily unavailable; no data is written and nobody is charged." if safe_disabled else "The disabled fallback failed its safety probe.", "tradeoff":"The demo loses Save until a follow-up fix. The favorites acceptance tests still fail; this is a fallback, not a completed feature.", "checks":checks}
	var strategy: String = str(config.get("strategy", "request_guard"))
	return {"ready":all_pass, "safe":all_pass, "mode":"feature" if all_pass else "blocked", "reason":"All three isolated acceptance tests pass." if all_pass else "A required case still writes the wrong data, charges money, or handles a retry incorrectly.", "tradeoff":"Stores each drink only once, including retries with new request IDs; this changes the write behavior more broadly." if strategy == "upsert" else "Small request guard; a retry must reuse its request ID to be recognized.", "checks":checks}

static func trace(config: Dictionary, scenario: String) -> Array[Dictionary]:
	if scenario not in ["member", "guest", "double"]:
		scenario = "member"
	var original: String = source(config)
	var instrumented: String = ""
	var inside_save: bool = false
	var lines: PackedStringArray = original.split("\n")
	for index: int in lines.size():
		var line: String = lines[index]
		if line.begins_with("func save_favorite"):
			inside_save = true
			instrumented += line + "\n\t_debug_step(%d, user_id, drink, request_id)\n" % (index + 1)
		elif inside_save and line.begins_with("\t") and not line.strip_edges().begins_with("#"):
			var indentation: String = ""
			for character: String in line:
				if character != "\t":
					break
				indentation += "\t"
			instrumented += indentation + "_debug_step(%d, user_id, drink, request_id)\n" % (index + 1)
			instrumented += line + "\n"
		else:
			instrumented += line + "\n"
	instrumented += """
var _debug_steps: Array[Dictionary] = []
var _debug_charged_total: int = 0
var _debug_invocation: int = 1
func _debug_step(line: int, user_id: String, drink: String, request_id: String) -> void:
	_debug_steps.append({"line":line, "invocation":_debug_invocation, "variables":{"user_id":user_id,"drink":drink,"request_id":request_id,"favorites":favorites.duplicate(),"orders":orders.duplicate(),"seen_requests":seen_requests.duplicate(),"favorite_count":favorites.size(),"order_count":orders.size(),"charged_total":_debug_charged_total},"result":{}})
"""
	var script := GDScript.new()
	script.source_code = instrumented
	if script.reload() != OK:
		return [{"line":1,"explanation":"The code could not compile.","variables":{},"result":{},"invocation":1}]
	var app: RefCounted = script.new()
	var output: Array[Dictionary] = []
	var charged_total: int = 0
	var user_id: String = "" if scenario == "guest" else "intern"
	for invocation: int in (2 if scenario == "double" else 1):
		app.set("_debug_steps", [])
		app.set("_debug_invocation", invocation + 1)
		app.set("_debug_charged_total", charged_total)
		var response: Dictionary = app.save_favorite(user_id, "flat_white", "req-104")
		charged_total += int(response.get("charged", 0))
		var steps: Array = app.get("_debug_steps")
		for raw: Dictionary in steps:
			var step: Dictionary = raw.duplicate(true)
			var line_number: int = int(step["line"])
			step["explanation"] = _explain_line(lines[line_number - 1], step["variables"])
			output.append(step)
		if not steps.is_empty():
			var last: Dictionary = output.back()
			last["variables"] = {"user_id":user_id,"drink":"flat_white","request_id":"req-104","favorites":app.get("favorites").duplicate(),"orders":app.get("orders").duplicate(),"seen_requests":app.get("seen_requests").duplicate(),"favorite_count":app.get("favorites").size(),"order_count":app.get("orders").size(),"charged_total":charged_total}
			last["result"] = response.duplicate(true)
			last["explanation"] = "Return ‘%s’. Favorites: %d; orders: %d; total charged: $%d." % [response.get("status", ""),app.get("favorites").size(),app.get("orders").size(),charged_total]
	return output

static func _explain_line(line: String, variables: Dictionary) -> String:
	var stripped: String = line.strip_edges()
	if stripped.begins_with("func "):
		return "Handle Save request %s (user: %s)." % [variables.get("request_id", ""), "guest" if str(variables.get("user_id", "")).is_empty() else variables.get("user_id", "")]
	if stripped.contains("user_id.is_empty"):
		return "Check the guest guard: %s." % ("this user is a guest" if str(variables.get("user_id", "")).is_empty() else "this user is signed in")
	if stripped.contains("if seen_requests.has"):
		return "Check whether this exact request was already handled: %s." % ("yes" if variables.get("seen_requests", []).has(variables.get("request_id", "")) else "no")
	if stripped.contains("if favorites.has"):
		return "Check whether this drink is already a favorite: %s." % ("yes" if variables.get("favorites", []).has(variables.get("drink", "")) else "no")
	if stripped.contains("seen_requests.append"):
		return "Remember the request ID so a retry can be ignored."
	if stripped.contains("favorites.append"):
		return "Write to favorites. This remembers the drink; it does not buy it."
	if stripped.contains("orders.append"):
		return "Write to orders. This creates a paid coffee order instead of remembering a favorite."
	return "Return the result to the caller."
