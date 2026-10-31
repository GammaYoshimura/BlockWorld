class_name VoxelRaycast
extends RefCounted

static func cast(
	origin: Vector3,
	direction: Vector3,
	max_distance: float,
	block_getter: Callable
) -> Dictionary:
	if direction.is_zero_approx() or max_distance < 0.0 or not block_getter.is_valid():
		return _miss()

	var ray_direction: Vector3 = direction.normalized()
	var cell: Vector3i = Vector3i(
		floori(origin.x),
		floori(origin.y),
		floori(origin.z)
	)
	var previous_cell: Vector3i = cell
	var initial_id: int = int(block_getter.call(cell.x, cell.y, cell.z))
	if _is_target_block(initial_id):
		return _hit(cell, previous_cell, Vector3i.ZERO, 0.0, initial_id)

	var step_x: int = 1 if ray_direction.x > 0.0 else (-1 if ray_direction.x < 0.0 else 0)
	var step_y: int = 1 if ray_direction.y > 0.0 else (-1 if ray_direction.y < 0.0 else 0)
	var step_z: int = 1 if ray_direction.z > 0.0 else (-1 if ray_direction.z < 0.0 else 0)
	var delta_x: float = absf(1.0 / ray_direction.x) if step_x != 0 else INF
	var delta_y: float = absf(1.0 / ray_direction.y) if step_y != 0 else INF
	var delta_z: float = absf(1.0 / ray_direction.z) if step_z != 0 else INF
	var max_x: float = _first_boundary(origin.x, cell.x, ray_direction.x, step_x)
	var max_y: float = _first_boundary(origin.y, cell.y, ray_direction.y, step_y)
	var max_z: float = _first_boundary(origin.z, cell.z, ray_direction.z, step_z)
	var hit_normal: Vector3i = Vector3i.ZERO
	var distance: float = 0.0

	while true:
		previous_cell = cell
		if max_x <= max_y and max_x <= max_z:
			distance = max_x
			if distance > max_distance:
				break
			cell.x += step_x
			max_x += delta_x
			hit_normal = Vector3i(-step_x, 0, 0)
		elif max_y <= max_z:
			distance = max_y
			if distance > max_distance:
				break
			cell.y += step_y
			max_y += delta_y
			hit_normal = Vector3i(0, -step_y, 0)
		else:
			distance = max_z
			if distance > max_distance:
				break
			cell.z += step_z
			max_z += delta_z
			hit_normal = Vector3i(0, 0, -step_z)

		var block_id: int = int(block_getter.call(cell.x, cell.y, cell.z))
		if _is_target_block(block_id):
			return _hit(cell, previous_cell, hit_normal, distance, block_id)
	return _miss()

static func _first_boundary(origin_axis: float, cell_axis: int, direction_axis: float, step_axis: int) -> float:
	if step_axis > 0:
		return (float(cell_axis + 1) - origin_axis) / direction_axis
	if step_axis < 0:
		return (origin_axis - float(cell_axis)) / -direction_axis
	return INF

static func _is_target_block(block_id: int) -> bool:
	return block_id != Blocks.AIR and block_id != Blocks.WATER

static func _hit(
	block: Vector3i,
	previous: Vector3i,
	normal: Vector3i,
	distance: float,
	block_id: int
) -> Dictionary:
	return {
		"hit": true,
		"block": block,
		"prev": previous,
		"normal": normal,
		"distance": distance,
		"block_id": block_id
	}

static func _miss() -> Dictionary:
	return {
		"hit": false,
		"block": Vector3i.ZERO,
		"prev": Vector3i.ZERO,
		"normal": Vector3i.ZERO,
		"distance": INF,
		"block_id": Blocks.AIR
	}
