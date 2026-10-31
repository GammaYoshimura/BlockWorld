extends Node3D

const CrosshairScript = preload("res://scripts/ui/crosshair.gd")
const HotbarScript = preload("res://scripts/ui/hotbar.gd")
const PauseMenuScript = preload("res://scripts/ui/pause_menu.gd")
const SaveManagerScript = preload("res://scripts/world/save_manager.gd")

var _camera: Camera3D
var _world: World
var _player: Player
var _block_highlight: BlockHighlight
var _block_interaction: BlockInteraction
var _debug_label: Label
var _loading_label: Label
var _mesh_build_ms: float = 0.0
var _peak_frame_ms: float = 0.0
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
	if GameSettings.world_name.is_empty():
		GameSettings.world_name = "Mundo-%d" % _world.world_seed
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
	_camera.fov = 70.0
	_camera.near = 0.05
	_camera.far = float((GameSettings.render_distance + 2) * Const.CHUNK_SIZE)
	_world.stream_target = _camera
	_block_highlight = BlockHighlight.new()
	_block_highlight.camera = _camera
	_block_highlight.world = _world
	add_child(_block_highlight)
	_block_interaction = BlockInteraction.new()
	_block_interaction.setup(_player, _camera, _world)
	add_child(_block_interaction)

	var debug_layer: CanvasLayer = CanvasLayer.new()
	var crosshair: Control = CrosshairScript.new()
	crosshair.name = "Crosshair"
	debug_layer.add_child(crosshair)
	var hotbar: Control = HotbarScript.new()
	hotbar.name = "Hotbar"
	hotbar.setup(BlockMaterials.solid().albedo_texture, _block_interaction)
	debug_layer.add_child(hotbar)
	var pause_menu: Control = PauseMenuScript.new()
	pause_menu.name = "PauseMenu"
	debug_layer.add_child(pause_menu)
	pause_menu.configure(_world, _camera)
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
	_world.set_render_distance(GameSettings.render_distance)
	_world.stream_target = _camera
	add_child(_world)

func _process(delta: float) -> void:
	_peak_frame_ms = maxf(_peak_frame_ms, delta * 1000.0)
	if not _spawn_pending and _player.global_position.y < -20.0:
		_begin_spawn_loading()
	if _spawn_pending and _world.are_collisions_ready(Vector2i.ZERO, 2):
		var safe_spawn: Variant = _find_safe_spawn()
		if safe_spawn is Vector3:
			_player.global_position = safe_spawn
			_player.spawn_position = safe_spawn
			_player.velocity = Vector3.ZERO
			_spawn_pending = false
			_player.set_physics_process(true)
			_loading_label.visible = false
	if _world != null and _world.last_mesh_build_usec > 0:
		_mesh_build_ms = float(_world.last_mesh_build_usec) / 1000.0
	if Input.is_action_just_pressed(&"toggle_debug"):
		_debug_label.visible = not _debug_label.visible
	if _debug_label.visible:
		_update_debug_label(delta)

func _exit_tree() -> void:
	if _world == null or _player == null or _block_interaction == null:
		return
	var save_error: Error = SaveManagerScript.save_world_metadata(
		GameSettings.world_name,
		_world.world_seed,
		0.0,
		_player.global_position,
		_player.rotation.y,
		_player.head.rotation.x,
		_player.is_flying,
		_block_interaction.slots,
		_block_interaction.selected
	)
	if save_error != OK:
		push_warning("No se pudo guardar world.json; error %d" % save_error)

func _begin_spawn_loading() -> void:
	_spawn_pending = true
	_player.set_physics_process(false)
	_player.velocity = Vector3.ZERO
	_player.is_flying = false
	_player.global_position = Vector3(
		0.5,
		float(_world.generator.height_at(0, 0) + 2),
		0.5
	)
	_loading_label.visible = true

func _find_safe_spawn() -> Variant:
	var candidates: Array[Vector2i] = []
	for dz: int in range(-12, 13):
		for dx: int in range(-12, 13):
			candidates.append(Vector2i(dx, dz))
	candidates.sort_custom(_spawn_candidate_before)
	for offset: Vector2i in candidates:
		var wx: int = offset.x
		var wz: int = offset.y
		var chunk_coord: Vector2i = Coords.world_to_chunk(wx, wz)
		if not _world.is_chunk_loaded(chunk_coord):
			continue
		var ground_height: int = _world.generator.height_at(wx, wz)
		if ground_height <= Const.SEA_LEVEL + 2:
			continue
		var clear: bool = true
		for y: int in range(ground_height + 1, ground_height + ceili(Const.PLAYER_HEIGHT)):
			var block_id: int = _world.get_block(wx, y, wz)
			if block_id != Blocks.AIR and block_id != Blocks.WATER:
				clear = false
				break
		if clear:
			return Vector3(float(wx) + 0.5, float(ground_height + 1), float(wz) + 0.5)
	return null

func _spawn_candidate_before(a: Vector2i, b: Vector2i) -> bool:
	var distance_a: int = a.length_squared()
	var distance_b: int = b.length_squared()
	if distance_a == distance_b:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	return distance_a < distance_b

func _update_debug_label(delta: float = 1.0 / 60.0) -> void:
	var camera_position: Vector3 = _camera.global_position
	var horizontal_speed: float = Vector2(_player.velocity.x, _player.velocity.z).length()
	var block_x: int = floori(_player.global_position.x)
	var block_y: int = floori(_player.global_position.y)
	var block_z: int = floori(_player.global_position.z)
	var chunk: Vector2i = Coords.world_to_chunk(block_x, block_z)
	var facing: String = _facing_name(-_player.global_transform.basis.z)
	var hit: Dictionary = VoxelRaycast.cast(
		camera_position,
		-_camera.global_transform.basis.z,
		Const.PLAYER_REACH,
		Callable(_world, "get_block")
	)
	var target_description: String = "ninguno"
	if bool(hit["hit"]):
		var target: Vector3i = hit["block"]
		target_description = "%s %s" % [Blocks.name_of(int(hit["block_id"])), str(target)]
	_debug_label.text = "FPS: %d (%.2f ms/frame; pico %.2f)\nXYZ: %.2f / %.2f / %.2f | bloque: %d, %d, %d\nChunk: %d, %d | dirección: %s\nApuntando: %s\nChunks: %d datos / %d mallas / %d colisión\nPendiente: %d datos / %d mallas / %d remallados\nMallado: worker %.2f ms / aplicación %.2f ms por frame | semilla: %d\nSuelo: %s (vy %.2f) | velocidad: %.2f | vuelo: %s | auto-salto: %s\nHotbar: %d %s" % [
		Engine.get_frames_per_second(),
		maxf(delta, 0.000001) * 1000.0,
		_peak_frame_ms,
		_player.global_position.x,
		_player.global_position.y,
		_player.global_position.z,
		block_x,
		block_y,
		block_z,
		chunk.x,
		chunk.y,
		facing,
		target_description,
		_world.chunks.size(),
		_world.get_meshed_chunk_count(),
		_world.get_collision_chunk_count(),
		_world.get_pending_data_count(),
		_world.get_pending_mesh_count(),
		_world.get_pending_dirty_count(),
		_mesh_build_ms,
		float(_world.last_mesh_apply_frame_usec) / 1000.0,
		_world.world_seed,
		str(_player.is_on_floor()),
		_player.velocity.y,
		horizontal_speed,
		str(_player.is_flying),
		_player.auto_step_status,
		_block_interaction.selected + 1,
		Blocks.name_of(_block_interaction.slots[_block_interaction.selected])
	]

func _facing_name(direction: Vector3) -> String:
	if absf(direction.x) > absf(direction.z):
		return "este" if direction.x > 0.0 else "oeste"
	return "sur" if direction.z > 0.0 else "norte"
