extends SceneTree
const Lab = preload("res://content/engineering_lab.gd")
var checks: int = 0
var failures: Array[String] = []
func _initialize() -> void:
	run.call_deferred()
func check(condition: bool, description: String) -> void:
	checks += 1
	print(("PASS " if condition else "FAIL ") + description)
	if not condition:
		failures.append(description)
func run() -> void:
	var old := Lab.settings({"clear_prompt":true})
	check(old["strategy"] == "request_guard" and not old["deduplicate"], "Legacy clear prompt keeps the repeated-tap bug until repaired")
	var broken := Lab.settings({})
	var broken_report: Array[Dictionary] = Lab.suite(broken)
	check(not broken_report[0]["passed"] and not broken_report[1]["passed"] and not broken_report[2]["passed"], "Legacy ordering bug still fails every acceptance case")
	var guarded := Lab.settings({"sandbox_patch":true})
	var guard_report: Array[Dictionary] = Lab.suite(guarded)
	check(guard_report[0]["passed"] and guard_report[1]["passed"] and guard_report[2]["passed"], "Request guard solution passes all acceptance tests")
	var upsert := Lab.settings({"lab_strategy":"upsert","lab_guest_guard":true,"lab_write_target":"favorites"})
	var upsert_app := Lab.program(upsert)
	upsert_app.save_favorite("intern", "flat_white", "one")
	upsert_app.save_favorite("intern", "flat_white", "different")
	check(upsert_app.get("favorites").size() == 1 and upsert_app.get("orders").is_empty(), "Upsert prevents duplicate favorites across different request IDs")
	var upsert_report: Array[Dictionary] = Lab.suite(upsert)
	check(upsert_report[0]["passed"] and upsert_report[1]["passed"] and upsert_report[2]["passed"], "Upsert is a second working solution")
	var disabled := Lab.settings({"lab_strategy":"disabled"})
	var fallback: Dictionary = Lab.release_check(disabled)
	check(fallback["ready"] and fallback["safe"] and fallback["mode"] == "disabled", "Disabled Save is a safe release fallback")
	check(not fallback["checks"][0]["passed"] and not fallback["checks"][1]["passed"], "Fallback does not pretend the missing feature passes acceptance tests")
	check(not Lab.release_check(broken)["ready"] and Lab.release_check(upsert)["ready"], "Release check blocks unsafe code and accepts the working feature")
	var clues: Array = Lab.investigation()["clues"]
	check(clues.size() == 4 and clues[0]["id"] == "receipt" and clues[3]["id"] == "maya", "Investigation exposes receipts, logs, history, and Maya's note")
	for config: Dictionary in [broken, guarded, upsert, disabled]:
		for scenario: String in ["member", "guest", "double"]:
			var steps: Array[Dictionary] = Lab.trace(config, scenario)
			check(not steps.is_empty(), "Debugger executes " + str(config["strategy"]) + " / " + scenario)
			var app := Lab.program(config)
			var charged: int = 0
			var response: Dictionary = {}
			for _attempt: int in (2 if scenario == "double" else 1):
				response = app.save_favorite("" if scenario == "guest" else "intern", "flat_white", "req-104")
				charged += int(response["charged"])
			var final: Dictionary = steps.back()
			check(final["result"] == response and int(final["variables"]["favorite_count"]) == app.get("favorites").size() and int(final["variables"]["order_count"]) == app.get("orders").size() and int(final["variables"]["charged_total"]) == charged, "Debugger state matches actual execution for " + str(config["strategy"]) + " / " + scenario)
			for step: Dictionary in steps:
				check(int(step["line"]) >= 1 and int(step["line"]) <= Lab.source(config).split("\n").size() and not str(step["explanation"]).is_empty(), "Debugger step maps to a visible source line")
	print("ENGINEERING CASES TEST ", "PASS" if failures.is_empty() else "FAIL", " (", checks, " checks; ", failures.size(), " failures)")
	quit(0 if failures.is_empty() else 1)
