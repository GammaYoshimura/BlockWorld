extends Node3D

const TEST_CHUNK_MIN_COORD: int = -1
const TEST_CHUNK_MAX_COORD: int = 1
const CHUNK_NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1)
]

var _camera: Camera3D
var _debug_label: Label
var _mesh_build_ms: float = 0.0

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

	var camera: Camera3D = Camera3D.new()
	var camera_position: Vector3 = Vector3(8.0, 34.0, 52.0)
	var world_center: Vector3 = Vector3(8.0, 20.0, 8.0)
	camera.position = camera_position
	camera.look_at_from_position(camera_position, world_center, Vector3.UP)
	camera.set_script(preload("res://scripts/util/fly_camera.gd"))
	add_child(camera)
	_camera = camera

	_build_test_world()

	var debug_layer: CanvasLayer = CanvasLayer.new()
	_debug_label = Label.new()
	_debug_label.position = Vector2(10.0, 10.0)
	_debug_label.add_theme_color_override("font_color", Color.WHITE)
	debug_layer.add_child(_debug_label)
	add_child(debug_layer)
	_update_debug_label()

func _build_test_world() -> void:
	var chunk_data_by_coord: Dictionary = {}
	var total_mesh_time_usec: int = 0
	var mesh_build_count: int = 0
	for chunk_z: int in range(TEST_CHUNK_MIN_COORD, TEST_CHUNK_MAX_COORD + 1):
		for chunk_x: int in range(TEST_CHUNK_MIN_COORD, TEST_CHUNK_MAX_COORD + 1):
			var coord: Vector2i = Vector2i(chunk_x, chunk_z)
			var data: ChunkData = ChunkData.new(coord)
			data.fill_flat()
			chunk_data_by_coord[coord] = data

	for chunk_z: int in range(TEST_CHUNK_MIN_COORD, TEST_CHUNK_MAX_COORD + 1):
		for chunk_x: int in range(TEST_CHUNK_MIN_COORD, TEST_CHUNK_MAX_COORD + 1):
			var coord: Vector2i = Vector2i(chunk_x, chunk_z)
			var data: ChunkData = chunk_data_by_coord[coord] as ChunkData
			var neighbors: Dictionary = {}
			for offset: Vector2i in CHUNK_NEIGHBOR_OFFSETS:
				var neighbor_coord: Vector2i = coord + offset
				if chunk_data_by_coord.has(neighbor_coord):
					neighbors[offset] = chunk_data_by_coord[neighbor_coord]

			var chunk: Chunk = Chunk.new(coord)
			add_child(chunk)
			var build_start_usec: int = Time.get_ticks_usec()
			var mesh_result: Dictionary = ChunkMesher.build(data, neighbors)
			total_mesh_time_usec += Time.get_ticks_usec() - build_start_usec
			mesh_build_count += 1
			chunk.apply_mesh(mesh_result)

	if mesh_build_count > 0:
		_mesh_build_ms = float(total_mesh_time_usec) / float(mesh_build_count) / 1000.0

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"toggle_debug"):
		_debug_label.visible = not _debug_label.visible
	if _debug_label.visible:
		_update_debug_label()

func _update_debug_label() -> void:
	var camera_position: Vector3 = _camera.global_position
	_debug_label.text = "FPS: %d\nMesh: %s ms\nPos: %s, %s, %s" % [
		Engine.get_frames_per_second(),
		String.num(_mesh_build_ms, 2),
		String.num(camera_position.x, 2),
		String.num(camera_position.y, 2),
		String.num(camera_position.z, 2)
	]\n