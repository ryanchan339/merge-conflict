extends CanvasLayer

signal choice_selected(index: int)
signal continue_pressed
signal resume_pressed
signal restart_pressed
signal quit_pressed

const OfficeMap = preload("res://scripts/office_map.gd")
const UIFont = preload("res://assets/fonts/Inter.ttf")
const INK := Color("19333f")
const CREAM := Color("f8f5e9")
const MUTED := Color("5b7378")
const TEAL := Color("087f81")

var minimap: Control
var _root: Control
var _clock: Label
var _clock_chip: PanelContainer
var _objective: PanelContainer
var _objective_title: Label
var _objective_detail: Label
var _focus: PanelContainer
var _focus_text: Label
var _crosshair: Label
var _incident: PanelContainer
var _incident_time: Label
var _modal_layer: Control
var _dim: ColorRect
var _modal: PanelContainer
var _stack: VBoxContainer
var _toast_panel: PanelContainer
var _toast_text: Label
var _toast_timer: Timer
var _mode: String = ""
var _choice_count: int = 0
var _seated: bool = false
var _stats: Dictionary = {}
var _stats_layer: CanvasLayer
var _stats_root: Control
var _stats_panel: PanelContainer
var _stat_values: Dictionary = {}
var _conversation: bool = false


func _ready() -> void:
	layer = 20
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme := Theme.new()
	theme.default_font = UIFont
	theme.default_font_size = 18
	theme.set_color("font_color", "Label", INK)
	theme.set_color("font_color", "Button", INK)
	theme.set_color("font_hover_color", "Button", INK)
	theme.set_color("font_pressed_color", "Button", INK)
	theme.set_color("font_focus_color", "Button", INK)
	theme.set_stylebox("normal", "Button", _box(Color("e9eee5"), 9))
	theme.set_stylebox("hover", "Button", _box(Color("d6e9df"), 9, TEAL))
	theme.set_stylebox("pressed", "Button", _box(Color("c2dfd3"), 9))
	theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, 9, TEAL))
	_root.theme = theme
	add_child(_root)
	_build_walk_hud()
	_build_modal()
	_build_persistent_stats()
	set_status({}, "09:00", "")
	set_objective("Welcome to Small Batch", "Find your team.")
	get_viewport().size_changed.connect(_fit_modal)


func _build_walk_hud() -> void:
	_objective = _panel(Color(0.07, 0.16, 0.20, 0.86), 12)
	_root.add_child(_objective)
	_objective.position = Vector2(28, 28)
	_objective.size = Vector2(392, 88)
	var margin := _margin(17, 12, 17, 12)
	_objective.add_child(margin)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 4)
	margin.add_child(copy)
	_objective_title = _label("", 20, CREAM)
	_objective_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_objective_title)
	_objective_detail = _label("", 14, Color("ccd8cf"))
	_objective_detail.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	copy.add_child(_objective_detail)
	_clock_chip = _panel(Color(0.07, 0.16, 0.20, 0.86), 8)
	_root.add_child(_clock_chip)
	_clock_chip.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	_clock_chip.offset_left = -119
	_clock_chip.offset_right = -28
	_clock_chip.offset_top = 28
	_clock_chip.offset_bottom = 68
	_clock = _label("09:00", 21, CREAM)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_clock_chip.add_child(_clock)
	_crosshair = _label("·", 32, CREAM)
	_root.add_child(_crosshair)
	_crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_crosshair.offset_left = -12
	_crosshair.offset_right = 12
	_crosshair.offset_top = -24
	_crosshair.offset_bottom = 6
	_crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crosshair.add_theme_color_override("font_shadow_color", INK)
	_crosshair.add_theme_constant_override("shadow_offset_y", 1)
	_focus = _panel(Color(0.07, 0.16, 0.20, 0.91), 9)
	_root.add_child(_focus)
	_focus.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_focus.offset_left = -215
	_focus.offset_right = 215
	_focus.offset_top = -88
	_focus.offset_bottom = -40
	var focus_margin := _margin(16, 9, 16, 9)
	_focus.add_child(focus_margin)
	_focus_text = _label("", 18, CREAM)
	_focus_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_focus_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	focus_margin.add_child(_focus_text)
	_focus.hide()
	minimap = OfficeMap.new()
	_root.add_child(minimap)
	minimap.hide()
	_incident = _panel(Color("aa3b32"), 11)
	_root.add_child(_incident)
	_incident.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_incident.offset_left = -235
	_incident.offset_right = 235
	_incident.offset_top = 126
	_incident.offset_bottom = 184
	var incident_margin := _margin(18, 10, 18, 10)
	_incident.add_child(incident_margin)
	var incident_row := HBoxContainer.new()
	incident_margin.add_child(incident_row)
	var alert := _label("SEV-1 · Get to your desk", 18, Color.WHITE)
	alert.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	incident_row.add_child(alert)
	_incident_time = _label("00:45", 25, Color.WHITE)
	incident_row.add_child(_incident_time)
	_incident.hide()
	_toast_panel = _panel(INK, 10)
	_root.add_child(_toast_panel)
	_toast_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_toast_panel.offset_left = -350
	_toast_panel.offset_right = 350
	_toast_panel.offset_top = -150
	_toast_panel.offset_bottom = -100
	var toast_margin := _margin(18, 12, 18, 12)
	_toast_panel.add_child(toast_margin)
	_toast_text = _label("", 17, CREAM)
	_toast_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_toast_text.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_margin.add_child(_toast_text)
	_toast_panel.hide()
	_toast_timer = Timer.new()
	_toast_timer.one_shot = true
	_toast_timer.wait_time = 2.8
	_toast_timer.timeout.connect(func() -> void: _toast_panel.hide())
	add_child(_toast_timer)


func _build_modal() -> void:
	_modal_layer = Control.new()
	_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.add_child(_modal_layer)
	_dim = ColorRect.new()
	_dim.color = Color(0.03, 0.08, 0.10, 0.62)
	_dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.add_child(_dim)
	_modal = _panel(CREAM, 18)
	_modal_layer.add_child(_modal)
	var margin := _margin(27, 23, 27, 23)
	_modal.add_child(margin)
	_stack = VBoxContainer.new()
	_stack.add_theme_constant_override("separation", 13)
	margin.add_child(_stack)
	_modal_layer.hide()
	_fit_modal()


func _build_persistent_stats() -> void:
	# This layer stays above the dialogue dimmer and the phone's layer 40.
	_stats_layer = CanvasLayer.new()
	_stats_layer.layer = 60
	add_child(_stats_layer)
	_stats_root = Control.new()
	_stats_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stats_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stats_root.theme = _root.theme
	_stats_layer.add_child(_stats_root)
	_stats_panel = _panel(Color(0.07, 0.16, 0.20, 0.96), 10)
	_stats_panel.name = "PersistentStats"
	_stats_root.add_child(_stats_panel)
	_stats_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_stats_panel.offset_left = -280
	_stats_panel.offset_right = 280
	_stats_panel.offset_top = 28
	_stats_panel.offset_bottom = 78
	var margin := _margin(8, 9, 8, 9)
	_stats_panel.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 18)
	margin.add_child(row)
	for key: String in ["delivery", "quality", "trust", "energy"]:
		var cell := HBoxContainer.new()
		cell.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		cell.add_theme_constant_override("separation", 8)
		row.add_child(cell)
		var name_label := _label(key.capitalize(), 14, Color("b4c9c5"))
		name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(name_label)
		var number := _label("50", 20, CREAM)
		number.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		cell.add_child(number)
		_stat_values[key] = number


func set_status(stats: Dictionary, time_text: String, _chapter: String) -> void:
	_stats = stats.duplicate(true)
	_clock.text = time_text
	for key: String in _stat_values:
		var value: Label = _stat_values[key]
		value.text = str(clampi(roundi(float(stats.get(key, 50))), 0, 100))


func set_objective(title: String, detail: String) -> void:
	_objective_title.text = title
	_objective_detail.text = detail.split(". ")[0].trim_suffix(".")


func set_focus(text: String) -> void:
	_focus.visible = not text.is_empty() and not is_modal_open() and not _seated
	_focus_text.text = text if text.begins_with("F  ·  ") or text.begins_with("F · ") else "E  ·  " + text


func set_distance(_meters: float) -> void:
	pass


func set_seated(active: bool) -> void:
	_seated = active
	_objective.visible = not active
	_clock.visible = not active
	_clock_chip.visible = not active
	_crosshair.visible = not active
	if active:
		_focus.hide()


func set_conversation(active: bool) -> void:
	_conversation = active
	_crosshair.visible = not active and not _seated
	_objective.visible = not active and not _seated
	_fit_modal()


func toast(text: String) -> void:
	_toast_text.text = text
	_toast_panel.show()
	_toast_timer.start()


func set_incident(seconds: float, active: bool) -> void:
	_incident.visible = active
	var remaining: int = maxi(0, ceili(seconds))
	_incident_time.text = "%02d:%02d" % [floori(remaining / 60.0), remaining % 60]


func show_card(card: Dictionary) -> void:
	_open_modal("choice")
	var speaker: String = str(card.get("speaker", ""))
	if not speaker.is_empty():
		_stack.add_child(_label(speaker.split(" · ")[0], 14, MUTED))
	_stack.add_child(_title(str(card.get("title", ""))))
	var content := _scroll_content()
	content.add_child(_body(str(card.get("body", ""))))
	var choices: Array = card.get("choices", [])
	_choice_count = choices.size()
	for index in range(choices.size()):
		var choice: Dictionary = choices[index]
		var button := _button("%d  %s" % [index + 1, str(choice.get("label", "Continue."))])
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_emit_choice.bind(index))
		content.add_child(button)


func show_feedback(text: String, changes: Dictionary = {}) -> void:
	_open_modal("feedback")
	var content := _scroll_content()
	if not text.is_empty():
		content.add_child(_body(text.split("\n\n")[0]))
	var change_row := HFlowContainer.new()
	change_row.add_theme_constant_override("h_separation", 18)
	change_row.add_theme_constant_override("v_separation", 6)
	content.add_child(change_row)
	for key: String in ["delivery", "quality", "trust", "energy"]:
		var delta: int = int(changes.get(key, 0))
		if delta != 0:
			var change_label := _label("%s %+d" % [key.capitalize(), delta], 19, Color("16734c") if delta > 0 else Color("b33f3f"))
			change_row.add_child(change_label)
	if changes.is_empty():
		change_row.add_child(_label("No stat changes.", 16, MUTED))
	var button := _button("Continue.", true)
	button.pressed.connect(func() -> void: continue_pressed.emit())
	_stack.add_child(button)


func show_pause() -> void:
	_open_modal("pause")
	_stack.add_child(_title("Taking a breather."))
	var content := _scroll_content()
	var instructions: String = "Use WASD to walk, the mouse to look, Shift to hurry, and E to interact."
	if OS.has_feature("web"):
		instructions = "Use WASD to walk. Hold the right mouse button or use arrow keys to look when mouse capture is unavailable."
	content.add_child(_body(instructions))
	var resume := _button("Resume the game.", true)
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	_stack.add_child(resume)
	var restart := _button("Restart the day.")
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	_stack.add_child(restart)
	var quit_button := _button("Return to the title screen." if OS.has_feature("web") else "Quit the game.")
	quit_button.pressed.connect(func() -> void: quit_pressed.emit())
	_stack.add_child(quit_button)


func show_ending(result: Dictionary, stats: Dictionary, evidence: Array) -> void:
	_open_modal("ending")
	_stack.add_child(_title(str(result.get("title", "Your evaluation"))))
	var content := _scroll_content()
	var outcome := _panel(Color(str(result.get("color", "91c8af"))), 8)
	content.add_child(outcome)
	var outcome_margin := _margin(13, 9, 13, 9)
	outcome.add_child(outcome_margin)
	outcome_margin.add_child(_label(str(result.get("subtitle", "")), 17, INK))
	content.add_child(_body(str(result.get("body", result.get("description", "")))))
	_add_stats(content, stats)
	var decisions: Array[Dictionary] = []
	for index in range(evidence.size() - 1, -1, -1):
		var item: Variant = evidence[index]
		if item is Dictionary and not str(item.get("decision", "")).begins_with("Clock in"):
			decisions.push_front(item)
		if decisions.size() >= 3:
			break
	for item: Dictionary in decisions:
		content.add_child(_body("[b]%s[/b]\n%s" % [str(item.get("task", "")), str(item.get("decision", ""))]))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_stack.add_child(row)
	var restart := _button("Play another day.", true)
	restart.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	row.add_child(restart)
	var quit_button := _button("Return to the title screen." if OS.has_feature("web") else "Clock out.")
	quit_button.pressed.connect(func() -> void: quit_pressed.emit())
	row.add_child(quit_button)


func hide_modal() -> void:
	_modal_layer.hide()
	_mode = ""
	_choice_count = 0


func is_modal_open() -> bool:
	return is_instance_valid(_modal_layer) and _modal_layer.visible


func _open_modal(mode: String) -> void:
	for child: Node in _stack.get_children():
		_stack.remove_child(child)
		child.queue_free()
	_mode = mode
	_choice_count = 0
	_modal_layer.show()
	_focus.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_fit_modal()


func _fit_modal() -> void:
	if not is_instance_valid(_modal):
		return
	var viewport_size: Vector2 = _root.size
	if viewport_size.x < 1:
		viewport_size = Vector2(1440, 900)
	var height: float = 450.0
	if _mode == "feedback":
		height = 270.0
	elif _mode == "pause":
		height = 380.0
	elif _mode == "ending":
		height = 560.0
	var panel_size := Vector2(minf(760.0, viewport_size.x - 64.0), minf(height, viewport_size.y - 100.0))
	var conversation_layout: bool = _conversation and viewport_size.x >= 1100 and _mode in ["choice", "feedback"]
	_dim.color.a = 0.12 if conversation_layout else 0.62
	if conversation_layout:
		panel_size.x = viewport_size.x * 0.48
		_modal.position = Vector2(viewport_size.x - panel_size.x - 28, (viewport_size.y - panel_size.y) * 0.5)
	else:
		_modal.position = (viewport_size - panel_size) * 0.5
	_modal.size = panel_size


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_modal_open() or not event is InputEventKey:
		return
	var key: InputEventKey = event
	if not key.pressed or key.echo:
		return
	if _mode == "choice" and key.keycode >= KEY_1 and key.keycode <= KEY_9:
		var index: int = key.keycode - KEY_1
		if index < _choice_count:
			get_viewport().set_input_as_handled()
			_emit_choice(index)
	elif _mode == "feedback" and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
		get_viewport().set_input_as_handled()
		continue_pressed.emit()
	elif _mode == "pause" and key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		resume_pressed.emit()


func _emit_choice(index: int) -> void:
	if _mode == "choice":
		choice_selected.emit(index)


func _add_stats(parent: Control, stats: Dictionary) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 16)
	parent.add_child(row)
	for key: String in ["delivery", "quality", "trust", "energy"]:
		var column := VBoxContainer.new()
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(column)
		column.add_child(_label(key.capitalize(), 13, MUTED))
		column.add_child(_label(str(roundi(float(stats.get(key, 50)))), 24, INK))


func _scroll_content() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_stack.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	return content


func _label(text: String, font_size: int = 18, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _title(text: String) -> Label:
	var label := _label(text, 27, INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _body(text: String) -> RichTextLabel:
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.text = text
	body.fit_content = true
	body.scroll_active = false
	body.add_theme_font_size_override("normal_font_size", 18)
	body.add_theme_font_size_override("bold_font_size", 18)
	body.add_theme_color_override("default_color", INK)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return body


func _button(text: String, solid: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(106, 47)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 17)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if solid:
		button.add_theme_stylebox_override("normal", _box(TEAL, 9))
		button.add_theme_stylebox_override("hover", _box(TEAL.lightened(0.12), 9))
		button.add_theme_color_override("font_color", Color.WHITE)
		button.add_theme_color_override("font_hover_color", Color.WHITE)
	return button


func _panel(color: Color, radius: int) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(color, radius))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _box(color: Color, radius: int, border: Color = Color.TRANSPARENT) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_color = border
	box.set_border_width_all(1 if border.a > 0 else 0)
	box.content_margin_left = 12
	box.content_margin_right = 12
	return box


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return margin
