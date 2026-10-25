extends SceneTree
## Run: Godot --headless --path . --script tests/world_test.gd
## Checks real collision geometry, rather than merely checking marker data.

const OfficeScene = preload("res://scripts/office.gd")
const REQUIRED_TARGETS: Array[String] = ["desk", "mentor", "manager", "manager_seat", "hr", "standup", "kitchen", "intern", "exit", "phone", "fridge", "drawer", "cup", "coffee_machine", "printer", "vending_machine", "snack", "water_cooler", "whiteboard", "water_plant", "coffee_tablet"]
const CELL_SIZE: float = 0.5
const REACH: float = 3.6
var _failures: int = 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var office: Node3D = OfficeScene.new()
	root.add_child(office)
	# Allow the server to register all procedural static collision shapes.
	for frame: int in range(3):
		await physics_frame
	_check(office.printer_jammed, "Printer starts with a visible paper jam")
	_check(not office.snack_available and not office._snack_root.visible, "Vending pickup is initially empty")
	office.dispense_snack()
	_check(office.snack_available and office._snack_root.visible, "Vending machine dispenses a physical snack")
	await create_timer(0.75).timeout
	_check(absf(office._snack_root.position.y - 0.56) < 0.01, "Snack falls into the accessible pickup tray")
	var space: PhysicsDirectSpaceState3D = office.get_world_3d().direct_space_state
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.32
	capsule.height = 1.78
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = capsule
	var free_cells: Dictionary = {}
	for gx: int in range(-27, 28):
		for gz: int in range(-23, 24):
			var position := Vector3(float(gx) * CELL_SIZE, 0.0, float(gz) * CELL_SIZE)
			query.transform = Transform3D(Basis.IDENTITY, position + Vector3.UP * 0.94)
			if space.intersect_shape(query, 1).is_empty():
				free_cells[Vector2i(gx, gz)] = true
	var spawn_cell := Vector2i(roundi(office.spawn_position.x / CELL_SIZE), roundi(office.spawn_position.z / CELL_SIZE))
	_check(free_cells.has(spawn_cell), "Spawn accommodates the standing player capsule")
	var queue: Array[Vector2i] = [spawn_cell]
	var reachable: Dictionary = {spawn_cell: true}
	var cursor: int = 0
	while cursor < queue.size():
		var cell: Vector2i = queue[cursor]
		cursor += 1
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var neighbor: Vector2i = cell + step
			if free_cells.has(neighbor) and not reachable.has(neighbor):
				reachable[neighbor] = true
				queue.append(neighbor)
	_check(reachable.size() == free_cells.size(), "All %d sampled free cells connect to spawn (%d reachable)" % [free_cells.size(), reachable.size()])
	_check(office.interaction_positions.size() == REQUIRED_TARGETS.size(), "All %d office interaction targets are registered" % REQUIRED_TARGETS.size())
	for id: String in REQUIRED_TARGETS:
		if not office.interaction_positions.has(id):
			_check(false, "Missing interaction marker: " + id)
			continue
		_check(office.target_label(id).ends_with("."), id + " has a complete action sentence")
		var marker: Vector3 = office.target_position(id)
		var valid_points: int = 0
		for key: Variant in reachable:
			var cell: Vector2i = key as Vector2i
			var camera := Vector3(float(cell.x) * CELL_SIZE, 1.66, float(cell.y) * CELL_SIZE)
			if camera.distance_to(marker) > REACH - 0.2:
				continue
			var direction: Vector3 = (marker - camera).normalized()
			var ray := PhysicsRayQueryParameters3D.create(camera, camera + direction * REACH)
			var hit: Dictionary = space.intersect_ray(ray)
			if hit.is_empty():
				continue
			var node: Node = hit["collider"] as Node
			var collider: Node = node
			while node != null:
				if node.has_meta("interaction_id"):
					if str(node.get_meta("interaction_id")) == id:
						valid_points += 1
						_check_metadata(collider, id)
					break
				node = node.get_parent()
		_check(valid_points > 0, "%s can be aimed at from %d reachable standing positions" % [id, valid_points])
	var surface: MeshInstance3D = office.monitor_surface
	_check(is_instance_valid(surface) and surface.mesh is QuadMesh, "Interactive monitor exposes a flat UV QuadMesh")
	_check(surface.global_position.distance_to(Vector3(8.2, 1.34, 2.99)) < 0.01, "Monitor center matches the seated-camera contract")
	_check(surface.global_transform.basis.z.normalized().dot(Vector3.BACK) > 0.99, "Monitor faces the seated player (+Z)")
	_check((surface.mesh as QuadMesh).size.is_equal_approx(Vector2(1.45, 0.82)), "Monitor surface is 1.45 by 0.82 metres")
	_check(office.toggle_fridge() and office.fridge_open, "Refrigerator opens")
	_check(office.toggle_drawer() and office.drawer_open, "Desk drawer opens")
	await create_timer(0.4).timeout
	_check(office._fridge_hinge.rotation.y > deg_to_rad(100.0), "Refrigerator door completes its hinge animation")
	_check(absf(office._drawer_slide.position.z - 3.95) < 0.01, "Drawer slides into the office to reveal its contents")
	for id: String in ["fridge", "drawer", "cup", "coffee_machine"]:
		var open_hits: int = 0
		var marker: Vector3 = office.target_position(id)
		for key: Variant in reachable:
			var cell: Vector2i = key as Vector2i
			var floor_position := Vector3(float(cell.x) * CELL_SIZE, 0.0, float(cell.y) * CELL_SIZE)
			query.transform = Transform3D(Basis.IDENTITY, floor_position + Vector3.UP * 0.94)
			if not space.intersect_shape(query, 1).is_empty():
				continue
			var camera: Vector3 = floor_position + Vector3.UP * 1.66
			if camera.distance_to(marker) > REACH - 0.2:
				continue
			var ray := PhysicsRayQueryParameters3D.create(camera, camera + (marker - camera).normalized() * REACH)
			var hit: Dictionary = space.intersect_ray(ray)
			if not hit.is_empty() and str((hit["collider"] as Node).get_meta("interaction_id", "")) == id:
				open_hits += 1
		_check(open_hits > 0, "%s remains reachable with doors and drawer open (%d aiming spots)" % [id, open_hits])
	office.set_cup_state("held")
	await process_frame
	_check(not office._cup_root.visible, "Held cup is removed from the counter")
	office.set_cup_state("machine")
	_check(office._cup_root.global_position.distance_to(Vector3(-11.99, 1.2, 4.7)) < 0.01, "Cup can be placed under the coffee spout")
	office.set_coffee_brewing(true)
	_check(office._coffee_stream.visible and office._steam_root.visible, "Brewing displays coffee and steam")
	office.set_cup_state("filled")
	_check(office._cup_contents.visible, "Filled cup displays coffee")
	office.set_coffee_brewing(false)
	office.set_phone_visible(false)
	_check(not office._phone_root.visible, "Held phone disappears from the desk")
	office.set_phone_visible(true)
	_check(office._phone_root.visible, "Returned phone reappears on the desk")
	_check(not office.toggle_fridge() and not office.fridge_open, "Refrigerator closes")
	_check(not office.toggle_drawer() and not office.drawer_open, "Drawer closes")
	_check(office.people.has("hr") and office.people.has("manager"), "HR and manager retain their conversation actors")
	office.clear_printer()
	_check(not office.printer_jammed and office.target_label("printer") == "Print a page.", "Clearing the printer changes its state and action")
	await create_timer(1.15).timeout
	_check(not office._printer_jam.visible and office._printed_page.visible, "Jammed paper clears and a real printed page emerges")
	_check(absf(office._printed_page.position.z + 3.38) < 0.01, "Printed paper reaches the output tray")
	office.print_page()
	_check(office._printed_page.position.z < -3.7, "Printer can start another physical page")
	office.take_snack()
	_check(not office.snack_available and not office._snack_root.visible, "Picking up the snack empties the tray")
	office.use_water_cooler()
	_check(office._water_stream.visible and office._cooler_water.visible, "Water cooler physically pours into a cup")
	office.update_whiteboard()
	_check(office.whiteboard_updated, "Mystery ticket is marked for clarification")
	office.water_plant()
	_check(office.plant_watered and office._plant_stream.visible and office._watering_can.visible, "Plant watering displays a can and water")
	await create_timer(1.3).timeout
	_check(not office._water_stream.visible, "Water cooler stops pouring")
	_check(office._whiteboard_note.position.distance_to(Vector3(10.95, 1.62, -11.45)) < 0.01, "Mystery sticky physically moves to Needs clarification")
	_check(not office._plant_stream.visible and not office._watering_can.visible, "Plant watering finishes cleanly")
	_check(office._plant_leaves.size() > 0 and office._plant_leaves[0].material_override == office._materials["leaf_watered"], "Watered leaves respond and become greener")
	print("WORLD TEST: %s" % ("PASS" if _failures == 0 else "%d failures" % _failures))
	office.queue_free()
	await process_frame
	quit(0 if _failures == 0 else 1)


func _check_metadata(collider: Node, id: String) -> void:
	if not collider.has_meta("interaction_id") or str(collider.get_meta("interaction_id")) != id:
		_failures += 1
		push_error("Interaction collider must carry its own ID: " + id)
	if not collider.has_meta("display_name") or str(collider.get_meta("display_name")).is_empty():
		_failures += 1
		push_error("Interaction collider must carry a readable display name: " + id)


func _check(condition: bool, message: String) -> void:
	if condition:
		print("PASS: " + message)
	else:
		_failures += 1
		push_error("FAIL: " + message)
