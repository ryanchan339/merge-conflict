extends SceneTree
## Run: Godot --headless --path . --script tests/world_test.gd
## Checks real collision geometry, rather than merely checking marker data.

const OfficeScene = preload("res://scripts/office.gd")
const REQUIRED_TARGETS: Array[String] = ["desk", "mentor", "manager", "standup", "kitchen", "intern", "exit"]
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
	_check(office.interaction_positions.size() == REQUIRED_TARGETS.size(), "Exactly seven office interaction targets are registered")
	for id: String in REQUIRED_TARGETS:
		if not office.interaction_positions.has(id):
			_check(false, "Missing interaction marker: " + id)
			continue
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
