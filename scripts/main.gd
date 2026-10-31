extends Node3D

var _camera: Camera3D
var _world: World
var _player: Player
var _debug_label: Label
var _loading_label: Label
var _mesh_build_ms: float = 0.0
var _spawn_pending: bool = true

func _ready() -> void:
	var light: DirectionalLight3D = DirectionalLight3D.new()
	light.rotation.x = deg_to_rad(-50.0)
	add_child(light)

	var environment: Environment = Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.53, 0.75, 0.95)

	var world_environment: WorldEnvironment = WorldEnvironment.new()
	world_environment.environment = environment
	add_child(world_environment)

	_build_streamed_world()
	_player = Player.new()
	_player.name = "Player"
	_player.position = Vector3(
		0.5,
		float(_world.generator.height_at(0, 0) + 2),
		0.5
	)
	add_child(_player)
	_player.set_physics_process(false)
	_player.head.rotation.x = -0.12
	_camera = _player.get_camera()
	_world.stream_target = _camera

	var debug_layer: CanvasLayer = CanvasLayer.new()
	_debug_label = Label.new()
	_debug_label.position = Vector2(10.0, 10.0)
	_debug_label.add_theme_color_override("font_color", Color.WHITE)
	debug_layer.add_child(_debug_label)
	_loading_label = Label.new()
	_loading_label.name = "LoadingLabel"
	_loading_label.position = Vector2(10.0, 36.0)
	_loading_label.add_theme_color_override("font_color", Color.WHITE)
	_loading_label.text = "Generando mundo…"
	debug_layer.add_child(_loading_label)
	add_child(debug_layer)
	_update_debug_label()

func _build_streamed_world() -> void:
	_world = World.new()
	_world.name = "World"
	_world.set_render_distance(Const.DEFAULT_RENDER_DISTANCE)
	_world.stream_target = _camera
	add_child(_world)

func _process(_delta: float) -> void:
	if _spawn_pending and _world.are_collisions_ready(Vector2i.ZERO, 2):
		_spawn_pending = false
		_player.set_physics_process(true)
		_loading_label.visible = false
	if _world != null and _world.last_mesh_build_usec > 0:
		_mesh_build_ms = float(_world.last_mesh_build_usec) / 1000.0
	if Input.is_action_just_pressed(&"toggle_debug"):
		_debug_label.visible = not _debug_label.visible
	if _debug_label.visible:
		_update_debug_label()

func _update_debug_label() -> void:
	var camera_position: Vector3 = _camera.global_position
	_debug_label.text = "FPS: %d\nMesh: %s ms\nChunks: %d data / %d mesh\nCollision chunks: %d\nFloor: %s (vy %s)\nPos: %s, %s, %s" % [
		Engine.get_frames_per_second(),
		String.num(_mesh_build_ms, 2),
		_world.chunks.size(),
		_world.get_meshed_chunk_count(),
		_world.get_collision_chunk_count(),
		str(_player.is_on_floor()),
		String.num(_player.velocity.y, 2),
		String.num(camera_position.x, 2),
		String.num(camera_position.y, 2),
		String.num(camera_position.z, 2)
	]
