extends Control

var player_position := Vector3.ZERO
var player_yaw: float = 0
var target_position := Vector3.ZERO
var target_id: String = "standup"
var target_text: String = "TEAM HUDDLE"
var font: Font

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	font = ThemeDB.fallback_font

func _draw() -> void:
	var navy := Color("172e3c")
	var muted := Color("87999e")
	var line := Color("c7d2ce")
	var teal := Color("087f81")
	draw_style_box(_box(Color("f3f2e9"), 12), Rect2(Vector2.ZERO, size))
	draw_string(font, Vector2(16, 23), "FLOOR 04  /  SMALL BATCH", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, navy)
	var map_rect := Rect2(16, 36, size.x - 32, size.y - 69)
	draw_rect(map_rect, Color("e1e7e0"), true)
	draw_rect(map_rect, line, false, 1)
	var rooms: Array[Rect2] = [Rect2(-14,-12,10,7), Rect2(4,-12,10,7), Rect2(-14,4,9,8)]
	for room in rooms:
		var start: Vector2 = _point(Vector3(room.position.x, 0, room.position.y), map_rect)
		var finish: Vector2 = _point(Vector3(room.end.x, 0, room.end.y), map_rect)
		draw_rect(Rect2(start, finish-start), Color("d1dcd3"), true)
		draw_rect(Rect2(start, finish-start), line, false, 1)
	for desk: Vector3 in [Vector3(-7,0,-1),Vector3(-7,0,3),Vector3(7,0,1),Vector3(7,0,-3)]:
		var point: Vector2 = _point(desk, map_rect)
		draw_rect(Rect2(point-Vector2(9,4), Vector2(18,8)), muted)
	if not target_id.is_empty():
		var goal: Vector2 = _point(target_position, map_rect)
		draw_circle(goal, 7, Color(teal, 0.15))
		draw_circle(goal, 3.5, teal)
	var player: Vector2 = _point(player_position, map_rect)
	draw_circle(player, 5, navy)
	var forward := Vector2(-sin(player_yaw), -cos(player_yaw))
	draw_line(player, player+forward*13, navy, 2.5, true)
	draw_string(font, Vector2(16, size.y-13), "●  " + target_text, HORIZONTAL_ALIGNMENT_LEFT, size.x - 28, 11, teal)

func _point(pos: Vector3, rect: Rect2) -> Vector2:
	return rect.position + Vector2((pos.x + 14.0) / 28.0, (pos.z + 12.0) / 24.0) * rect.size

func _box(color: Color, radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = radius
	style.corner_radius_top_right = radius
	style.corner_radius_bottom_left = radius
	style.corner_radius_bottom_right = radius
	return style
