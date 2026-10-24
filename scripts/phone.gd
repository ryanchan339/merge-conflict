extends CanvasLayer
## A fictional, entirely local short-video feed. The game owns consequences.

signal closed
signal scrolled(count: int)

const INTER_FONT = preload("res://assets/fonts/Inter.ttf")

const POSTS: Array[Dictionary] = [
	{"caption": "Deploying directly\nto caffeine.", "creator": "@bean_deploy", "likes": "12.8K", "scene": 0, "a": "#ff855f", "b": "#ffc868", "sound": "espresso.exe"},
	{"caption": "Senior engineer\nreviewing my work.", "creator": "@staff_cat", "likes": "84.2K", "scene": 1, "a": "#81ddbc", "b": "#bff6d4", "sound": "mechanical purrs"},
	{"caption": "Me after saying\n‘quick fix’.", "creator": "@one_more_commit", "likes": "43.1K", "scene": 2, "a": "#7667ee", "b": "#f7a3d6", "sound": "tiny keyboard panic"},
	{"caption": "This meeting could\nhave been a snack.", "creator": "@calendar_crime", "likes": "9,104", "scene": 3, "a": "#f3cc64", "b": "#f59f65", "sound": "alignment, alignment"},
	{"caption": "My most qualified\ncolleague.", "creator": "@duck_driven", "likes": "29.7K", "scene": 4, "a": "#5e9af0", "b": "#8bcfe5", "sound": "original quack"},
	{"caption": "Production when\nI leave for lunch.", "creator": "@uptime_optional", "likes": "51.6K", "scene": 5, "a": "#ed737c", "b": "#ffb395", "sound": "the pager remix"},
	{"caption": "Just five\nmore minutes.", "creator": "@tomorrow_me", "likes": "105K", "scene": 6, "a": "#b28bef", "b": "#eab9ef", "sound": "where did Friday go"},
	{"caption": "Senior\nphotosynthesizer.", "creator": "@office_fern", "likes": "18.2K", "scene": 7, "a": "#79cbe7", "b": "#b5e8dd", "sound": "growth mindset"},
	{"caption": "Two branches.\nOne brain cell.", "creator": "@merge_emergency", "likes": "67.4K", "scene": 8, "a": "#5bd0c5", "b": "#b4ec83", "sound": "conflict resolution"},
	{"caption": "AI wrote it.\nI read none of it.", "creator": "@prompt_and_pray", "likes": "36.9K", "scene": 9, "a": "#e987b4", "b": "#ffbdc5", "sound": "confidently incorrect"}
]

var _opened: bool = false
var _post_index: int = 0
var _likes: Dictionary = {}
var _previous_mouse_mode: Input.MouseMode = Input.MOUSE_MODE_CAPTURED
var _root: Control
var _device: Control
var _screen: Control
var _video: LoopVideo
var _caption: Label
var _creator: Label
var _sound: Label
var _like_button: Button
var _like_count: Label
var _dots: Label
var _progress: ColorRect
var _dragging: bool = false
var _drag_origin: Vector2
var _drag_distance: float = 0.0
var _transition: Tween


func _ready() -> void:
	layer = 40
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	_root.hide()
	set_process_input(false)
	get_viewport().size_changed.connect(_layout)


func open_phone() -> void:
	if _opened:
		return
	_opened = true
	_previous_mouse_mode = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_root.show()
	_layout()
	_show_post()
	set_process_input(true)
	_device.modulate.a = 0.0
	create_tween().tween_property(_device, "modulate:a", 1.0, 0.18)


func close_phone() -> void:
	if not _opened:
		return
	_opened = false
	_dragging = false
	_root.hide()
	set_process_input(false)
	Input.mouse_mode = _previous_mouse_mode
	closed.emit()


func is_open() -> bool:
	return _opened


func _process(_delta: float) -> void:
	if _opened and is_instance_valid(_video):
		_progress.size.x = 340.0 * fmod(_video.elapsed, 6.0) / 6.0


func _input(event: InputEvent) -> void:
	if not _opened:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		match event.keycode:
			KEY_ESCAPE:
				close_phone()
				get_viewport().set_input_as_handled()
			KEY_DOWN, KEY_PAGEDOWN, KEY_SPACE:
				_advance(1)
				get_viewport().set_input_as_handled()
			KEY_UP, KEY_PAGEUP:
				_advance(-1)
				get_viewport().set_input_as_handled()
	if event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			_advance(1)
			get_viewport().set_input_as_handled()
		elif event.pressed and event.button_index == MOUSE_BUTTON_WHEEL_UP:
			_advance(-1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed and _screen.get_global_rect().has_point(event.position):
				_dragging = true
				_drag_origin = event.position
				_drag_distance = 0.0
			elif not event.pressed and _dragging:
				_dragging = false
				_finish_swipe()
	if event is InputEventMouseMotion and _dragging:
		_drag_distance = event.position.y - _drag_origin.y
		_video.position.y = clampf(_drag_distance * 0.12, -28.0, 28.0)
	if event is InputEventScreenTouch:
		if event.pressed:
			_dragging = _screen.get_global_rect().has_point(event.position)
			_drag_origin = event.position
			_drag_distance = 0.0
		elif _dragging:
			_dragging = false
			_finish_swipe()
	if event is InputEventScreenDrag and _dragging:
		_drag_distance = event.position.y - _drag_origin.y
		_video.position.y = clampf(_drag_distance * 0.12, -28.0, 28.0)


func _finish_swipe() -> void:
	if absf(_drag_distance) > 45.0:
		_advance(1 if _drag_distance < 0.0 else -1)
		get_viewport().set_input_as_handled()
	else:
		create_tween().tween_property(_video, "position:y", 0.0, 0.12)
	_drag_distance = 0.0


func _advance(direction: int) -> void:
	if not _opened:
		return
	_post_index = posmod(_post_index + direction, POSTS.size())
	_show_post()
	if is_instance_valid(_transition):
		_transition.kill()
	_video.position.y = 68.0 * signf(float(direction))
	_video.modulate.a = 0.5
	_transition = create_tween().set_parallel(true)
	_transition.tween_property(_video, "position:y", 0.0, 0.17).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_transition.tween_property(_video, "modulate:a", 1.0, 0.17)
	scrolled.emit(1)


func _toggle_like() -> void:
	_likes[_post_index] = not bool(_likes.get(_post_index, false))
	_update_like()
	var bump: Tween = create_tween()
	bump.tween_property(_like_button, "scale", Vector2.ONE * 1.17, 0.09)
	bump.tween_property(_like_button, "scale", Vector2.ONE, 0.14)


func _update_like() -> void:
	var liked: bool = bool(_likes.get(_post_index, false))
	_like_button.text = "♥" if liked else "♡"
	_like_button.add_theme_color_override("font_color", Color("#ff547c") if liked else Color.WHITE)
	_like_count.text = POSTS[_post_index]["likes"]


func _show_post() -> void:
	var post: Dictionary = POSTS[_post_index]
	_video.set_clip(int(post["scene"]), Color(post["a"]), Color(post["b"]))
	_caption.text = post["caption"]
	_creator.text = post["creator"]
	_sound.text = "♪  " + str(post["sound"])
	var dot_text: String = ""
	for index in POSTS.size():
		dot_text += "● " if index == _post_index else "· "
	_dots.text = dot_text.strip_edges()
	_update_like()


func _build_ui() -> void:
	_root = Control.new()
	_root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_root.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(_root)
	var dim: ColorRect = ColorRect.new()
	dim.color = Color(0.015, 0.025, 0.04, 0.46)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.mouse_filter = Control.MOUSE_FILTER_STOP
	_root.add_child(dim)
	_device = Control.new()
	_device.size = Vector2(368, 720)
	_root.add_child(_device)
	var case_panel: Panel = Panel.new()
	case_panel.size = _device.size
	case_panel.add_theme_stylebox_override("panel", _style(Color("#10131c"), 47, Color("#5a6272"), 2, 30))
	_device.add_child(case_panel)
	_screen = Control.new()
	_screen.position = Vector2(14, 14)
	_screen.size = Vector2(340, 692)
	_screen.clip_contents = true
	_screen.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_device.add_child(_screen)
	_video = LoopVideo.new()
	_video.size = _screen.size
	_video.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(_video)
	var shade: Gradient = Gradient.new()
	shade.offsets = PackedFloat32Array([0.0, 0.18, 0.46, 0.72, 1.0])
	shade.colors = PackedColorArray([Color(0, 0, 0, 0.35), Color(0, 0, 0, 0), Color(0, 0, 0, 0), Color(0.01, 0.02, 0.05, 0.5), Color(0.01, 0.02, 0.05, 0.94)])
	var texture: GradientTexture2D = GradientTexture2D.new()
	texture.gradient = shade
	texture.fill_from = Vector2(0, 0)
	texture.fill_to = Vector2(0, 1)
	var scrim: TextureRect = TextureRect.new()
	scrim.texture = texture
	scrim.size = _screen.size
	scrim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_screen.add_child(scrim)
	var ring: Panel = Panel.new()
	ring.size = _device.size
	ring.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var ring_style: StyleBoxFlat = _style(Color("#10131c"), 47)
	ring_style.set_border_width_all(14)
	ring_style.border_color = Color("#10131c")
	ring_style.draw_center = false
	ring.add_theme_stylebox_override("panel", ring_style)
	_device.add_child(ring)
	var notch: Panel = Panel.new()
	notch.position = Vector2(130, 14)
	notch.size = Vector2(108, 24)
	notch.add_theme_stylebox_override("panel", _style(Color("#10131c"), 12))
	_device.add_child(notch)
	_label("9:41", Vector2(36, 24), Vector2(60, 20), 13)
	_label("▰  ▰", Vector2(276, 24), Vector2(58, 20), 13)
	_label("Loop", Vector2(34, 62), Vector2(110, 40), 31)
	var tab: Label = _label("For you", Vector2(143, 73), Vector2(96, 25), 17)
	tab.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var active_line: ColorRect = ColorRect.new()
	active_line.position = Vector2(166, 102)
	active_line.size = Vector2(50, 3)
	active_line.color = Color("#c0ffde")
	active_line.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_device.add_child(active_line)
	_button("×", Vector2(294, 62), Vector2(40, 40), 26, close_phone)
	_button("↑", Vector2(292, 331), Vector2(40, 40), 21, func() -> void: _advance(-1))
	_button("↓", Vector2(292, 380), Vector2(40, 40), 21, func() -> void: _advance(1))
	_like_button = _button("♡", Vector2(282, 453), Vector2(60, 53), 38, _toggle_like)
	_like_button.pivot_offset = _like_button.size * 0.5
	_like_count = _label("", Vector2(278, 508), Vector2(69, 22), 13)
	_like_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_caption = _label("", Vector2(34, 492), Vector2(242, 74), 25)
	_caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_caption.add_theme_constant_override("outline_size", 3)
	_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.25))
	_creator = _label("", Vector2(35, 574), Vector2(265, 27), 18)
	_sound = _label("", Vector2(35, 608), Vector2(280, 23), 14)
	_sound.modulate.a = 0.8
	_dots = _label("", Vector2(34, 639), Vector2(300, 19), 15)
	_dots.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_dots.modulate.a = 0.8
	_button("I’ll put this down.", Vector2(101, 662), Vector2(166, 32), 14, close_phone)
	_progress = ColorRect.new()
	_progress.position = Vector2(14, 653)
	_progress.size = Vector2(0, 2)
	_progress.color = Color(1, 1, 1, 0.55)
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_device.add_child(_progress)


func _layout() -> void:
	if not is_instance_valid(_device):
		return
	var viewport_size: Vector2 = get_viewport().get_visible_rect().size
	var factor: float = minf(1.0, (viewport_size.y - 42.0) / 720.0)
	factor = minf(factor, (viewport_size.x - 32.0) / 368.0)
	_device.scale = Vector2.ONE * factor
	var width: float = 368.0 * factor
	var height: float = 720.0 * factor
	var center_x: float = viewport_size.x * 0.72 if viewport_size.x > 850.0 else viewport_size.x * 0.5
	_device.position = Vector2(clampf(center_x - width * 0.5, 16.0, viewport_size.x - width - 16.0), (viewport_size.y - height) * 0.5)


func _label(text: String, at: Vector2, dimensions: Vector2, font_size: int) -> Label:
	var label: Label = Label.new()
	label.text = text
	label.position = at
	label.size = dimensions
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_override("font", INTER_FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color.WHITE)
	label.add_theme_constant_override("shadow_offset_x", 0)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.35))
	_device.add_child(label)
	return label


func _button(text: String, at: Vector2, dimensions: Vector2, font_size: int, action: Callable) -> Button:
	var button: Button = Button.new()
	button.text = text
	button.position = at
	button.size = dimensions
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_override("font", INTER_FONT)
	button.add_theme_font_size_override("font_size", font_size)
	button.add_theme_color_override("font_color", Color.WHITE)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _style(Color(0.02, 0.025, 0.04, 0.29), 20))
	button.add_theme_stylebox_override("hover", _style(Color(0.1, 0.13, 0.19, 0.65), 20, Color(1, 1, 1, 0.25), 1))
	button.add_theme_stylebox_override("pressed", _style(Color(0.12, 0.16, 0.19, 0.8), 20))
	button.pressed.connect(action)
	_device.add_child(button)
	return button


func _style(fill: Color, radius: int, border: Color = Color.TRANSPARENT, width: int = 0, shadow: int = 0) -> StyleBoxFlat:
	var box: StyleBoxFlat = StyleBoxFlat.new()
	box.bg_color = fill
	box.set_corner_radius_all(radius)
	box.set_border_width_all(width)
	box.border_color = border
	box.shadow_color = Color(0, 0, 0, 0.4)
	box.shadow_size = shadow
	box.shadow_offset = Vector2(0, 13)
	return box


class LoopVideo extends Control:
	var elapsed: float = 0.0
	var clip: int = 0
	var color_a: Color = Color("#ff855f")
	var color_b: Color = Color("#ffc868")
	var ink: Color = Color("#243447")
	var cream: Color = Color("#fff5dd")
	var font: Font = preload("res://assets/fonts/Inter.ttf")


	func set_clip(index: int, first: Color, second: Color) -> void:
		clip = index
		color_a = first
		color_b = second
		elapsed = 0.0
		position = Vector2.ZERO
		queue_redraw()


	func _process(delta: float) -> void:
		if is_visible_in_tree():
			elapsed += delta
			queue_redraw()


	func _draw() -> void:
		draw_set_transform(Vector2.ZERO, 0, size / Vector2(360, 640))
		draw_rect(Rect2(0, 0, 360, 640), color_a)
		for row in 64:
			var blend: float = float(row) / 64.0
			draw_rect(Rect2(0, row * 10, 360, 10), color_a.lerp(color_b, blend * 0.65))
		var t: float = elapsed
		for index in 8:
			var center: Vector2 = Vector2(fposmod(index * 91.0 + sin(t * 0.25 + index) * 18.0, 410.0) - 25.0, fposmod(index * 147.0 - t * 9.0, 730.0) - 45.0)
			draw_circle(center, 20 + index * 7, Color(1, 1, 1, 0.07), false, 2.0, true)
		match clip:
			0: _coffee(t)
			1: _cat(t)
			2: _code_rain(t)
			3: _meeting(t)
			4: _duck(t)
			5: _servers(t)
			6: _time_sink(t)
			7: _plant(t)
			8: _merge(t)
			9: _robot(t)
		for index in 18:
			var x: float = float((index * 53 + 17) % 360)
			var y: float = float((index * 97 + 33) % 640)
			draw_circle(Vector2(x, y), 1.0, Color(1, 1, 1, 0.16))


	func _round(rect: Rect2, color: Color, radius: float = 12.0) -> void:
		var r: float = minf(radius, minf(rect.size.x, rect.size.y) * 0.5)
		draw_rect(Rect2(rect.position + Vector2(r, 0), rect.size - Vector2(2 * r, 0)), color)
		draw_rect(Rect2(rect.position + Vector2(0, r), rect.size - Vector2(0, 2 * r)), color)
		for center in [rect.position + Vector2(r, r), rect.position + Vector2(rect.size.x - r, r), rect.end - Vector2(r, r), rect.position + Vector2(r, rect.size.y - r)]:
			draw_circle(center, r, color, true, -1.0, true)


	func _word(text: String, at: Vector2, font_size: int, color: Color = Color.WHITE) -> void:
		draw_string(font, at, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, color)


	func _spark(at: Vector2, radius: float, color: Color) -> void:
		draw_colored_polygon(PackedVector2Array([at + Vector2(0, -radius), at + Vector2(radius * 0.24, -radius * 0.24), at + Vector2(radius, 0), at + Vector2(radius * 0.24, radius * 0.24), at + Vector2(0, radius), at + Vector2(-radius * 0.24, radius * 0.24), at + Vector2(-radius, 0), at + Vector2(-radius * 0.24, -radius * 0.24)]), color)


	func _eyes(at: Vector2, spacing: float, blink: float = 1.0) -> void:
		for side in [-1, 1]:
			_round(Rect2(at + Vector2(spacing * side - 4, -4), Vector2(8, maxf(2, 11 * blink))), ink, 4)


	func _coffee(t: float) -> void:
		var y: float = 235 + sin(t * 2.1) * 8
		_ellipse(Vector2(180, 389), Vector2(112, 15), Color(ink, 0.13))
		draw_arc(Vector2(256, y + 48), 35, -PI * 0.56, PI * 0.56, 28, cream, 15, true)
		_round(Rect2(87, y, 174, 128), cream, 22)
		_ellipse(Vector2(174, y + 8), Vector2(86, 22), Color("#e8d3b7"))
		_ellipse(Vector2(174, y + 9), Vector2(73, 15), Color("#704833"))
		_eyes(Vector2(174, y + 62), 26)
		draw_arc(Vector2(174, y + 69), 17, 0.1, PI - 0.1, 20, ink, 3, true)
		for index in 3:
			var steam: PackedVector2Array = PackedVector2Array()
			for point in 20:
				steam.append(Vector2(132 + index * 40 + sin(t * 2 + point * 0.22 + index) * 8, y - 16 - point * 3))
			draw_polyline(steam, Color(cream, 0.65), 4, true)
		_spark(Vector2(60, 230 + sin(t) * 8), 17, cream)
		_spark(Vector2(301, 182 + cos(t) * 10), 12, cream)
		_word("100% CAFFEINATED", Vector2(77, 422), 20, ink)


	func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
		var points: PackedVector2Array = PackedVector2Array()
		for index in 40:
			var angle: float = TAU * index / 40.0
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
		draw_colored_polygon(points, color)


	func _cat(t: float) -> void:
		_ellipse(Vector2(180, 396), Vector2(127, 16), Color(ink, 0.13))
		_round(Rect2(45, 319, 270, 73), ink, 13)
		for row in 3:
			for key in 9:
				var key_color: Color = cream if (key + row + int(t * 7)) % 8 != 0 else Color("#f794aa")
				_round(Rect2(58 + key * 27, 332 + row * 16, 21, 10), key_color, 3)
		var bob: float = sin(t * 3) * 6
		_ellipse(Vector2(180, 287 + bob), Vector2(75, 67), Color("#edb77b"))
		var center: Vector2 = Vector2(179, 219 + bob)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-62, -20), center + Vector2(-66, -86), center + Vector2(-14, -48)]), Color("#d9965e"))
		draw_colored_polygon(PackedVector2Array([center + Vector2(62, -20), center + Vector2(66, -86), center + Vector2(14, -48)]), Color("#d9965e"))
		_ellipse(center, Vector2(76, 60), Color("#edb77b"))
		_eyes(center + Vector2(0, -1), 27, 0.45 if fmod(t, 3.2) > 3.0 else 1.0)
		draw_circle(center + Vector2(0, 17), 6, Color("#bb6d66"))
		for side in [-1, 1]:
			for line in 2:
				draw_line(center + Vector2(38 * side, 17 + line * 9), center + Vector2(83 * side, 9 + line * 18), ink, 2, true)
			var paw_y: float = 330 + sin(t * 11 + side) * 10
			_ellipse(Vector2(131 if side == -1 else 229, paw_y), Vector2(25, 17), Color("#f5c994"))
		_word("APPROVED, PROBABLY", Vector2(65, 427), 19, ink)


	func _code_rain(t: float) -> void:
		for index in 13:
			var y: float = fposmod(index * 81.0 + t * (37 + index % 3 * 14), 380.0) + 113
			var x: float = float((index * 59) % 300) + 12
			_round(Rect2(x, y, 30 + index % 4 * 12, 8), Color(cream, 0.45), 3)
			_round(Rect2(x + 9, y + 14, 20 + index % 3 * 8, 6), Color(cream, 0.25), 3)
		var center: Vector2 = Vector2(182 + sin(t * 1.4) * 14, 305)
		draw_line(center + Vector2(0, -42), center + Vector2(0, 40), cream, 5, true)
		draw_colored_polygon(PackedVector2Array([center + Vector2(-78, -42), center + Vector2(-48, -83), center + Vector2(0, -99), center + Vector2(48, -83), center + Vector2(78, -42)]), Color("#f4c76b"))
		draw_circle(center + Vector2(0, -8), 18, cream)
		_round(Rect2(center + Vector2(-18, 12), Vector2(36, 61)), ink, 12)
		draw_line(center + Vector2(-10, 66), center + Vector2(-23, 102 + sin(t * 5) * 6), ink, 9, true)
		draw_line(center + Vector2(10, 66), center + Vector2(23, 102 - sin(t * 5) * 6), ink, 9, true)
		_word("IT WAS ONE LINE", Vector2(89, 170), 22, cream)


	func _meeting(t: float) -> void:
		draw_circle(Vector2(180, 238), 89, cream)
		draw_circle(Vector2(180, 238), 76, Color("#f4dea9"))
		for mark in 12:
			var a: float = TAU * mark / 12.0
			draw_line(Vector2(180, 238) + Vector2(sin(a), -cos(a)) * 61, Vector2(180, 238) + Vector2(sin(a), -cos(a)) * 68, ink, 3, true)
		draw_line(Vector2(180, 238), Vector2(180, 238) + Vector2(sin(t * 2.5), -cos(t * 2.5)) * 56, ink, 5, true)
		draw_line(Vector2(180, 238), Vector2(180, 238) + Vector2(sin(t * 0.3), -cos(t * 0.3)) * 33, ink, 7, true)
		draw_circle(Vector2(180, 238), 7, ink)
		_round(Rect2(43, 360, 274, 32), Color("#b66d4a"), 12)
		for index in 3:
			var y: float = 344 + sin(t * 2 + index) * 4
			_round(Rect2(81 + index * 76, y - 39, 43, 40), cream, 7)
			_ellipse(Vector2(102 + index * 76, y - 38), Vector2(21, 6), Color("#77513a"))
		_word("15 MINUTES, SOMEHOW", Vector2(66, 429), 19, ink)


	func _duck(t: float) -> void:
		for ripple in 4:
			_ellipse(Vector2(183, 348 + ripple * 8), Vector2(80 + ripple * 20 + sin(t * 2) * 5, 10), Color(cream, 0.09))
		var bob: float = sin(t * 2.5) * 9
		_ellipse(Vector2(176, 299 + bob), Vector2(82, 57), Color("#ffdf68"))
		draw_circle(Vector2(220, 243 + bob), 45, Color("#ffe985"))
		draw_colored_polygon(PackedVector2Array([Vector2(253, 242 + bob), Vector2(297, 253 + bob), Vector2(252, 267 + bob)]), Color("#ed9460"))
		draw_circle(Vector2(233, 233 + bob), 5, ink)
		draw_arc(Vector2(170, 299 + bob), 28, 0.3, 2.5, 24, Color("#eeb749"), 4, true)
		_round(Rect2(45, 140, 137, 61), cream, 18)
		draw_colored_polygon(PackedVector2Array([Vector2(132, 195), Vector2(147, 217), Vector2(157, 191)]), cream)
		_word("have you tried", Vector2(60, 164), 15, ink)
		_word("a break?", Vector2(60, 186), 19, ink)
		_spark(Vector2(68, 282 + sin(t) * 8), 13, cream)


	func _servers(t: float) -> void:
		var wobble: float = sin(t * 11) * 2.5
		_round(Rect2(90 + wobble, 167, 178, 232), ink, 15)
		for row in 4:
			_round(Rect2(103 + wobble, 184 + row * 51, 152, 39), Color("#405064"), 7)
			for led in 4:
				var active: bool = (int(t * 5) + row + led) % 3 != 0
				draw_circle(Vector2(122 + wobble + led * 17, 203 + row * 51), 4, Color("#ffcc7a") if active else Color("#6bdab7"))
			draw_line(Vector2(204 + wobble, 197 + row * 51), Vector2(241 + wobble, 197 + row * 51), Color("#8292a3"), 3)
			draw_line(Vector2(204 + wobble, 208 + row * 51), Vector2(241 + wobble, 208 + row * 51), Color("#8292a3"), 3)
		var triangle: PackedVector2Array = PackedVector2Array([Vector2(278, 125 + sin(t * 5) * 7), Vector2(315, 190 + sin(t * 5) * 7), Vector2(242, 190 + sin(t * 5) * 7)])
		draw_colored_polygon(triangle, Color("#ffdf78"))
		_word("!", Vector2(272, 176 + sin(t * 5) * 7), 33, ink)
		_word("ALL SYSTEMS: VIBES", Vector2(74, 433), 20, ink)


	func _time_sink(t: float) -> void:
		var center: Vector2 = Vector2(180, 268)
		draw_circle(center, 102, cream)
		draw_circle(center, 84, Color("#e3c4ef"))
		for index in 12:
			var a: float = index * TAU / 12.0
			draw_circle(center + Vector2(cos(a), sin(a)) * 72, 3, ink)
		draw_line(center, center + Vector2(cos(t * 4), sin(t * 4)) * 66, ink, 5, true)
		draw_line(center, center + Vector2(cos(t * 0.8), sin(t * 0.8)) * 39, ink, 8, true)
		draw_circle(center, 9, Color("#ee8da9"))
		for index in 4:
			var y: float = 162 + fposmod(t * 24 + index * 67.0, 230)
			var x: float = 42 if index % 2 == 0 else 289
			_round(Rect2(x, y, 29, 43), ink, 7)
			_round(Rect2(x + 4, y + 5, 21, 28), Color("#f4bad2"), 3)
		_word("MONDAY  →  FRIDAY", Vector2(71, 418), 21, ink)


	func _plant(t: float) -> void:
		var center: Vector2 = Vector2(180, 290)
		draw_line(center + Vector2(0, 45), center + Vector2(sin(t * 1.6) * 6, -107), Color("#318474"), 9, true)
		for index in 6:
			var direction: float = -1 if index % 2 == 0 else 1
			var at: Vector2 = center + Vector2(direction * (27 + sin(t * 1.6 + index) * 6), -30 - index * 15)
			_ellipse(at, Vector2(40, 17), Color("#3eab82") if index % 2 == 0 else Color("#68c895"))
		_round(Rect2(132, 312, 96, 82), Color("#ec9b72"), 11)
		_round(Rect2(123, 305, 114, 22), Color("#f6b58c"), 8)
		_round(Rect2(147, 341, 25, 17), ink, 5)
		_round(Rect2(188, 341, 25, 17), ink, 5)
		draw_line(Vector2(171, 346), Vector2(190, 346), ink, 4, true)
		_spark(Vector2(91, 212 + sin(t) * 9), 15, cream)
		_spark(Vector2(274, 284 + cos(t) * 7), 11, cream)
		_word("GROWTH: EXCEPTIONAL", Vector2(63, 432), 19, ink)


	func _merge(t: float) -> void:
		var left: PackedVector2Array = PackedVector2Array([Vector2(85, 150), Vector2(85, 250), Vector2(180, 330), Vector2(180, 420)])
		var right: PackedVector2Array = PackedVector2Array([Vector2(275, 150), Vector2(275, 250), Vector2(180, 330), Vector2(180, 420)])
		draw_polyline(left, ink, 13, true)
		draw_polyline(right, cream, 13, true)
		for index in 4:
			var phase: float = fposmod(t * 0.4 + index * 0.25, 1.0)
			for side in [-1, 1]:
				var start: Vector2 = Vector2(85 if side == -1 else 275, 155)
				var mid: Vector2 = Vector2(start.x, 250)
				var point: Vector2 = start.lerp(mid, phase * 2) if phase < 0.5 else mid.lerp(Vector2(180, 330), (phase - 0.5) * 2)
				draw_circle(point, 10, Color("#eea179") if side == -1 else Color("#f8e9a1"))
		var pulse: float = 22 + sin(t * 5) * 4
		draw_circle(Vector2(180, 330), pulse, Color("#f8d58a"))
		_word("?", Vector2(171, 339), 28, ink)
		_word("PLEASE DISCUSS", Vector2(95, 470), 21, ink)


	func _robot(t: float) -> void:
		var y: float = 233 + sin(t * 2.8) * 7
		draw_line(Vector2(180, y - 26), Vector2(180, y - 64), ink, 5, true)
		draw_circle(Vector2(180, y - 69), 9, cream)
		_round(Rect2(92, y - 23, 176, 124), ink, 22)
		_round(Rect2(107, y - 7, 146, 85), Color("#b7ecd5"), 15)
		for side in [-1, 1]:
			var x: float = 150 if side == -1 else 210
			draw_arc(Vector2(x, y + 29), 12, PI * 1.1, PI * 1.9, 18, ink, 4, true)
		draw_arc(Vector2(180, y + 38), 21, 0.1, PI - 0.1, 18, ink, 4, true)
		_round(Rect2(124, y + 108, 112, 68), cream, 15)
		_word("LGTM", Vector2(148, y + 149), 20, ink)
		for side in [-1, 1]:
			draw_line(Vector2(124 if side == -1 else 236, y + 126), Vector2(67 if side == -1 else 291, y + 104 + sin(t * 4) * 9), ink, 11, true)
		_spark(Vector2(72, y + 38), 14, cream)
		_spark(Vector2(289, y - 30), 15, cream)
