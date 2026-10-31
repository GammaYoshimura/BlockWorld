class_name WorldGenerator
extends RefCounted

var world_seed: int = 0
var _height_noise: FastNoiseLite
var _cave_noise: FastNoiseLite

func _init(seed_value: int = 0) -> void:
	world_seed = seed_value
	_height_noise = FastNoiseLite.new()
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height_noise.frequency = 0.01
	_height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_height_noise.fractal_octaves = 4
	_height_noise.seed = world_seed
	_cave_noise = FastNoiseLite.new()
	_cave_noise.frequency = 0.05
	_cave_noise.seed = world_seed + 1

func height_at(wx: int, wz: int) -> int:
	var noise_value: float = _height_noise.get_noise_2d(float(wx), float(wz))
	var height: int = Const.BASE_HEIGHT + roundi(noise_value * float(Const.HEIGHT_AMPLITUDE))
	return clampi(height, 4, 60)

func generate(cx: int, cz: int) -> ChunkData:
	var data: ChunkData = ChunkData.new(Vector2i(cx, cz))
	for local_z: int in range(Const.CHUNK_SIZE):
		for local_x: int in range(Const.CHUNK_SIZE):
			var world_x: int = cx * Const.CHUNK_SIZE + local_x
			var world_z: int = cz * Const.CHUNK_SIZE + local_z
			var height: int = height_at(world_x, world_z)
			data.set_block(local_x, 0, local_z, Blocks.BEDROCK)
			for y: int in range(1, height - 3):
				var block_id: int = Blocks.AIR if _is_cave_at(world_x, y, world_z, height) else Blocks.STONE
				data.set_block(local_x, y, local_z, block_id)
			for y: int in range(height - 3, height):
				data.set_block(local_x, y, local_z, Blocks.DIRT)
			var is_beach: bool = height <= Const.SEA_LEVEL + 2
			if is_beach:
				for y: int in range(height - 2, height + 1):
					data.set_block(local_x, y, local_z, Blocks.SAND)
			else:
				data.set_block(local_x, height, local_z, Blocks.GRASS)
			if height < Const.SEA_LEVEL:
				for y: int in range(height + 1, Const.SEA_LEVEL + 1):
					data.set_block(local_x, y, local_z, Blocks.WATER)
	_generate_nearby_trees(data, cx, cz)
	data.generated = true
	data.modified = false
	return data

func _generate_nearby_trees(data: ChunkData, cx: int, cz: int) -> void:
	var origin_x: int = cx * Const.CHUNK_SIZE
	var origin_z: int = cz * Const.CHUNK_SIZE
	for candidate_z: int in range(origin_z - 2, origin_z + Const.CHUNK_SIZE + 2):
		for candidate_x: int in range(origin_x - 2, origin_x + Const.CHUNK_SIZE + 2):
			var ground_height: int = height_at(candidate_x, candidate_z)
			if ground_height <= Const.SEA_LEVEL + 2:
				continue
			var rng: RandomNumberGenerator = RandomNumberGenerator.new()
			rng.seed = _hash_combo(world_seed, candidate_x, candidate_z)
			if rng.randf() >= 0.012:
				continue

			var trunk_height: int = rng.randi_range(4, 6)
			var canopy_base_y: int = ground_height + trunk_height - 2
			for layer: int in range(2):
				for dz: int in range(-2, 3):
					for dx: int in range(-2, 3):
						if absi(dx) == 2 and absi(dz) == 2:
							continue
						_place_tree_block(data, cx, cz, candidate_x + dx, canopy_base_y + layer, candidate_z + dz, Blocks.LEAVES)
			for layer: int in range(2, 4):
				for dz: int in range(-1, 2):
					for dx: int in range(-1, 2):
						_place_tree_block(data, cx, cz, candidate_x + dx, canopy_base_y + layer, candidate_z + dz, Blocks.LEAVES)
			for trunk_offset: int in range(1, trunk_height + 1):
				_place_tree_block(data, cx, cz, candidate_x, ground_height + trunk_offset, candidate_z, Blocks.LOG)

func _place_tree_block(
	data: ChunkData,
	cx: int,
	cz: int,
	world_x: int,
	y: int,
	world_z: int,
	block_id: int
) -> void:
	if y < 0 or y >= Const.CHUNK_HEIGHT:
		return
	var local_x: int = world_x - cx * Const.CHUNK_SIZE
	var local_z: int = world_z - cz * Const.CHUNK_SIZE
	if local_x < 0 or local_x >= Const.CHUNK_SIZE or local_z < 0 or local_z >= Const.CHUNK_SIZE:
		return
	var existing_block: int = data.get_block(local_x, y, local_z)
	if existing_block == Blocks.AIR or existing_block == Blocks.LEAVES:
		data.set_block(local_x, y, local_z, block_id)

static func _hash_combo(seed_value: int, wx: int, wz: int) -> int:
	const UINT_MASK: int = 0xFFFFFFFF
	var value: int = (seed_value ^ ((wx * 73856093) & UINT_MASK) ^ ((wz * 19349663) & UINT_MASK)) & UINT_MASK
	value = (value ^ (value >> 16)) & UINT_MASK
	value = (value * 1597334677) & UINT_MASK
	value = (value ^ (value >> 13)) & UINT_MASK
	value = (value * 1540483477) & UINT_MASK
	value = (value ^ (value >> 15)) & UINT_MASK
	return value & 0x7FFFFFFF

func _is_cave_at(wx: int, y: int, wz: int, surface_height: int) -> bool:
	if y < 5 or y >= surface_height - 4:
		return false
	return _cave_noise.get_noise_3d(float(wx), float(y), float(wz)) > 0.55
