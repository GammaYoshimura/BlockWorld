extends RefCounted

static func run(
	coord: Vector2i,
	data_snapshot: ChunkData,
	neighbor_snapshots: Dictionary,
	version_snapshot: Dictionary,
	purpose: String,
	result_queue: RefCounted
) -> void:
	var start_usec: int = Time.get_ticks_usec()
	var mesh_data: Dictionary = ChunkMesher.build(data_snapshot, neighbor_snapshots)
	result_queue.call("push_result", {
		"coord": coord,
		"mesh": mesh_data,
		"versions": version_snapshot,
		"purpose": purpose,
		"usec": Time.get_ticks_usec() - start_usec
	})
