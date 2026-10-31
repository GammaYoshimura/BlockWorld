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
	data.fill_flat()
	data.generated = true
	return data
