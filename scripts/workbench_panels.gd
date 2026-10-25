extends RefCounted
## Additive workstation pages. Gameplay state and actions are owned by main.gd.

const INK := Color("24292f")
const SOFT := Color("6e7781")
const GREEN := Color("238449")
const PAPER := Color("ffffff")
const PALE := Color("f6f8fa")

static func render(host: Node, page: String, state: Dictionary) -> void:
	match page:
		"investigation":
			_investigation(host, state)
		"release":
			_release(host, state)
		"debugger":
			_debugger(host, state)
		"calendar":
			_calendar(host, state)
		_:
			var content: VBoxContainer = host._browse_start("changes", "Workbench")
			host._plain_message(content, "Workspace", "This view is not available yet.", PAPER)

static func _action(host: Node, parent: Control, text: String, route: String, primary: bool = false, width: int = 180) -> Button:
	var button: Button = host._button(text, primary)
	button.custom_minimum_size = Vector2(width, 42)
	button.add_theme_font_size_override("font_size", 17)
	button.set_meta("action_text", text)
	button.pressed.connect(func() -> void: host.app_requested.emit(route))
	parent.add_child(button)
	return button

static func _actions(host: Node) -> HFlowContainer:
	var row := HFlowContainer.new()
	row.add_theme_constant_override("h_separation", 8)
	row.add_theme_constant_override("v_separation", 6)
	host._window_stack.add_child(row)
	return row

static func _body(host: Node, parent: Control, text: String, size: int = 18, color: Color = INK) -> Label:
	var label: Label = host._label(text, size, color)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	parent.add_child(label)
	return label

static func _investigation(host: Node, state: Dictionary) -> void:
	var data: Dictionary = state.get("ticket", {})
	var ticket: Dictionary = data.get("ticket", data)
	var content: VBoxContainer = host._browse_start("changes", str(ticket.get("id", "SB-105")) + " · Bug investigation")
	_body(host, content, str(ticket.get("title", "One Save, two charges")), 23)
	host._plain_message(content, str(ticket.get("reporter", "Sam")) + " · Bug report", str(ticket.get("body", "A coworker tapped Save twice and received two coffee orders. Find the request path before changing it.")), PAPER)
	var evidence_actions := HFlowContainer.new()
	evidence_actions.add_theme_constant_override("h_separation", 7)
	evidence_actions.add_theme_constant_override("v_separation", 6)
	host._window_stack.add_child(evidence_actions)
	host._window_stack.move_child(evidence_actions, content.get_parent().get_index())
	var discovered: Array = state.get("clues", [])
	for entry: Array in [["receipt", "Receipt"], ["log", "Request log"], ["history", "Previous CR"], ["maya", "Maya's note"]]:
		var clue_id: String = str(entry[0])
		var title: String = str(entry[1])
		_action(host, evidence_actions, ("✓ " if discovered.has(clue_id) else "") + title, "lab:clue:" + clue_id, false, 180)
	if discovered.is_empty():
		_body(host, content, "The report, request log, and previous change are available in this case.", 17, SOFT)
	var focused_evidence: Control
	var focus_id: String = str(state.get("focus_clue", discovered.back() if not discovered.is_empty() else ""))
	for clue_id: Variant in discovered:
		var clue: Dictionary = _find_clue(data, str(clue_id))
		var location: String = ""
		if int(clue.get("line", 0)) > 0:
			location = " · favorites.gd:%d" % int(clue["line"])
		host._plain_message(content, str(clue.get("title", str(clue_id).capitalize())) + location, str(clue.get("text", "Evidence attached.")), Color("f1f7fb"))
		var evidence: String = str(clue.get("evidence", ""))
		if not evidence.is_empty() and evidence != str(clue.get("text", "")):
			host._code_block(content, evidence)
		if str(clue_id) == "log":
			_action(host, content, "Inspect the write in debugger", "lab:inspect_log", false, 290)
		if str(clue_id) == focus_id:
			focused_evidence = content.get_child(content.get_child_count() - 1)
	_reveal_line(host, focused_evidence)
	var diagnosis: String = str(state.get("diagnosis", ""))
	if not diagnosis.is_empty():
		_body(host, host._window_stack, diagnosis, 18, GREEN if bool(state.get("diagnosis_correct", false)) else INK)
	var choices := VBoxContainer.new()
	choices.add_theme_constant_override("separation", 5)
	host._window_stack.add_child(choices)
	_action(host, choices, "The repeated request is processed twice.", "lab:diagnose:retry", false, 0)
	_action(host, choices, "The payment provider charged the wrong price.", "lab:diagnose:payment", false, 0)
	_action(host, choices, "The office server needs a restart.", "lab:diagnose:server", false, 0)
	var links := _actions(host)
	_action(host, links, "Open source", "source", false, 180)
	_action(host, links, "Open app preview", "sandbox", false, 210)

static func _find_clue(data: Dictionary, id: String) -> Dictionary:
	var clues: Variant = data.get("clues", [])
	if clues is Dictionary:
		var value: Variant = clues.get(id, {})
		return value if value is Dictionary else {"title":id.capitalize(), "text":str(value)}
	if clues is Array:
		for entry: Variant in clues:
			if entry is Dictionary and str(entry.get("id", "")) == id:
				return entry
	var fallback: Dictionary = {
		"receipt":{"title":"Duplicate receipt", "text":"Two $4 coffee charges share the same Save request."},
		"log":{"title":"Request log", "text":"The same request arrived twice; each attempt reached the write path."},
		"history":{"title":"Previous CR", "text":"The old Save change added the write but did not handle repeated requests."},
		"maya":{"title":"Maya's note", "text":"Check the request identifier. A retried request should not buy another coffee."}
	}
	return fallback.get(id, {"title":id.capitalize(), "text":"Evidence attached."})

static func _release(host: Node, state: Dictionary) -> void:
	var content: VBoxContainer = host._browse_start("changes", "Release · coffee-app")
	var passed: int = int(state.get("staging_passed", 0))
	var revision: int = int(state.get("production_revision", 0))
	var status: String = str(state.get("production_status", "Initial release"))
	host._plain_message(content, "STAGING · intern/save-favorites", "%d / 3 checks passed · %s. The kitchenette tablet still runs production." % [passed, "CR merged" if state.get("review_approved", false) else "CR review pending"], Color("eef6fb"))
	var summary: String = "Revision %d · %s\nFavorites: %d    Orders: %d" % [revision, status, int(state.get("production_favorites", 0)), int(state.get("production_orders", 0))]
	host._plain_message(content, "PRODUCTION · Kitchenette tablet", summary, Color("eef8f0") if status.to_lower().contains("healthy") else Color("fff8ed"))
	var candidate: String = str(state.get("release_reason", state.get("staging_summary", "Deploy sends the current source to the office tablet. Rollback restores the previous revision; disabling Save keeps the rest of the app available.")))
	_body(host, content, candidate, 18, SOFT)
	var events: Array = state.get("events", [])
	if not events.is_empty():
		_body(host, content, "Release activity", 19)
		for event: Variant in events.slice(maxi(0, events.size() - 5)):
			_body(host, content, "• " + str(event), 17, SOFT)
	var notice: String = str(state.get("notice", ""))
	if not notice.is_empty():
		host._plain_message(host._window_stack, "Release update", notice, PAPER)
	var approaches := _actions(host)
	var strategy: String = str(state.get("strategy", state.get("staging_strategy", "request_guard")))
	for entry: Array in [["request_guard", "Small request guard"], ["upsert", "Store each favorite once"], ["disabled", "Hold feature for the demo"]]:
		_action(host, approaches, str(entry[1]), "lab:strategy:" + str(entry[0]), strategy == str(entry[0]), 270)
	var controls := _actions(host)
	_action(host, controls, "Deploy to office tablet", "lab:deploy", passed == 3, 240)
	_action(host, controls, "Roll back", "lab:rollback", false, 180)
	_action(host, controls, "Disable Save", "lab:disable", false, 180)
	_action(host, controls, "Refresh office orders", "lab:refresh_orders", false, 240)
	var links := _actions(host)
	if passed < 3:
		var override := _action(host, links, "Ship despite failed checks", "lab:deploy_anyway", false, 270)
		override.add_theme_color_override("font_color", Color("b33d45"))
	if state.get("followup_review", false) and passed == 3 and not state.get("review_approved", false):
		_action(host, links, "Request follow-up review", "lab:request_review", false, 260)
	_action(host, links, "Run tests", "tests", false, 180)
	_action(host, links, "Open source", "source", false, 180)
	_action(host, links, "Back to CR #104", "cr:104", false, 200)

static func _debugger(host: Node, state: Dictionary) -> void:
	var content: VBoxContainer = host._browse_start("changes", "Debugger · favorites.gd")
	var scenario: String = str(state.get("scenario", "member"))
	_body(host, content, str(state.get("debug_context", "Staging · current editor revision")), 16, SOFT)
	var scenarios := HFlowContainer.new()
	scenarios.add_theme_constant_override("h_separation", 8)
	host._window_stack.add_child(scenarios)
	host._window_stack.move_child(scenarios, content.get_parent().get_index())
	for entry: Array in [["member", "Signed-in Save"], ["guest", "Guest Save"], ["double", "Double tap"]]:
		_action(host, scenarios, str(entry[1]), "lab:debug:" + str(entry[0]), scenario == str(entry[0]), 210)
	var trace: Array = state.get("trace", [])
	var index: int = clampi(int(state.get("trace_index", 0)), 0, maxi(0, trace.size() - 1))
	var step: Dictionary = trace[index] if not trace.is_empty() and trace[index] is Dictionary else {}
	var current_line: int = int(step.get("line", 0))
	var selected_line: Control = _highlighted_source(host, content, str(state.get("source", "")), current_line)
	_reveal_line(host, selected_line)
	if trace.is_empty():
		_body(host, content, "Choose a request to follow its path through the code.", 17, SOFT)
	else:
		var variables: Dictionary = step.get("variables", {})
		var values := HFlowContainer.new()
		values.add_theme_constant_override("h_separation", 15)
		values.add_theme_constant_override("v_separation", 5)
		host._window_stack.add_child(values)
		for key: String in ["user_id", "request_id", "favorite_count", "order_count", "charged_total"]:
			if variables.has(key):
				var watch := _body(host, values, key + " = " + _value(variables[key]), 16, SOFT)
				watch.autowrap_mode = TextServer.AUTOWRAP_OFF
		var result: Dictionary = step.get("result", {})
		if not result.is_empty():
			_body(host, content, "Returned: " + JSON.stringify(result), 17, GREEN)
	var explanation: String = str(step.get("explanation", "The current line is highlighted. Advance to see what it does."))
	host._plain_message(host._window_stack, "Step %d / %d · line %d" % [index + 1 if not trace.is_empty() else 0, trace.size(), current_line], explanation, Color("eef8f0"))
	var controls := _actions(host)
	_action(host, controls, "Trace staging code", "lab:debugger", false, 220)
	var back := _action(host, controls, "Previous line", "lab:back", false, 200)
	back.disabled = index <= 0
	var next := _action(host, controls, "Step forward", "lab:step", true, 200)
	next.disabled = trace.is_empty() or index >= trace.size() - 1
	_action(host, controls, "Restart trace", "lab:reset_trace", false, 200)
	_action(host, controls, "Open source", "source", false, 180)

static func _highlighted_source(host: Node, parent: Control, source: String, current_line: int) -> Control:
	var panel := PanelContainer.new()
	var style := StyleBoxFlat.new()
	style.bg_color = Color("18222e")
	style.set_corner_radius_all(8)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 2)
	panel.add_child(stack)
	var mono := SystemFont.new()
	mono.font_names = PackedStringArray(["Consolas", "Liberation Mono", "monospace"])
	var selected_line: Control
	var line_number: int = 1
	for line: String in source.split("\n"):
		var selected: bool = line_number == current_line
		var label: Label = host._label(("▶ " if selected else "  ") + "%02d  %s" % [line_number, line.replace("\t", "    ")], 15, Color("d8e4ef"))
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.add_theme_font_override("font", mono)
		if selected:
			selected_line = label
			var highlight := StyleBoxFlat.new()
			highlight.bg_color = Color("28564d")
			highlight.content_margin_left = 4
			highlight.content_margin_right = 4
			label.add_theme_stylebox_override("normal", highlight)
		stack.add_child(label)
		line_number += 1
	return selected_line

static func _reveal_line(host: Node, line: Control) -> void:
	if not is_instance_valid(host):
		return
	var tree: SceneTree = host.get_tree()
	await tree.process_frame
	await tree.process_frame
	if not is_instance_valid(line):
		return
	var ancestor: Node = line.get_parent()
	while ancestor != null:
		if ancestor is ScrollContainer:
			ancestor.ensure_control_visible(line)
			return
		ancestor = ancestor.get_parent()

static func _value(value: Variant) -> String:
	if value is String:
		return '"' + str(value) + '"'
	return JSON.stringify(value)

static func _calendar(host: Node, state: Dictionary) -> void:
	var content: VBoxContainer = host._browse_start("changes", "Team calendar")
	var entries: Array = state.get("schedule", [])
	if entries.is_empty():
		_body(host, content, "The team's current locations will appear here.", 18, SOFT)
	for entry: Variant in entries:
		if not entry is Dictionary:
			continue
		var person: String = str(entry.get("person", entry.get("name", "Coworker")))
		var location: String = str(entry.get("location", "Office"))
		var status: String = str(entry.get("status", "Available"))
		host._plain_message(content, person + " · " + location, status, PAPER)
		var first_name: String = person.split(" ")[0]
		if first_name in ["Maya", "Sam", "Jordan"]:
			_action(host, content, "Message " + first_name, "dm:" + first_name, false, 210)
	var note: String = str(state.get("calendar_note", "People move between their desks, meetings, and coffee breaks. Messages still reach them while they are away."))
	_body(host, host._window_stack, note, 17, SOFT)
	var controls := _actions(host)
	_action(host, controls, "Refresh calendar", "lab:calendar", false, 230)
	_action(host, controls, "Back to CR #104", "cr:104", false, 210)
