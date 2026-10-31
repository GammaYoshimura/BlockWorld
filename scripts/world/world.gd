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
var last_mesh_build_usec: int = 0

func ensure_chunk(cx: int, cz: int) -> ChunkData:
	var coord: Vector2i = Vector2i(cx, cz)
	if chunks.has(coord):
		return chunks[coord] as ChunkData

	var data: ChunkData = ChunkData.new(coord)
	data.fill_flat()
	chunks[coord] = data

	var chunk_node: Chunk = Chunk.new(coord)
	chunk_nodes[coord] = chunk_node
	add_child(chunk_node)
	return data

func remesh(coord: Vector2i) -> bool:
	last_mesh_build_usec = 0
	if not chunks.has(coord) or not chunk_nodes.has(coord):
		return false

	var neighbors: Dictionary = {}
	for offset: Vector2i in CHUNK_NEIGHBOR_OFFSETS:
		var neighbor_coord: Vector2i = coord + offset
		if not chunks.has(neighbor_coord):
			return false
		neighbors[offset] = chunks[neighbor_coord]

	var chunk_data: ChunkData = chunks[coord] as ChunkData
	var chunk_node: Chunk = chunk_nodes[coord] as Chunk
	var build_start_usec: int = Time.get_ticks_usec()
	var mesh_result: Dictionary = ChunkMesher.build(chunk_data, neighbors)
	last_mesh_build_usec = Time.get_ticks_usec() - build_start_usec
	chunk_node.apply_mesh(mesh_result)
	return true

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
	var chunk_coord: Vector2i = Coords.world_to_chunk(wx, wz)
	var chunk_data: ChunkData = get_chunk_data(chunk_coord)
	if chunk_data == null:
		return

	var local_pos: Vector2i = Coords.world_to_local(wx, wz)
	chunk_data.set_block(local_pos.x, wy, local_pos.y, id)

func get_chunk_data(c: Vector2i) -> ChunkData:
	return chunks.get(c) as ChunkData

func is_chunk_loaded(c: Vector2i) -> bool:
	return chunks.has(c)
