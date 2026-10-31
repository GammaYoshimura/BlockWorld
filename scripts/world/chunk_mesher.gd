class_name ChunkMesher
extends RefCounted

const FACES: Array[int] = [
	Blocks.Face.TOP,
	Blocks.Face.BOTTOM,
	Blocks.Face.EAST,
	Blocks.Face.WEST,
	Blocks.Face.SOUTH,
	Blocks.Face.NORTH
]
const FACE_BRIGHTNESS: Array[float] = [1.0, 0.5, 0.6, 0.6, 0.8, 0.8]

static func build(data: ChunkData, neighbors: Dictionary) -> Dictionary:
	var solid_builder: MeshBuilder = MeshBuilder.new()
	var water_builder: MeshBuilder = MeshBuilder.new()
	var blocks: PackedByteArray = data.blocks
	var west_data: ChunkData = neighbors.get(Vector2i(-1, 0)) as ChunkData
	var east_data: ChunkData = neighbors.get(Vector2i(1, 0)) as ChunkData
	var north_data: ChunkData = neighbors.get(Vector2i(0, -1)) as ChunkData
	var south_data: ChunkData = neighbors.get(Vector2i(0, 1)) as ChunkData
	var west_blocks: PackedByteArray = west_data.blocks if west_data != null else PackedByteArray()
	var east_blocks: PackedByteArray = east_data.blocks if east_data != null else PackedByteArray()
	var north_blocks: PackedByteArray = north_data.blocks if north_data != null else PackedByteArray()
	var south_blocks: PackedByteArray = south_data.blocks if south_data != null else PackedByteArray()
	var blocks_per_layer: int = Const.CHUNK_SIZE * Const.CHUNK_SIZE
	var size_mask: int = Const.CHUNK_SIZE - 1
	var target_builder: MeshBuilder
	for block_index: int in range(blocks.size()):
		var block_id: int = int(blocks[block_index])
		if block_id == Blocks.AIR:
			continue

		var x: int = block_index & size_mask
		var z: int = (block_index >> 4) & size_mask
		var y: int = block_index >> 8
		var local_pos: Vector3i = Vector3i(x, y, z)
		target_builder = water_builder if block_id == Blocks.WATER else solid_builder

		var neighbor_id: int = Blocks.AIR
		if y + 1 < Const.CHUNK_HEIGHT:
			neighbor_id = int(blocks[block_index + blocks_per_layer])
		if neighbor_id == Blocks.AIR or (neighbor_id != block_id and not Blocks.is_opaque(neighbor_id)):
			target_builder.add_face(local_pos, Blocks.Face.TOP, Blocks.tile_for_face(block_id, Blocks.Face.TOP), FACE_BRIGHTNESS[0])

		neighbor_id = Blocks.BEDROCK if y == 0 else int(blocks[block_index - blocks_per_layer])
		if neighbor_id == Blocks.AIR or (neighbor_id != block_id and not Blocks.is_opaque(neighbor_id)):
			target_builder.add_face(local_pos, Blocks.Face.BOTTOM, Blocks.tile_for_face(block_id, Blocks.Face.BOTTOM), FACE_BRIGHTNESS[1])

		if x + 1 < Const.CHUNK_SIZE:
			neighbor_id = int(blocks[block_index + 1])
		elif east_data != null:
			neighbor_id = int(east_blocks[block_index - size_mask])
		else:
			neighbor_id = Blocks.AIR
		if neighbor_id == Blocks.AIR or (neighbor_id != block_id and not Blocks.is_opaque(neighbor_id)):
			target_builder.add_face(local_pos, Blocks.Face.EAST, Blocks.tile_for_face(block_id, Blocks.Face.EAST), FACE_BRIGHTNESS[2])

		if x > 0:
			neighbor_id = int(blocks[block_index - 1])
		elif west_data != null:
			neighbor_id = int(west_blocks[block_index + size_mask])
		else:
			neighbor_id = Blocks.AIR
		if neighbor_id == Blocks.AIR or (neighbor_id != block_id and not Blocks.is_opaque(neighbor_id)):
			target_builder.add_face(local_pos, Blocks.Face.WEST, Blocks.tile_for_face(block_id, Blocks.Face.WEST), FACE_BRIGHTNESS[3])

		if z + 1 < Const.CHUNK_SIZE:
			neighbor_id = int(blocks[block_index + Const.CHUNK_SIZE])
		elif south_data != null:
			neighbor_id = int(south_blocks[block_index - (size_mask * Const.CHUNK_SIZE)])
		else:
			neighbor_id = Blocks.AIR
		if neighbor_id == Blocks.AIR or (neighbor_id != block_id and not Blocks.is_opaque(neighbor_id)):
			target_builder.add_face(local_pos, Blocks.Face.SOUTH, Blocks.tile_for_face(block_id, Blocks.Face.SOUTH), FACE_BRIGHTNESS[4])

		if z > 0:
			neighbor_id = int(blocks[block_index - Const.CHUNK_SIZE])
		elif north_data != null:
			neighbor_id = int(north_blocks[block_index + (size_mask * Const.CHUNK_SIZE)])
		else:
			neighbor_id = Blocks.AIR
		if neighbor_id == Blocks.AIR or (neighbor_id != block_id and not Blocks.is_opaque(neighbor_id)):
			target_builder.add_face(local_pos, Blocks.Face.NORTH, Blocks.tile_for_face(block_id, Blocks.Face.NORTH), FACE_BRIGHTNESS[5])

	return {
		"solid": solid_builder,
		"water": water_builder
	}

static func _get_neighbor_block(
	data: ChunkData,
	neighbors: Dictionary,
	x: int,
	y: int,
	z: int
) -> int:
	if y < 0:
		return Blocks.BEDROCK
	if y >= Const.CHUNK_HEIGHT:
		return Blocks.AIR

	var neighbor_coord: Vector2i = Vector2i.ZERO
	var neighbor_x: int = x
	var neighbor_z: int = z
	if x < 0:
		neighbor_coord = Vector2i(-1, 0)
		neighbor_x = Const.CHUNK_SIZE - 1
	elif x >= Const.CHUNK_SIZE:
		neighbor_coord = Vector2i(1, 0)
		neighbor_x = 0
	elif z < 0:
		neighbor_coord = Vector2i(0, -1)
		neighbor_z = Const.CHUNK_SIZE - 1
	elif z >= Const.CHUNK_SIZE:
		neighbor_coord = Vector2i(0, 1)
		neighbor_z = 0
	else:
		return data.get_block(x, y, z)

	var neighbor_data: ChunkData = neighbors.get(neighbor_coord) as ChunkData
	if neighbor_data == null:
		return Blocks.AIR
	return neighbor_data.get_block(neighbor_x, y, neighbor_z)

static func _face_visible(block_id: int, neighbor_id: int) -> bool:
	if neighbor_id == Blocks.AIR:
		return true
	if block_id == neighbor_id:
		return false
	if Blocks.is_opaque(neighbor_id):
		return false
	return true

static func _face_offset(face: int) -> Vector3i:
	match face:
		Blocks.Face.TOP:
			return Vector3i(0, 1, 0)
		Blocks.Face.BOTTOM:
			return Vector3i(0, -1, 0)
		Blocks.Face.EAST:
			return Vector3i(1, 0, 0)
		Blocks.Face.WEST:
			return Vector3i(-1, 0, 0)
		Blocks.Face.SOUTH:
			return Vector3i(0, 0, 1)
		Blocks.Face.NORTH:
			return Vector3i(0, 0, -1)
		_:
			return Vector3i.ZERO
