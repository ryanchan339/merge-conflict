extends Node
## A real interactive desktop rendered onto the office monitor's QuadMesh.

signal choice_selected(index: int)
signal continue_pressed
signal close_requested
signal phone_requested
signal task_requested
signal app_requested(app: String)
signal notification_received(app: String, title: String)

const SIZE := Vector2i(1440, 810)
const UIFont = preload("res://assets/fonts/Inter.ttf")
const WorkspaceData = preload("res://content/workspace_data.gd")
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
var _desktop_badges: Dictionary = {}
var _task_app: String = ""
var _task_thread: String = ""
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
var _menu_app: Label
var _menu_clock: Label
var _slack_badge: Label
var _window_title: Label
var _dock_buttons: Dictionary = {}
var _dock_dots: Dictionary = {}
var _icon_cache: Dictionary = {}
var _ink := Color("202332")
var _soft := Color("6f7282")
var _accent := Color("1264a3")
var _paper := Color("ffffff")
var _line := Color("e7e7ec")
var _zoomed: bool = false
var _work_flags: Dictionary = {}
var _slack_channel: String = "# engineering"
var _app_unread: Dictionary = {"slack":0, "changes":0, "ai":0}
var _dock_badges: Dictionary = {}
var _notification_button: Button
var _notification_title: Label
var _notification_body: Label
var _notification_icon: TextureRect
var _notification_timer: Timer
var _notification_app: String = ""
var _cr_records: Array[Dictionary] = []
var _selected_cr: int = 104
var _cr_tab: String = "Conversation"
var _chats: Array[Dictionary] = []
var _active_chat: int = -1
var _chat_input: LineEdit
var _chat_pending: Dictionary = {}
var _chat_mode: bool = false
var _chat_scroll: ScrollContainer


func setup(surface: MeshInstance3D, camera: Camera3D) -> void:
	_messages = WorkspaceData.messages()
	_cr_records = WorkspaceData.change_requests()
	_chats = WorkspaceData.chats()
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
	theme.default_font_size = 21
	_root.theme = theme
	_viewport.add_child(_root)
	var wallpaper := TextureRect.new()
	wallpaper.texture = _svg_texture("""<svg xmlns="http://www.w3.org/2000/svg" width="1440" height="810"><defs><linearGradient id="sky" x2="0.9" y2="1"><stop stop-color="#251b63"/><stop offset=".5" stop-color="#a07dcc"/><stop offset="1" stop-color="#f5b0a4"/></linearGradient><linearGradient id="hill" x2=".6" y2="1"><stop stop-color="#ffb7a0"/><stop offset="1" stop-color="#bf4c81"/></linearGradient><linearGradient id="blue" x2=".9" y2="1"><stop stop-color="#6668dc"/><stop offset="1" stop-color="#172c6d"/></linearGradient></defs><rect width="1440" height="810" fill="url(#sky)"/><path d="M-80 740C190 270 350 610 610 300S1020 140 1530 80V850H-80Z" fill="url(#hill)"/><path d="M-100 820C240 400 490 850 810 470S1130 350 1530 180V850Z" fill="url(#blue)"/><path d="M120 850C450 590 620 960 980 650S1250 560 1500 480V850Z" fill="#2e2a6d" opacity=".7"/></svg>""")
	wallpaper.size = Vector2(SIZE)
	wallpaper.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_root.add_child(wallpaper)
	var menubar := _panel(Color(0.96, 0.94, 1, 0.87), 0)
	menubar.position = Vector2.ZERO
	menubar.size = Vector2(1440, 36)
	_root.add_child(menubar)
	var brand := _label("●", 24, Color("332b51"))
	brand.position = Vector2(22, 1)
	_root.add_child(brand)
	_menu_app = _label("Finder", 18, Color("29223c"))
	_menu_app.position = Vector2(65, 6)
	_root.add_child(_menu_app)
	var menu := _label("File     Edit     View     Go     Window     Help", 17, Color("42394f"))
	menu.position = Vector2(215, 7)
	_root.add_child(menu)
	_menu_clock = _label("100%   •   Fri 09:00", 16, Color("332b51"))
	_menu_clock.position = Vector2(1210, 7)
	_root.add_child(_menu_clock)
	var greeting := _label("Small Batch", 54, Color.WHITE)
	greeting.position = Vector2(65, 155)
	_root.add_child(greeting)
	var subtitle := _label("Your slightly overcaffeinated workspace.", 22, Color("f4eafa"))
	subtitle.position = Vector2(69, 225)
	_root.add_child(subtitle)
	var note := _panel(Color(0.98, 0.96, 1, 0.88), 18)
	note.position = Vector2(65, 520)
	note.size = Vector2(460, 138)
	_root.add_child(note)
	var note_margin := _margin(24, 18, 24, 18)
	note.add_child(note_margin)
	var note_stack := VBoxContainer.new()
	note_stack.add_theme_constant_override("separation", 8)
	note_margin.add_child(note_stack)
	note_stack.add_child(_label("UP NEXT", 14, Color("766a91")))
	_desktop_task = _label("Open Tasks to start your work.", 23, Color("302544"))
	_desktop_task.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	note_stack.add_child(_desktop_task)
	_cr_summary = _label("CR #104  /  Not started", 17, Color("736585"))
	note_stack.add_child(_cr_summary)
	for index: int in range(4):
		var app: String = ["tasks", "slack", "changes", "ai"][index]
		var label: String = ["Tasks", "Slack", "Changes", "BatchGPT"][index]
		var shortcut := _icon_button(app, "Open %s." % label)
		shortcut.position = Vector2(1280, 80 + index * 143)
		shortcut.size = Vector2(76, 76)
		shortcut.pressed.connect(_launch_icon.bind(app))
		_root.add_child(shortcut)
		if app != "tasks":
			_desktop_badges[app] = _red_dot(shortcut, Vector2(62, 0))
		var caption := _label(label, 18, Color.WHITE)
		caption.position = Vector2(1245, 163 + index * 143)
		caption.size = Vector2(145, 28)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_shadow_color", Color("34254c"))
		caption.add_theme_constant_override("shadow_offset_y", 1)
		_root.add_child(caption)
	_window = _panel(Color.WHITE, 13)
	_window.position = Vector2(65, 58)
	_window.size = Vector2(1310, 638)
	_root.add_child(_window)
	var dock := _panel(Color(0.96, 0.94, 1, 0.72), 21)
	dock.position = Vector2(420, 714)
	dock.size = Vector2(600, 86)
	dock.z_index = 5
	_root.add_child(dock)
	var dock_margin := _margin(18, 7, 18, 5)
	dock.add_child(dock_margin)
	var dock_row := HBoxContainer.new()
	dock_row.add_theme_constant_override("separation", 17)
	dock_margin.add_child(dock_row)
	var actions: Dictionary = {"tasks":"Open my task.", "slack":"Open Slack.", "changes":"Open Changes.", "ai":"Use BatchGPT.", "phone":"Open Loop on my phone.", "stand":"Stand up from my desk."}
	for app: String in actions:
		var cell := VBoxContainer.new()
		cell.add_theme_constant_override("separation", 0)
		dock_row.add_child(cell)
		var icon := _icon_button(app, str(actions[app]))
		icon.custom_minimum_size = Vector2(66, 66)
		icon.pressed.connect(_launch_icon.bind(app))
		cell.add_child(icon)
		_dock_buttons[app] = icon
		var dot := _label("•", 13, Color("49395a"))
		dot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		dot.custom_minimum_size = Vector2(66, 8)
		dot.hide()
		cell.add_child(dot)
		_dock_dots[app] = dot
	_slack_button = _dock_buttons["slack"]
	for app: String in ["slack", "changes", "ai"]:
		_dock_badges[app] = _red_dot(_dock_buttons[app], Vector2(53, 0))
	_slack_badge = _dock_badges["slack"]
	_build_notifications()
	_cursor = _label("↖", 29, Color("182332"))
	_cursor.z_index = 10
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_cursor.add_theme_color_override("font_shadow_color", Color.WHITE)
	_cursor.add_theme_constant_override("shadow_offset_x", 1)
	_cursor.add_theme_constant_override("shadow_offset_y", 1)
	_root.add_child(_cursor)
	_cursor.hide()


func _launch_icon(app: String) -> void:
	if app == "tasks":
		_open_saved_task()
	elif app == "phone":
		phone_requested.emit()
	elif app == "stand":
		close_requested.emit()
	else:
		_navigate_app(app)


func _svg_texture(svg: String) -> ImageTexture:
	var image := Image.new()
	var result: Error = image.load_svg_from_string(svg)
	if result != OK:
		push_error("Could not render desktop artwork.")
	return ImageTexture.create_from_image(image)


func _icon_button(app: String, action: String) -> Button:
	if not _icon_cache.has(app):
		var art: Dictionary = {
			"tasks":"<rect x='5' y='5' width='54' height='54' rx='15' fill='#eaa94e'/><path d='M16 23h13l5 5h16v22H16Z' fill='#fff0c4'/><path d='M16 23h16l4 5H16Z' fill='#ffe2a1'/><path d='m23 38 4 4 8-9' fill='none' stroke='#bc752d' stroke-width='4' stroke-linecap='round' stroke-linejoin='round'/>",
			"slack":"<rect x='5' y='5' width='54' height='54' rx='15' fill='#fff'/><rect x='27' y='13' width='8' height='22' rx='4' fill='#36c5f0'/><rect x='13' y='27' width='22' height='8' rx='4' fill='#2eb67d'/><rect x='37' y='29' width='8' height='22' rx='4' fill='#ecb22e'/><rect x='29' y='37' width='22' height='8' rx='4' fill='#e01e5a'/><circle cx='17' cy='17' r='4' fill='#36c5f0'/><circle cx='47' cy='17' r='4' fill='#2eb67d'/><circle cx='47' cy='47' r='4' fill='#ecb22e'/><circle cx='17' cy='47' r='4' fill='#e01e5a'/>",
			"changes":"<rect x='5' y='5' width='54' height='54' rx='15' fill='#258b64'/><path d='M22 45V19m0 14c0-9 20 3 20-14' fill='none' stroke='#fff' stroke-width='4'/><g fill='#258b64' stroke='#fff' stroke-width='3'><circle cx='22' cy='18' r='5'/><circle cx='22' cy='46' r='5'/><circle cx='42' cy='18' r='5'/></g>",
			"ai":"<rect x='5' y='5' width='54' height='54' rx='15' fill='#138d85'/><path d='M16 18h32v23H30l-9 7v-7h-5Z' fill='#f2fffa'/><path d='m32 23 2.7 6.3L41 32l-6.3 2.7L32 41l-2.7-6.3L23 32l6.3-2.7Z' fill='#138d85'/>",
			"phone":"<rect x='5' y='5' width='54' height='54' rx='15' fill='#292339'/><path d='M38 18v21a7 7 0 1 1-6-7V18Z' fill='#55e0d1'/><path d='M41 18v21a7 7 0 1 1-6-7V18Z' fill='#ff668e' opacity='.8'/><path d='M37 18c0 8 6 10 10 10' fill='none' stroke='#fff' stroke-width='4'/>",
			"stand":"<rect x='5' y='5' width='54' height='54' rx='15' fill='#6383b1'/><path d='M18 15h23v35H18Z' fill='#eaf1fb'/><path d='M27 32h23m-8-8 8 8-8 8' fill='none' stroke='#34547f' stroke-width='4' stroke-linecap='round' stroke-linejoin='round'/>"
		}
		_icon_cache[app] = _svg_texture("<svg xmlns='http://www.w3.org/2000/svg' width='72' height='72' viewBox='0 0 64 64'>" + str(art.get(app, art["tasks"])) + "</svg>")
	var button := Button.new()
	button.icon = _icon_cache[app]
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.tooltip_text = action
	button.set_meta("action_text", action)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	for state: String in ["normal", "hover", "pressed", "focus"]:
		var background: Color = Color(1, 1, 1, 0.23) if state == "hover" else (Color(1, 1, 1, 0.35) if state == "pressed" else Color.TRANSPARENT)
		var style := _box(background, 15, Color(1, 1, 1, 0.7) if state == "focus" else Color.TRANSPARENT)
		style.content_margin_left = 0
		style.content_margin_right = 0
		button.add_theme_stylebox_override(state, style)
	return button


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
	_desktop_task.text = "Open Tasks to continue your work." if _stage not in ["standup", "manager", "kitchen", "exit"] else task
	_menu_app.text = "Finder"
	_window.hide()
	_card_open = false
	_feedback = false


func show_card(card: Dictionary) -> void:
	_app = str(card.get("app", "changes"))
	if _app == "slack":
		_unread = 0
		var sender: String = str(card.get("speaker", "")).split(" · ")[0]
		if sender in ["Maya", "Sam", "Jordan"]:
			_slack_channel = sender
		_refresh_inbox_badge()
	_last_card = card.duplicate(true)
	_task = str(card.get("title", _task))
	_card_open = true
	_feedback = false
	_choice_count = 0
	_build_app_shell(_app)
	if _app == "changes":
		_cr_header(_current_cr())
	else:
		_add_app_heading(str(card.get("title", "Your task")))
	if _app == "ai":
		_window_stack.add_child(_label("✦ BatchGPT · Feature conversation", 17, TEAL))
	elif _app == "slack":
		_window_stack.add_child(_label(_slack_channel + " · Today", 17, MUTED))
	var content := _scroll_content()
	_add_message(content, str(card.get("body", "")))
	var decision: String = str(card.get("decision", ""))
	if not decision.is_empty():
		var question := _body("[b]" + decision + "[/b]")
		var question_font := FontVariation.new()
		question_font.base_font = UIFont
		question_font.variation_embolden = 0.6
		question.add_theme_font_override("bold_font", question_font)
		question.add_theme_color_override("default_color", _accent)
		content.add_child(question)
	var choices: Array = card.get("choices", [])
	_choice_count = choices.size()
	for index: int in range(choices.size()):
		var button := _button(str(choices[index].get("label", "Continue working.")))
		button.custom_minimum_size.y = 56
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.pressed.connect(_select.bind(index))
		content.add_child(button)


func show_feedback(text: String, changes: Dictionary = {}) -> void:
	_card_open = true
	_feedback = true
	_choice_count = 0
	_build_app_shell(_app)
	_add_app_heading("Message delivered." if _app == "slack" else ("Change updated." if _app == "changes" else "BatchGPT replied."))
	var content := _scroll_content()
	if not text.is_empty():
		_add_message(content, text.split("\n\n")[0])
	var change_row := HFlowContainer.new()
	change_row.add_theme_constant_override("h_separation", 18)
	change_row.add_theme_constant_override("v_separation", 8)
	content.add_child(change_row)
	for key: String in ["delivery", "quality", "trust", "energy"]:
		var delta: int = int(changes.get(key, 0))
		if delta != 0:
			change_row.add_child(_label("%s %+d" % [key.capitalize(), delta], 21, Color("18734d") if delta > 0 else Color("bd3a4a")))
	if changes.is_empty():
		change_row.add_child(_label("No stat changes.", 18, MUTED))
	var next := _button("Continue working.", true)
	next.pressed.connect(func() -> void: continue_pressed.emit())
	_window_stack.add_child(next)


func is_card_open() -> bool:
	return _card_open


func forward_input(event: InputEvent) -> bool:
	if not active or not is_instance_valid(_camera) or not is_instance_valid(_surface):
		return false
	if event is InputEventKey:
		if not _window.visible:
			return false
		if is_instance_valid(_chat_input) and _chat_input.has_focus():
			_viewport.push_input(event.duplicate(), true)
			return true
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
		_menu_app.text = str({"slack":"Slack", "changes":"Changes", "ai":"BatchGPT"}.get(_app, "Workspace"))
		return
	task_requested.emit()

func _navigate_app(app: String) -> void:
	if _feedback:
		_window.show()
		_menu_app.text = str({"slack":"Slack", "changes":"Changes", "ai":"BatchGPT"}.get(_app, "Workspace"))
		return
	app_requested.emit(app)

func set_work_state(stage: String, flags: Dictionary, _awaiting_person: String) -> void:
	_stage = stage
	_task_app = ""
	_task_thread = ""
	if stage in ["mentor", "intern"]:
		_task_app = "slack"
		_task_thread = "Maya" if stage == "mentor" else "Sam"
	elif stage == "feature":
		var built: bool = bool(flags.get("clear_prompt", false)) or bool(flags.get("vague_prompt", false)) or bool(flags.get("overbuilt", false))
		_task_app = "changes" if built else "ai"
		_task_thread = "CR #104" if built else "Save favorites (task)"
	elif stage in ["review_info", "review", "incident"]:
		_task_app = "changes"
		_task_thread = "CR #104"
	_work_flags = flags.duplicate()
	_menu_clock.text = "100%   •   Fri " + str({"standup":"09:05", "mentor":"09:30", "feature":"10:00", "review_info":"11:15", "review":"11:30", "intern":"13:00", "manager":"14:30", "kitchen":"15:15", "incident":"15:17", "exit":"17:00"}.get(stage, "09:00"))
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
			_messages.append({"sender":str(updates[stage][0]), "text":str(updates[stage][1]), "time":"Today " + _menu_clock.text.right(5)})
			var destination: String = "ai" if stage == "feature" else ("changes" if stage in ["review_info", "review", "incident"] else "slack")
			_notify(destination, str(updates[stage][0]).split(" · ")[0], str(updates[stage][1]))
	if stage == "feature" and not bool(flags.get("cr_submitted", false)) and (bool(flags.get("clear_prompt", false)) or bool(flags.get("vague_prompt", false)) or bool(flags.get("overbuilt", false))) and not _notified.has("draft_ready"):
		_notified["draft_ready"] = true
		_notify("changes", "CR #104 is ready to push", "Your draft is saved. Send it to Maya for review.")
	_cr_status = "Merged" if bool(flags.get("cr_merged", false)) else ("Changes requested" if stage in ["review_info", "review"] else ("Review requested" if bool(flags.get("cr_submitted", false)) else ("Draft" if stage == "feature" else "Not started")))
	_cr_summary.text = "CR #104  /  " + _cr_status
	_refresh_inbox_badge()

func _red_dot(parent: Control, point: Vector2) -> Label:
	var dot := Label.new()
	dot.name = "TaskDot"
	dot.position = point
	dot.size = Vector2(13, 13)
	var style := _box(Color("ed334b"), 7)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	dot.add_theme_font_size_override("font_size", 1)
	dot.add_theme_stylebox_override("normal", style)
	dot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(dot)
	dot.hide()
	return dot

func _thread_has_task(app: String, thread: String) -> bool:
	return app == _task_app and thread == _task_thread

func _refresh_inbox_badge() -> void:
	_app_unread["slack"] = _unread
	for app: String in _dock_badges:
		_dock_badges[app].visible = app == _task_app
		_desktop_badges[app].visible = app == _task_app
	_slack_button.tooltip_text = "Open Slack. %d unread messages." % _unread

func _build_notifications() -> void:
	_notification_button = Button.new()
	_notification_button.name = "AppNotification"
	_notification_button.position = Vector2(1000, 51)
	_notification_button.size = Vector2(405, 109)
	_notification_button.z_index = 8
	_notification_button.add_theme_stylebox_override("normal", _box(Color("fffdfb"), 15, Color("e2dce7")))
	_notification_button.add_theme_stylebox_override("hover", _box(Color.WHITE, 15, Color("c7b7d9")))
	_notification_button.pressed.connect(_activate_notification)
	_root.add_child(_notification_button)
	_notification_icon = TextureRect.new()
	_notification_icon.position = Vector2(14, 26)
	_notification_icon.size = Vector2(50, 50)
	_notification_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_notification_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_notification_button.add_child(_notification_icon)
	_notification_title = _label("", 18, Color("282333"))
	_notification_title.position = Vector2(77, 14)
	_notification_title.size = Vector2(310, 25)
	_notification_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	_notification_button.add_child(_notification_title)
	_notification_body = _label("", 16, Color("6c6476"))
	_notification_body.position = Vector2(77, 42)
	_notification_body.size = Vector2(307, 57)
	_notification_body.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notification_body.max_lines_visible = 2
	_notification_button.add_child(_notification_body)
	_notification_button.hide()
	_notification_timer = Timer.new()
	_notification_timer.one_shot = true
	_notification_timer.wait_time = 7.0
	_notification_timer.timeout.connect(func() -> void: _notification_button.hide())
	add_child(_notification_timer)

func _notify(app: String, title: String, message: String) -> void:
	_notification_app = app
	if app == "slack":
		_unread += 1
	else:
		_app_unread[app] = int(_app_unread.get(app, 0)) + 1
	_refresh_inbox_badge()
	_notification_icon.texture = _icon_cache[app]
	_notification_title.text = str({"slack":"Slack", "changes":"Changes", "ai":"BatchGPT"}[app]) + " · " + title
	_notification_body.text = message
	_notification_button.show()
	_notification_timer.start()
	notification_received.emit(app, title)

func _mark_app_read(app: String) -> void:
	if app == "slack":
		_unread = 0
	_app_unread[app] = 0
	_refresh_inbox_badge()
	if _notification_app == app:
		_notification_button.hide()

func _activate_notification() -> void:
	var app: String = _notification_app
	if _feedback:
		_feedback = false
		continue_pressed.emit()
	_notification_button.hide()
	app_requested.emit("notice:" + app)

func _build_app_shell(app: String) -> void:
	_chat_input = null
	_chat_mode = false
	_mark_app_read(app)
	var palettes: Dictionary = {
		"slack":["1e1d22", "797680", "68406e", "ffffff", "e9e6eb", "351538"],
		"changes":["24292f", "6e7781", "238449", "f6f8fa", "d8dee4", "eef1f4"],
		"ai":["243633", "7d8580", "158173", "fffefa", "e7e8e2", "f1f2eb"]
	}
	var palette: Array = palettes.get(app, palettes["changes"])
	_ink = Color(str(palette[0]))
	_soft = Color(str(palette[1]))
	_accent = Color(str(palette[2]))
	_paper = Color(str(palette[3]))
	_line = Color(str(palette[4]))
	var border := _box(_paper, 13, Color(1, 1, 1, 0.7))
	border.shadow_color = Color(0.08, 0.05, 0.15, 0.28)
	border.shadow_size = 17
	border.shadow_offset = Vector2(0, 8)
	border.content_margin_left = 0
	border.content_margin_right = 0
	_window.add_theme_stylebox_override("panel", border)
	for child: Node in _window.get_children():
		_window.remove_child(child)
		child.queue_free()
	var frame := VBoxContainer.new()
	frame.add_theme_constant_override("separation", 0)
	_window.add_child(frame)
	var chrome := PanelContainer.new()
	chrome.add_theme_stylebox_override("panel", _box(Color("f1eff3"), 12))
	chrome.custom_minimum_size.y = 43
	frame.add_child(chrome)
	var titlebar := HBoxContainer.new()
	titlebar.add_theme_constant_override("separation", 9)
	chrome.add_child(titlebar)
	for index: int in range(3):
		var light := Button.new()
		light.custom_minimum_size = Vector2(30, 30)
		light.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		light.tooltip_text = ["Close this window.", "Minimize this window.", "Zoom this window."][index]
		light.text = ["×", "−", "+"][index]
		light.add_theme_font_size_override("font_size", 21)
		light.add_theme_color_override("font_color", Color("572b30"))
		light.add_theme_color_override("font_hover_color", Color("572b30"))
		light.add_theme_color_override("font_pressed_color", Color("572b30"))
		light.mouse_filter = Control.MOUSE_FILTER_STOP
		light.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var color: Color = [Color("ff6059"), Color("ffbd2e"), Color("28c840")][index]
		for state: String in ["normal", "hover", "pressed", "focus"]:
			var light_style := _box(color.lightened(0.12) if state == "hover" else color, 15)
			light_style.content_margin_left = 0
			light_style.content_margin_right = 0
			light_style.content_margin_top = 0
			light_style.content_margin_bottom = 0
			light.add_theme_stylebox_override(state, light_style)
		if index == 0:
			light.pressed.connect(_close_window)
		elif index == 1:
			light.pressed.connect(_minimize_window)
		else:
			light.pressed.connect(_zoom_window)
		titlebar.add_child(light)
	var app_name: String = str({"slack":"Slack", "changes":"Changes", "ai":"BatchGPT"}.get(app, "Workspace"))
	_window_title = _label(app_name + "   —   Small Batch", 17, Color("57515e"))
	_window_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_window_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titlebar.add_child(_window_title)
	var column := HBoxContainer.new()
	column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	column.add_theme_constant_override("separation", 0)
	frame.add_child(column)
	var sidebar := PanelContainer.new()
	var side_style := _box(Color(str(palette[5])), 0)
	side_style.content_margin_left = 0
	side_style.content_margin_right = 0
	sidebar.add_theme_stylebox_override("panel", side_style)
	sidebar.custom_minimum_size.x = 218
	column.add_child(sidebar)
	_build_sidebar(sidebar, app)
	var area := _margin(28, 22, 28, 22)
	area.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	column.add_child(area)
	_window_stack = VBoxContainer.new()
	_window_stack.add_theme_constant_override("separation", 13)
	area.add_child(_window_stack)
	_menu_app.text = app_name
	for key: String in _dock_dots:
		_dock_dots[key].visible = key == app
	_window.show()


func _build_sidebar(parent: Control, app: String) -> void:
	var margin := _margin(15, 22, 15, 18)
	parent.add_child(margin)
	var stack := VBoxContainer.new()
	stack.add_theme_constant_override("separation", 9)
	margin.add_child(stack)
	var side_ink: Color = Color("f5eaf7") if app == "slack" else _ink
	var side_muted: Color = Color("bc9bbf") if app == "slack" else _soft
	stack.add_child(_label("Small Batch" if app == "slack" else ("coffee-app" if app == "changes" else "BatchGPT"), 23, side_ink))
	stack.add_child(_label("Intern workspace", 14, side_muted))
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 17
	stack.add_child(spacer)
	var links: Array = ["# engineering", "# reviews", "# incidents", "Direct messages", "Maya", "Sam", "Jordan"] if app == "slack" else (["Change requests  5", "CR #104", "Open", "Merged", "Closed", "Checks"] if app == "changes" else ["New chat", "Save favorites (task)"] + _chat_titles())
	for item: String in links:
		var button := Button.new()
		button.text = item
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 39
		button.add_theme_font_size_override("font_size", 17)
		button.add_theme_color_override("font_color", side_ink)
		button.add_theme_color_override("font_hover_color", side_ink)
		var selected: bool = item == _slack_channel if app == "slack" else item == str(links[0])
		button.add_theme_stylebox_override("normal", _box(Color(1, 1, 1, 0.09) if selected else Color.TRANSPARENT, 7))
		button.add_theme_stylebox_override("hover", _box(Color(1, 1, 1, 0.15) if app == "slack" else Color("e0e6e1"), 7))
		button.pressed.connect(_sidebar_action.bind(app, item))
		stack.add_child(button)
		if _thread_has_task(app, item) or (app == "changes" and item == "Change requests  5" and _task_app == "changes"):
			_red_dot(button, Vector2(171, 12)).show()
	var filler := Control.new()
	filler.size_flags_vertical = Control.SIZE_EXPAND_FILL
	stack.add_child(filler)
	stack.add_child(_label("●  You · available", 14, side_muted))


func _sidebar_action(app: String, item: String) -> void:
	if _feedback:
		return
	if app == "slack":
		show_slack(item)
	elif app == "ai":
		if item == "New chat":
			show_ai_chat(-1)
		elif item == "Save favorites (task)":
			app_requested.emit("ai_task")
		else:
			for index: int in range(_chats.size()):
				if _chats[index]["title"] == item:
					show_ai_chat(index)
					break
	elif item == "CR #104":
		app_requested.emit("cr:104")
	elif item == "Checks":
		show_cr_detail(104, "Checks")
	else:
		show_change_request(item if item in ["Open", "Merged", "Closed"] else "All")

func _chat_titles() -> Array:
	var titles: Array = []
	for chat: Dictionary in _chats.slice(maxi(0, _chats.size() - 6)):
		titles.append(str(chat["title"]))
	return titles



func _add_app_heading(title: String) -> void:
	if _app == "slack":
		_window_stack.add_child(_label("Messages   /   Small Batch", 15, MUTED))
	elif _app == "changes":
		var status := _label("small-batch / coffee-app     •     " + _cr_status, 16, TEAL)
		_window_stack.add_child(status)
	else:
		_window_stack.add_child(_label("BatchGPT   •   Your feature assistant", 15, MUTED))
	var heading := _label(title, 29, TEXT)
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_window_stack.add_child(heading)


func _add_message(parent: Control, text: String) -> void:
	var bubble := _panel(Color("f7f3f8") if _app == "slack" else (Color.WHITE if _app == "changes" else Color("f0f5ee")), 10)
	var style := _box(Color("f7f3f8") if _app == "slack" else (Color.WHITE if _app == "changes" else Color("f0f5ee")), 10, _line)
	bubble.add_theme_stylebox_override("panel", style)
	parent.add_child(bubble)
	var margin := _margin(15, 13, 15, 13)
	bubble.add_child(margin)
	margin.add_child(_body(text))


func _close_window() -> void:
	var acknowledge_update: bool = _feedback
	_card_open = false
	_feedback = false
	_choice_count = 0
	_window.hide()
	if acknowledge_update:
		continue_pressed.emit()
	_window.hide()
	_menu_app.text = "Finder"
	for app: String in _dock_dots:
		_dock_dots[app].hide()


func _minimize_window() -> void:
	_window.hide()
	_menu_app.text = "Finder"


func _zoom_window() -> void:
	_zoomed = not _zoomed
	_window.position = Vector2(28, 45) if _zoomed else Vector2(65, 58)
	_window.size = Vector2(1384, 658) if _zoomed else Vector2(1310, 638)


func _browse_start(app: String, title: String) -> VBoxContainer:
	_app = app
	_card_open = false
	_feedback = false
	_choice_count = 0
	_build_app_shell(app)
	_add_app_heading(title)
	return _scroll_content()

func _link(parent: Control, text: String, route: String) -> void:
	var button := _button(text)
	button.pressed.connect(func() -> void: app_requested.emit(route))
	parent.add_child(button)

func show_slack(channel: String = "# engineering", route_task: bool = true) -> void:
	if route_task and ((channel == "Maya" and _stage == "mentor") or (channel == "Sam" and _stage == "intern")):
		app_requested.emit("dm:" + channel)
		return
	_slack_channel = channel
	var content := _browse_start("slack", channel)
	for message: Dictionary in _messages:
		var sender: String = str(message["sender"])
		if channel.begins_with("#") and not sender.replace(" ", "").contains(channel.replace(" ", "")) and not (channel == "# reviews" and sender.contains("CR")):
			continue
		if channel == "Direct messages" and not (sender.contains("Direct message") or sender.begins_with("You")):
			continue
		if channel in ["Maya", "Sam", "Jordan"] and (not sender.contains(channel) or not (sender.contains("Direct message") or sender.begins_with("You") or sender.contains("CR #"))):
			continue
		content.add_child(_label(sender + "    " + str(message.get("time", "Today")), 16, MUTED))
		_add_message(content, str(message["text"]))
	if channel == "Maya" and _stage in ["review_info", "review"]:
		_link(content, "Open CR #104 and Maya's comments", "cr:104")
	elif channel == "# engineering" and _stage in ["mentor", "intern"]:
		_link(content, "Reply to " + ("Maya" if _stage == "mentor" else "Sam"), "dm:" + ("Maya" if _stage == "mentor" else "Sam"))

	await get_tree().process_frame
	if is_instance_valid(content):
		var scroll := content.get_parent() as ScrollContainer
		scroll.scroll_vertical = int(scroll.get_v_scroll_bar().max_value)

func _current_cr() -> Dictionary:
	return {"id":104, "title":"Save coffee favorites", "author":"You", "branch":"intern/save-favorites", "status":_cr_status, "added":32, "removed":4, "files":2, "comments":[["You", "Save remembers a favorite. It must never place an order."], ["Maya", "What happens when a guest double-taps? Please check before merging."]], "diff":"  When Save is clicked\n+ Remember the selected favorite\n+ Ask guests to sign in\n- Place a coffee order\n+ Ignore a repeated tap", "checks":["Favorites: " + ("passed" if _work_flags.get("tested", false) else "pending"), "Guests: " + ("passed" if _work_flags.get("tested", false) else "pending"), "Double-tap: " + ("passed" if _work_flags.get("tested", false) else "pending")]}

func show_change_request(filter_status: String = "All") -> void:
	var content := _browse_start("changes", "Change requests")
	content.add_child(_label("coffee-app    /    5 changes    /    " + filter_status, 17, MUTED))
	var records: Array = [_current_cr()] + _cr_records
	for record: Dictionary in records:
		if filter_status != "All" and str(record["status"]) != filter_status:
			continue
		var id: int = int(record["id"])
		var button := _button("#%d  %s\n%s · %s · %d files · +%d −%d" % [id, record["title"], record["status"], record["author"], record["files"], record["added"], record["removed"]])
		button.set_meta("action_text", "Open CR #%d" % id)
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.custom_minimum_size.y = 85
		button.pressed.connect(func() -> void:
			if id == 104:
				app_requested.emit("cr:104")
			else:
				show_cr_detail(id)
		)
		content.add_child(button)
		if id == 104 and _task_app == "changes":
			_red_dot(button, Vector2(6, 6)).show()

func _cr_header(record: Dictionary) -> void:
	_window_stack.add_child(_label("#%d  %s" % [record["id"], record["title"]], 26, TEXT))
	_window_stack.add_child(_label("%s · %s wants to merge %s → main" % [record["status"], record["author"], record["branch"]], 16, TEAL))
	var tabs := HBoxContainer.new()
	_window_stack.add_child(tabs)
	for tab: String in ["Conversation", "Files changed", "Checks"]:
		var button := _button(tab)
		button.add_theme_font_size_override("font_size", 17)
		button.custom_minimum_size.x = 175
		button.pressed.connect(func() -> void:
			if tab == "Conversation" and int(record["id"]) == 104:
				app_requested.emit("cr:104")
			else:
				show_cr_detail(int(record["id"]), tab)
		)
		tabs.add_child(button)

func show_cr_detail(id: int, tab: String = "Conversation") -> void:
	_app = "changes"
	_card_open = false
	_feedback = false
	_choice_count = 0
	_build_app_shell("changes")
	var record: Dictionary = _current_cr()
	for old: Dictionary in _cr_records:
		if int(old["id"]) == id:
			record = old
	_selected_cr = id
	_cr_tab = tab
	_cr_header(record)
	var content := _scroll_content()
	if tab == "Files changed":
		content.add_child(_label("%d files changed     +%d additions     −%d deletions" % [record["files"], record["added"], record["removed"]], 17, MUTED))
		for line: String in str(record["diff"]).split("\n"):
			content.add_child(_label(line, 20, Color("18734d") if line.begins_with("+") else (Color("bd3a4a") if line.begins_with("-") else _ink)))
	elif tab == "Checks":
		for check: String in record["checks"]:
			_add_message(content, check)
	else:
		for comment: Array in record["comments"]:
			content.add_child(_label(str(comment[0]) + " commented", 17, MUTED))
			_add_message(content, str(comment[1]))

func show_ai_idle() -> void:
	show_ai_chat(_active_chat)

func show_ai_chat(index: int = -1) -> void:
	_active_chat = index
	var content := _browse_start("ai", "New chat" if index < 0 else str(_chats[index]["title"]))
	_chat_mode = true
	_chat_scroll = content.get_parent() as ScrollContainer
	if index < 0:
		_add_message(content, "What are we pretending to ship today?")
	else:
		for message: Dictionary in _chats[index]["messages"]:
			content.add_child(_label("You" if message["role"] == "user" else "✦ BatchGPT", 16, TEAL))
			var label := _label(str(message["text"]), 21, TEXT)
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			content.add_child(label)
		if _chat_pending.has(index):
			content.add_child(_label("BatchGPT is typing…", 17, MUTED))
	var composer := HBoxContainer.new()
	_window_stack.add_child(composer)
	_chat_input = LineEdit.new()
	_chat_input.placeholder_text = "Message BatchGPT…"
	_chat_input.max_length = 600
	_chat_input.add_theme_stylebox_override("normal", _box(Color("f1f4ef"), 14, Color("dce3db")))
	_chat_input.add_theme_stylebox_override("focus", _box(Color("f1f4ef"), 14, Color("158173")))
	_chat_input.add_theme_color_override("font_color", Color("243633"))
	_chat_input.add_theme_color_override("font_placeholder_color", Color("7d8580"))
	_chat_input.custom_minimum_size.y = 52
	_chat_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_chat_input.add_theme_font_size_override("font_size", 20)
	_chat_input.text_submitted.connect(func(_text: String) -> void: _send_chat())
	composer.add_child(_chat_input)
	var send := _button("Send", true)
	send.pressed.connect(_send_chat)
	composer.add_child(send)
	await get_tree().process_frame
	if is_instance_valid(_chat_scroll):
		_chat_scroll.scroll_vertical = int(_chat_scroll.get_v_scroll_bar().max_value)

func _send_chat() -> void:
	if not is_instance_valid(_chat_input):
		return
	var prompt: String = _chat_input.text.strip_edges()
	if prompt.is_empty() or _chat_pending.has(_active_chat):
		return
	if _active_chat < 0:
		_chats.append({"title":prompt.left(28), "messages":[]})
		_active_chat = _chats.size() - 1
	var index: int = _active_chat
	_chats[index]["messages"].append({"role":"user", "text":prompt})
	_chat_pending[index] = true
	show_ai_chat(index)
	await get_tree().create_timer(0.45).timeout
	var answer: String = WorkspaceData.reply(prompt, str(_chats[index].get("last_reply", "")))
	_chats[index]["last_reply"] = answer
	_chats[index]["messages"].append({"role":"assistant", "text":answer})
	_chat_pending.erase(index)
	if _chat_mode and _active_chat == index and _window.visible:
		show_ai_chat(index)


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
	if color == TEXT:
		color = _ink
	elif color == MUTED:
		color = _soft
	elif color == TEAL:
		color = _accent
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
	body.add_theme_color_override("default_color", _ink)
	body.add_theme_font_size_override("normal_font_size", 21)
	body.add_theme_font_size_override("bold_font_size", 21)
	body.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return body


func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(100, 47)
	button.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	button.add_theme_font_size_override("font_size", 21)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("normal", _box(_accent if primary else Color.WHITE, 8, _accent if primary else _line))
	button.add_theme_stylebox_override("hover", _box(_accent.lightened(0.1) if primary else _paper.darkened(0.035), 8, _accent))
	button.add_theme_stylebox_override("pressed", _box(_accent.darkened(0.08) if primary else _paper.darkened(0.07), 8))
	button.add_theme_stylebox_override("focus", _box(Color.TRANSPARENT, 8, _accent))
	button.add_theme_color_override("font_color", Color.WHITE if primary else _ink)
	button.add_theme_color_override("font_hover_color", Color.WHITE if primary else _ink)
	button.add_theme_color_override("font_pressed_color", Color.WHITE if primary else _ink)
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
