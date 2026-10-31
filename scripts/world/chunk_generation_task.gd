extends RefCounted

static func run(world_seed: int, coord: Vector2i, result_queue: RefCounted) -> void:
	# Every worker owns its noise generators; FastNoiseLite instances are not shared across threads.
	var generator: WorldGenerator = WorldGenerator.new(world_seed)
	var chunk_data: ChunkData = generator.generate(coord.x, coord.y)
	result_queue.call("push_result", {"coord": coord, "data": chunk_data})
