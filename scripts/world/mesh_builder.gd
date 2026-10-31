class_name MeshBuilder
extends RefCounted

var vertices: PackedVector3Array = PackedVector3Array()
var normals: PackedVector3Array = PackedVector3Array()
var uvs: PackedVector2Array = PackedVector2Array()
var colors: PackedColorArray = PackedColorArray()
var indices: PackedInt32Array = PackedInt32Array()

static var FACE_VERTICES: Array[PackedVector3Array] = [
	PackedVector3Array([
		Vector3(0, 1, 0), Vector3(1, 1, 0),
		Vector3(1, 1, 1), Vector3(0, 1, 1)
	]),
	PackedVector3Array([
		Vector3(0, 0, 1), Vector3(1, 0, 1),
		Vector3(1, 0, 0), Vector3(0, 0, 0)
	]),
	PackedVector3Array([
		Vector3(1, 1, 1), Vector3(1, 1, 0),
		Vector3(1, 0, 0), Vector3(1, 0, 1)
	]),
	PackedVector3Array([
		Vector3(0, 1, 0), Vector3(0, 1, 1),
		Vector3(0, 0, 1), Vector3(0, 0, 0)
	]),
	PackedVector3Array([
		Vector3(0, 1, 1), Vector3(1, 1, 1),
		Vector3(1, 0, 1), Vector3(0, 0, 1)
	]),
	PackedVector3Array([
		Vector3(1, 1, 0), Vector3(0, 1, 0),
		Vector3(0, 0, 0), Vector3(1, 0, 0)
	])
]
static var FACE_NORMALS: Array[Vector3] = [
	Vector3(0, 1, 0),
	Vector3(0, -1, 0),
	Vector3(1, 0, 0),
	Vector3(-1, 0, 0),
	Vector3(0, 0, 1),
	Vector3(0, 0, -1)
]

func add_face(local_pos: Vector3i, face: int, tile: int, brightness: float) -> void:
	if face < 0 or face >= FACE_VERTICES.size():
		return

	var face_vertices: PackedVector3Array = FACE_VERTICES[face]
	var normal: Vector3 = FACE_NORMALS[face]
	var first_vertex: int = vertices.size()
	var tile_column: int = posmod(tile, Const.ATLAS_TILES)
	var tile_row: int = floori(float(tile) / float(Const.ATLAS_TILES))
	var tile_size: float = 1.0 / float(Const.ATLAS_TILES)
	var u0: float = float(tile_column) * tile_size + Const.UV_EPSILON
	var v0: float = float(tile_row) * tile_size + Const.UV_EPSILON
	var u1: float = float(tile_column + 1) * tile_size - Const.UV_EPSILON
	var v1: float = float(tile_row + 1) * tile_size - Const.UV_EPSILON
	var vertex_color: Color = Color(brightness, brightness, brightness, 1.0)
	var local_offset: Vector3 = Vector3(local_pos)
	for vertex_index: int in range(4):
		vertices.append(face_vertices[vertex_index] + local_offset)
		normals.append(normal)
		colors.append(vertex_color)
		match vertex_index:
			0:
				uvs.append(Vector2(u0, v0))
			1:
				uvs.append(Vector2(u1, v0))
			2:
				uvs.append(Vector2(u1, v1))
			3:
				uvs.append(Vector2(u0, v1))

	indices.append(first_vertex)
	indices.append(first_vertex + 1)
	indices.append(first_vertex + 2)
	indices.append(first_vertex)
	indices.append(first_vertex + 2)
	indices.append(first_vertex + 3)

func is_empty() -> bool:
	return vertices.is_empty()

func face_count() -> int:
	return floori(float(indices.size()) / 6.0)

func to_arrays() -> Array:
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	return arrays
