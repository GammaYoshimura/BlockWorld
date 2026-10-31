class_name WorldGenerator
extends RefCounted

var world_seed: int = 0

func _init(seed_value: int = 0) -> void:
	world_seed = seed_value

func generate(cx: int, cz: int) -> ChunkData:
	var data: ChunkData = ChunkData.new(Vector2i(cx, cz))
	data.fill_flat()
	data.generated = true
	return data
