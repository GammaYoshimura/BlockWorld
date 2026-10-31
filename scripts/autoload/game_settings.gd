extends Node

var world_seed: int = 0
var render_distance: int = Const.DEFAULT_RENDER_DISTANCE
var world_name: String = ""
var pending_world_data: Dictionary = {}

func resolve_world_seed() -> int:
	if world_seed == 0:
		world_seed = randi()
		if world_seed == 0:
			world_seed = 1
	return world_seed
