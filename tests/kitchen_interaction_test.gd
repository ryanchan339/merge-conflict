extends SceneTree
## Real key events and physics rays exercise the complete physical coffee loop.

var failures: Array[String] = []
var game: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var scene: PackedScene = load("res://scenes/main.tscn")
	game = scene.instantiate()
	root.add_child(game)
	current_scene = game
	game.test_mode = true
	await _frames(5)
	_check(game.hud.is_modal_open(), "Welcome appears before clock-in")
	await _tap(KEY_1)
	_check(game.stage_index == 0 and game.player.enabled and not game.hud.is_modal_open(), "Numeric 1 clocks in without a blocking first-cue modal")
	if not game.player.enabled or game.hud.is_modal_open():
		_finish()
		return
	game._set_stage(7)
	game.stats.energy = 50
	game._update_hud()
	_check(game.STAGES[game.stage_index] == "kitchen" and not game.hud.is_modal_open(), "Kitchen objective allows physical interaction immediately")
	_check(game.cup_state == "none" and game.office.cup_state == "counter", "An empty cup begins on the counter")
	await _tap(KEY_F)
	_check(int(game.stats.energy) == 50 and not game.coffee_drank and not game.hud.is_modal_open(), "F without coffee has no effect")

	# Opening and closing are driven by the player's actual E handler, not prop methods.
	if not await _aim_at("fridge"):
		_finish()
		return
	await _tap(KEY_E)
	await create_timer(0.4).timeout
	_check(game.office.fridge_open and absf(game.office._fridge_hinge.rotation.y) > 1.0, "E opens the fridge and rotates its physical door")
	_check(not game.hud.is_modal_open() and game.player.enabled, "Opening the fridge keeps the office playable")
	if not await _aim_at("fridge"):
		_finish()
		return
	await _tap(KEY_E)
	await create_timer(0.4).timeout
	_check(not game.office.fridge_open and absf(game.office._fridge_hinge.rotation.y) < 0.01, "A second E closes the physical fridge door")

	var closed_drawer_position: Vector3 = game.office._drawer_slide.position
	if not await _aim_at("drawer"):
		_finish()
		return
	await _tap(KEY_E)
	await create_timer(0.35).timeout
	_check(game.office.drawer_open and game.office._drawer_slide.position.z > closed_drawer_position.z + 0.4, "E opens and physically slides the desk drawer")
	_check(game.office._drawer_cup.visible, "The open drawer reveals its spare cup")
	if not await _aim_at("drawer"):
		_finish()
		return
	await _tap(KEY_E)
	await create_timer(0.35).timeout
	_check(not game.office.drawer_open and game.office._drawer_slide.position.is_equal_approx(closed_drawer_position), "A second E closes the physical desk drawer")
	_check(not game.office._drawer_cup.visible, "Closing the drawer hides the spare cup")

	# Counter cup -> hand -> machine -> visibly filled cup -> hand.
	if not await _aim_at("cup"):
		_finish()
		return
	await _tap(KEY_E)
	_check(game.cup_state == "held" and game.office.cup_state == "held", "E takes the empty cup through the real cup target")
	_check(game.held_cup.visible and not game.held_liquid.visible, "The held empty cup has no visible coffee")
	_check(not game.office._cup_root.visible, "Picking up the cup removes its counter duplicate")
	if not await _aim_at("coffee_machine"):
		_finish()
		return
	await _tap(KEY_E)
	_check(game.cup_state == "machine" and game.coffee_brewing, "E places the held cup in the machine and starts brewing")
	_check(not game.held_cup.visible and game.office._cup_root.visible, "The cup is on the machine instead of in the player's hand")
	_check(game.office._coffee_stream.visible and not game.office._cup_contents.visible, "Brewing shows a stream before the cup is full")
	await _tap(KEY_F)
	_check(game.cup_state == "machine" and int(game.stats.energy) == 50, "F cannot drink coffee while it is brewing")
	await _tap(KEY_E)
	_check(game.cup_state == "machine" and game.coffee_brewing, "Repeated machine interaction preserves the brewing state")
	await create_timer(2.9).timeout
	await _frames(2)
	_check(game.cup_state == "filled" and not game.coffee_brewing, "The cup is ready after 2.9 seconds")
	_check(game.office.cup_state == "filled" and game.office._cup_contents.visible, "The ready world cup visibly contains coffee")
	_check(not game.office._coffee_stream.visible and not game.held_cup.visible, "The stream stops while the full cup waits for pickup")
	if not await _aim_at("cup"):
		_finish()
		return
	_check(game.player.focused_id == "cup", "The ready cup itself, rather than the machine, is under the interaction ray")
	await _tap(KEY_E)
	_check(game.cup_state == "held_full" and game.held_cup.visible and game.held_liquid.visible, "E on the ready cup picks up a full held cup")
	_check(game.office.cup_state == "held" and not game.office._cup_root.visible, "Full-cup pickup removes the world duplicate")

	await _tap(KEY_F)
	_check(int(game.stats.energy) == 62, "Drinking adds exactly 12 energy")
	_check(game.coffee_drank and game.coffee_boosted, "Drinking records consumption and the one-time bonus")
	_check(game.cup_state == "none" and not game.held_cup.visible, "Drinking clears the held cup")
	_check(game.office.cup_state == "counter" and game.office._cup_root.visible, "The empty cup returns to the counter")
	_check(game.office._cup_root.global_position.is_equal_approx(game.office.CUP_COUNTER) and not game.office._cup_contents.visible, "The restored counter cup is empty and at its original location")
	_check(game.hud.is_modal_open() and game.current_card_id == "kitchen" and not game.player.enabled, "Drinking opens the kitchen choice card")
	await _tap(KEY_F)
	_check(int(game.stats.energy) == 62 and game.current_card_id == "kitchen", "Duplicate F during the choice cannot award energy again")

	# Finish the card normally, then try again with real gameplay input enabled.
	await _tap(KEY_1)
	_check(game.pending_advance, "The kitchen response shows feedback")
	await _tap(KEY_ENTER)
	_check(not game.hud.is_modal_open() and game.player.enabled and game.stage_index == 8, "Enter returns to office controls for the next objective")
	var energy_after_choice: int = int(game.stats.energy)
	await _tap(KEY_F)
	_check(int(game.stats.energy) == energy_after_choice and game.cup_state == "none", "Duplicate F with office controls active does not award a second bonus")

	# A second legitimate coffee also cannot repeat the day's energy reward.
	if not await _aim_at("cup"):
		_finish()
		return
	await _tap(KEY_E)
	if not await _aim_at("coffee_machine"):
		_finish()
		return
	await _tap(KEY_E)
	await create_timer(2.9).timeout
	if not await _aim_at("cup"):
		_finish()
		return
	await _tap(KEY_E)
	_check(game.cup_state == "held_full", "A second physical coffee can still be brewed and picked up")
	await _tap(KEY_F)
	_check(int(game.stats.energy) == energy_after_choice, "Even a second full coffee cannot repeat the one-time +12 bonus")
	_check(game.cup_state == "none" and game.office.cup_state == "counter" and not game.hud.is_modal_open(), "The second coffee restores the cup without reopening the completed kitchen card")
	_finish()


func _aim_at(id: String) -> bool:
	var found: bool = await _stand_near_target(id, game.office.target_position(id))
	_check(found, "A clear floor position can ray-target %s" % id)
	return found


func _stand_near_target(id: String, target: Vector3) -> bool:
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.78
	for radius: float in [2.0, 1.55, 2.35]:
		for index in range(24):
			var angle: float = TAU * float(index) / 24.0
			var candidate := Vector3(target.x + sin(angle) * radius, 0.06, target.z + cos(angle) * radius)
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
	_key(KEY_E, false)
	_key(KEY_F, false)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	print("KITCHEN INTERACTION TEST ", "PASS" if failures.is_empty() else "FAIL", " (", failures.size(), " failures)")
	for failure: String in failures:
		push_error(failure)
	quit(0 if failures.is_empty() else 1)
