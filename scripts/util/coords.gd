class_name Coords

static func world_to_chunk(wx: int, wz: int) -> Vector2i:
	var cx: int = floori(float(wx) / float(Const.CHUNK_SIZE))
	var cz: int = floori(float(wz) / float(Const.CHUNK_SIZE))
	return Vector2i(cx, cz)

static func world_to_local(wx: int, wz: int) -> Vector2i:
	var local_x: int = posmod(wx, Const.CHUNK_SIZE)
	var local_z: int = posmod(wz, Const.CHUNK_SIZE)
	return Vector2i(local_x, local_z)

static func pos_to_block(p: Vector3) -> Vector3i:
	return Vector3i(floori(p.x), floori(p.y), floori(p.z))

static func chunk_origin(c: Vector2i) -> Vector3:
	return Vector3(float(c.x * Const.CHUNK_SIZE), 0.0, float(c.y * Const.CHUNK_SIZE))
