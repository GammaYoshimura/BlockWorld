class_name Player
extends CharacterBody3D

var head: Node3D
var camera: Camera3D
var _body_collision: CollisionShape3D

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
	var jump_requested: bool = Input.is_action_just_pressed(&"jump") and is_on_floor()
	if jump_requested:
		velocity.y = Const.JUMP_VELOCITY
	if not jump_requested and is_on_floor() and wish_direction != Vector3.ZERO:
		var horizontal_motion: Vector3 = Vector3(velocity.x, 0.0, velocity.z) * delta
		if _try_auto_step(horizontal_motion):
			velocity.y = 0.0
			return
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y = maxf(
			velocity.y - Const.GRAVITY * delta,
			-Const.TERMINAL_VELOCITY
		)
	move_and_slide()

func _try_auto_step(horizontal_motion: Vector3) -> bool:
	if horizontal_motion.is_zero_approx():
		return false
	var original_transform: Transform3D = global_transform
	var wall_collision: KinematicCollision3D = KinematicCollision3D.new()
	if not test_move(global_transform, horizontal_motion, wall_collision):
		return false
	if wall_collision.get_normal().dot(Vector3.UP) >= cos(floor_max_angle):
		return false

	var step_transform: Transform3D = global_transform
	step_transform.origin += Vector3.UP * Const.AUTO_STEP_HEIGHT
	if not _step_position_is_clear(step_transform):
		return false
	var forward_collision: KinematicCollision3D = KinematicCollision3D.new()
	if test_move(step_transform, horizontal_motion, forward_collision):
		return false

	var target_transform: Transform3D = step_transform
	target_transform.origin += horizontal_motion
	if not _step_position_is_clear(target_transform):
		return false
	var landing_collision: KinematicCollision3D = KinematicCollision3D.new()
	var down_motion: Vector3 = Vector3.DOWN * (Const.AUTO_STEP_HEIGHT + 0.1)
	if not test_move(target_transform, down_motion, landing_collision):
		return false
	if landing_collision.get_normal().dot(Vector3.UP) < cos(floor_max_angle):
		return false

	global_transform = target_transform
	if move_and_collide(down_motion) == null:
		global_transform = original_transform
		return false
	return true

func _step_position_is_clear(body_transform: Transform3D) -> bool:
	var query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	query.shape = _body_collision.shape
	query.transform = body_transform * _body_collision.transform
	query.collision_mask = collision_mask
	query.exclude = [get_rid()]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.margin = 0.0
	return get_world_3d().direct_space_state.intersect_shape(query, 1).is_empty()

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1

	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = Const.PLAYER_WIDTH * 0.5
	capsule.height = Const.PLAYER_HEIGHT
	_body_collision = CollisionShape3D.new()
	_body_collision.name = "CollisionShape3D"
	_body_collision.shape = capsule
	_body_collision.position.y = Const.PLAYER_HEIGHT * 0.5
	add_child(_body_collision)

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
