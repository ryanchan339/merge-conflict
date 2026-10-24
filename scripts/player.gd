extends CharacterBody3D

signal interacted(id: String)

var camera: Camera3D
var ray: RayCast3D
var enabled: bool = false
var look_sensitivity: float = 0.0021
var focused_id: String = ""
var focused_label: String = ""
var walk_distance: float = 0.0
var energy: int = 75
var _step_timer: float = 0.0

func _ready() -> void:
	name = "Player"
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.31
	capsule.height = 1.78
	var collider := CollisionShape3D.new()
	collider.shape = capsule
	collider.position.y = 0.9
	add_child(collider)
	camera = Camera3D.new()
	camera.position.y = 1.66
	camera.fov = 78.0
	camera.near = 0.06
	add_child(camera)
	camera.current = true
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -3.6)
	ray.enabled = true
	camera.add_child(ray)
	ray.add_exception(self)

func _unhandled_input(event: InputEvent) -> void:
	if not enabled:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * look_sensitivity)
		camera.rotation.x = clampf(camera.rotation.x - event.relative.y * look_sensitivity, -1.25, 1.25)
	if event is InputEventKey and event.pressed and not event.echo and event.physical_keycode == KEY_E:
		if not focused_id.is_empty():
			interacted.emit(focused_id)
		get_viewport().set_input_as_handled()

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	var direction := Vector3.ZERO
	if enabled:
		var axes := Vector2(
			float(Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT)) - float(Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT)),
			float(Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN)) - float(Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP)))
		direction = (transform.basis * Vector3(axes.x, 0, axes.y)).normalized()
	var sprint_speed: float = 6.5 if energy >= 25 else 4.7
	var speed: float = sprint_speed if Input.is_physical_key_pressed(KEY_SHIFT) else 4.0
	velocity.x = move_toward(velocity.x, direction.x * speed, 24.0 * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, 24.0 * delta)
	move_and_slide()
	if direction.length_squared() > 0.1 and enabled:
		walk_distance += delta * speed
		_step_timer += delta * speed * 1.8
		camera.position.y = 1.66 + sin(_step_timer) * 0.025
	else:
		camera.position.y = lerpf(camera.position.y, 1.66, delta * 10.0)
	_update_focus()

func _update_focus() -> void:
	focused_id = ""
	focused_label = ""
	if not enabled:
		return
	ray.force_raycast_update()
	if ray.is_colliding():
		var target: Node = ray.get_collider() as Node
		while target != null:
			if target.has_meta("interaction_id"):
				focused_id = str(target.get_meta("interaction_id"))
				focused_label = str(target.get_meta("display_name", "Interact"))
				return
			target = target.get_parent()

func set_active(active: bool) -> void:
	enabled = active
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED if active else Input.MOUSE_MODE_VISIBLE
	if not active:
		velocity.x = 0
		velocity.z = 0
