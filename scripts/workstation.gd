extends Node
## A real interactive desktop rendered onto the office monitor's QuadMesh.

signal choice_selected(index: int)
signal continue_pressed
signal close_requested
signal phone_requested
signal task_requested
signal app_requested(app: String)

const SIZE := Vector2i(1440, 810)
const UIFont = preload("res://assets/fonts/Inter.ttf")
const BG := Color("101d27")
const PANEL := Color("1b2c38")
const TEXT := Color("edf4ec")
const MUTED := Color("a5b9b8")
const TEAL := Color("78d2b4")

var active: bool = false
var _surface: MeshInstance3D
var _camera: Camera3D
var _viewport: SubViewport
var _root: Control
var _window: PanelContainer
var _window_stack: VBoxContainer
var _desktop_task: Label
var _cursor: Label
var _mouse_inside: bool = false
var _last_mouse: Vector2 = Vector2.ZERO
var _card_open: bool = false
var _feedback: bool = false
var _last_card: Dictionary = {}
var _task: String = "Your task"
var _choice_count: int = 0
var _messages: Array[Dictionary] = []
var _notified: Dictionary = {}
var _stage: String = ""
var _cr_status: String = "Not started"
var _cr_summary: Label
var _slack_button: Button
var _unread: int = 0
var _app: String = ""


func setup(surface: MeshInstance3D, camera: Camera3D) -> void:
	_surface = surface
	_camera = camera
	_viewport = SubViewport.new()
	_viewport.name = "WorkstationScreen"
	_viewport.size = SIZE
	_viewport.disable_3d = true
	_viewport.transparent_bg = false
	_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	_viewport.handle_input_locally = true
	add_child(_viewport)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_texture = _viewport.get_texture()
	material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_surface.material_override = material
	_build_desktop()
	show_desktop("Your task")


func _build_desktop() -> void:
	_root = Control.new()
	_root.size = Vector2(SIZE)
	var theme := Theme.new()
	theme.default_font = UIFont
	theme.default_font_size = 22
	theme.set_color("font_color", "Label", TEXT)
	theme.set_color("font_color", "Button", TEXT)
	theme.set_color("font_hover_color", "Button", Color.WHITE)
	theme.set_color("font_pressed_color", "Button", TEXT)
	theme.set_color("font_focus_color", "Button", TEXT)
	theme.set_stylebox("normal", "Button", _box(Color("263e4b"), 10))
	theme.set_stylebox("hover", "Button", _box(Color("325b63"), 10, TEAL))
	theme.set_stylebox("pressed", "Button", _box(Color("1e4c4d"), 10))
	theme.set_stylebox("focus", "Button", _box(Color.TRANSPARENT, 10, TEAL))
	_root.theme = theme
	_viewport.add_child(_root)
	var background := ColorRect.new()
	background.color = BG
	background.size = Vector2(SIZE)
	_root.add_child(background)
	var glow := _panel(Color("18353d"), 180)
	glow.position = Vector2(650, 230)
	glow.size = Vector2(660, 350)
	_root.add_child(glow)
	var ring := _label("sb", 116, Color("26515a"))
	ring.position = Vector2(1090, 445)
	_root.add_child(ring)
	var topbar := _panel(Color("152630"), 0)
	topbar.position = Vector2.ZERO
	topbar.size = Vector2(1440, 46)
	_root.add_child(topbar)
	var os := _label("●   Small Batch", 19, TEAL)
	os.position = Vector2(28, 10)
	_root.add_child(os)
	var status := _label("Workspace  /  Intern", 18, MUTED)
	status.position = Vector2(1175, 11)
	_root.add_child(status)
	var greeting := _label("Your inbox is your quest log.", 44, TEXT)
	greeting.position = Vector2(105, 155)
	_root.add_child(greeting)
	_desktop_task = _label("Your task", 24, MUTED)
	_desktop_task.position = Vector2(108, 226)
	_desktop_task.size = Vector2(1000, 42)
	_root.add_child(_desktop_task)
	var open_task := _button("Open my task.", true)
	open_task.position = Vector2(108, 306)
	open_task.size = Vector2(290, 76)
	open_task.pressed.connect(_open_saved_task)
	_root.add_child(open_task)
	var inbox := _button("Open Slack.")
	inbox.position = Vector2(420, 306)
	inbox.size = Vector2(270, 76)
	inbox.pressed.connect(_navigate_app.bind("slack"))
	_root.add_child(inbox)
	var changes := _button("Open Changes.")
	changes.position = Vector2(712, 306)
	changes.size = Vector2(290, 76)
	changes.pressed.connect(_navigate_app.bind("changes"))
	_root.add_child(changes)
	_cr_summary = _label("CR #104  /  Not started", 23, TEAL)
	_cr_summary.position = Vector2(108, 425)
	_root.add_child(_cr_summary)
	_window = _panel(PANEL, 17)
	_window.position = Vector2(89, 74)
	_window.size = Vector2(1262, 628)
	_root.add_child(_window)
	var window_margin := _margin(30, 23, 30, 26)
	_window.add_child(window_margin)
	_window_stack = VBoxContainer.new()
	_window_stack.add_theme_constant_override("separation", 17)
	window_margin.add_child(_window_stack)
	var toolbar := _panel(Color("182b36"), 15)
	toolbar.position = Vector2(89, 724)
	toolbar.size = Vector2(1262, 64)
	_root.add_child(toolbar)
	var toolbar_margin := _margin(9, 7, 9, 7)
	toolbar.add_child(toolbar_margin)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	toolbar_margin.add_child(row)
	var work := _button("Open my task.")
	work.custom_minimum_size.x = 190
	work.pressed.connect(_open_saved_task)
	row.add_child(work)
	_slack_button = _button("Open Slack.")
	_slack_button.custom_minimum_size.x = 145
	_slack_button.pressed.connect(_navigate_app.bind("slack"))
	row.add_child(_slack_button)
	var cr_button := _button("Open Changes.")
	cr_button.custom_minimum_size.x = 170
	cr_button.pressed.connect(_navigate_app.bind("changes"))
	row.add_child(cr_button)
	var ai := _button("Use BatchGPT.")
	ai.custom_minimum_size.x = 170
	ai.pressed.connect(_navigate_app.bind("ai"))
	row.add_child(ai)
	var phone := _button("Open Loop on my phone.")
	phone.custom_minimum_size.x = 265
	phone.pressed.connect(func() -> void: phone_requested.emit())
	row.add_child(phone)
	var space := Control.new()
	space.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(space)
	var stand := _button("Stand up from my desk.")
	stand.custom_minimum_size.x = 255
	stand.pressed.connect(func() -> void: close_requested.emit())
	row.add_child(stand)
	for child: Node in row.get_children():
		if child is Button:
			(child as Button).add_theme_font_size_override("font_size", 19)
	_cursor = _label("↖", 31, Color("c1ffdf"))
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.add_theme_color_override("font_shadow_color", Color("0a141b"))
	_cursor.add_theme_constant_override("shadow_offset_x", 1)
	_cursor.add_theme_constant_override("shadow_offset_y", 2)
	_root.add_child(_cursor)
	_cursor.hide()


func set_active(value: bool) -> void:
	var was_active: bool = active
	active = value
	if not value:
		_cursor.hide()
		if _mouse_inside:
			_viewport.notify_mouse_exited()
		_mouse_inside = false
		if was_active and Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE


func show_desktop(task: String) -> void:
	if task != _task:
		_last_card.clear()
	_task = task
	_desktop_task.text = task
	_window.hide()
	_card_open = false
	_feedback = false


func show_card(card: Dictionary) -> void:
	_app = str(card.get("app", "changes"))
	if _app == "slack":
		_unread = 0
		_refresh_inbox_badge()
	_last_card = card.duplicate(true)
	_task = str(card.get("title", _task))
	_desktop_task.text = _task
	_card_open = true
	_feedback = false
	_choice_count = 0
	_clear_window()
	_window.show()
	var header := HBoxContainer.new()
	_window_stack.add_child(header)
	var app_name: String = str({"slack":"SLACK  /  DIRECT MESSAGE", "changes":"CHANGES  /  CR #104  /  " + _cr_status.to_upper(), "ai":"BATCHGPT  /  FEATURE TICKET"}.get(_app, "WORKSPACE"))
	var name_label := _label(app_name, 17, TEAL)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	var close := _button("Return to the desktop.")
	close.custom_minimum_size = Vector2(245, 39)
	close.add_theme_font_size_override("font_size", 18)
	close.pressed.connect(func() -> void: show_desktop(_task))
	header.add_child(close)
	var title := _label(str(card.get("title", "Your task")), 32, TEXT)
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_window_stack.add_child(title)
	var content := _scroll_content()
	content.add_child(_body(str(card.get("body", ""))))
	var choices: Array = card.get("choices", [])
	_choice_count = choices.size()
	for index in range(choices.size()):
		var choice: Dictionary = choices[index]
		var button := _button(str(choice.get("label", "Continue working.")))
		button.custom_minimum_size.y = 66
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select.bind(index))
		content.add_child(button)


func show_feedback(text: String, changes: Dictionary = {}) -> void:
	_clear_window()
	_card_open = true
	_feedback = true
	_choice_count = 0
	_window.show()
	_window_stack.add_child(_label("%s  /  UPDATE" % str({"slack":"SLACK", "changes":"CHANGES", "ai":"BATCHGPT"}.get(_app, "WORKSPACE")), 17, TEAL))
	var content := _scroll_content()
	if not text.is_empty():
		content.add_child(_body(text.split("\n\n")[0]))
	var change_row := HFlowContainer.new()
	change_row.add_theme_constant_override("h_separation", 22)
	change_row.add_theme_constant_override("v_separation", 8)
	content.add_child(change_row)
	for key: String in ["delivery", "quality", "trust", "energy"]:
		var delta: int = int(changes.get(key, 0))
		if delta != 0:
			change_row.add_child(_label("%s %+d" % [key.capitalize(), delta], 23, Color("97e5b4") if delta > 0 else Color("ffaaa0")))
	if changes.is_empty():
		change_row.add_child(_label("No stat changes.", 20, TEAL))
	var next := _button("Continue working.", true)
	next.pressed.connect(func() -> void: continue_pressed.emit())
	_window_stack.add_child(next)


func is_card_open() -> bool:
	return _card_open


func forward_input(event: InputEvent) -> bool:
	if not active or not is_instance_valid(_camera) or not is_instance_valid(_surface):
		return false
	if event is InputEventKey:
		var key: InputEventKey = event
		if not key.pressed or key.echo:
			return false
		if _feedback and (key.keycode == KEY_ENTER or key.keycode == KEY_KP_ENTER):
			continue_pressed.emit()
			return true
		if _card_open and not _feedback and key.keycode >= KEY_1 and key.keycode <= KEY_9:
			var index: int = key.keycode - KEY_1
			if index < _choice_count:
				_select(index)
				return true
		return false
	if not event is InputEventMouse:
		return false
	var mouse: InputEventMouse = event
	var point: Vector2 = _screen_point(mouse.position)
	if point.x < 0:
		if _mouse_inside:
			_viewport.notify_mouse_exited()
		_mouse_inside = false
		_cursor.hide()
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return false
	if not _mouse_inside:
		_viewport.notify_mouse_entered()
	_cursor.position = point + Vector2(2, 0)
	_cursor.show()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	var screen_event: InputEventMouse = mouse.duplicate()
	screen_event.position = point
	screen_event.global_position = point
	if screen_event is InputEventMouseMotion:
		var motion: InputEventMouseMotion = screen_event
		motion.relative = point - _last_mouse if _mouse_inside else Vector2.ZERO
	_last_mouse = point
	_mouse_inside = true
	_viewport.push_input(screen_event, true)
	return true


func _screen_point(screen_position: Vector2) -> Vector2:
	var inverse: Transform3D = _surface.global_transform.affine_inverse()
	var origin: Vector3 = inverse * _camera.project_ray_origin(screen_position)
	var direction: Vector3 = inverse.basis * _camera.project_ray_normal(screen_position)
	if absf(direction.z) < 0.00001:
		return Vector2(-1, -1)
	var distance: float = -origin.z / direction.z
	if distance < 0:
		return Vector2(-1, -1)
	var hit: Vector3 = origin + direction * distance
	var mesh: QuadMesh = _surface.mesh as QuadMesh
	if mesh == null:
		return Vector2(-1, -1)
	var uv := Vector2(hit.x / mesh.size.x + 0.5, 0.5 - hit.y / mesh.size.y)
	if uv.x < 0 or uv.x > 1 or uv.y < 0 or uv.y > 1:
		return Vector2(-1, -1)
	return uv * Vector2(SIZE)


func _open_saved_task() -> void:
	if _feedback:
		_window.show()
		return
	task_requested.emit()

func _navigate_app(app: String) -> void:
	if _feedback:
		_window.show()
		return
	app_requested.emit(app)

func set_work_state(stage: String, flags: Dictionary, _awaiting_person: String) -> void:
	_stage = stage
	if not _notified.has(stage):
		_notified[stage] = true
		var updates: Dictionary = {
			"standup":["Jordan · #engineering", "Standup is in the meeting corner. Bring one update, not your entire autobiography."],
			"mentor":["Maya · Direct message", "The Save favorites ticket is yours. Ask me about the requirements before you build."],
			"feature":["Jordan · #feature-team", "Build the Save favorites change with BatchGPT, then push CR #104 for review."],
			"review_info":["Maya · CR #104", "I left two comments. Please clarify Save and double-tap behavior before merging."],
			"review":["Changes bot · #reviews", "CR #104 needs your response. Check the comments and decide whether to merge."],
			"intern":["Sam · Direct message", "My discount applies twice. Finance has discovered negative-priced coffee. Can you help?"],
			"manager":["Jordan · Direct message", "Our 1:1 is ready. Take the visitor chair in my office."],
			"kitchen":["Jordan · #engineering", "Take a real break. The coffee machine is accepting dependencies."],
			"incident":["Pager bot · #incidents", "SEV-1: Coffee checkout is down. Get to your desk and open the incident."],
			"exit":["People Operations · Direct message", "Your evaluation is ready at the elevator. Please return all borrowed confidence."]
		}
		if updates.has(stage):
			_messages.append({"sender":str(updates[stage][0]), "text":str(updates[stage][1])})
			_unread += 1
	_cr_status = "Merged" if bool(flags.get("cr_merged", false)) else ("Changes requested" if stage in ["review_info", "review"] else ("Review requested" if bool(flags.get("cr_submitted", false)) else ("Draft" if stage == "feature" else "Not started")))
	_cr_summary.text = "CR #104  /  " + _cr_status
	_refresh_inbox_badge()

func _refresh_inbox_badge() -> void:
	_slack_button.text = "Slack (%d)." % _unread if _unread > 0 else "Open Slack."

func _read_only_window(app: String, title: String, body: String) -> void:
	_app = app
	_clear_window()
	_card_open = false
	_feedback = false
	_choice_count = 0
	_window.show()
	var header := HBoxContainer.new()
	_window_stack.add_child(header)
	var app_label := _label(app.to_upper(), 17, TEAL)
	app_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(app_label)
	var close := _button("Return to the desktop.")
	close.add_theme_font_size_override("font_size", 18)
	close.custom_minimum_size = Vector2(245, 39)
	close.pressed.connect(func() -> void: show_desktop(_task))
	header.add_child(close)
	_window_stack.add_child(_label(title, 30, TEXT))
	var content := _scroll_content()
	content.add_child(_body(body))
	var action := _button("Open my current task.", true)
	action.pressed.connect(func() -> void: app_requested.emit("task"))
	_window_stack.add_child(action)

func show_slack() -> void:
	_unread = 0
	_refresh_inbox_badge()
	var body: String = ""
	for index: int in range(maxi(0, _messages.size() - 3), _messages.size()):
		var message: Dictionary = _messages[index]
		body += "[b]%s[/b]\n%s\n\n" % [message["sender"], message["text"]]
	_read_only_window("slack", "#engineering  /  Messages", body.strip_edges())

func show_change_request() -> void:
	var body: String = "[b]Status: %s[/b]\n\nSave remembers a favorite. Guests sign in. No coffee orders are placed.\n\n" % _cr_status
	if _stage in ["review_info", "review", "intern", "manager", "kitchen", "incident", "exit"]:
		body += "[b]Maya · Comment 1[/b]\nDoes Save only remember a drink, or can it place an order?\n\n[b]Maya · Comment 2[/b]\nWhat happens when a guest double-taps?"
	else:
		body += "Maya is the assigned reviewer. Build the feature, then push the draft for review."
	_read_only_window("changes", "CR #104  /  Save coffee favorites", body)

func show_ai_idle() -> void:
	_read_only_window("batchgpt", "BatchGPT is confidently standing by.", "Open your current feature ticket to give the AI instructions.\n\nBatchGPT cannot approve its own work, although it has written a compelling essay about why it should.")


func _select(index: int) -> void:
	if not _feedback and _card_open:
		choice_selected.emit(index)


func _clear_window() -> void:
	for child: Node in _window_stack.get_children():
		_window_stack.remove_child(child)
		child.queue_free()


func _scroll_content() -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_window_stack.add_child(scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 14)
	scroll.add_child(content)
	return content


func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _body(text: String) -> RichTextLabel:
	var body := RichTextLabel.new()
	body.bbcode_enabled = true
	body.text = text
	body.fit_content = true
	body.scroll_active = false
	body.add_theme_color_override("default_color", TEXT)
	body.add_theme_font_size_override("normal_font_size", 23)
	body.add_theme_font_size_override("bold_font_size", 23)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return body


func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(100, 49)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 23)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if primary:
		button.add_theme_stylebox_override("normal", _box(TEAL, 10))
		button.add_theme_stylebox_override("hover", _box(TEAL.lightened(0.13), 10))
		button.add_theme_color_override("font_color", BG)
		button.add_theme_color_override("font_hover_color", BG)
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
	box.content_margin_left = 14
	box.content_margin_right = 14
	return box


func _margin(left: int, top: int, right: int, bottom: int) -> MarginContainer:
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", left)
	margin.add_theme_constant_override("margin_top", top)
	margin.add_theme_constant_override("margin_right", right)
	margin.add_theme_constant_override("margin_bottom", bottom)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return margin
