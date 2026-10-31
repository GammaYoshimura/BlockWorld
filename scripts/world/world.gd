class_name World
extends Node3D

const CHUNK_NEIGHBOR_OFFSETS: Array[Vector2i] = [
	Vector2i(-1, 0),
	Vector2i(1, 0),
	Vector2i(0, -1),
	Vector2i(0, 1)
]
const ChunkGenerationTask = preload("res://scripts/world/chunk_generation_task.gd")
const ChunkMeshTask = preload("res://scripts/world/chunk_mesh_task.gd")
const ThreadResultQueueScript = preload("res://scripts/util/thread_result_queue.gd")
const MAX_GENERATION_TASKS: int = 4
const MAX_MESH_TASKS: int = 4

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
var _generation_tasks: Dictionary = {}
var _generation_results: RefCounted = ThreadResultQueueScript.new()
var _mesh_tasks: Dictionary = {}
var _mesh_results: RefCounted = ThreadResultQueueScript.new()

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
	_register_chunk_data(data)
	return data

func _register_chunk_data(data: ChunkData) -> void:
	var coord: Vector2i = data.coord
	if chunks.has(coord):
		return
	var modified_data: ChunkData = _take_modified_chunk(coord)
	if modified_data != null:
		data = modified_data
	chunks[coord] = data

	var chunk_node: Chunk = Chunk.new(coord)
	chunk_nodes[coord] = chunk_node
	add_child(chunk_node)

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
	_process_generation_results()
	_process_mesh_results()
	_process_one_data_chunk()
	_process_one_mesh_chunk()
	_update_collision_range(center_chunk)
	_process_one_dirty_chunk()

func set_render_distance(distance: int) -> void:
	render_distance = clampi(distance, Const.MIN_RENDER_DISTANCE, Const.MAX_RENDER_DISTANCE)
	_stream_center_chunk = Vector2i(2147483647, 2147483647)

func get_pending_data_count() -> int:
	return _data_queue.size() + _generation_tasks.size()

func get_pending_mesh_count() -> int:
	return _mesh_queue.size() + _mesh_tasks.size()

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
	var disable_radius: int = Const.COLLISION_RADIUS + 1
	var disable_radius_squared: int = disable_radius * disable_radius
	for coord_variant: Variant in chunk_nodes.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var chunk_node: Chunk = chunk_nodes[coord] as Chunk
		var distance_squared: int = (coord - center_chunk).length_squared()
		var enable_collision: bool = distance_squared <= radius_squared
		if chunk_node.is_collision_enabled() and distance_squared <= disable_radius_squared:
			enable_collision = true
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
	if _data_queue.is_empty() or _generation_tasks.size() >= MAX_GENERATION_TASKS:
		return
	var coord: Vector2i = _data_queue.pop_front()
	if chunks.has(coord) or _is_generation_active(coord):
		return
	var task_id: int = WorkerThreadPool.add_task(
		Callable(ChunkGenerationTask, "run").bind(world_seed, coord, _generation_results),
		false,
		"Generate chunk %d,%d" % [coord.x, coord.y]
	)
	_generation_tasks[task_id] = coord

func _process_generation_results() -> void:
	for task_id_variant: Variant in _generation_tasks.keys():
		var task_id: int = int(task_id_variant)
		if WorkerThreadPool.is_task_completed(task_id):
			WorkerThreadPool.wait_for_task_completion(task_id)
			_generation_tasks.erase(task_id)
	var results: Array = _generation_results.call("pop_all")
	for result_variant: Variant in results:
		var result: Dictionary = result_variant as Dictionary
		var data: ChunkData = result["data"] as ChunkData
		if _is_in_data_range(data.coord):
			_register_chunk_data(data)

func _is_generation_active(coord: Vector2i) -> bool:
	return _generation_tasks.values().has(coord)

func _is_in_data_range(coord: Vector2i) -> bool:
	var radius: int = render_distance + 1
	return (coord - _stream_center_chunk).length_squared() <= radius * radius

func _is_in_mesh_range(coord: Vector2i) -> bool:
	return (coord - _stream_center_chunk).length_squared() <= render_distance * render_distance

func _process_one_mesh_chunk() -> void:
	if _mesh_queue.is_empty():
		return
	var coord: Vector2i = _mesh_queue.pop_front()
	if meshed_chunks.has(coord) or _is_mesh_active(coord):
		return
	if _mesh_tasks.size() >= MAX_MESH_TASKS:
		_mesh_queue.push_front(coord)
		return
	if not _schedule_mesh_task(coord, "stream"):
		_mesh_queue.append(coord)

func _schedule_mesh_task(coord: Vector2i, purpose: String) -> bool:
	if _mesh_tasks.size() >= MAX_MESH_TASKS or _is_mesh_active(coord):
		return false
	var snapshot: Dictionary = _make_mesh_snapshot(coord)
	if snapshot.is_empty():
		return false
	var task_id: int = WorkerThreadPool.add_task(
		Callable(ChunkMeshTask, "run").bind(
			coord,
		snapshot["data"],
		snapshot["neighbors"],
		snapshot["versions"],
		purpose,
		_mesh_results
		),
		false,
		"Mesh chunk %d,%d" % [coord.x, coord.y]
	)
	_mesh_tasks[task_id] = {"coord": coord, "purpose": purpose}
	return true

func _make_mesh_snapshot(coord: Vector2i) -> Dictionary:
	var source: ChunkData = chunks.get(coord) as ChunkData
	if source == null or not chunk_nodes.has(coord):
		return {}
	var versions: Dictionary = {coord: source.mesh_version}
	var neighbors: Dictionary = {}
	for offset: Vector2i in CHUNK_NEIGHBOR_OFFSETS:
		var neighbor_coord: Vector2i = coord + offset
		var neighbor_source: ChunkData = chunks.get(neighbor_coord) as ChunkData
		if neighbor_source == null:
			return {}
		versions[neighbor_coord] = neighbor_source.mesh_version
		neighbors[offset] = _copy_chunk_data(neighbor_source)
	return {
		"data": _copy_chunk_data(source),
		"neighbors": neighbors,
		"versions": versions
	}

func _copy_chunk_data(source: ChunkData) -> ChunkData:
	var snapshot: ChunkData = ChunkData.new(source.coord)
	snapshot.blocks = source.blocks.duplicate()
	snapshot.generated = source.generated
	snapshot.modified = source.modified
	snapshot.mesh_version = source.mesh_version
	return snapshot

func _is_mesh_active(coord: Vector2i) -> bool:
	for task_variant: Variant in _mesh_tasks.values():
		if Vector2i(task_variant["coord"]) == coord:
			return true
	return false

func _mesh_versions_match(versions: Dictionary) -> bool:
	for coord_variant: Variant in versions.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var data: ChunkData = chunks.get(coord) as ChunkData
		if data == null or data.mesh_version != int(versions[coord]):
			return false
	return true

func _process_mesh_results() -> void:
	for task_id_variant: Variant in _mesh_tasks.keys():
		var task_id: int = int(task_id_variant)
		if WorkerThreadPool.is_task_completed(task_id):
			WorkerThreadPool.wait_for_task_completion(task_id)
			_mesh_tasks.erase(task_id)
	var results: Array = _mesh_results.call("pop_all")
	for result_variant: Variant in results:
		var result: Dictionary = result_variant as Dictionary
		var coord: Vector2i = result["coord"] as Vector2i
		if not _is_in_mesh_range(coord):
			if result["purpose"] == "dirty":
				_pending_dirty_meshes.erase(coord)
			continue
		if not _mesh_versions_match(result["versions"] as Dictionary):
			if result["purpose"] == "dirty":
				_pending_dirty_meshes.erase(coord)
			elif not _mesh_queue.has(coord) and not meshed_chunks.has(coord):
				_mesh_queue.append(coord)
			continue
		if result["purpose"] == "dirty":
			_pending_dirty_meshes[coord] = result
		else:
			_apply_mesh_result(coord, result)

func _apply_mesh_result(coord: Vector2i, result: Dictionary) -> void:
	var chunk_node: Chunk = chunk_nodes.get(coord) as Chunk
	if chunk_node == null:
		return
	chunk_node.apply_mesh(result["mesh"] as Dictionary)
	meshed_chunks[coord] = true
	last_mesh_build_usec = int(result["usec"])

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
		_dirty_chunks.erase(coord)
		_pending_dirty_meshes.erase(coord)
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
	var dirty_in_range: Array[Vector2i] = []
	for coord_variant: Variant in _dirty_chunks.keys():
		var coord: Vector2i = coord_variant as Vector2i
		var chunk_data: ChunkData = chunks.get(coord) as ChunkData
		if chunk_data == null:
			_dirty_chunks.erase(coord)
			_pending_dirty_meshes.erase(coord)
			continue
		if not _is_in_mesh_range(coord):
			continue
		dirty_in_range.append(coord)
		if _pending_dirty_meshes.has(coord):
			var pending: Dictionary = _pending_dirty_meshes[coord] as Dictionary
			if _mesh_versions_match(pending["versions"] as Dictionary):
				continue
			_pending_dirty_meshes.erase(coord)
		if not _is_mesh_active(coord):
			_schedule_mesh_task(coord, "dirty")

	if dirty_in_range.is_empty():
		return
	for coord: Vector2i in dirty_in_range:
		var pending: Dictionary = _pending_dirty_meshes.get(coord, {}) as Dictionary
		if pending.is_empty() or not _mesh_versions_match(pending["versions"] as Dictionary):
			return

	for coord: Vector2i in dirty_in_range:
		var chunk_node: Chunk = chunk_nodes.get(coord) as Chunk
		if chunk_node == null:
			continue
		var pending: Dictionary = _pending_dirty_meshes[coord] as Dictionary
		_apply_mesh_result(coord, pending)
		_dirty_chunks.erase(coord)
		_pending_dirty_meshes.erase(coord)

func get_chunk_data(c: Vector2i) -> ChunkData:
	return chunks.get(c) as ChunkData

func is_chunk_loaded(c: Vector2i) -> bool:
	return chunks.has(c)
