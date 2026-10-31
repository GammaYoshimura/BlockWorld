class_name Chunk
extends Node3D

var coord: Vector2i = Vector2i.ZERO
var _solid_mesh: MeshInstance3D
var _water_mesh: MeshInstance3D
var _static_body: StaticBody3D
var _collision_shape: CollisionShape3D
var _collision_enabled: bool = false

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
	_water_mesh.material_override = BlockMaterials.water()
	add_child(_water_mesh)

	_static_body = StaticBody3D.new()
	_static_body.name = "StaticBody3D"
	_static_body.collision_layer = 1
	_static_body.collision_mask = 0
	add_child(_static_body)

	_collision_shape = CollisionShape3D.new()
	_collision_shape.name = "CollisionShape3D"
	_static_body.add_child(_collision_shape)

func apply_mesh(result: Dictionary) -> void:
	var solid_builder: MeshBuilder = result.get("solid") as MeshBuilder
	var water_builder: MeshBuilder = result.get("water") as MeshBuilder
	_apply_builder(_solid_mesh, solid_builder)
	_apply_builder(_water_mesh, water_builder)
	if _collision_enabled:
		_refresh_collision_shape()

func set_collision_enabled(enabled: bool) -> void:
	if _collision_enabled == enabled:
		return
	_collision_enabled = enabled
	_refresh_collision_shape()

func has_collision() -> bool:
	return _collision_enabled and _collision_shape.shape != null

func _refresh_collision_shape() -> void:
	if not _collision_enabled or _solid_mesh.mesh == null:
		_collision_shape.shape = null
		return
	var trimesh_shape: ConcavePolygonShape3D = _solid_mesh.mesh.create_trimesh_shape()
	trimesh_shape.backface_collision = true
	_collision_shape.shape = trimesh_shape

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
