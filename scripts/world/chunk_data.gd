class_name ChunkData
extends RefCounted

var coord: Vector2i = Vector2i.ZERO
var blocks: PackedByteArray = PackedByteArray()
var generated: bool = false
var modified: bool = false
var mesh_version: int = 0

func _init(chunk_coord: Vector2i = Vector2i.ZERO) -> void:
	coord = chunk_coord
	blocks.resize(Const.CHUNK_SIZE * Const.CHUNK_HEIGHT * Const.CHUNK_SIZE)

static func index(x: int, y: int, z: int) -> int:
	return x + z * Const.CHUNK_SIZE + y * Const.CHUNK_SIZE * Const.CHUNK_SIZE

func get_block(x: int, y: int, z: int) -> int:
	if y < 0 or y >= Const.CHUNK_HEIGHT:
		return Blocks.AIR
	if x < 0 or x >= Const.CHUNK_SIZE:
		push_error("ChunkData.get_block: x fuera de rango") # DEBUG-M2.03
		return Blocks.AIR
	if z < 0 or z >= Const.CHUNK_SIZE:
		push_error("ChunkData.get_block: z fuera de rango") # DEBUG-M2.03
		return Blocks.AIR
	return int(blocks[index(x, y, z)])

func set_block(x: int, y: int, z: int, id: int) -> void:
	if x < 0 or x >= Const.CHUNK_SIZE:
		push_error("ChunkData.set_block: x fuera de rango") # DEBUG-M2.03
		return
	if y < 0 or y >= Const.CHUNK_HEIGHT:
		push_error("ChunkData.set_block: y fuera de rango") # DEBUG-M2.03
		return
	if z < 0 or z >= Const.CHUNK_SIZE:
		push_error("ChunkData.set_block: z fuera de rango") # DEBUG-M2.03
		return

	var block_index: int = index(x, y, z)
	if int(blocks[block_index]) == id:
		return
	blocks[block_index] = id
	mesh_version += 1
	modified = true

func fill_flat() -> void:
	for z: int in range(Const.CHUNK_SIZE):
		for x: int in range(Const.CHUNK_SIZE):
			set_block(x, 0, z, Blocks.BEDROCK)
			for y: int in range(1, 18):
				set_block(x, y, z, Blocks.STONE)
			for y: int in range(18, 20):
				set_block(x, y, z, Blocks.DIRT)
			set_block(x, 20, z, Blocks.GRASS)
