extends CanvasLayer

signal choice_selected(index: int)
signal continue_pressed
signal resume_pressed
signal restart_pressed
signal quit_pressed

const OfficeMap = preload("res://scripts/office_map.gd")
const INK := Color("19333f")
const CREAM := Color("f8f5e9")
const MUTED := Color("5b7378")
const TEAL := Color("087f81")
const CORAL := Color("ef795e")
const LINE := Color("d8dfd7")

var minimap: Control
var _root: Control
var _theme: Theme
var _clock: Label
var _chapter: Label
var _objective_title: Label
var _objective_detail: Label
var _distance: Label
var _focus: PanelContainer
var _focus_text: Label
var _incident: PanelContainer
var _incident_time: Label
var _modal_layer: Control
var _modal: PanelContainer
var _modal_stack: VBoxContainer
var _bars: Dictionary = {}
var _numbers: Dictionary = {}
var _choice_buttons: Array[Button] = []
var _mode: String = ""


func _ready() -> void:
	layer = 20
	_build_theme()
	_root = Control.new()
	_root.name = "InternHUD"
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.theme = _theme
	add_child(_root)
	_build_brand()
	_build_status()
	_build_objective()
	_build_navigation()
	_build_incident()
	_build_modal()
	set_status({}, "09:00 AM", "FINAL DAY / EVALUATION")
	set_objective("Welcome to Small Batch", "Find your team. Try to look employed.")
	set_focus("")
	set_incident(0.0, false)
	get_viewport().size_changed.connect(_fit_modal)


func _build_theme() -> void:
	_theme = Theme.new()
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Segoe UI", "Arial"])
	_theme.default_font = font
	_theme.default_font_size = 18
	_theme.set_color("font_color", "Label", INK)
	_theme.set_color("default_color", "RichTextLabel", INK)
	_theme.set_color("font_color", "Button", INK)
	_theme.set_color("font_hover_color", "Button", INK)
	_theme.set_color("font_pressed_color", "Button", INK)
	_theme.set_color("font_focus_color", "Button", INK)
	_theme.set_stylebox("normal", "Button", _box(Color("eef0e8"), 12, LINE, 1))
	_theme.set_stylebox("hover", "Button", _box(Color("deeee4"), 12, TEAL, 2))
	_theme.set_stylebox("pressed", "Button", _box(Color("cfe6dd"), 12, TEAL, 2))
	_theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, 12, TEAL, 2))
	_theme.set_stylebox("scroll", "VScrollBar", _box(Color("e5e7df"), 4))
	_theme.set_stylebox("grabber", "VScrollBar", _box(Color("a6b7ad"), 4))
	_theme.set_stylebox("grabber_highlight", "VScrollBar", _box(TEAL, 4))
	_theme.set_stylebox("grabber_pressed", "VScrollBar", _box(TEAL, 4))
	_theme.set_constant("scrollbar_width", "VScrollBar", 6)


func _build_brand() -> void:
	var brand_back := _panel(Color(0.07, 0.16, 0.20, 0.91), 14)
	_root.add_child(brand_back)
	brand_back.position = Vector2(22, 20)
	brand_back.size = Vector2(320, 74)
	var clock_back := _panel(Color(0.07, 0.16, 0.20, 0.91), 14)
	_root.add_child(clock_back)
	clock_back.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	clock_back.offset_left = -284
	clock_back.offset_right = -22
	clock_back.offset_top = 20
	clock_back.offset_bottom = 94
	var brand := HBoxContainer.new()
	brand.add_theme_constant_override("separation", 12)
	_root.add_child(brand)
	brand.position = Vector2(34, 30)
	var badge := _panel(Color("f39879"), 13)
	badge.custom_minimum_size = Vector2(50, 50)
	brand.add_child(badge)
	var sb := _label("SB", 21, INK)
	sb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_child(sb)
	var copy := VBoxContainer.new()
	copy.add_theme_constant_override("separation", 0)
	brand.add_child(copy)
	copy.add_child(_label("SMALL BATCH", 23, CREAM))
	copy.add_child(_label("INTERN EXPERIENCE  /  PROTOTYPE", 10, Color("d7e5da")))
	var time_box := VBoxContainer.new()
	time_box.add_theme_constant_override("separation", 0)
	_root.add_child(time_box)
	time_box.set_anchors_and_offsets_preset(Control.PRESET_TOP_RIGHT)
	time_box.offset_left = -340
	time_box.offset_right = -34
	time_box.offset_top = 28
	time_box.offset_bottom = 80
	_clock = _label("09:00 AM", 26, CREAM)
	_clock.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_box.add_child(_clock)
	_chapter = _label("FINAL DAY / EVALUATION", 11, Color("d7e5da"))
	_chapter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	time_box.add_child(_chapter)


func _build_status() -> void:
	var tray := _panel(Color("f8f5e9"), 14)
	_root.add_child(tray)
	tray.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	tray.offset_left = -276
	tray.offset_right = 276
	tray.offset_top = 28
	tray.offset_bottom = 93
	var margin := _margin(18, 12, 18, 12)
	tray.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 20)
	margin.add_child(row)
	var names: Array[String] = ["delivery", "quality", "trust", "energy"]
	var colors: Array[Color] = [TEAL, Color("6579a0"), CORAL, Color("b28b40")]
	for index in range(names.size()):
		var key: String = names[index]
		var column := VBoxContainer.new()
		column.custom_minimum_size.x = 111
		column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		column.add_theme_constant_override("separation", 7)
		row.add_child(column)
		var heading := HBoxContainer.new()
		column.add_child(heading)
		var label := _label(key.to_upper(), 11, MUTED)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		heading.add_child(label)
		var number := _label("50", 11, INK)
		heading.add_child(number)
		_numbers[key] = number
		var bar := ProgressBar.new()
		bar.custom_minimum_size.y = 5
		bar.show_percentage = false
		bar.max_value = 100
		bar.value = 50
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background", _box(Color("e1e5dc"), 3))
		bar.add_theme_stylebox_override("fill", _box(colors[index], 3))
		column.add_child(bar)
		_bars[key] = bar


func _build_objective() -> void:
	var card := _panel(CREAM, 14)
	_root.add_child(card)
	card.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_LEFT)
	card.offset_left = 34
	card.offset_right = 410
	card.offset_top = -201
	card.offset_bottom = -65
	var margin := _margin(20, 17, 20, 17)
	card.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 6)
	margin.add_child(stack)
	var top := HBoxContainer.new()
	stack.add_child(top)
	var eyebrow := _label("YOUR NEXT MOVE", 10, TEAL)
	eyebrow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	top.add_child(eyebrow)
	_distance = _label("", 11, MUTED)
	top.add_child(_distance)
	_objective_title = _label("", 21, INK)
	_objective_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_objective_title)
	_objective_detail = _label("", 14, MUTED)
	_objective_detail.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stack.add_child(_objective_detail)


func _build_navigation() -> void:
	minimap = OfficeMap.new()
	minimap.name = "OfficeMinimap"
	_root.add_child(minimap)
	minimap.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	minimap.offset_left = -274
	minimap.offset_right = -34
	minimap.offset_top = -251
	minimap.offset_bottom = -65
	var controls_back := _panel(Color(0.07, 0.16, 0.20, 0.87), 9)
	_root.add_child(controls_back)
	controls_back.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	controls_back.offset_left = -406
	controls_back.offset_right = 406
	controls_back.offset_top = -45
	controls_back.offset_bottom = -12
	var controls := _label("W A S D   MOVE     ·     MOUSE   LOOK     ·     SHIFT   HUSTLE     ·     E   INTERACT     ·     ESC   PAUSE", 12, CREAM)
	controls.add_theme_color_override("font_shadow_color", Color("192b35"))
	controls.add_theme_constant_override("shadow_offset_y", 1)
	controls.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_root.add_child(controls)
	controls.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	controls.offset_left = -500
	controls.offset_right = 500
	controls.offset_top = -37
	controls.offset_bottom = -16
	var crosshair := _label("·", 38, CREAM)
	crosshair.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	crosshair.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	crosshair.add_theme_color_override("font_shadow_color", Color("19333f"))
	crosshair.add_theme_constant_override("shadow_offset_y", 1)
	_root.add_child(crosshair)
	crosshair.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	crosshair.offset_left = -14
	crosshair.offset_right = 14
	crosshair.offset_top = -27
	crosshair.offset_bottom = 5
	_focus = _panel(INK, 14)
	_root.add_child(_focus)
	_focus.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	_focus.offset_left = -231
	_focus.offset_right = 231
	_focus.offset_top = -140
	_focus.offset_bottom = -85
	var focus_margin := _margin(15, 10, 15, 10)
	_focus.add_child(focus_margin)
	var focus_row := HBoxContainer.new()
	focus_row.alignment = BoxContainer.ALIGNMENT_CENTER
	focus_row.add_theme_constant_override("separation", 12)
	focus_margin.add_child(focus_row)
	var key := _panel(CREAM, 6)
	key.custom_minimum_size = Vector2(32, 32)
	focus_row.add_child(key)
	var key_text := _label("E", 17, INK)
	key_text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.add_child(key_text)
	_focus_text = _label("", 17, CREAM)
	_focus_text.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	focus_row.add_child(_focus_text)


func _build_incident() -> void:
	_incident = _panel(Color("ab3d35"), 14)
	_root.add_child(_incident)
	_incident.set_anchors_and_offsets_preset(Control.PRESET_CENTER_TOP)
	_incident.offset_left = -290
	_incident.offset_right = 290
	_incident.offset_top = 111
	_incident.offset_bottom = 179
	var margin := _margin(20, 12, 20, 12)
	_incident.add_child(margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 24)
	margin.add_child(row)
	var words := VBoxContainer.new()
	words.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	words.add_theme_constant_override("separation", 0)
	row.add_child(words)
	words.add_child(_label("SEV-1  /  PRODUCTION IS HAVING A MOMENT", 12, Color("ffdfcf")))
	words.add_child(_label("Get to your desk. The internet needs you.", 17, Color.WHITE))
	_incident_time = _label("00:45", 27, Color.WHITE)
	_incident_time.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(_incident_time)


func _build_modal() -> void:
	_modal_layer = Control.new()
	_modal_layer.name = "DialogueOverlay"
	_modal_layer.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_modal_layer.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(_modal_layer)
	var dim := ColorRect.new()
	dim.color = Color(0.025, 0.08, 0.10, 0.76)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_modal_layer.add_child(dim)
	_modal = _panel(CREAM, 22)
	var style: StyleBoxFlat = _modal.get_theme_stylebox("panel").duplicate()
	style.shadow_color = Color(0.0, 0.0, 0.0, 0.22)
	style.shadow_size = 25
	style.shadow_offset = Vector2(0, 12)
	_modal.add_theme_stylebox_override("panel", style)
	_modal_layer.add_child(_modal)
	var margins := _margin(38, 28, 38, 27)
	_modal.add_child(margins)
	_modal_stack = VBoxContainer.new()
	_modal_stack.add_theme_constant_override("separation", 12)
	margins.add_child(_modal_stack)
	_modal_layer.hide()
	_fit_modal()


func _fit_modal() -> void:
	if not is_instance_valid(_modal):
		return
	var viewport_size: Vector2 = _root.size
	if viewport_size.x < 1.0:
		viewport_size = Vector2(1440, 900)
	var panel_size := Vector2(minf(1000.0, viewport_size.x - 80.0), minf(700.0, viewport_size.y - 100.0))
	_modal.position = (viewport_size - panel_size) * 0.5
	_modal.size = panel_size


func set_status(stats: Dictionary, time_text: String, chapter: String) -> void:
	if not is_instance_valid(_clock):
		return
	_clock.text = time_text
	_chapter.text = chapter.to_upper()
	for key: String in _bars:
		var amount: float = clampf(float(stats.get(key, 50)), 0.0, 100.0)
		var bar: ProgressBar = _bars[key]
		bar.value = amount
		var number: Label = _numbers[key]
		number.text = str(roundi(amount))


func set_objective(title: String, detail: String) -> void:
	_objective_title.text = title
	_objective_detail.text = detail


func set_focus(text: String) -> void:
	_focus.visible = not text.is_empty() and not is_modal_open()
	_focus_text.text = text


func set_distance(meters: float) -> void:
	_distance.text = "%dm AWAY" % ceili(meters) if meters >= 0.0 else ""


func set_incident(seconds: float, active: bool) -> void:
	_incident.visible = active
	var remaining: int = maxi(0, ceili(seconds))
	_incident_time.text = "%02d:%02d" % [floori(remaining / 60.0), remaining % 60]


func show_card(card: Dictionary) -> void:
	_open_modal("choice")
	_header(str(card.get("eyebrow", "OFFICE HOURS")), str(card.get("speaker", "")))
	_modal_stack.add_child(_title(str(card.get("title", "A career-defining moment"))))
	var content := _scroll_content()
	content.add_child(_body(str(card.get("body", ""))))
	var choices: Array = card.get("choices", [])
	for index in range(choices.size()):
		var choice: Dictionary = choices[index]
		var button := _choice_button(index, str(choice.get("label", "Continue")), str(choice.get("hint", "")))
		content.add_child(button)
		button.pressed.connect(_emit_choice.bind(index))
		_choice_buttons.append(button)
	var footer := _label("MAKE YOUR CALL     ·     CLICK A RESPONSE OR PRESS ITS NUMBER", 11, MUTED)
	_modal_stack.add_child(footer)


func show_feedback(text: String) -> void:
	_open_modal("feedback")
	_header("THE OFFICE REMEMBERS", "SMALL BATCH")
	_modal_stack.add_child(_title("Noted. Professionally."))
	var content := _scroll_content()
	content.add_child(_body(text))
	var footer := HBoxContainer.new()
	footer.alignment = BoxContainer.ALIGNMENT_END
	footer.add_theme_constant_override("separation", 16)
	_modal_stack.add_child(footer)
	var prompt := _label("ENTER TO CONTINUE", 11, MUTED)
	prompt.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	footer.add_child(prompt)
	var button := _solid_button("Back to the office  →", TEAL)
	button.pressed.connect(func() -> void: continue_pressed.emit())
	footer.add_child(button)


func show_pause() -> void:
	_open_modal("pause")
	_header("TAKING A BREATHER", "PAUSED")
	_modal_stack.add_child(_title("Away from keyboard."))
	var content := _scroll_content()
	content.add_child(_body("Your tabs are safe. Your calendar, less so.\n\n[b]WASD[/b] to walk  ·  [b]Mouse[/b] to look  ·  [b]Shift[/b] to hustle\n[b]E[/b] to interact  ·  [b]1 / 2 / 3[/b] to choose a response\n\nTalk to your coworkers, make your calls, and see what kind of offer you earn."))
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_modal_stack.add_child(row)
	var resume := _solid_button("Back to work  →", TEAL)
	resume.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	resume.pressed.connect(func() -> void: resume_pressed.emit())
	row.add_child(resume)
	var restart := _plain_button("Restart day")
	restart.pressed.connect(func() -> void: restart_pressed.emit())
	row.add_child(restart)
	var quit := _plain_button("Quit")
	quit.pressed.connect(func() -> void: quit_pressed.emit())
	row.add_child(quit)
	_modal_stack.add_child(_label("ESC TO RESUME", 11, MUTED))


func show_ending(result: Dictionary, stats: Dictionary, evidence: Array) -> void:
	_open_modal("ending")
	var accent := Color(str(result.get("color", "087f81")))
	_header("INTERN EVALUATION  /  FINAL DAY", "PEOPLE & CULTURE")
	var title := _title(str(result.get("title", "Your internship is in the books.")))
	_modal_stack.add_child(title)
	var content := _scroll_content()
	var subtitle: String = str(result.get("subtitle", ""))
	if not subtitle.is_empty():
		var outcome := _panel(accent, 10)
		content.add_child(outcome)
		var outcome_margin := _margin(16, 10, 16, 10)
		outcome.add_child(outcome_margin)
		var sub := _label(subtitle, 18, INK)
		sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		outcome_margin.add_child(sub)
	var explanation: String = str(result.get("body", result.get("description", "")))
	if not explanation.is_empty():
		content.add_child(_body(explanation))
	var scores := HBoxContainer.new()
	scores.add_theme_constant_override("separation", 12)
	content.add_child(scores)
	for key: String in ["delivery", "quality", "trust", "energy"]:
		var panel := _panel(Color("e9ede4"), 10)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		scores.add_child(panel)
		var margin := _margin(15, 10, 15, 10)
		panel.add_child(margin)
		var column := VBoxContainer.new()
		column.add_theme_constant_override("separation", 0)
		margin.add_child(column)
		column.add_child(_label(key.to_upper(), 10, MUTED))
		column.add_child(_label(str(roundi(float(stats.get(key, 50)))), 27, INK))
	var recent_decisions: Array[Dictionary] = []
	for index in range(evidence.size() - 1, -1, -1):
		var item: Variant = evidence[index]
		if not item is Dictionary:
			continue
		var decision: String = str(item.get("decision", ""))
		if decision.is_empty() or decision.begins_with("Open my evaluation") or decision.begins_with("Clock in"):
			continue
		recent_decisions.push_front(item)
		if recent_decisions.size() == 5:
			break
	if not recent_decisions.is_empty():
		content.add_child(_label("WHAT YOUR MANAGER REMEMBERED", 11, TEAL))
		for item: Dictionary in recent_decisions:
			var task: String = str(item.get("task", "Your decision"))
			var decision: String = str(item.get("decision", ""))
			var notes := _body("[b]%s[/b]\n%s" % [task, decision])
			notes.add_theme_font_size_override("normal_font_size", 16)
			notes.add_theme_font_size_override("bold_font_size", 16)
			content.add_child(notes)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_modal_stack.add_child(row)
	var replay := _solid_button("Another day, another deploy  ↻", TEAL)
	replay.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	replay.pressed.connect(func() -> void: restart_pressed.emit())
	row.add_child(replay)
	var quit := _plain_button("Clock out")
	quit.pressed.connect(func() -> void: quit_pressed.emit())
	row.add_child(quit)


func hide_modal() -> void:
	_modal_layer.hide()
	_mode = ""
	_choice_buttons.clear()


func is_modal_open() -> bool:
	return is_instance_valid(_modal_layer) and _modal_layer.visible


func _open_modal(mode: String) -> void:
	for child: Node in _modal_stack.get_children():
		_modal_stack.remove_child(child)
		child.queue_free()
	_choice_buttons.clear()
	_mode = mode
	_modal_layer.show()
	_focus.hide()
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_fit_modal()


func _header(eyebrow: String, speaker: String) -> void:
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	_modal_stack.add_child(row)
	var label := _label(eyebrow.to_upper(), 11, TEAL)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(label)
	if not speaker.is_empty():
		var pill := _panel(Color("e5e9df"), 8)
		row.add_child(pill)
		var margin := _margin(12, 6, 12, 6)
		pill.add_child(margin)
		margin.add_child(_label(speaker.to_upper(), 10, MUTED))


func _scroll_content() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.follow_focus = true
	_modal_stack.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 10)
	scroll.add_child(content)
	return content


func _choice_button(index: int, text: String, hint: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(0, 84 if not hint.is_empty() else 59)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	var margin := _margin(16, 12, 20, 12)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.add_child(margin)
	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 15)
	margin.add_child(row)
	var key := _panel(INK, 7)
	key.custom_minimum_size = Vector2(33, 33)
	key.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(key)
	var key_label := _label(str(index + 1), 16, CREAM)
	key_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	key.add_child(key_label)
	var copy := VBoxContainer.new()
	copy.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	copy.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	copy.mouse_filter = Control.MOUSE_FILTER_IGNORE
	copy.add_theme_constant_override("separation", 3)
	row.add_child(copy)
	var label := _label(text, 17, INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	copy.add_child(label)
	if not hint.is_empty():
		var hint_label := _label(hint, 13, MUTED)
		hint_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		copy.add_child(hint_label)
	var arrow := _label("→", 23, TEAL)
	arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(arrow)
	return button


func _emit_choice(index: int) -> void:
	if _mode == "choice":
		choice_selected.emit(index)


func _unhandled_key_input(event: InputEvent) -> void:
	if not is_modal_open() or not event is InputEventKey:
		return
	var key: InputEventKey = event
	if not key.pressed or key.echo:
		return
	if _mode == "choice" and key.keycode >= KEY_1 and key.keycode <= KEY_9:
		var index: int = key.keycode - KEY_1
		if index < _choice_buttons.size():
			get_viewport().set_input_as_handled()
			_emit_choice(index)
	elif _mode == "feedback" and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
		get_viewport().set_input_as_handled()
		continue_pressed.emit()
	elif _mode == "pause" and key.keycode == KEY_ESCAPE:
		get_viewport().set_input_as_handled()
		resume_pressed.emit()


func _label(text: String, font_size: int = 18, color: Color = INK) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _title(text: String) -> Label:
	var label := _label(text, 34, INK)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label


func _body(text: String) -> RichTextLabel:
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.text = text
	body.fit_content = true
	body.scroll_active = false
	body.selection_enabled = false
	body.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_theme_font_size_override("normal_font_size", 18)
	body.add_theme_font_size_override("bold_font_size", 18)
	body.add_theme_color_override("default_color", INK)
	body.add_theme_constant_override("line_separation", 2)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return body


func _panel(color: Color, radius: int = 12) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.add_theme_stylebox_override("panel", _box(color, radius))
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return panel


func _box(color: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.corner_radius_top_left = radius
	box.corner_radius_top_right = radius
	box.corner_radius_bottom_left = radius
	box.corner_radius_bottom_right = radius
	box.border_color = border
	box.set_border_width_all(width)
	return box


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return margin


func _solid_button(text: String, color: Color) -> Button:
	var button := _plain_button(text)
	button.add_theme_stylebox_override("normal", _box(color, 10))
	button.add_theme_stylebox_override("hover", _box(color.lightened(0.10), 10))
	button.add_theme_stylebox_override("pressed", _box(color.darkened(0.12), 10))
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_color_override("font_focus_color", Color.WHITE)
	return button


func _plain_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(150, 54)
	button.add_theme_font_size_override("font_size", 17)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	return button
