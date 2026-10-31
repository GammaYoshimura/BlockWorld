class_name Chunk
extends Node3D

var coord: Vector2i = Vector2i.ZERO
var _solid_mesh: MeshInstance3D
var _water_mesh: MeshInstance3D

func _init(chunk_coord: Vector2i = Vector2i.ZERO) -> void:
	coord = chunk_coord
	position = Coords.chunk_origin(coord)
	name = "Chunk_%d_%d" % [coord.x, coord.y]

	_solid_mesh = MeshInstance3D.new()
	_solid_mesh.name = "SolidMesh"
	_solid_mesh.custom_aabb = _chunk_aabb()
	_solid_mesh.material_override = BlockMaterials.solid()
	add_child(_solid_mesh)

	_water_mesh = MeshInstance3D.new()
	_water_mesh.name = "WaterMesh"
	_water_mesh.custom_aabb = _chunk_aabb()
	add_child(_water_mesh)

func apply_mesh(result: Dictionary) -> void:
	var solid_builder: MeshBuilder = result.get("solid") as MeshBuilder
	var water_builder: MeshBuilder = result.get("water") as MeshBuilder
	_apply_builder(_solid_mesh, solid_builder)
	_apply_builder(_water_mesh, water_builder)

func _apply_builder(mesh_instance: MeshInstance3D, builder: MeshBuilder) -> void:
	if builder == null or builder.is_empty():
		mesh_instance.mesh = null
		return

	var array_mesh: ArrayMesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, builder.to_arrays())
	mesh_instance.mesh = array_mesh

func _chunk_aabb() -> AABB:
	return AABB(
		Vector3.ZERO,
		Vector3(
			float(Const.CHUNK_SIZE),
			float(Const.CHUNK_HEIGHT),
			float(Const.CHUNK_SIZE)
		)
	)
