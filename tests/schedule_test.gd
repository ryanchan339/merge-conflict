extends SceneTree
## Authored schedules preserve a reachable conversation target while the office tablet reflects deployments.
const Office = preload("res://scripts/office.gd")
var failures: int = 0
func _initialize() -> void:
	run.call_deferred()
func check(ok: bool, label: String) -> void:
	print(("PASS " if ok else "FAIL ") + label)
	if not ok:
		failures += 1
func run() -> void:
	var office = Office.new()
	root.add_child(office)
	for frame: int in 4:
		await physics_frame
	check(office.interaction_positions.has("coffee_tablet"), "The office registers a physical coffee tablet")
	office.set_tablet_state(1, 2, "Production · r104")
	check(office._tablet_label.text.contains("Favorites: 1") and office._tablet_label.text.contains("Orders: 2"), "Live counters appear on the tablet screen")
	var tablet_hits: int = 0
	var space: PhysicsDirectSpaceState3D = office.get_world_3d().direct_space_state
	for z: float in [4.9, 5.5, 5.9, 6.4]:
		var origin := Vector3(-10.8, 1.66, z)
		var target: Vector3 = office.target_position("coffee_tablet")
		var hit: Dictionary = space.intersect_ray(PhysicsRayQueryParameters3D.create(origin, origin + (target - origin).normalized() * 3.6))
		if not hit.is_empty() and str(hit["collider"].get_meta("interaction_id", "")) == "coffee_tablet":
			tablet_hits += 1
	check(tablet_hits > 0, "The tablet can be ray-targeted from the kitchenette floor")
	var home: Vector3 = office.target_position("mentor")
	office.set_work_clock(2)
	await create_timer(2.1).timeout
	var coffee: Vector3 = office.target_position("mentor")
	check(coffee.distance_to(home) > 6.0 and coffee.distance_to(Vector3(-7.3, 1.5, 7.6)) < 0.05, "Maya physically moves to the kitchenette at feature time")
	check(coffee.distance_to(office.people["mentor"].global_position + Vector3.UP * 1.5) < 0.02, "Maya's interaction marker follows her visual actor")
	office.set_work_clock(3)
	await create_timer(2.1).timeout
	check(office.target_position("mentor").distance_to(coffee) < 0.05 and office.person_available("mentor"), "Maya remains accessible for review clarification")
	check(office.target_position("intern").distance_to(Vector3(11.2, 1.5, -6.1)) < 0.05 and not office.person_available("intern"), "Sam rehearses in the standup corner and is marked busy")
	check(office.schedule_status().size() == 3, "The calendar exposes all three named coworker schedules")
	office.face_person("mentor", Vector3(-6.5, 1.66, 7.8))
	check(not office._schedule_tweens.has("mentor"), "A conversation stops a scheduled movement")
	office.set_work_clock(5)
	await create_timer(2.1).timeout
	check(office.target_position("mentor").distance_to(home) < 0.05, "Maya returns to her desk")
	check(office.person_available("intern") and office.target_position("intern").distance_to(Vector3(10.15, 1.5, -1.1)) < 0.05, "Sam returns to his desk for the help request")
	office.set_work_clock(6)
	check(office.person_available("manager") and office.people["manager"].global_position.distance_to(Vector3(-10.7, 0, -10.4)) < 0.01, "Jordan stays in the office and is available for the seated 1:1")
	print("SCHEDULE TEST: %s" % ("PASS" if failures == 0 else "FAIL"))
	quit(0 if failures == 0 else 1)
