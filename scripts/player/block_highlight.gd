class_name BlockHighlight
extends MeshInstance3D

var camera: Camera3D
var world: World

func _init() -> void:
	name = "BlockHighlight"
	mesh = _build_wire_cube()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	material_override = _build_material()
	visible = false

func _process(_delta: float) -> void:
	if camera == null or world == null:
		visible = false
		return
	var hit: Dictionary = VoxelRaycast.cast(
		camera.global_position,
		-camera.global_transform.basis.z,
		Const.PLAYER_REACH,
		Callable(world, "get_block")
	)
	visible = bool(hit["hit"])
	if visible:
		global_position = Vector3(hit["block"])

static func _build_wire_cube() -> ArrayMesh:
	var mesh_arrays: Array = []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	var vertices: PackedVector3Array = PackedVector3Array([
		Vector3(-0.002, -0.002, -0.002), Vector3(1.002, -0.002, -0.002),
		Vector3(1.002, -0.002, -0.002), Vector3(1.002, -0.002, 1.002),
		Vector3(1.002, -0.002, 1.002), Vector3(-0.002, -0.002, 1.002),
		Vector3(-0.002, -0.002, 1.002), Vector3(-0.002, -0.002, -0.002),
		Vector3(-0.002, 1.002, -0.002), Vector3(1.002, 1.002, -0.002),
		Vector3(1.002, 1.002, -0.002), Vector3(1.002, 1.002, 1.002),
		Vector3(1.002, 1.002, 1.002), Vector3(-0.002, 1.002, 1.002),
		Vector3(-0.002, 1.002, 1.002), Vector3(-0.002, 1.002, -0.002),
		Vector3(-0.002, -0.002, -0.002), Vector3(-0.002, 1.002, -0.002),
		Vector3(1.002, -0.002, -0.002), Vector3(1.002, 1.002, -0.002),
		Vector3(1.002, -0.002, 1.002), Vector3(1.002, 1.002, 1.002),
		Vector3(-0.002, -0.002, 1.002), Vector3(-0.002, 1.002, 1.002)
	])
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	var wire_mesh: ArrayMesh = ArrayMesh.new()
	wire_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, mesh_arrays)
	return wire_mesh

static func _build_material() -> StandardMaterial3D:
	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.02, 0.02, 0.02, 1.0)
	return material
