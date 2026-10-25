extends RefCounted
## The exact GDScript shown in-game is compiled and exercised by the preview and tests.

static func settings(flags: Dictionary) -> Dictionary:
	var patched: bool = bool(flags.get("sandbox_patch", false))
	var clear: bool = bool(flags.get("clear_prompt", false)) or patched
	return {"guest_guard":bool(flags.get("lab_guest_guard", clear)), "write_target":str(flags.get("lab_write_target", "favorites" if clear else "orders")), "deduplicate":bool(flags.get("lab_deduplicate", patched))}

static func source(config: Dictionary) -> String:
	var code := "extends RefCounted\n\nvar favorites: Array[String] = []\nvar orders: Array[String] = []\nvar seen_requests: Array[String] = []\n\nfunc save_favorite(user_id: String, drink: String, request_id: String) -> Dictionary:\n"
	if config["guest_guard"]:
		code += "\tif user_id.is_empty():\n\t\treturn {\"status\": \"sign_in\", \"charged\": 0}\n"
	if config["deduplicate"]:
		code += "\tif seen_requests.has(request_id):\n\t\treturn {\"status\": \"already_saved\", \"charged\": 0}\n\tseen_requests.append(request_id)\n"
	code += "\t" + str(config["write_target"]) + ".append(drink)\n"
	code += "\treturn {\"status\": \"" + ("saved" if config["write_target"] == "favorites" else "ordered") + "\", \"charged\": " + ("0" if config["write_target"] == "favorites" else "4") + "}\n"
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
