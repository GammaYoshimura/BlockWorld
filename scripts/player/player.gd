class_name Player
extends CharacterBody3D

var head: Node3D
var camera: Camera3D
var _body_collision: CollisionShape3D
var auto_step_status: String = "esperando pared"
var is_flying: bool = false
var spawn_position: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(&"toggle_fly"):
		is_flying = not is_flying
		if is_flying:
			velocity.y = 0.0
	if global_position.y < -20.0:
		respawn()
		return
	if is_flying:
		_process_flight(delta)
		return
	var input_direction: Vector2 = Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_forward",
		&"move_back"
	)
	var local_direction: Vector3 = Vector3(input_direction.x, 0.0, input_direction.y)
	var wish_direction: Vector3 = (transform.basis * local_direction).normalized()
	var target_speed: float = Const.WALK_SPEED
	var moving_forward: bool = input_direction.y < -0.01
	if Input.is_action_pressed(&"sneak"):
		target_speed = Const.SNEAK_SPEED
	elif Input.is_action_pressed(&"sprint") and moving_forward:
		target_speed = Const.SPRINT_SPEED
	var target_velocity: Vector3 = wish_direction * target_speed
	var acceleration: float = 60.0 if is_on_floor() else 20.0
	var was_on_floor: bool = is_on_floor()
	velocity.x = move_toward(velocity.x, target_velocity.x, acceleration * delta)
	velocity.z = move_toward(velocity.z, target_velocity.z, acceleration * delta)
	var jump_requested: bool = Input.is_action_pressed(&"jump") and is_on_floor()
	if jump_requested:
		velocity.y = Const.JUMP_VELOCITY
	if is_on_floor():
		if velocity.y < 0.0:
			velocity.y = 0.0
	else:
		velocity.y = maxf(
			velocity.y - Const.GRAVITY * delta,
			-Const.TERMINAL_VELOCITY
		)
	move_and_slide()
	if was_on_floor and not jump_requested and wish_direction != Vector3.ZERO:
		if is_on_wall():
			if _can_auto_jump_over_step(wish_direction):
				velocity.y = Const.JUMP_VELOCITY
				auto_step_status = "auto-salto %.2f" % Const.AUTO_STEP_HEIGHT
		else:
			auto_step_status = "sin pared detectada"

func _can_auto_jump_over_step(direction: Vector3) -> bool:
	if direction.is_zero_approx():
		auto_step_status = "sin dirección"
		return false
	auto_step_status = "comprobando superficie"
	var horizontal_direction: Vector3 = Vector3(direction.x, 0.0, direction.z).normalized()
	var probe_distance: float = Const.PLAYER_WIDTH * 0.5 + safe_margin + 0.1
	var probe_target: Vector3 = global_position + horizontal_direction * probe_distance
	var ray_query: PhysicsRayQueryParameters3D = PhysicsRayQueryParameters3D.create(
		probe_target + Vector3.UP * (Const.AUTO_STEP_HEIGHT + 0.1),
		probe_target + Vector3.DOWN * 0.1
	)
	ray_query.collision_mask = collision_mask
	ray_query.exclude = [get_rid()]
	ray_query.collide_with_areas = false
	var floor_hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(ray_query)
	if floor_hit.is_empty():
		auto_step_status = "sin suelo delante"
		return false
	var floor_normal: Vector3 = floor_hit["normal"]
	if floor_normal.dot(Vector3.UP) < cos(floor_max_angle):
		return false
	var floor_position: Vector3 = floor_hit["position"]
	var step_rise: float = floor_position.y - global_position.y
	if step_rise <= 0.05 or step_rise > Const.AUTO_STEP_HEIGHT + 0.01:
		auto_step_status = "altura %.2f" % step_rise
		return false

	var target_transform: Transform3D = global_transform
	target_transform.origin = probe_target
	target_transform.origin.y = floor_position.y
	var shape_query: PhysicsShapeQueryParameters3D = PhysicsShapeQueryParameters3D.new()
	shape_query.shape = _body_collision.shape
	var clearance_transform: Transform3D = target_transform
	clearance_transform.origin.y += 0.02
	shape_query.transform = clearance_transform * _body_collision.transform
	shape_query.collision_mask = collision_mask
	shape_query.exclude = [get_rid()]
	shape_query.collide_with_areas = false
	shape_query.collide_with_bodies = true
	shape_query.margin = 0.0
	if not get_world_3d().direct_space_state.intersect_shape(shape_query, 1).is_empty():
		auto_step_status = "cápsula bloqueada (%.2f)" % step_rise
		return false
	auto_step_status = "obstáculo %.2f" % step_rise
	return true

func _process_flight(delta: float) -> void:
	var input_direction: Vector2 = Input.get_vector(
		&"move_left",
		&"move_right",
		&"move_forward",
		&"move_back"
	)
	var local_direction: Vector3 = Vector3(input_direction.x, 0.0, input_direction.y)
	var flight_direction: Vector3 = (transform.basis * local_direction).normalized()
	var vertical_direction: float = 0.0
	if Input.is_action_pressed(&"jump"):
		vertical_direction += 1.0
	if Input.is_action_pressed(&"sneak"):
		vertical_direction -= 1.0
	var motion: Vector3 = flight_direction * Const.FLY_SPEED
	motion.y = vertical_direction * Const.FLY_SPEED
	velocity = velocity.move_toward(motion, 60.0 * delta)
	move_and_slide()

func respawn() -> void:
	global_position = spawn_position
	velocity = Vector3.ZERO
	is_flying = false

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
	camera.fov = 70.0
	camera.near = 0.05
	head.add_child(camera)
	spawn_position = global_position
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
