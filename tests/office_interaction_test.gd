extends SceneTree
## Physical office interactions, NPC conversation framing and one-time optional rewards.

var game: Node3D
var failures: Array[String] = []
var checks: int = 0
var finished: bool = false


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	create_timer(45.0).timeout.connect(_timeout)
	var scene: PackedScene = load("res://scenes/main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	await _frames(5)
	await _tap(KEY_1)
	_check(game.stage_index == 0 and game.player.enabled, "The day begins through the real welcome input")

	# Arrange only the scheduled assignment; every interaction and decision uses key input.
	game._set_stage(6)
	if not await _interact_e("manager_seat"):
		_finish()
		return
	await create_timer(0.45).timeout
	_check(game.conversation_id == "manager" and game.manager_sitting, "The physical visitor chair starts the manager 1:1")
	_check(game.player.camera.global_position.distance_to(game.office.manager_seat_eye) < 0.025, "The 1:1 camera sits at the visitor-chair eye position")
	_check(not game.player.enabled and game.player.camera_locked, "The seated conversation disables walking and free look")
	_assert_conversation_framing("manager")
	var stationary: Vector3 = game.player.global_position
	_key(KEY_W, true)
	await _frames(12)
	_key(KEY_W, false)
	_check(game.player.global_position.distance_to(stationary) < 0.03, "Holding a movement key cannot walk away during the seated 1:1")
	var before_manager: Dictionary = game.stats.duplicate(true)
	var before_evidence: int = game.evidence.size()
	await _tap(KEY_1)
	_check(bool(game.flags.get("disclosed", false)), "The manager decision records honest disclosure")
	var disclosure_stats: Dictionary = game.stats.duplicate(true)
	await _tap(KEY_1)
	_check(game.stats == disclosure_stats, "Repeated numeric input during feedback cannot apply the manager choice twice")
	await _tap(KEY_ENTER)
	_check(game.current_card_id == "manager_scope" and game.conversation_id == "manager", "The scope follow-up retains the manager conversation")
	_check(game.hud._modal.position.x >= game.hud._root.size.x * 0.49, "The scope follow-up stays on the right of the manager")
	await _tap(KEY_1)
	_check(bool(game.flags.get("essential_scope", false)), "The scope decision records the essential feature")
	await _tap(KEY_ENTER)
	_check(game.stage_index == 7 and game.conversation_id.is_empty(), "Finishing both 1:1 decisions advances to the kitchen task")
	_check(game.player.enabled and not game.player.camera_locked and not game.manager_sitting, "Finishing the 1:1 restores the walking controller")
	_check(game.player.global_position.distance_to(game.office.manager_stand_position) < 0.1, "The player stands at the manager's clear exit position")
	_check(game.stats.delivery == before_manager.delivery + 16 and game.stats.quality == before_manager.quality + 11 and game.stats.trust == before_manager.trust + 18, "The two manager decisions apply their intended effects exactly once")
	_check(game.evidence.size() == before_evidence + 2, "The completed 1:1 records exactly two decisions")
	var stood: Vector3 = game.player.global_position
	_key(KEY_D, true)
	await _frames(12)
	_key(KEY_D, false)
	await _frames(5)
	_check(game.player.global_position.distance_to(stood) > 0.3, "The restored player can move away from the visitor chair")

	# People Operations is optional and must not advance the workday assignment.
	var hr_stage: int = game.stage_index
	var hr_minutes: int = game.phone_minutes
	var hr_stats: Dictionary = game.stats.duplicate(true)
	var hr_evidence: int = game.evidence.size()
	if not await _interact_e("hr"):
		_finish()
		return
	await create_timer(0.45).timeout
	_check(game.current_card_id == "hr_complaint" and game.ambient, "Talking to Alex opens the optional HR topic menu")
	_assert_conversation_framing("hr")
	var person: Node3D = game.office.people["hr"]
	var to_viewer: Vector3 = game.player.camera.global_position - person.global_position
	to_viewer.y = 0
	_check(person.global_basis.z.normalized().dot(to_viewer.normalized()) > 0.98, "Alex turns to face the person speaking")
	await _tap(KEY_3)
	_check(game.stats == hr_stats and game.phone_minutes == hr_minutes, "Choosing an HR topic does not apply resolution rewards early")
	await _tap(KEY_ENTER)
	_check(game.current_card_id == "hr_crunch" and game.ambient and game.stage_index == hr_stage, "The unsafe-hours topic opens its optional resolution card")
	await _tap(KEY_1)
	_check(bool(game.flags.get("hr_resolved", false)) and bool(game.flags.get("hr_boundary", false)), "The HR resolution records the report and a safer boundary")
	_check(game.phone_minutes == hr_minutes + 10, "Documenting unsafe hours spends ten in-game minutes")
	_check(game.stats.delivery == hr_stats.delivery - 5 and game.stats.trust == hr_stats.trust + 8 and game.stats.energy == hr_stats.energy + 8, "The HR resolution applies its delivery, trust and recovery tradeoff")
	var resolved_stats: Dictionary = game.stats.duplicate(true)
	await _tap(KEY_1)
	_check(game.stats == resolved_stats and game.phone_minutes == hr_minutes + 10, "Repeated feedback input cannot repeat the HR effects or time cost")
	await _tap(KEY_ENTER)
	_check(game.stage_index == hr_stage and game.player.enabled and game.conversation_id.is_empty(), "Finishing optional HR returns to the same workday assignment")
	_check(game.evidence.size() == hr_evidence + 2, "HR records one topic and one resolution as evaluation evidence")
	var parts: PackedStringArray = str(game.TIMES[hr_stage]).split(":")
	var elapsed: int = int(parts[0]) * 60 + int(parts[1]) + game.phone_minutes
	var expected_clock: String = "%02d:%02d" % [floori(elapsed / 60.0), elapsed % 60]
	_check(game.hud._clock.text == expected_clock, "The visible clock includes the HR conversation's time cost")

	var resolved_evidence: int = game.evidence.size()
	if not await _interact_e("hr"):
		_finish()
		return
	_check(game.current_card_id == "custom" and game.current_card.title == "Your report is on file.", "A repeat HR visit uses the existing-report guard")
	await _tap(KEY_1)
	_check(game.stats == resolved_stats and game.phone_minutes == hr_minutes + 10 and game.evidence.size() == resolved_evidence, "A repeated report cannot farm rewards, minutes or decision evidence")
	_check(game.stage_index == hr_stage and game.player.enabled, "The repeated HR visit also preserves the active assignment")

	await _office_rewards()
	_finish()


func _office_rewards() -> void:
	for id: String in ["water_cooler", "vending_machine", "snack", "printer"]:
		if not game.office.interaction_positions.has(id):
			_check(false, "Office object exposes its physical interaction target: " + id)
			return
	var energy_before: int = game.stats.energy
	var minutes_before: int = game.phone_minutes
	if not await _interact_e("water_cooler"):
		return
	_check(game.stats.energy == mini(100, energy_before + 4) and game.phone_minutes == minutes_before + 1, "Drinking water gives its one-time recovery and time cost")
	await _tap(KEY_E)
	_check(game.stats.energy == mini(100, energy_before + 4) and game.phone_minutes == minutes_before + 1, "Repeated water interactions do not farm recovery or time")
	if not await _interact_e("vending_machine"):
		return
	await create_timer(0.8).timeout
	_check(game.office.snack_available, "The vending machine physically dispenses a snack")
	var snack_energy: int = game.stats.energy
	var snack_minutes: int = game.phone_minutes
	if not await _interact_e("snack"):
		return
	_check(not game.office.snack_available and game.stats.energy == mini(100, snack_energy + 6) and game.phone_minutes == snack_minutes + 2, "Taking the dispensed snack consumes it and applies its one-time recovery")
	if not await _interact_e("vending_machine"):
		return
	await create_timer(0.8).timeout
	if not await _interact_e("snack"):
		return
	_check(game.stats.energy == mini(100, snack_energy + 6) and game.phone_minutes == snack_minutes + 2, "A second dispensed snack cannot farm meter rewards")
	var quality_before: int = game.stats.quality
	var printer_minutes: int = game.phone_minutes
	if not await _interact_e("printer"):
		return
	_check(not game.office.printer_jammed and game.stats.quality == quality_before + 3 and game.phone_minutes == printer_minutes + 3, "Clearing the printer jam applies its one-time quality reward")
	await _tap(KEY_E)
	_check(game.stats.quality == quality_before + 3 and game.phone_minutes == printer_minutes + 3, "Printing again cannot repeat the jam-clearing reward")


func _assert_conversation_framing(id: String) -> void:
	var size: Vector2 = game.hud._root.size
	var face: Vector3 = game.office.conversation_position(id)
	var projected: Vector2 = game.player.camera.unproject_position(face)
	_check(not game.player.camera.is_position_behind(face) and projected.x > 40 and projected.x < size.x * 0.49 and projected.y > 30 and projected.y < size.y - 30, "%s remains visible on the left side of the conversation" % id)
	var ray := PhysicsRayQueryParameters3D.create(game.player.camera.global_position, face)
	ray.exclude = [game.player.get_rid()]
	var hit: Dictionary = game.get_world_3d().direct_space_state.intersect_ray(ray)
	_check(hit.is_empty() or _interaction_id(hit["collider"] as Node) == id, "No solid object obstructs the view of %s's face" % id)
	_check(game.hud._modal.position.x >= size.x * 0.49 and game.hud._dim.color.a < 0.15, "%s dialogue stays on the right with a light dimmer" % id)
	_check(game.hud._stats_panel.is_visible_in_tree(), "The four meter values remain visible during the %s conversation" % id)


func _interact_e(id: String) -> bool:
	var visible: bool = await _stand_near(id, game.office.target_position(id))
	_check(visible, "A clear standing position reaches the physical %s target" % id)
	if not visible:
		return false
	await _tap(KEY_E)
	return true


func _stand_near(id: String, target: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.78
	var space: PhysicsDirectSpaceState3D = game.get_world_3d().direct_space_state
	for radius: float in [2.0, 1.5, 2.6]:
		for index in range(32):
			var angle: float = TAU * float(index) / 32.0
			var position := Vector3(target.x + sin(angle) * radius, 0.06, target.z + cos(angle) * radius)
			var query := PhysicsShapeQueryParameters3D.new()
			query.shape = capsule
			query.transform = Transform3D(Basis.IDENTITY, position + Vector3(0, 0.9, 0))
			query.exclude = [game.player.get_rid()]
			if not space.intersect_shape(query, 1).is_empty():
				continue
			var eye: Vector3 = position + Vector3.UP * 1.66
			var ray := PhysicsRayQueryParameters3D.create(eye, eye + (target - eye).normalized() * 3.6)
			ray.exclude = [game.player.get_rid()]
			var hit: Dictionary = space.intersect_ray(ray)
			if hit.is_empty() or _interaction_id(hit["collider"] as Node) != id:
				continue
			game.player.global_position = position
			game.player.velocity = Vector3.ZERO
			game.player.camera.look_at(target, Vector3.UP)
			await _frames(8)
			if game.player.focused_id == id and game.player.is_on_floor():
				return true
	return false


func _interaction_id(node: Node) -> String:
	while node != null:
		if node.has_meta("interaction_id"):
			return str(node.get_meta("interaction_id"))
		node = node.get_parent()
	return ""


func _tap(code: Key) -> void:
	_key(code, true)
	await process_frame
	_key(code, false)
	await process_frame


func _key(code: Key, pressed: bool) -> void:
	var event := InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)


func _frames(count: int) -> void:
	for frame in range(count):
		await physics_frame
	await process_frame


func _check(condition: bool, description: String) -> void:
	checks += 1
	print("PASS " if condition else "FAIL ", description)
	if not condition:
		failures.append(description)


func _timeout() -> void:
	if not finished:
		_check(false, "Office interaction test completed before its timeout")
		_finish()


func _finish() -> void:
	if finished:
		return
	finished = true
	_key(KEY_W, false)
	_key(KEY_D, false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("OFFICE INTERACTION TEST ", "PASS" if failures.is_empty() else "FAIL", " (", checks, " checks; ", failures.size(), " failures)")
	for failure: String in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)
