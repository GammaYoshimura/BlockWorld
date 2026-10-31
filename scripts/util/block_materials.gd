class_name BlockMaterials

static var _solid_material: StandardMaterial3D

static func solid() -> StandardMaterial3D:
	if _solid_material == null:
		_solid_material = StandardMaterial3D.new()
		_solid_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_solid_material.vertex_color_use_as_albedo = true
		_solid_material.albedo_texture = AtlasBuilder.build()
		_solid_material.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
		_solid_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		_solid_material.alpha_scissor_threshold = 0.5
		_solid_material.cull_mode = BaseMaterial3D.CULL_BACK
	return _solid_material
