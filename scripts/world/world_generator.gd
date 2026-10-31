class_name WorldGenerator
extends RefCounted

var world_seed: int = 0
var _height_noise: FastNoiseLite

func _init(seed_value: int = 0) -> void:
	world_seed = seed_value
	_height_noise = FastNoiseLite.new()
	_height_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_height_noise.frequency = 0.01
	_height_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_height_noise.fractal_octaves = 4
	_height_noise.seed = world_seed

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
				data.set_block(local_x, y, local_z, Blocks.STONE)
			for y: int in range(height - 3, height):
				data.set_block(local_x, y, local_z, Blocks.DIRT)
			var is_beach: bool = height <= Const.SEA_LEVEL + 2
			if is_beach:
				for y: int in range(height - 2, height + 1):
					data.set_block(local_x, y, local_z, Blocks.SAND)
			else:
				data.set_block(local_x, height, local_z, Blocks.GRASS)
	data.generated = true
	data.modified = false
	return data
