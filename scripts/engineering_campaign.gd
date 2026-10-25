extends RefCounted
## Investigation, staged releases, and the physical office's running coffee app.
const Lab = preload("res://content/engineering_lab.gd")
const Panels = preload("res://scripts/workbench_panels.gd")
var game: Node
var clues: Array[String] = []
var diagnosis: String = ""
var notice: String = ""
var events: Array[String] = []
var production_config: Dictionary = {}
var previous_config: Dictionary = {}
var case_config: Dictionary = {}
var production: RefCounted
var revision: int = 1
var guest: bool = false
var tablet_message: String = "Coffee app v1 · Save is live"
var waiting_for_maya: bool = false
var debug_production: bool = false
var scenario: String = "double"
var trace_index: int = 0
var production_activity: int = 0
var _cached_signature: String = ""
var _cached_check: Dictionary = {}
var _cached_traces: Dictionary = {}
var _complained: Dictionary = {}

func setup(owner: Node) -> void:
	game = owner
	production_config = Lab.settings({"vague_prompt":true})
	production = Lab.program(production_config)
	case_config = production_config.duplicate(true)
	_update_tablet()

func stage_changed(index: int) -> void:
	game.office.set_work_clock(index)
	if index == 3:
		game.flags["investigation_started"] = true
	if index in [4, 5, 7] and game.flags.get("release_deployed", false):
		_coworker_order()
	if index == 9 and game.flags.get("cr_merged", false) and not game.flags.get("release_deployed", false) and not game.flags.get("release_held", false) and not game.flags.get("release_missing_recorded", false):
		game.flags["release_missing_recorded"] = true
		game.stats.delivery = maxi(0, int(game.stats.delivery) - 4)
		game.evidence.append({"task":"An unshipped change", "decision":"The CR was merged but never deployed.", "feedback":"The office kept running the old coffee app. Delivery -4."})

func decorate(card: Dictionary, id: String) -> Dictionary:
	if id == "review" and game.flags.get("release_held", false):
		card["choices"][0] = {"label":"I'll hold the feature and document the follow-up after the demo.", "effects":{"delivery":2,"quality":3,"trust":5,"energy":-2,"tested":false,"cr_merged":false}, "feedback":"You keep Save disabled, explain the remaining work, and preserve checkout for the demo. The feature is deferred rather than falsely marked tested.", "next":""}
	elif id == "review" and str(game.flags.get("lab_strategy", "")) == "upsert":
		card["choices"][0]["effects"]["delivery"] = 3
		card["choices"][0]["effects"]["quality"] = 18
		card["choices"][0]["effects"]["energy"] = -11
		card["choices"][0]["feedback"] = "You verify that each drink is stored once, even if the request ID changes. The cleanup takes longer, but the passing evidence supports your CR."
	if id in ["mentor", "review_context"] and clues.has("maya"):
		card["body"] += "\n\nMaya adds: ‘The receipt has the same request ID twice. Check which collection the Save handler writes to.’"
	return card

func interact(id: String) -> bool:
	if id in ["manager", "manager_seat", "intern"]:
		var person_id: String = "manager" if id == "manager_seat" else id
		if not game.office.person_available(person_id) and game.awaiting_person != person_id:
			for entry: Dictionary in game.office.schedule_status():
				if str(entry["id"]) == person_id:
					game._start_conversation(person_id)
					game._open_custom({"_lab_action":"schedule", "_person":str(entry["person"]), "title":str(entry["person"]) + " is busy", "speaker":str(entry["person"]), "body":str(entry["status"]) + " · " + str(entry["location"]) + ". They can read a message when they finish.", "choices":[{"label":"I'll send the context on Slack."},{"label":"I'll catch you after the meeting."}]}, true)
					return true
	if id == "coffee_tablet":
		_open_tablet()
		return true
	if id == "mentor" and waiting_for_maya:
		waiting_for_maya = false
		_remember("maya")
		if game.awaiting_person == "mentor":
			return false
		game._start_conversation("mentor")
		game._open_custom({"title":"Maya's original change", "speaker":"Maya", "body":"The previous CR reused the order handler. The receipt shows the same request ID twice. Save should remember a drink, not buy it, and a retry should not write again.", "choices":[{"label":"Thanks. I'll compare the log with that write path.", "effects":{}, "feedback":"", "next":""}]}, true)
		return true
	return false

func schedule_action(index: int) -> void:
	var person: String = str(game.current_card.get("_person", "Jordan"))
	if index == 0:
		game.computer.record_sent_message(person, "I'm investigating the coffee Save issue. I'll attach the receipt and test results so you can read them after the meeting.")
		game.computer.post_office_message(person, "Thanks for sending context. I'll read it when this session finishes.")
	game.hud.hide_modal()
	game._end_conversation()
	game.decision_open = false
	game.player.set_active(true)

func tablet_action(index: int) -> void:
	if index == 3:
		game.hud.hide_modal()
		game.player.set_active(true)
		game.decision_open = false
		return
	if index == 1:
		guest = not guest
		tablet_message = "Guest session" if guest else "Signed in as intern"
	else:
		var key: String = "office-%d" % production_activity
		production_activity += 1
		var result := _save("" if guest else "intern", key)
		if index == 2:
			var second := _save("" if guest else "intern", key)
			tablet_message = "Two taps · %s / %s · charged $%d" % [result["status"], second["status"], int(result["charged"]) + int(second["charged"])]
		else:
			tablet_message = "%s · charged $%d" % [str(result["status"]).capitalize(), int(result["charged"])]
		if int(result["charged"]) > 0:
			game.flags["investigation_started"] = true
			_post_complaint("Sam", "I tapped Save on the kitchen tablet and got charged. The receipt is in the investigation case.")
	_update_tablet()
	_open_tablet()

func _open_tablet() -> void:
	game._open_custom({"_lab_action":"tablet", "title":"Small Batch · Office tablet", "speaker":"Coffee app v%d · %s" % [revision, "Guest" if guest else "Intern"], "body":"Flat white · $4\n%s\nFavorites: %d · Orders: %d\n\nLive revision · Deploy staging changes from Release." % [tablet_message, production.get("favorites").size(), production.get("orders").size()], "choices":[{"label":"Save a flat white."},{"label":"Sign in." if guest else "Use guest mode."},{"label":"Tap Save twice."},{"label":"Close the tablet."}]}, true)

func _save(user: String, key: String) -> Dictionary:
	return production.save_favorite(user, "flat_white", key)

func _update_tablet() -> void:
	if game.office.has_method("set_tablet_state"):
		game.office.set_tablet_state(production.get("favorites").size(), production.get("orders").size(), "v%d · %s" % [revision, tablet_message])

func _remember(clue: String) -> void:
	if not clues.has(clue):
		clues.append(clue)
	game.flags["investigation_started"] = true
	game._update_hud()

func _post_complaint(sender: String, text: String) -> void:
	var key: String = "%d:%s" % [revision, sender]
	if _complained.has(key):
		return
	_complained[key] = true
	game.computer.post_office_message(sender, text)
	events.append(sender + ": " + text)

func _coworker_order() -> void:
	var before: int = production.get("orders").size()
	var key: String = "coworker-%d" % production_activity
	production_activity += 1
	_save("sam", key)
	_save("sam", key)
	if production.get("orders").size() > before:
		tablet_message = "Unexpected orders · inspect or roll back"
		_post_complaint("Sam", "The deployed Save button made extra coffee orders. Please roll back or disable it while you investigate.")
	elif str(production_config.get("strategy", "")) == "disabled":
		tablet_message = "Save paused · checkout available"
		_post_complaint("Maya", "Save is temporarily unavailable. Checkout still works; thanks for making the tradeoff visible.")
	else:
		tablet_message = "Healthy · favorites saved, no charges"
		_post_complaint("Sam", "Tried the kitchen tablet again. One favorite, no surprise charges. Nice fix!")
	_update_tablet()

func route(action: String) -> void:
	if action.begins_with("clue:"):
		var clue: String = action.trim_prefix("clue:")
		if clue == "maya":
			waiting_for_maya = true
			game.flags["investigation_started"] = true
			if game.seated:
				game._stand_up()
			var location: String = "her desk"
			for entry: Dictionary in game.office.schedule_status():
				if str(entry.get("id", "")) == "mentor":
					location = str(entry.get("location", location))
			game._update_hud()
			game.hud.toast("Maya is at " + location + ". Ask about the original Save change.")
			return
		_remember(clue)
		_render("investigation")
		return
	if action.begins_with("diagnose:"):
		if not clues.has("receipt") or not clues.has("log"):
			diagnosis = "Attach a receipt and request log before posting a cause."
		elif action == "diagnose:retry":
			diagnosis = str(Lab.investigation()["root_cause"])
			game.flags["investigation_diagnosed"] = true
			waiting_for_maya = false
		else:
			diagnosis = "The two receipts have the same request ID and price. Inspect the repeated write before changing another system."
		_render("investigation")
		return
	if action.begins_with("strategy:"):
		var strategy: String = action.trim_prefix("strategy:")
		if strategy == "disabled":
			_disable()
		else:
			game._sandbox_action("edit:guest_guard:true")
			game._sandbox_action("edit:write_target:favorites")
			game._sandbox_action("edit:deduplicate:" + ("true" if strategy == "request_guard" else "false"))
			game._sandbox_action("edit:strategy:" + strategy)
			game.flags["release_held"] = false
			notice = "Small retry guard selected: minimal scope, same-request retries protected." if strategy == "request_guard" else "Store-once cleanup selected: also handles retries with a new request ID; allow extra review time."
		_render("release")
		return
	match action:
		"investigation":
			game.flags["investigation_started"] = true
			_render("investigation")
		"release": _render("release")
		"calendar": _render("calendar")
		"debugger": debug_production = false; trace_index = 0; _render("debugger")
		"deploy": _deploy()
		"deploy_anyway": _deploy(true)
		"rollback":
			if previous_config.is_empty():
				notice = "No earlier deployment is available to roll back."
			else:
				var restore: Dictionary = previous_config.duplicate(true)
				previous_config = production_config.duplicate(true)
				production_config = restore
				production = Lab.program(production_config)
				game.flags["release_held"] = str(production_config.get("strategy", "")) == "disabled"
				game.flags["release_deployed"] = true
				revision += 1
				tablet_message = "Rolled back to the previous code revision"
				notice = "Previous code restored. Verify it on the office tablet: a rollback can restore an old bug too."
				_coworker_order()
			_update_tablet()
			_render("release")
		"disable": _disable()
		"request_review":
			if game.flags.get("release_followup_allowed", false) and bool(_release_check()["safe"]):
				game.flags["cr_merged"] = true
				game.flags["tested"] = str(Lab.settings(game.flags).get("strategy", "")) != "disabled"
				notice = "Maya approved the passing follow-up. Deploy when you're ready; production is still unchanged."
				game.computer.post_office_message("Maya", "The follow-up checks pass. Approved the small repair; please verify it on the tablet after deployment.")
			else:
				notice = "Complete the current CR task, or attach passing checks to the deferred feature before requesting its follow-up review."
			_render("release")
		"refresh_orders":
			_coworker_order()
			notice = "A coworker tried the deployed revision. Live tablet counts and messages are updated."
			_render("release")
		"inspect_log":
			debug_production = true
			scenario = "double"
			trace_index = 0
			var trace: Array[Dictionary] = _trace()
			for index: int in trace.size():
				if str(trace[index].get("explanation", "")).to_lower().contains("append") or str(trace[index].get("explanation", "")).to_lower().contains("write"):
					trace_index = index
					break
			_render("debugger")
		"step": trace_index += 1; _render("debugger")
		"back": trace_index = maxi(0, trace_index - 1); _render("debugger")
		"reset_trace": trace_index = 0; _render("debugger")
		_:
			if action.begins_with("debug:"):
				scenario = action.trim_prefix("debug:")
				trace_index = 0
				_render("debugger")

func _deploy(allow_unsafe: bool = false) -> void:
	var config := Lab.settings(game.flags)
	var check := _release_check()
	if not bool(check["safe"]) and not allow_unsafe:
		notice = "Deployment blocked: " + str(check["reason"]) + " Run the tests or choose a safe temporary hold."
		_render("release")
		return
	if not allow_unsafe and not game.flags.get("cr_merged", false) and str(config.get("strategy", "")) != "disabled":
		notice = "The candidate passes checks, but CR #104 still needs review and merge before a normal deployment. The temporary hold remains available for an urgent mitigation."
		_render("release")
		return
	previous_config = production_config.duplicate(true)
	production_config = config.duplicate(true)
	production = Lab.program(production_config)
	revision += 1
	game.flags["release_deployed"] = true
	game.flags["release_held"] = str(config.get("strategy", "")) == "disabled"
	tablet_message = "Release deployed"
	notice = "Revision %d is live on the kitchen tablet. Staging edits won't change it until the next deployment." % revision
	if not bool(check["safe"]):
		game.stats.quality = maxi(0, int(game.stats.quality) - 3)
		game.stats.trust = maxi(0, int(game.stats.trust) - 4)
		notice = "Unverified revision %d is live. Quality -3; Trust -4. Try the tablet or roll back if it misbehaves." % revision
		game.computer.post_office_message("Pager bot", "SEV-2: the coffee revision shipped with failed checks. Watch for duplicate writes and unexpected orders.")
	events.append(notice)
	game.evidence.append({"task":"Coffee app release", "decision":"Deployed revision %d using %s." % [revision, config.get("strategy", "request_guard")], "feedback":str(check["tradeoff"])})
	_coworker_order()
	game._update_hud()
	_render("release")

func _disable() -> void:
	previous_config = production_config.duplicate(true)
	production_config = Lab.settings({"lab_strategy":"disabled"})
	production = Lab.program(production_config)
	revision += 1
	game.flags["release_held"] = true
	game.flags["release_followup_allowed"] = true
	game.flags["release_deployed"] = true
	tablet_message = "Save temporarily disabled · Checkout remains available"
	notice = "Save is held for the demo. No false passing tests: the feature still needs a follow-up, while coffee checkout stays available."
	events.append(notice)
	game._update_hud()
	_update_tablet()
	_render("release")

func _release_check() -> Dictionary:
	var config := Lab.settings(game.flags)
	var signature: String = Lab.source(config)
	if signature != _cached_signature or _cached_check.is_empty():
		_cached_signature = signature
		_cached_check = Lab.release_check(config)
		_cached_traces.clear()
	return _cached_check

func _trace() -> Array[Dictionary]:
	_release_check()
	var config: Dictionary = case_config if debug_production else Lab.settings(game.flags)
	var key: String = Lab.source(config) + ":" + scenario
	if not _cached_traces.has(key):
		_cached_traces[key] = Lab.trace(config, scenario)
	return _cached_traces[key]

func _render(page: String) -> void:
	var config := Lab.settings(game.flags)
	var check := _release_check()
	var passed: int = 0
	for result: Dictionary in check["checks"]:
		if result["passed"]:
			passed += 1
	var trace: Array[Dictionary] = []
	if page == "debugger":
		trace = _trace()
	trace_index = clampi(trace_index, 0, maxi(0, trace.size() - 1))
	Panels.render(game.computer, page, {"ticket":Lab.investigation(), "clues":clues, "diagnosis":diagnosis, "diagnosis_correct":game.flags.get("investigation_diagnosed", false), "source":Lab.source(case_config if page == "debugger" and debug_production else config), "debug_context":"Production v1 · captured receipt/log snapshot" if debug_production else "Staging · current editor revision", "trace":trace, "trace_index":trace_index, "scenario":scenario, "production_status":tablet_message, "production_revision":revision, "production_orders":production.get("orders").size(), "production_favorites":production.get("favorites").size(), "staging_passed":passed, "review_approved":game.flags.get("cr_merged", false), "followup_review":game.flags.get("release_followup_allowed", false), "events":events, "schedule":game.office.schedule_status(), "notice":notice, "release_reason":check["reason"], "strategy":str(config.get("strategy", "request_guard")), "staging_summary":str(config.get("strategy", "request_guard"))})
	game._update_hud()
