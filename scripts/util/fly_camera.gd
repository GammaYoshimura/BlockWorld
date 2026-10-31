extends Camera3D

var _yaw: float = 0.0
var _pitch: float = 0.0

func _ready() -> void:
	_yaw = rotation.y
	_pitch = rotation.x
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			return
		var mouse_event: InputEventMouseMotion = event as InputEventMouseMotion
		_yaw -= mouse_event.relative.x * Const.MOUSE_SENSITIVITY
		_pitch -= mouse_event.relative.y * Const.MOUSE_SENSITIVITY
		_pitch = clampf(
			_pitch,
			-deg_to_rad(Const.PITCH_LIMIT_DEG),
			deg_to_rad(Const.PITCH_LIMIT_DEG)
		)
		rotation = Vector3(_pitch, _yaw, 0.0)
	elif event.is_action_pressed(&"pause"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _process(delta: float) -> void:
	var movement: Vector3 = Vector3.ZERO
	var forward: Vector3 = Vector3(sin(_yaw), 0.0, -cos(_yaw))
	var right: Vector3 = Vector3(cos(_yaw), 0.0, sin(_yaw))

	if Input.is_action_pressed(&"move_forward"):
		movement += forward
	if Input.is_action_pressed(&"move_back"):
		movement -= forward
	if Input.is_action_pressed(&"move_left"):
		movement -= right
	if Input.is_action_pressed(&"move_right"):
		movement += right
	if Input.is_action_pressed(&"jump"):
		movement.y += 1.0
	if Input.is_action_pressed(&"sneak"):
		movement.y -= 1.0

	if movement.length_squared() > 0.0:
		global_position += movement.normalized() * 10.0 * delta
