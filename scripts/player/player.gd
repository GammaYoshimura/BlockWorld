class_name Player
extends CharacterBody3D

var head: Node3D
var camera: Camera3D

func _physics_process(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_forward",
		&"move_back"
	)
	var local_direction: Vector3 = Vector3(input_direction.x, 0.0, input_direction.y)
	var wish_direction: Vector3 = (transform.basis * local_direction).normalized()
	var target_velocity: Vector3 = wish_direction * Const.WALK_SPEED
	var acceleration: float = 60.0 if is_on_floor() else 20.0
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y = maxf(
			velocity.y - Const.GRAVITY * delta,
			-Const.TERMINAL_VELOCITY
		)
	move_and_slide()

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1

	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = Const.PLAYER_WIDTH * 0.5
	capsule.height = Const.PLAYER_HEIGHT
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = capsule
	collision.position.y = Const.PLAYER_HEIGHT * 0.5
	add_child(collision)

	head = Node3D.new()
	head.name = "Head"
	head.position.y = Const.PLAYER_EYE_HEIGHT
	add_child(head)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	head.add_child(camera)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		return
	if event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
		var mouse_button: InputEventMouseButton = event as InputEventMouseButton
		if mouse_button.button_index == MOUSE_BUTTON_LEFT and mouse_button.pressed:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		var mouse_motion: InputEventMouseMotion = event as InputEventMouseMotion
		rotate_y(-mouse_motion.relative.x * Const.MOUSE_SENSITIVITY)
		head.rotation.x = clampf(
			head.rotation.x - mouse_motion.relative.y * Const.MOUSE_SENSITIVITY,
			-deg_to_rad(Const.PITCH_LIMIT_DEG),
			deg_to_rad(Const.PITCH_LIMIT_DEG)
		)

func get_camera() -> Camera3D:
	return camera
