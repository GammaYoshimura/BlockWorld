class_name World
extends Node3D

const CHUNK_NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1)
]

var chunks: Dictionary = {}
var chunk_nodes: Dictionary = {}
var meshed_chunks: Dictionary = {}
var modified_chunks: Array[ChunkData] = []
var _dirty_chunks: Dictionary = {}
var _pending_dirty_meshes: Dictionary = {}
var last_mesh_build_usec: int = 0
var generator: WorldGenerator
var world_seed: int
var render_distance: int = Const.DEFAULT_RENDER_DISTANCE
var stream_target: Node3D
var _stream_center_chunk: Vector2i = Vector2i(2147483647, 2147483647)
var _data_queue: Array[Vector2i] = []
var _mesh_queue: Array[Vector2i] = []

func _init(seed_override: int = 0) -> void:
	world_seed = seed_override if seed_override != 0 else GameSettings.resolve_world_seed()
	generator = WorldGenerator.new(world_seed)

func _process(_delta: float) -> void:
	if stream_target != null and is_instance_valid(stream_target):
		update_streaming(stream_target.global_position)

func ensure_chunk(cx: int, cz: int) -> ChunkData:
	var coord: Vector2i = Vector2i(cx, cz)
	if chunks.has(coord):
		return chunks[coord] as ChunkData

	var data: ChunkData = _take_modified_chunk(coord)
	if data == null:
		data = generator.generate(cx, cz)
	chunks[coord] = data

	var chunk_node: Chunk = Chunk.new(coord)
	chunk_nodes[coord] = chunk_node
	add_child(chunk_node)
	return data

func remesh(coord: Vector2i) -> bool:
	last_mesh_build_usec = 0
	var build_info: Dictionary = _build_mesh_info(coord)
	if build_info.is_empty():
		return false
	var chunk_node: Chunk = chunk_nodes[coord] as Chunk
	chunk_node.apply_mesh(build_info["mesh"])
	last_mesh_build_usec = int(build_info["usec"])
	meshed_chunks[coord] = true
	return true

func _build_mesh_info(coord: Vector2i) -> Dictionary:
	if not chunks.has(coord) or not chunk_nodes.has(coord):
		return {}
	var neighbors: Dictionary = {}
	for offset: Vector2i in CHUNK_NEIGHBOR_OFFSETS:
		var neighbor_coord: Vector2i = coord + offset
		if not chunks.has(neighbor_coord):
			return {}
		neighbors[offset] = chunks[neighbor_coord]
	var build_start_usec: int = Time.get_ticks_usec()
	var mesh_result: Dictionary = ChunkMesher.build(chunks[coord] as ChunkData, neighbors)
	return {
		"mesh": mesh_result,
		"usec": Time.get_ticks_usec() - build_start_usec,
		"version": (chunks[coord] as ChunkData).mesh_version
	}

func update_streaming(world_position: Vector3) -> void:
	var center_chunk: Vector2i = Coords.world_to_chunk(floori(world_position.x), floori(world_position.z))
	if center_chunk != _stream_center_chunk:
		_unload_distant_chunks(center_chunk)
		_refresh_streaming_queues(center_chunk)
	_process_one_data_chunk()
	_process_one_mesh_chunk()
	_update_collision_range(center_chunk)
	_process_one_dirty_chunk()

func set_render_distance(distance: int) -> void:
	render_distance = clampi(distance, Const.MIN_RENDER_DISTANCE, Const.MAX_RENDER_DISTANCE)
	_stream_center_chunk = Vector2i(2147483647, 2147483647)

func get_pending_data_count() -> int:
	return _data_queue.size()

func get_pending_mesh_count() -> int:
	return _mesh_queue.size()

func get_pending_dirty_count() -> int:
	return _dirty_chunks.size()

func get_meshed_chunk_count() -> int:
	return meshed_chunks.size()

func get_collision_chunk_count() -> int:
	var count: int = 0
	for chunk_variant: Variant in chunk_nodes.values():
		var chunk_node: Chunk = chunk_variant as Chunk
		if chunk_node.has_collision():
			count += 1
	return count

func are_collisions_ready(center_chunk: Vector2i, radius: int) -> bool:
	for dz: int in range(-radius, radius + 1):
		for dx: int in range(-radius, radius + 1):
			if dx * dx + dz * dz > radius * radius:
				continue
			var coord: Vector2i = center_chunk + Vector2i(dx, dz)
			var chunk_node: Chunk = chunk_nodes.get(coord) as Chunk
			if chunk_node == null or not chunk_node.has_collision():
				return false
	return true

func _update_collision_range(center_chunk: Vector2i) -> void:
	var radius_squared: int = Const.COLLISION_RADIUS * Const.COLLISION_RADIUS
	for coord_variant: Variant in chunk_nodes.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var chunk_node: Chunk = chunk_nodes[coord] as Chunk
		var enable_collision: bool = (coord - center_chunk).length_squared() <= radius_squared
		chunk_node.set_collision_enabled(enable_collision)

func _refresh_streaming_queues(center_chunk: Vector2i) -> void:
	_stream_center_chunk = center_chunk
	_data_queue = _build_circle_queue(center_chunk, render_distance + 1, chunks)
	_mesh_queue = _build_circle_queue(center_chunk, render_distance, meshed_chunks)

func _build_circle_queue(center_chunk: Vector2i, radius: int, already_present: Dictionary) -> Array[Vector2i]:
	var queue: Array[Vector2i] = []
	for dz: int in range(-radius, radius + 1):
		for dx: int in range(-radius, radius + 1):
			if dx * dx + dz * dz > radius * radius:
				continue
			var coord: Vector2i = center_chunk + Vector2i(dx, dz)
			if not already_present.has(coord):
				queue.append(coord)
	queue.sort_custom(_coord_before)
	return queue

func _coord_before(a: Vector2i, b: Vector2i) -> bool:
	var distance_a: int = (a - _stream_center_chunk).length_squared()
	var distance_b: int = (b - _stream_center_chunk).length_squared()
	if distance_a == distance_b:
		if a.x == b.x:
			return a.y < b.y
		return a.x < b.x
	return distance_a < distance_b

func _process_one_data_chunk() -> void:
	if _data_queue.is_empty():
		return
	var coord: Vector2i = _data_queue.pop_front()
	ensure_chunk(coord.x, coord.y)

func _process_one_mesh_chunk() -> void:
	if _mesh_queue.is_empty():
		return
	var coord: Vector2i = _mesh_queue.pop_front()
	if not remesh(coord):
		_mesh_queue.append(coord)

func _unload_distant_chunks(center_chunk: Vector2i) -> void:
	var unload_radius: int = render_distance + Const.UNLOAD_MARGIN
	var unload_radius_squared: int = unload_radius * unload_radius
	for coord_variant: Variant in chunks.keys():
		var coord: Vector2i = coord_variant as Vector2i
		if (coord - center_chunk).length_squared() <= unload_radius_squared:
			continue

		var data: ChunkData = chunks[coord] as ChunkData
		if data.modified and not modified_chunks.has(data):
			modified_chunks.append(data)
		var chunk_node: Chunk = chunk_nodes.get(coord) as Chunk
		if chunk_node != null:
			chunk_node.queue_free()
		chunk_nodes.erase(coord)
		chunks.erase(coord)
		meshed_chunks.erase(coord)

func _take_modified_chunk(coord: Vector2i) -> ChunkData:
	for index: int in range(modified_chunks.size()):
		if modified_chunks[index].coord == coord:
			return modified_chunks.pop_at(index)
	return null

func get_block(wx: int, wy: int, wz: int) -> int:
	if wy < 0:
		return Blocks.BEDROCK
	if wy >= Const.CHUNK_HEIGHT:
		return Blocks.AIR

	var chunk_coord: Vector2i = Coords.world_to_chunk(wx, wz)
	var chunk_data: ChunkData = get_chunk_data(chunk_coord)
	if chunk_data == null:
		return Blocks.AIR

	var local_pos: Vector2i = Coords.world_to_local(wx, wz)
	return chunk_data.get_block(local_pos.x, wy, local_pos.y)

func set_block(wx: int, wy: int, wz: int, id: int) -> void:
	if wy < 0 or wy >= Const.CHUNK_HEIGHT:
		return
	var chunk_coord: Vector2i = Coords.world_to_chunk(wx, wz)
	var chunk_data: ChunkData = get_chunk_data(chunk_coord)
	if chunk_data == null:
		return

	var local_pos: Vector2i = Coords.world_to_local(wx, wz)
	var previous_version: int = chunk_data.mesh_version
	chunk_data.set_block(local_pos.x, wy, local_pos.y, id)
	if chunk_data.mesh_version == previous_version:
		return
	_mark_chunk_dirty(chunk_coord)
	if local_pos.x == 0:
		_mark_chunk_dirty(chunk_coord + Vector2i(-1, 0))
	elif local_pos.x == Const.CHUNK_SIZE - 1:
		_mark_chunk_dirty(chunk_coord + Vector2i(1, 0))
	if local_pos.y == 0:
		_mark_chunk_dirty(chunk_coord + Vector2i(0, -1))
	elif local_pos.y == Const.CHUNK_SIZE - 1:
		_mark_chunk_dirty(chunk_coord + Vector2i(0, 1))

func _mark_chunk_dirty(coord: Vector2i) -> void:
	if chunks.has(coord) and chunk_nodes.has(coord):
		_dirty_chunks[coord] = true

func _process_one_dirty_chunk() -> void:
	if _dirty_chunks.is_empty():
		return
	for coord_variant: Variant in _dirty_chunks.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var chunk_data: ChunkData = chunks.get(coord) as ChunkData
		if chunk_data == null:
			_dirty_chunks.erase(coord)
			_pending_dirty_meshes.erase(coord)
			continue
		var pending: Dictionary = _pending_dirty_meshes.get(coord, {}) as Dictionary
		if not pending.is_empty() and int(pending["version"]) == chunk_data.mesh_version:
			continue
		var build_info: Dictionary = _build_mesh_info(coord)
		if build_info.is_empty():
			continue
		last_mesh_build_usec = int(build_info["usec"])
		_pending_dirty_meshes[coord] = build_info
		break

	for coord_variant: Variant in _dirty_chunks.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var chunk_data: ChunkData = chunks.get(coord) as ChunkData
		var pending: Dictionary = _pending_dirty_meshes.get(coord, {}) as Dictionary
		if chunk_data == null or pending.is_empty() or int(pending["version"]) != chunk_data.mesh_version:
			return

	for coord_variant: Variant in _dirty_chunks.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var chunk_node: Chunk = chunk_nodes.get(coord) as Chunk
		if chunk_node == null:
			continue
		var pending: Dictionary = _pending_dirty_meshes[coord] as Dictionary
		chunk_node.apply_mesh(pending["mesh"])
		meshed_chunks[coord] = true
	_dirty_chunks.clear()
	_pending_dirty_meshes.clear()

func get_chunk_data(c: Vector2i) -> ChunkData:
	return chunks.get(c) as ChunkData

func is_chunk_loaded(c: Vector2i) -> bool:
	return chunks.has(c)
