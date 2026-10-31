class_name World
extends Node3D

var chunks: Dictionary = {}

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
