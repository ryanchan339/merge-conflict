extends SceneTree
## Exercises the same key events, physics movement, raycast and HUD callbacks as a player.

var failures: Array[String] = []
var game: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await _frames(5)
	_check(game.hud.is_modal_open() and game.stage_index == -1, "Welcome starts in a modal before the day")
	await _tap(KEY_1)
	_check(game.stage_index == 0 and game.player.enabled and not game.hud.is_modal_open(), "Numeric 1 clocks in through the HUD")
	if not game.player.enabled:
		_finish()
		return

	# Hold physical W for one second of physics; no direct movement/controller calls.
	var start: Vector3 = game.player.global_position
	_key(KEY_W, true)
	await process_frame
	_check(Input.is_physical_key_pressed(KEY_W), "Physical W event is held in the Input singleton")
	var floor_is_stable := true
	for frame in range(60):
		await physics_frame
		if absf(game.player.global_position.y) > 0.18:
			floor_is_stable = false
	_key(KEY_W, false)
	await _frames(6)
	var distance: float = Vector2(game.player.global_position.x - start.x, game.player.global_position.z - start.z).length()
	_check(distance > 2.0, "Holding W moves more than 2 metres (%.2fm)" % distance)
	_check(floor_is_stable and game.player.is_on_floor(), "Walking feet remain on the office floor")
	_check(not Input.is_physical_key_pressed(KEY_W), "Releasing W clears the held key")
	var stopped: Vector3 = game.player.global_position
	await _frames(15)
	_check(game.player.global_position.distance_to(stopped) < 0.04, "Releasing W stops movement")

	# Escape is routed through the real scene input handlers in both directions.
	var stage_before: int = game.stage_index
	await _tap(KEY_ESCAPE)
	_check(game.paused and game.hud.is_modal_open() and not game.player.enabled, "Escape opens the pause menu")
	await _tap(KEY_ESCAPE)
	_check(not game.paused and not game.hud.is_modal_open() and game.player.enabled, "Escape resumes from the pause menu")
	_check(game.stage_index == stage_before, "Pausing and resuming preserve the current task")

	# Search clear floor positions near the actual world target, then aim the camera.
	var target: Vector3 = game.office.target_position("standup")
	var found: bool = await _stand_near_target("standup", target)
	_check(found, "A clear standing position sees standup through the player's physics ray")
	if not found:
		_finish()
		return
	var before_stats: Dictionary = game.stats.duplicate(true)
	await _tap(KEY_E)
	_check(game.hud.is_modal_open() and game.current_card_id == "standup" and not game.player.enabled, "E on the ray target opens the correct standup card")
	await _tap(KEY_1)
	_check(game.hud.is_modal_open() and game.pending_advance, "Numeric 1 selects a response and shows feedback")
	_check(bool(game.flags.get("honest", false)), "The chosen response records its honest flag")
	_check(int(game.stats.delivery) == int(before_stats.delivery) + 6, "Standup delivery effect applies once")
	_check(int(game.stats.quality) == int(before_stats.quality) + 3, "Standup quality effect applies once")
	_check(int(game.stats.trust) == int(before_stats.trust) + 10, "Standup trust effect applies once")
	_check(game.evidence.size() == 1, "One input creates one decision record")
	var applied_stats: Dictionary = game.stats.duplicate(true)
	await _tap(KEY_1)
	_check(game.stats == applied_stats and game.evidence.size() == 1, "Numeric input on feedback cannot apply a choice twice")
	await _tap(KEY_ENTER)
	_check(game.stage_index == stage_before + 1 and not game.hud.is_modal_open() and game.player.enabled, "Enter dismisses feedback and advances to the next task")
	_check(game.stats == applied_stats, "Advancing does not apply effects again")
	await _tap(KEY_ENTER)
	_check(game.stage_index == stage_before + 1, "Extra Enter in the office does not skip a task")
	_finish()


func _stand_near_target(id: String, target: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.78
	for index in range(24):
		var angle: float = TAU * float(index) / 24.0
		var candidate := Vector3(target.x + sin(angle) * 2.0, 0.06, target.z + cos(angle) * 2.0)
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.transform = Transform3D(Basis.IDENTITY, candidate + Vector3(0.0, 0.9, 0.0))
		query.exclude = [game.player.get_rid()]
		if not game.get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty():
			continue
		game.player.global_position = candidate
		game.player.velocity = Vector3.ZERO
		game.player.camera.look_at(target, Vector3.UP)
		await _frames(8)
		if game.player.focused_id == id and game.player.is_on_floor():
			return true
	return false


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _tap(code: Key) -> void:
	_key(code, true)
	await process_frame
	_key(code, false)
	await process_frame


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
	await process_frame


func _check(condition: bool, description: String) -> void:
	print("PASS " if condition else "FAIL ", description)
	if not condition:
		failures.append(description)


func _finish() -> void:
	_key(KEY_W, false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("INPUT INTEGRATION TEST ", "PASS" if failures.is_empty() else "FAIL", " (", failures.size(), " failures)")
	for failure: String in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)
