extends Node3D
## A fully procedural, walkable office. All dimensions are in metres.

var spawn_position := Vector3(0.0, 0.0, 9.0)
var interaction_positions: Dictionary = {}
var interaction_labels: Dictionary = {}
var _materials: Dictionary = {}


func _ready() -> void:
	_make_materials()
	_build_lighting()
	_build_shell()
	_build_manager_office()
	_build_standup_space()
	_build_kitchen()
	_build_workstations()
	_build_lobby()
	_build_details()


func target_position(id: String) -> Vector3:
	return interaction_positions.get(id, spawn_position + Vector3.UP * 1.5) as Vector3


func target_label(id: String) -> String:
	return str(interaction_labels.get(id, id.capitalize()))


func _make_materials() -> void:
	_material("wall", Color("eee9df"))
	_material("floor", Color("d1d5cb"))
	_material("ceiling", Color("f4eee2"))
	_material("navy", Color("203744"))
	_material("dark", Color("152932"))
	_material("teal", Color("247c7b"))
	_material("light_teal", Color("93bbb0"))
	_material("coral", Color("e98f74"))
	_material("gold", Color("e7ba65"))
	_material("wood", Color("c69b70"))
	_material("wood_light", Color("dfbf93"))
	_material("white", Color("fff8e9"))
	_material("black", Color("253137"))
	_material("metal", Color("748786"), 0.52)
	_material("rug", Color("577f7b"))
	_material("rug_pale", Color("a9b7a7"))
	_material("green", Color("4d7956"))
	_material("leaf_light", Color("799b66"))
	_material("skin", Color("d8a17c"))
	_material("skin_dark", Color("9f6a4d"))
	_material("hair", Color("382e32"))
	_material("hair_light", Color("b27e4f"))
	_material("screen", Color("183b46"))
	_material("screen_line", Color("87d4bc"))
	_material("screen_coral", Color("f4b98f"))
	_material("glass", Color(0.63, 0.82, 0.80, 0.18), 0.12)
	_material("sky", Color("b8d6d6"))
	_material("city", Color("94b8bc"))
	_material("city_dark", Color("7da2a8"))
	_material("light", Color("fff2d0"))
	var luminous: StandardMaterial3D = _materials["light"]
	luminous.emission_enabled = true
	luminous.emission = Color("fff2d0")
	luminous.emission_energy_multiplier = 1.5
	var screen_line: StandardMaterial3D = _materials["screen_line"]
	screen_line.emission_enabled = true
	screen_line.emission = Color("87d4bc")
	screen_line.emission_energy_multiplier = 0.22


func _material(key: String, color: Color, roughness: float = 0.86) -> void:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = roughness
	if color.a < 1.0:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.cull_mode = BaseMaterial3D.CULL_DISABLED
	_materials[key] = material


func _build_lighting() -> void:
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color("b8d6d6")
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color("e9f0e5")
	environment.ambient_light_energy = 0.72
	environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var world := WorldEnvironment.new()
	world.name = "Office atmosphere"
	world.environment = environment
	add_child(world)
	var sun := DirectionalLight3D.new()
	sun.name = "Afternoon daylight"
	sun.rotation_degrees = Vector3(-38.0, -32.0, 0.0)
	sun.light_color = Color("fff3d9")
	sun.light_energy = 1.15
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 45.0
	add_child(sun)
	for pos: Vector3 in [Vector3(-8.0, 3.6, 5.0), Vector3(7.0, 3.7, 3.0), Vector3(-8.0, 3.5, -8.0), Vector3(8.0, 3.7, -8.0)]:
		var light := OmniLight3D.new()
		light.position = pos
		light.light_color = Color("fff0cd")
		light.light_energy = 0.65
		light.omni_range = 10.0
		light.omni_attenuation = 1.8
		light.shadow_enabled = false
		add_child(light)


func _build_shell() -> void:
	_box(self, "Floor", Vector3(0.0, -0.16, 0.0), Vector3(28.0, 0.32, 24.0), "floor", true)
	_box(self, "Ceiling", Vector3(0.0, 4.42, 0.0), Vector3(28.0, 0.2, 24.0), "ceiling")
	_box(self, "North wall", Vector3(0.0, 2.15, -12.0), Vector3(28.0, 4.3, 0.24), "wall", true)
	_box(self, "South wall", Vector3(0.0, 2.15, 12.0), Vector3(28.0, 4.3, 0.24), "wall", true)
	for x: float in [-14.0, 14.0]:
		_box(self, "Window sill wall", Vector3(x, 0.4, 0.0), Vector3(0.22, 0.8, 24.0), "wall", true)
		_box(self, "Window wall collision", Vector3(x, 2.6, 0.0), Vector3(0.14, 3.6, 24.0), "glass", true)
		_box(self, "Upper window lintel", Vector3(x, 4.08, 0.0), Vector3(0.3, 0.52, 24.0), "wall")
		for z: float in [-11.6, -8.2, -4.8, -1.4, 2.0, 5.4, 8.8, 11.6]:
			_box(self, "Window mullion", Vector3(x, 2.4, z), Vector3(0.24, 3.2, 0.065), "navy")
		_box(self, "Window cross rail", Vector3(x, 2.7, 0.0), Vector3(0.24, 0.055, 24.0), "navy")
		_box(self, "Window sill", Vector3(x * 0.991, 0.84, 0.0), Vector3(0.38, 0.09, 24.0), "wood_light")
		_box(self, "Distant sky", Vector3(x * 1.34, 3.3, 0.0), Vector3(0.12, 11.0, 42.0), "sky")
		for i: int in range(9):
			var height: float = 1.8 + float((i * 7) % 5) * 0.55
			_box(self, "Distant city", Vector3(x * 1.21, height * 0.5 - 0.8, -14.0 + float(i) * 3.8), Vector3(1.2, height, 2.7), "city_dark" if i % 2 == 0 else "city")
	for z: float in [-11.8, 11.8]:
		_box(self, "Wall skirting", Vector3(0.0, 0.065, z), Vector3(27.6, 0.13, 0.05), "navy")
	# Thin carpet strips give the central walking route a gentle visual rhythm.
	_box(self, "Central circulation rug", Vector3(2.8, 0.008, 1.5), Vector3(2.4, 0.016, 16.4), "rug_pale")
	for z: float in [-5.8, -1.8, 2.2, 6.2]:
		_box(self, "Rug stitch", Vector3(2.8, 0.019, z), Vector3(1.9, 0.006, 0.025), "light_teal")
	# Ceiling beams and economical emissive pendant strips.
	for z: float in [-8.6, -2.0, 4.0, 9.3]:
		_box(self, "Ceiling beam", Vector3(0.0, 4.23, z), Vector3(27.7, 0.18, 0.18), "white")
	for pos: Vector3 in [Vector3(-7.5, 3.8, -8.2), Vector3(8.0, 3.8, -8.0), Vector3(-1.8, 3.8, -1.5), Vector3(8.1, 3.8, 2.6), Vector3(-8.8, 3.8, 5.0)]:
		_pendant(pos)


func _build_manager_office() -> void:
	var room := _group(self, "Manager office", Vector3.ZERO)
	_box(room, "Manager accent wall", Vector3(-9.35, 2.0, -11.82), Vector3(8.9, 4.0, 0.08), "teal")
	_box(room, "Manager rug", Vector3(-9.4, 0.015, -8.7), Vector3(7.7, 0.03, 5.0), "rug")
	# Front glazing has a 2.2 m entrance at its right-hand end.
	_glass_partition(room, Vector3(-10.6, 0.0, -5.5), 6.5, 0.0)
	_glass_partition(room, Vector3(-4.85, 0.0, -8.72), 6.45, 90.0)
	_box(room, "Door jamb left", Vector3(-7.28, 1.65, -5.5), Vector3(0.11, 3.3, 0.12), "navy", true)
	_box(room, "Door jamb right", Vector3(-4.85, 1.65, -5.5), Vector3(0.11, 3.3, 0.12), "navy", true)
	_box(room, "Door header", Vector3(-6.07, 3.25, -5.5), Vector3(2.45, 0.13, 0.15), "navy")
	_sign(room, "MANAGER", Vector3(-10.5, 2.85, -5.37), 0.0, 0.006, Color("203744"))
	_sign(room, "OPEN DOOR. FULL CALENDAR.", Vector3(-10.5, 2.53, -5.36), 0.0, 0.0024, Color("203744"))
	_desk(room, "Manager desk", Vector3(-9.8, 0.0, -9.25), 0.0, false)
	_chair(room, Vector3(-9.8, 0.0, -10.42), 180.0, "coral")
	var manager := _target(room, "manager", "Jordan · engineering manager", Vector3(-9.8, 0.0, -10.4), Vector3(-9.8, 1.48, -10.4))
	_person(manager, Vector3.ZERO, "teal", "skin_dark", "hair", 0.0, true)
	_sign(room, "JORDAN", Vector3(-9.8, 1.03, -8.78), 0.0, 0.0021, Color("fff8e9"))
	_box(room, "Desk nameplate", Vector3(-9.8, 0.99, -8.82), Vector3(0.65, 0.17, 0.055), "navy")
	_chair(room, Vector3(-10.8, 0.0, -7.55), 0.0, "light_teal")
	_chair(room, Vector3(-8.6, 0.0, -7.55), 0.0, "light_teal")
	_planter(room, Vector3(-13.0, 0.0, -6.4), 1.2)
	_shelf(room, Vector3(-13.3, 0.0, -9.8), 90.0)
	_sign(room, "SHIP SMALL.\nDREAM IN QUARTERS.", Vector3(-9.1, 2.65, -11.69), 0.0, 0.0055, Color("fff8e9"))
	_box(room, "Award shelf", Vector3(-6.15, 1.6, -11.52), Vector3(1.7, 0.08, 0.55), "wood")
	_cylinder(room, "Definitely earned trophy", Vector3(-6.15, 1.86, -11.5), 0.13, 0.45, "gold")
	_sphere(room, "Trophy orb", Vector3(-6.15, 2.12, -11.5), Vector3(0.32, 0.32, 0.32), "gold")


func _build_standup_space() -> void:
	var room := _group(self, "Standup corner", Vector3.ZERO)
	_box(room, "Standup carpet", Vector3(8.7, 0.018, -8.0), Vector3(8.8, 0.035, 6.4), "rug_pale")
	_box(room, "Board surround", Vector3(9.0, 2.05, -11.7), Vector3(6.2, 2.6, 0.13), "wood")
	_box(room, "Whiteboard", Vector3(9.0, 2.05, -11.59), Vector3(5.95, 2.36, 0.055), "white")
	_sign(room, "DAILY STANDUP", Vector3(9.0, 2.92, -11.53), 0.0, 0.0042, Color("203744"))
	_sign(room, "YESTERDAY        TODAY          BLOCKED", Vector3(9.0, 2.41, -11.52), 0.0, 0.00255, Color("247c7b"))
	for x: float in [8.0, 10.05]:
		_box(room, "Board column", Vector3(x, 1.85, -11.53), Vector3(0.025, 1.45, 0.015), "light_teal")
	for i: int in range(7):
		var x: float = 6.9 + float(i % 3) * 2.0 + float(i % 2) * 0.12
		var y: float = 2.05 - float(i / 3) * 0.39
		_box(room, "Sticky note", Vector3(x, y, -11.49), Vector3(0.55, 0.29, 0.012), "gold" if i % 2 == 0 else "coral")
	_sign(room, "IT'S A STANDUP, NOT A TED TALK.", Vector3(8.8, 0.88, -11.5), 0.0, 0.00215, Color("203744"))
	_round_table(room, Vector3(9.0, 0.0, -7.65), 0.82, 0.98, "wood_light")
	_mug(room, Vector3(8.6, 1.07, -7.6), "coral")
	_box(room, "Meeting notebook", Vector3(9.25, 1.015, -7.65), Vector3(0.3, 0.025, 0.4), "navy")
	var huddle := _target(room, "standup", "Standup · team huddle", Vector3(7.05, 0.0, -7.9), Vector3(7.05, 1.5, -7.9))
	_person(huddle, Vector3.ZERO, "coral", "skin", "hair_light", 0.0, false)
	var colleague := _group(room, "Huddle engineer", Vector3(10.85, 0.0, -8.5))
	_person(colleague, Vector3.ZERO, "navy", "skin_dark", "hair", -40.0, false)
	_planter(room, Vector3(12.7, 0.0, -10.5), 1.3)
	_box(room, "Acoustic divider", Vector3(4.0, 0.65, -9.0), Vector3(0.2, 1.3, 5.7), "teal", true)
	for i: int in range(8):
		_box(room, "Acoustic timber slat", Vector3(4.01, 1.95, -11.4 + float(i) * 0.63), Vector3(0.11, 1.4, 0.09), "wood")


func _build_kitchen() -> void:
	var kitchen := _target(self, "kitchen", "Kitchenette · coffee station", Vector3.ZERO, Vector3(-11.55, 1.3, 4.7))
	_box(kitchen, "Kitchen floor", Vector3(-10.25, 0.012, 6.5), Vector3(7.0, 0.025, 8.6), "white")
	for z: float in [3.0, 5.0, 7.0, 9.0, 10.0]:
		_box(kitchen, "Tile grout", Vector3(-10.25, 0.027, z), Vector3(6.9, 0.005, 0.025), "floor")
	for x: float in [-13.0, -11.0, -9.0, -7.0]:
		_box(kitchen, "Tile grout", Vector3(x, 0.027, 6.5), Vector3(0.025, 0.005, 8.5), "floor")
	_box(kitchen, "Kitchen cabinets", Vector3(-12.9, 0.47, 5.2), Vector3(1.5, 0.94, 5.5), "teal", true)
	_box(kitchen, "Countertop", Vector3(-12.85, 0.98, 5.2), Vector3(1.65, 0.13, 5.7), "wood_light", true)
	for z: float in [2.95, 4.1, 5.25, 6.4, 7.45]:
		_box(kitchen, "Cabinet division", Vector3(-12.135, 0.48, z), Vector3(0.012, 0.83, 0.022), "light_teal")
		_box(kitchen, "Cabinet pull", Vector3(-12.1, 0.72, z + 0.2), Vector3(0.055, 0.055, 0.26), "gold")
	_box(kitchen, "Coffee machine", Vector3(-12.55, 1.35, 4.7), Vector3(0.74, 0.65, 0.62), "navy", true)
	_box(kitchen, "Coffee machine face", Vector3(-12.155, 1.39, 4.7), Vector3(0.035, 0.44, 0.48), "black")
	_box(kitchen, "Coffee machine status", Vector3(-12.13, 1.53, 4.7), Vector3(0.025, 0.1, 0.22), "screen_line")
	_box(kitchen, "Coffee drip tray", Vector3(-11.99, 1.08, 4.7), Vector3(0.31, 0.055, 0.5), "metal")
	_mug(kitchen, Vector3(-11.98, 1.2, 4.7), "coral")
	_box(kitchen, "Sink edge", Vector3(-12.72, 1.06, 6.7), Vector3(1.0, 0.035, 1.0), "metal")
	_box(kitchen, "Sink basin", Vector3(-12.72, 1.082, 6.7), Vector3(0.78, 0.014, 0.78), "navy")
	_cylinder(kitchen, "Tap upright", Vector3(-13.0, 1.24, 6.7), 0.035, 0.38, "metal")
	_box(kitchen, "Tap spout", Vector3(-12.85, 1.42, 6.7), Vector3(0.32, 0.055, 0.055), "metal")
	_box(kitchen, "Fridge", Vector3(-12.9, 1.05, 9.3), Vector3(1.4, 2.1, 1.25), "white", true)
	_box(kitchen, "Fridge split", Vector3(-12.185, 1.4, 9.3), Vector3(0.015, 0.028, 1.22), "metal")
	_box(kitchen, "Fridge handle", Vector3(-12.12, 1.1, 8.83), Vector3(0.08, 0.54, 0.07), "navy")
	_box(kitchen, "Fridge note", Vector3(-12.17, 1.78, 9.35), Vector3(0.017, 0.31, 0.4), "coral")
	# The coffee interaction has a generous approachable front face.
	_interaction_box(kitchen, Vector3(-12.05, 1.35, 4.7), Vector3(0.3, 0.75, 0.85))
	_round_table(kitchen, Vector3(-8.9, 0.0, 5.4), 0.88, 0.98, "wood_light")
	_stool(kitchen, Vector3(-8.9, 0.0, 6.8))
	_stool(kitchen, Vector3(-8.9, 0.0, 4.0))
	_stool(kitchen, Vector3(-7.5, 0.0, 5.4))
	_mug(kitchen, Vector3(-8.9, 1.07, 5.4), "teal")
	_sofa(kitchen, Vector3(-8.5, 0.0, 9.8), 0.0)
	_planter(kitchen, Vector3(-6.45, 0.0, 9.6), 1.1)
	_sign(kitchen, "THE RECHARGE STATION", Vector3(-9.5, 2.8, 11.83), 180.0, 0.0052, Color("247c7b"))
	_sign(kitchen, "COFFEE COUNTS AS A DEPENDENCY.", Vector3(-9.5, 2.36, 11.82), 180.0, 0.0027, Color("203744"))
	var hanging := _group(kitchen, "Kitchen hanging sign", Vector3(-10.0, 3.15, 2.25))
	_box(hanging, "Sign panel", Vector3.ZERO, Vector3(4.0, 0.55, 0.1), "teal")
	_sign(hanging, "KITCHENETTE", Vector3(0.0, 0.0, 0.065), 0.0, 0.0048, Color("fff8e9"))
	_sign(hanging, "KITCHENETTE", Vector3(0.0, 0.0, -0.065), 180.0, 0.0048, Color("fff8e9"))


func _build_workstations() -> void:
	# A compact left-hand engineering pod with wide passages on every side.
	_box(self, "Engineering pod carpet", Vector3(-1.6, 0.012, -0.5), Vector3(7.0, 0.025, 6.8), "rug_pale")
	_desk(self, "Maya desk", Vector3(-3.4, 0.0, 0.2), 180.0, false)
	_chair(self, Vector3(-3.4, 0.0, 1.35), 0.0, "teal")
	_desk(self, "Engineering desk A", Vector3(0.1, 0.0, 0.2), 180.0, false)
	_chair(self, Vector3(0.1, 0.0, 1.35), 0.0, "navy")
	_desk(self, "Engineering desk B", Vector3(-3.4, 0.0, -2.5), 0.0, false)
	_chair(self, Vector3(-3.4, 0.0, -3.65), 180.0, "navy")
	_desk(self, "Engineering desk C", Vector3(0.1, 0.0, -2.5), 0.0, false)
	_chair(self, Vector3(0.1, 0.0, -3.65), 180.0, "coral")
	_box(self, "Pod divider", Vector3(-1.65, 1.13, -1.15), Vector3(6.4, 0.68, 0.09), "teal")
	for x: float in [-3.4, 0.1]:
		_box(self, "Divider sticky", Vector3(x, 1.21, -1.09), Vector3(0.24, 0.23, 0.014), "gold")
	var mentor := _target(self, "mentor", "Maya · senior engineer", Vector3(-5.4, 0.0, -0.15), Vector3(-5.4, 1.5, -0.15))
	_person(mentor, Vector3.ZERO, "teal", "skin_dark", "hair", 0.0, false)
	_sign(self, "MAYA", Vector3(-3.4, 0.92, 0.77), 0.0, 0.0020, Color("fff8e9"))
	_box(self, "Maya desk sign", Vector3(-3.4, 0.9, 0.74), Vector3(0.62, 0.16, 0.04), "navy")
	var background_worker := _group(self, "Focused teammate", Vector3(0.1, 0.0, -3.65))
	_person(background_worker, Vector3.ZERO, "coral", "skin", "hair_light", 0.0, true)
	# The player's monitor faces the main entrance and is easy to find in a page.
	var desk := _target(self, "desk", "Your desk · workstation", Vector3(8.2, 0.0, 3.25), Vector3(8.2, 1.2, 3.05))
	_desk(desk, "Your desk", Vector3.ZERO, 180.0, true)
	_chair(self, Vector3(8.2, 0.0, 4.55), 0.0, "coral")
	_box(self, "Intern zone rug", Vector3(8.2, 0.008, 3.5), Vector3(5.5, 0.015, 4.5), "rug")
	_box(desk, "INTERN nameplate", Vector3(0.0, 0.93, 0.57), Vector3(1.05, 0.22, 0.055), "coral")
	_sign(desk, "YOU / INTERN", Vector3(0.0, 0.94, 0.605), 0.0, 0.0025, Color("203744"))
	_interaction_box(desk, Vector3(0.0, 1.05, -0.1), Vector3(1.75, 0.8, 0.8))
	_planter(self, Vector3(11.4, 0.0, 4.6), 1.25)
	_desk(self, "Sam desk", Vector3(8.2, 0.0, -1.45), 0.0, false)
	_chair(self, Vector3(8.2, 0.0, -2.7), 180.0, "light_teal")
	var intern := _target(self, "intern", "Sam · fellow intern", Vector3(10.15, 0.0, -1.1), Vector3(10.15, 1.48, -1.1))
	_person(intern, Vector3.ZERO, "coral", "skin", "hair_light", -20.0, false)
	_sign(self, "SAM", Vector3(8.2, 0.93, -0.85), 0.0, 0.0021, Color("fff8e9"))
	_box(self, "Sam desk sign", Vector3(8.2, 0.9, -0.88), Vector3(0.62, 0.16, 0.04), "navy")
	_mug(self, Vector3(9.2, 0.89, -1.3), "gold")
	# Perimeter furniture never blocks the loop around the workstations.
	_shelf(self, Vector3(13.25, 0.0, 0.0), -90.0)
	_box(self, "Printer cabinet", Vector3(12.6, 0.47, -4.1), Vector3(1.5, 0.94, 1.1), "wood_light", true)
	_box(self, "Printer", Vector3(12.6, 1.1, -4.1), Vector3(1.0, 0.42, 0.75), "white")
	_box(self, "Printer output", Vector3(12.6, 1.15, -3.7), Vector3(0.65, 0.06, 0.12), "black")
	_box(self, "Printer paper", Vector3(12.6, 1.16, -3.59), Vector3(0.45, 0.008, 0.23), "white")


func _build_lobby() -> void:
	var elevator := _target(self, "exit", "Elevator · end the day", Vector3(0.0, 0.0, 11.7), Vector3(0.0, 1.6, 11.57))
	_box(elevator, "Elevator surround", Vector3(0.0, 1.5, 0.0), Vector3(3.5, 3.0, 0.17), "navy", true)
	_box(elevator, "Elevator door left", Vector3(-0.71, 1.4, -0.11), Vector3(1.39, 2.72, 0.06), "metal")
	_box(elevator, "Elevator door right", Vector3(0.71, 1.4, -0.11), Vector3(1.39, 2.72, 0.06), "metal")
	_box(elevator, "Elevator centre seam", Vector3(0.0, 1.4, -0.15), Vector3(0.025, 2.72, 0.025), "navy")
	_box(elevator, "Elevator button panel", Vector3(2.02, 1.25, -0.12), Vector3(0.23, 0.5, 0.065), "navy")
	_sphere(elevator, "Elevator call button", Vector3(2.02, 1.28, -0.18), Vector3(0.085, 0.085, 0.035), "light")
	_sign(elevator, "ELEVATOR", Vector3(0.0, 3.2, -0.12), 180.0, 0.0044, Color("203744"))
	_sign(elevator, "01", Vector3(0.0, 2.92, -0.15), 180.0, 0.0033, Color("87d4bc"))
	_box(self, "Company sign backing", Vector3(7.8, 2.55, 11.83), Vector3(7.0, 1.45, 0.06), "navy")
	_sign(self, "SMALL BATCH", Vector3(7.8, 2.75, 11.77), 180.0, 0.0062, Color("fff8e9"))
	_sign(self, "A PERFECTLY NORMAL TECH COMPANY", Vector3(7.8, 2.2, 11.76), 180.0, 0.00255, Color("93bbb0"))
	_planter(self, Vector3(3.0, 0.0, 10.5), 1.3)
	_box(self, "Welcome mat", Vector3(0.0, 0.01, 10.3), Vector3(3.6, 0.02, 1.2), "navy")
	# The sign is in the player's first view, with arrows corresponding to this layout.
	var wayfinding := _group(self, "Wayfinding", Vector3(1.8, 3.35, 3.3))
	_box(wayfinding, "Wayfinding panel", Vector3.ZERO, Vector3(4.8, 0.63, 0.11), "navy")
	_sign(wayfinding, "← COFFEE     /     YOUR DESK →", Vector3(0.0, 0.14, 0.07), 0.0, 0.00265, Color("fff8e9"))
	_sign(wayfinding, "MANAGER  ↖       STANDUP  ↗", Vector3(0.0, -0.15, 0.07), 0.0, 0.0025, Color("93bbb0"))
	for x: float in [-2.15, 2.15]:
		_box(wayfinding, "Sign suspension", Vector3(x, 0.6, 0.0), Vector3(0.025, 0.78, 0.025), "metal")


func _build_details() -> void:
	_planter(self, Vector3(-12.8, 0.0, -3.5), 1.45)
	_planter(self, Vector3(12.8, 0.0, 8.6), 1.55)
	_planter(self, Vector3(0.0, 0.0, -7.5), 1.0)
	_planter(self, Vector3(-1.5, 0.79, -1.1), 0.4)
	# A bulletin board and a few framed posters bring color to the blank walls.
	_box(self, "Bulletin board rim", Vector3(-2.0, 2.0, -11.78), Vector3(3.5, 2.2, 0.1), "wood")
	_box(self, "Bulletin board", Vector3(-2.0, 2.0, -11.71), Vector3(3.26, 1.96, 0.04), "wood_light")
	_sign(self, "TEAM NOTICES", Vector3(-2.0, 2.7, -11.66), 0.0, 0.0034, Color("203744"))
	for i: int in range(4):
		_box(self, "Notice sheet", Vector3(-3.08 + float(i % 2) * 1.2, 2.1 - float(i / 2) * 0.62, -11.66), Vector3(0.84, 0.47, 0.015), "white" if i % 2 == 0 else "coral")
	_sign(self, "FRIDAY DEMO\nPLEASE CLAP", Vector3(-3.08, 2.1, -11.63), 0.0, 0.00155, Color("203744"))
	_sign(self, "NO MEETINGS\nABOUT MEETINGS", Vector3(-1.88, 1.48, -11.63), 0.0, 0.00145, Color("203744"))
	# An analogue clock: time still exists, even when the sprint does not.
	var clock := _cylinder(self, "Wall clock", Vector3(2.0, 2.95, -11.72), 0.45, 0.075, "navy")
	clock.rotation_degrees.x = 90.0
	var face := _cylinder(self, "Clock face", Vector3(2.0, 2.95, -11.66), 0.39, 0.025, "white")
	face.rotation_degrees.x = 90.0
	_box(self, "Clock minute hand", Vector3(2.0, 3.09, -11.63), Vector3(0.025, 0.28, 0.02), "navy")
	var hour := _box(self, "Clock hour hand", Vector3(2.1, 2.95, -11.62), Vector3(0.22, 0.035, 0.02), "coral")
	hour.rotation_degrees.z = -10.0
	# Small server appliance behind the engineering pod.
	_box(self, "Networking cabinet", Vector3(-2.3, 0.64, -7.5), Vector3(1.15, 1.28, 0.7), "navy", true)
	for y: float in [0.32, 0.64, 0.96]:
		_box(self, "Networking rack slot", Vector3(-2.3, y, -7.13), Vector3(0.93, 0.17, 0.025), "black")
		_box(self, "Blinkenlight", Vector3(-1.96, y, -7.11), Vector3(0.05, 0.05, 0.02), "screen_line")
	_sign(self, "THE CLOUD", Vector3(-2.3, 1.49, -7.1), 0.0, 0.0028, Color("203744"))


func _desk(parent: Node3D, title: String, pos: Vector3, yaw: float, player_desk: bool) -> void:
	var desk := _group(parent, title, pos)
	desk.rotation_degrees.y = yaw
	_box(desk, "Oak desk top", Vector3(0.0, 0.77, 0.0), Vector3(2.8, 0.12, 1.35), "wood_light", true)
	_box(desk, "Desk edge", Vector3(0.0, 0.72, 0.0), Vector3(2.78, 0.04, 1.31), "wood")
	for x: float in [-1.15, 1.15]:
		_box(desk, "Desk leg", Vector3(x, 0.36, 0.0), Vector3(0.085, 0.72, 1.05), "navy", true)
		_box(desk, "Desk foot", Vector3(x, 0.035, 0.0), Vector3(0.32, 0.07, 1.2), "navy")
	_box(desk, "Cable tray", Vector3(0.0, 0.62, 0.35), Vector3(2.0, 0.11, 0.2), "navy")
	_computer(desk, Vector3(0.0, 0.83, 0.28), player_desk)
	_box(desk, "Keyboard", Vector3(0.0, 0.85, -0.32), Vector3(0.72, 0.045, 0.24), "navy")
	for row: int in range(3):
		for col: int in range(10):
			_box(desk, "Keyboard key", Vector3(-0.3 + float(col) * 0.065, 0.875, -0.4 + float(row) * 0.067), Vector3(0.045, 0.008, 0.044), "metal")
	_box(desk, "Mouse mat", Vector3(0.68, 0.837, -0.29), Vector3(0.42, 0.008, 0.35), "teal")
	_sphere(desk, "Mouse", Vector3(0.68, 0.87, -0.31), Vector3(0.11, 0.065, 0.17), "white")
	_mug(desk, Vector3(-0.99, 0.92, -0.2), "coral" if player_desk else "teal")
	_box(desk, "Notebook", Vector3(1.04, 0.85, 0.21), Vector3(0.34, 0.045, 0.45), "coral" if player_desk else "navy")
	_box(desk, "Notebook page", Vector3(1.04, 0.875, 0.21), Vector3(0.3, 0.006, 0.41), "white")
	if player_desk:
		_box(desk, "Pager", Vector3(-0.74, 0.87, -0.4), Vector3(0.23, 0.08, 0.16), "navy")
		_box(desk, "Pager display", Vector3(-0.74, 0.915, -0.4), Vector3(0.14, 0.012, 0.08), "screen_line")
		_box(desk, "Welcome sticky", Vector3(-0.65, 0.85, 0.15), Vector3(0.26, 0.013, 0.26), "gold")


func _computer(parent: Node3D, pos: Vector3, special: bool) -> void:
	var computer := _group(parent, "Computer", pos)
	_box(computer, "Monitor base", Vector3(0.0, 0.02, 0.0), Vector3(0.48, 0.04, 0.28), "navy")
	_box(computer, "Monitor stem", Vector3(0.0, 0.19, 0.04), Vector3(0.085, 0.34, 0.075), "navy")
	_box(computer, "Monitor frame", Vector3(0.0, 0.5, 0.04), Vector3(1.08, 0.66, 0.075), "navy")
	_box(computer, "Monitor screen", Vector3(0.0, 0.5, -0.003), Vector3(0.98, 0.55, 0.014), "screen")
	_box(computer, "Editor side panel", Vector3(-0.37, 0.5, -0.013), Vector3(0.17, 0.5, 0.007), "teal")
	for i: int in range(6):
		var width: float = 0.23 + float((i * 3) % 5) * 0.065
		_box(computer, "Pretend code", Vector3(-0.16 + width * 0.5, 0.7 - float(i) * 0.073, -0.015), Vector3(width, 0.018, 0.008), "screen_coral" if i % 3 == 0 else "screen_line")
	if special:
		_sign(computer, "INTERN OS", Vector3(0.0, 0.81, -0.01), 180.0, 0.00135, Color("87d4bc"))


func _chair(parent: Node3D, pos: Vector3, yaw: float, upholstery: String) -> void:
	var chair := _group(parent, "Office chair", pos)
	chair.rotation_degrees.y = yaw
	_box(chair, "Cushion", Vector3(0.0, 0.48, 0.0), Vector3(0.65, 0.12, 0.62), upholstery, true)
	_box(chair, "Backrest", Vector3(0.0, 0.88, 0.29), Vector3(0.65, 0.72, 0.12), upholstery, true)
	_cylinder(chair, "Chair stem", Vector3(0.0, 0.24, 0.0), 0.05, 0.4, "metal")
	for angle: float in [0.0, 72.0, 144.0, 216.0, 288.0]:
		var leg := _box(chair, "Chair wheel spoke", Vector3.ZERO, Vector3(0.085, 0.06, 0.6), "navy")
		leg.position = Vector3(sin(deg_to_rad(angle)) * 0.15, 0.07, cos(deg_to_rad(angle)) * 0.15)
		leg.rotation_degrees.y = angle
		_sphere(chair, "Chair wheel", Vector3(sin(deg_to_rad(angle)) * 0.4, 0.055, cos(deg_to_rad(angle)) * 0.4), Vector3(0.09, 0.11, 0.09), "black")
	for x: float in [-0.37, 0.37]:
		_box(chair, "Chair arm", Vector3(x, 0.68, 0.015), Vector3(0.06, 0.07, 0.43), "navy")


func _person(parent: Node3D, pos: Vector3, shirt: String, skin: String, hair: String, yaw: float, seated: bool) -> void:
	var person := _group(parent, "Coworker", pos)
	person.rotation_degrees.y = yaw
	var offset: float = -0.25 if seated else 0.0
	_box(person, "Torso", Vector3(0.0, 1.0 + offset, 0.0), Vector3(0.49, 0.58, 0.32), shirt)
	_sphere(person, "Head", Vector3(0.0, 1.52 + offset, 0.0), Vector3(0.37, 0.43, 0.35), skin)
	_sphere(person, "Hair", Vector3(0.0, 1.66 + offset, -0.025), Vector3(0.39, 0.24, 0.36), hair)
	_box(person, "Hair back", Vector3(0.0, 1.51 + offset, -0.155), Vector3(0.33, 0.3, 0.075), hair)
	for x: float in [-0.075, 0.075]:
		_sphere(person, "Eye", Vector3(x, 1.54 + offset, 0.168), Vector3(0.025, 0.03, 0.012), "navy")
	_box(person, "Smile", Vector3(0.0, 1.42 + offset, 0.177), Vector3(0.07, 0.013, 0.008), "hair")
	for x: float in [-0.3, 0.3]:
		_box(person, "Shirt sleeve", Vector3(x, 1.09 + offset, 0.0), Vector3(0.16, 0.27, 0.28), shirt)
		_box(person, "Arm", Vector3(x, 0.84 + offset, 0.015), Vector3(0.125, 0.3, 0.13), skin)
		_sphere(person, "Hand", Vector3(x, 0.67 + offset, 0.025), Vector3(0.14, 0.16, 0.14), skin)
	for x: float in [-0.14, 0.14]:
		_box(person, "Trousers", Vector3(x, 0.39 + offset * 0.2, 0.0), Vector3(0.2, 0.64, 0.27), "navy")
		_box(person, "Shoe", Vector3(x, 0.075, 0.07), Vector3(0.22, 0.15, 0.4), "white")
	_box(person, "Lanyard", Vector3(0.0, 1.06 + offset, 0.17), Vector3(0.025, 0.35, 0.015), "gold")
	_box(person, "Employee badge", Vector3(0.0, 0.89 + offset, 0.185), Vector3(0.12, 0.16, 0.025), "white")
	_box(person, "Badge stripe", Vector3(0.0, 0.92 + offset, 0.201), Vector3(0.09, 0.025, 0.006), "teal")
	var body := StaticBody3D.new()
	body.name = "Coworker interaction"
	body.position = Vector3(0.0, 0.9 + offset * 0.5, 0.0)
	person.add_child(body)
	_copy_interaction(body, parent)
	var shape := CapsuleShape3D.new()
	shape.radius = 0.36
	shape.height = 1.8 + offset
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)


func _round_table(parent: Node3D, pos: Vector3, radius: float, height: float, surface: String) -> void:
	var table := _group(parent, "Round table", pos)
	_cylinder(table, "Tabletop", Vector3(0.0, height, 0.0), radius, 0.09, surface, true)
	_cylinder(table, "Table pedestal", Vector3(0.0, height * 0.5, 0.0), 0.075, height, "navy", true)
	_cylinder(table, "Table base", Vector3(0.0, 0.035, 0.0), radius * 0.52, 0.07, "navy")


func _stool(parent: Node3D, pos: Vector3) -> void:
	var stool := _group(parent, "Cafe stool", pos)
	_cylinder(stool, "Stool seat", Vector3(0.0, 0.66, 0.0), 0.28, 0.09, "coral", true)
	for x: float in [-0.18, 0.18]:
		for z: float in [-0.18, 0.18]:
			_box(stool, "Stool leg", Vector3(x, 0.3, z), Vector3(0.045, 0.6, 0.045), "navy")


func _sofa(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var sofa := _group(parent, "Lounge sofa", pos)
	sofa.rotation_degrees.y = yaw
	_box(sofa, "Sofa base", Vector3(0.0, 0.38, 0.0), Vector3(3.2, 0.55, 1.1), "teal", true)
	_box(sofa, "Sofa back", Vector3(0.0, 0.91, 0.48), Vector3(3.2, 0.8, 0.25), "teal", true)
	for x: float in [-1.45, 1.45]:
		_box(sofa, "Sofa arm", Vector3(x, 0.75, 0.0), Vector3(0.3, 0.5, 1.1), "teal")
	for x: float in [-0.86, 0.0, 0.86]:
		_box(sofa, "Sofa cushion", Vector3(x, 0.68, -0.05), Vector3(0.82, 0.15, 0.8), "light_teal")
	_box(sofa, "Throw pillow", Vector3(-1.0, 0.95, 0.19), Vector3(0.48, 0.48, 0.2), "coral")


func _planter(parent: Node3D, pos: Vector3, size: float) -> void:
	var plant := _group(parent, "Office plant", pos)
	_cylinder(plant, "Pot", Vector3(0.0, size * 0.2, 0.0), size * 0.22, size * 0.4, "white")
	_cylinder(plant, "Soil", Vector3(0.0, size * 0.405, 0.0), size * 0.2, 0.015, "hair")
	_cylinder(plant, "Plant stalk", Vector3(0.0, size * 0.73, 0.0), size * 0.022, size * 0.66, "green")
	for i: int in range(7):
		var angle: float = float(i) * 2.4
		var height: float = size * (0.55 + float(i % 3) * 0.23)
		var leaf := _sphere(plant, "Leaf", Vector3(sin(angle) * size * 0.19, height, cos(angle) * size * 0.19), Vector3(size * 0.25, size * 0.54, size * 0.12), "leaf_light" if i % 2 == 0 else "green")
		leaf.rotation_degrees = Vector3(28.0 * cos(angle), rad_to_deg(angle), 32.0 * sin(angle))


func _shelf(parent: Node3D, pos: Vector3, yaw: float) -> void:
	var shelf := _group(parent, "Bookshelf", pos)
	shelf.rotation_degrees.y = yaw
	_box(shelf, "Shelf back", Vector3(0.0, 0.95, 0.2), Vector3(2.2, 1.9, 0.06), "navy", true)
	for x: float in [-1.08, 1.08]:
		_box(shelf, "Shelf upright", Vector3(x, 0.95, 0.0), Vector3(0.07, 1.9, 0.5), "wood")
	for y: float in [0.08, 0.68, 1.28, 1.88]:
		_box(shelf, "Shelf board", Vector3(0.0, y, 0.0), Vector3(2.2, 0.07, 0.5), "wood_light")
	for i: int in range(9):
		var book_material: String = ["coral", "teal", "gold", "white"][i % 4]
		_box(shelf, "Book", Vector3(-0.89 + float(i % 5) * 0.27, 0.94 + float(i / 5) * 0.6, -0.04), Vector3(0.16, 0.44, 0.28), book_material)
	_box(shelf, "Storage box", Vector3(0.63, 0.37, 0.0), Vector3(0.65, 0.5, 0.43), "coral")
	_box(shelf, "Storage box handle", Vector3(0.63, 0.4, -0.224), Vector3(0.18, 0.06, 0.01), "white")


func _mug(parent: Node3D, pos: Vector3, color: String) -> void:
	_cylinder(parent, "Coffee mug", pos, 0.075, 0.16, color)
	_cylinder(parent, "Coffee", pos + Vector3(0.0, 0.081, 0.0), 0.06, 0.008, "hair")
	var handle := TorusMesh.new()
	handle.inner_radius = 0.035
	handle.outer_radius = 0.055
	var mesh := MeshInstance3D.new()
	mesh.name = "Mug handle"
	mesh.mesh = handle
	mesh.material_override = _materials[color]
	mesh.position = pos + Vector3(0.078, 0.0, 0.0)
	mesh.rotation_degrees.x = 90.0
	parent.add_child(mesh)


func _pendant(pos: Vector3) -> void:
	_box(self, "Pendant housing", pos, Vector3(3.7, 0.11, 0.3), "navy")
	_box(self, "Pendant diffuser", pos + Vector3(0.0, -0.061, 0.0), Vector3(3.5, 0.025, 0.22), "light")
	for x: float in [-1.5, 1.5]:
		_box(self, "Pendant cable", pos + Vector3(x, 0.27, 0.0), Vector3(0.015, 0.45, 0.015), "navy")


func _glass_partition(parent: Node3D, pos: Vector3, width: float, yaw: float) -> void:
	var partition := _group(parent, "Glass partition", pos)
	partition.rotation_degrees.y = yaw
	_box(partition, "Glass pane", Vector3(0.0, 1.65, 0.0), Vector3(width, 3.3, 0.06), "glass", true)
	_box(partition, "Lower privacy panel", Vector3(0.0, 0.5, 0.0), Vector3(width, 1.0, 0.08), "light_teal")
	for y: float in [0.08, 1.0, 3.28]:
		_box(partition, "Partition rail", Vector3(0.0, y, 0.0), Vector3(width, 0.07, 0.1), "navy")
	var count: int = maxi(1, int(width / 2.0))
	for i: int in range(count + 1):
		var x: float = -width * 0.5 + width * float(i) / float(count)
		_box(partition, "Partition mullion", Vector3(x, 1.65, 0.0), Vector3(0.055, 3.3, 0.1), "navy")


func _target(parent: Node3D, id: String, label: String, pos: Vector3, marker: Vector3) -> Node3D:
	var target := _group(parent, label, pos)
	target.set_meta("interaction_id", id)
	target.set_meta("display_name", label)
	interaction_positions[id] = marker
	interaction_labels[id] = label
	return target


func _interaction_box(parent: Node3D, pos: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = "Interaction target"
	body.position = pos
	parent.add_child(body)
	_copy_interaction(body, parent)
	var shape := BoxShape3D.new()
	shape.size = size
	var collision := CollisionShape3D.new()
	collision.shape = shape
	body.add_child(collision)


func _copy_interaction(body: StaticBody3D, start: Node) -> void:
	var current: Node = start
	while current != null and current != self.get_parent():
		if current.has_meta("interaction_id"):
			body.set_meta("interaction_id", current.get_meta("interaction_id"))
			body.set_meta("display_name", current.get_meta("display_name"))
			return
		current = current.get_parent()


func _group(parent: Node3D, title: String, pos: Vector3) -> Node3D:
	var node := Node3D.new()
	node.name = title
	node.position = pos
	parent.add_child(node)
	return node


func _box(parent: Node3D, title: String, pos: Vector3, size: Vector3, material: String, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var geometry := BoxMesh.new()
	geometry.size = size
	mesh.mesh = geometry
	mesh.material_override = _materials[material]
	mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		body.name = "Solid"
		mesh.add_child(body)
		_copy_interaction(body, parent)
		var shape := BoxShape3D.new()
		shape.size = size
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
	return mesh


func _cylinder(parent: Node3D, title: String, pos: Vector3, radius: float, height: float, material: String, solid: bool = false) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var geometry := CylinderMesh.new()
	geometry.top_radius = radius
	geometry.bottom_radius = radius
	geometry.height = height
	geometry.radial_segments = 16
	mesh.mesh = geometry
	mesh.material_override = _materials[material]
	mesh.position = pos
	parent.add_child(mesh)
	if solid:
		var body := StaticBody3D.new()
		mesh.add_child(body)
		_copy_interaction(body, parent)
		var shape := CylinderShape3D.new()
		shape.radius = radius
		shape.height = height
		var collision := CollisionShape3D.new()
		collision.shape = shape
		body.add_child(collision)
	return mesh


func _sphere(parent: Node3D, title: String, pos: Vector3, size: Vector3, material: String) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	var geometry := SphereMesh.new()
	geometry.radius = 0.5
	geometry.height = 1.0
	geometry.radial_segments = 12
	geometry.rings = 8
	mesh.mesh = geometry
	mesh.material_override = _materials[material]
	mesh.position = pos
	mesh.scale = size
	parent.add_child(mesh)
	return mesh


func _sign(parent: Node3D, text: String, pos: Vector3, yaw: float, pixel_size: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.name = "Sign " + text.left(24).replace("\n", " ")
	label.text = text
	label.position = pos
	label.rotation_degrees.y = yaw
	label.font_size = 64
	label.pixel_size = pixel_size
	label.modulate = color
	label.outline_size = 0
	label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	label.double_sided = false
	parent.add_child(label)
	return label
