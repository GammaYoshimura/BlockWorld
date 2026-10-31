extends Node

const COORD_CASES: Array[Vector3i] = [
	Vector3i(0, 0, 0),
	Vector3i(15, 0, 15),
	Vector3i(16, 1, 0),
	Vector3i(31, 1, 15),
	Vector3i(-1, -1, 15),
	Vector3i(-16, -1, 0),
	Vector3i(-17, -2, 15),
	Vector3i(-32, -2, 0)
]

var _current_milestone: String = "M1.06"

func _ready() -> void:
	_test_world_to_chunk_and_local()
	_check(
		Coords.pos_to_block(Vector3(-0.1, 5.9, 3.0)) == Vector3i(-1, 5, 3),
		"pos_to_block negativo"
	)
	_check(
		Coords.pos_to_block(Vector3(0.0, 0.0, -0.0001)) == Vector3i(0, 0, -1),
		"pos_to_block frontera Z negativa"
	)
	_current_milestone = "M2.01"
	_test_blocks()
	_current_milestone = "M2.02"
	_test_chunk_data()
	_current_milestone = "M2.03"
	_test_chunk_data_bounds()
	_current_milestone = "M2.04"
	_test_flat_chunk()
	_current_milestone = "M2.05"
	_test_world()
	_current_milestone = "M3.02"
	_test_mesh_builder()
	_current_milestone = "M3.05"
	_test_chunk_mesher_flat()
	_test_chunk_mesher_neighbors()
	_current_milestone = "M3.07"
	_test_shared_block_material()
	_current_milestone = "M3.08"
	_test_atlas_builder()
	_current_milestone = "M3.09"
	_test_block_face_tiles()
	_current_milestone = "M3.10"
	_test_face_brightness()
	_current_milestone = "M3.11"
	_test_face_visibility()
	_current_milestone = "M4.01"
	_test_world_chunk_manager()
	_current_milestone = "M4.02"
	_test_world_generator_deterministic()

func _test_world_to_chunk_and_local() -> void:
	for test_case: Vector3i in COORD_CASES:
		var wx: int = test_case.x
		var expected_chunk: int = test_case.y
		var expected_local: int = test_case.z
		var label: String = str(wx)

		_check(
			Coords.world_to_chunk(wx, 0) == Vector2i(expected_chunk, 0),
			"world_to_chunk X " + label
		)
		_check(
			Coords.world_to_chunk(0, wx) == Vector2i(0, expected_chunk),
			"world_to_chunk Z " + label
		)
		_check(
			Coords.world_to_local(wx, 0) == Vector2i(expected_local, 0),
			"world_to_local X " + label
		)
		_check(
			Coords.world_to_local(0, wx) == Vector2i(0, expected_local),
			"world_to_local Z " + label
		)

func _test_blocks() -> void:
	_check(Blocks.is_opaque(Blocks.STONE), "is_opaque STONE")
	_check(not Blocks.is_opaque(Blocks.LEAVES), "is_opaque LEAVES")
	_check(not Blocks.is_opaque(Blocks.GLASS), "is_opaque GLASS")
	_check(not Blocks.is_opaque(Blocks.AIR), "is_opaque AIR")
	_check(not Blocks.is_solid(Blocks.WATER), "is_solid WATER")
	_check(Blocks.is_solid(Blocks.LEAVES), "is_solid LEAVES")
	_check(Blocks.name_of(Blocks.PLANKS) == "planks", "name_of PLANKS")
	_check(
		Blocks.tile_for_face(Blocks.GRASS, Blocks.Face.TOP) == 0,
		"tile GRASS TOP"
	)
	_check(
		Blocks.tile_for_face(Blocks.GRASS, Blocks.Face.BOTTOM) == 2,
		"tile GRASS BOTTOM"
	)
	_check(
		Blocks.tile_for_face(Blocks.GRASS, Blocks.Face.NORTH) == 1,
		"tile GRASS NORTH"
	)
	_check(
		Blocks.tile_for_face(Blocks.LOG, Blocks.Face.TOP) == 7,
		"tile LOG TOP"
	)
	_check(
		Blocks.tile_for_face(Blocks.LOG, Blocks.Face.EAST) == 6,
		"tile LOG EAST"
	)

func _test_chunk_data() -> void:
	var chunk_data: ChunkData = ChunkData.new()
	_check(ChunkData.index(0, 0, 0) == 0, "index origen")
	_check(ChunkData.index(15, 0, 0) == 15, "index esquina X")
	_check(ChunkData.index(0, 0, 15) == 240, "index esquina Z")
	_check(ChunkData.index(0, 1, 0) == 256, "index segunda capa")
	_check(ChunkData.index(15, 63, 15) == 16383, "index último bloque")
	_check(chunk_data.blocks.size() == 16384, "tamaño del array")
	chunk_data.set_block(3, 10, 5, Blocks.STONE)
	_check(chunk_data.get_block(3, 10, 5) == Blocks.STONE, "get tras set")
	_check(chunk_data.get_block(3, 10, 6) == Blocks.AIR, "bloque vecino sigue vacío")

func _test_chunk_data_bounds() -> void:
	var chunk_data: ChunkData = ChunkData.new()
	_check(chunk_data.get_block(0, 64, 0) == Blocks.AIR, "get y sobre el chunk")
	_check(chunk_data.get_block(0, -1, 0) == Blocks.AIR, "get y bajo el chunk")
	_check(chunk_data.get_block(-1, 0, 0) == Blocks.AIR, "get x fuera de rango")
	_check(chunk_data.get_block(0, 0, 16) == Blocks.AIR, "get z fuera de rango")

	var original_blocks: PackedByteArray = chunk_data.blocks.duplicate()
	chunk_data.set_block(0, 100, 0, Blocks.STONE)
	_check(chunk_data.blocks == original_blocks, "set y inválido no escribe")

	chunk_data.set_block(0, 0, 0, Blocks.AIR)
	_check(chunk_data.mesh_version == 0, "set mismo valor no incrementa mesh_version")
	_check(not chunk_data.modified, "set mismo valor no marca modified")

	chunk_data.set_block(3, 10, 5, Blocks.STONE)
	var changed_version: int = chunk_data.mesh_version
	chunk_data.set_block(3, 10, 5, Blocks.STONE)
	_check(chunk_data.mesh_version == changed_version, "set repetido conserva mesh_version")

func _test_flat_chunk() -> void:
	var chunk_data: ChunkData = ChunkData.new()
	chunk_data.fill_flat()
	var non_air_count: int = 0
	for block_id: int in chunk_data.blocks:
		if block_id != Blocks.AIR:
			non_air_count += 1
	_check(non_air_count == 5376, "recuento de bloques no vacíos")
	_check(chunk_data.get_block(8, 20, 8) == Blocks.GRASS, "hierba en y 20")
	_check(chunk_data.get_block(8, 21, 8) == Blocks.AIR, "aire en y 21")

func _test_world() -> void:
	var world: World = World.new()
	var center_data: ChunkData = ChunkData.new(Vector2i(0, 0))
	var negative_data: ChunkData = ChunkData.new(Vector2i(-1, 0))
	world.chunks[Vector2i(0, 0)] = center_data
	world.chunks[Vector2i(-1, 0)] = negative_data

	_check(world.is_chunk_loaded(Vector2i(0, 0)), "chunk central cargado")
	_check(world.get_chunk_data(Vector2i(-1, 0)) == negative_data, "get_chunk_data")
	world.set_block(-1, 5, 0, Blocks.STONE)
	_check(
		negative_data.get_block(15, 5, 0) == Blocks.STONE,
		"set_block convierte a coordenada local"
	)
	_check(world.get_block(-1, 5, 0) == Blocks.STONE, "get_block del bloque escrito")

	var unloaded_world: World = World.new()
	_check(unloaded_world.get_block(-1, 5, 0) == Blocks.AIR, "chunk descargado devuelve aire")
	_check(world.get_block(0, -5, 0) == Blocks.BEDROCK, "debajo del mundo devuelve bedrock")
	_check(world.get_block(0, 64, 0) == Blocks.AIR, "encima del mundo devuelve aire")

func _test_mesh_builder() -> void:
	var builder: MeshBuilder = MeshBuilder.new()
	_check(builder.is_empty(), "vacío antes de añadir caras")
	_check(builder.face_count() == 0, "face_count inicial")

	builder.add_face(Vector3i.ZERO, Blocks.Face.TOP, 3, 1.0)
	_check(not builder.is_empty(), "no vacío tras añadir una cara")
	_check(builder.vertices.size() == 4, "una cara genera 4 vértices")
	_check(builder.normals.size() == 4, "una cara genera 4 normales")
	_check(builder.uvs.size() == 4, "una cara genera 4 uvs")
	_check(builder.colors.size() == 4, "una cara genera 4 colores")
	_check(builder.indices.size() == 6, "una cara genera 6 índices")
	_check(builder.face_count() == 1, "face_count tras una cara")
	_check(
		is_equal_approx(builder.uvs[0].x, 3.0 / 16.0 + Const.UV_EPSILON)
		and is_equal_approx(builder.uvs[0].y, Const.UV_EPSILON),
		"UV inicial del tile 3 con epsilon"
	)
	_check(builder.colors[0] == Color(1.0, 1.0, 1.0, 1.0), "color de vértice según brillo")
	var arrays: Array = builder.to_arrays()
	_check(arrays.size() == Mesh.ARRAY_MAX, "to_arrays rellena ARRAY_MAX")
	_check((arrays[Mesh.ARRAY_VERTEX] as PackedVector3Array).size() == 4, "to_arrays conserva vértices")
	_check((arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() == 6, "to_arrays conserva índices")

	builder.add_face(Vector3i(1, 0, 0), Blocks.Face.BOTTOM, 2, 0.5)
	_check(builder.vertices.size() == 8, "dos caras generan 8 vértices")
	_check(builder.face_count() == 2, "face_count tras dos caras")
	_check(
		builder.indices.slice(6, 12) == PackedInt32Array([4, 5, 6, 4, 6, 7]),
		"índices de la segunda cara usan base 4"
	)
	_test_mesh_builder_winding()

func _test_mesh_builder_winding() -> void:
	var faces: Array[int] = [
		Blocks.Face.TOP,
		Blocks.Face.BOTTOM,
		Blocks.Face.EAST,
		Blocks.Face.WEST,
		Blocks.Face.SOUTH,
		Blocks.Face.NORTH
	]
	for face: int in faces:
		var builder: MeshBuilder = MeshBuilder.new()
		builder.add_face(Vector3i.ZERO, face, 0, 1.0)
		var normal: Vector3 = builder.normals[0]
		var first_cross: Vector3 = (builder.vertices[1] - builder.vertices[0]).cross(
			builder.vertices[2] - builder.vertices[0]
		)
		var second_cross: Vector3 = (builder.vertices[2] - builder.vertices[0]).cross(
			builder.vertices[3] - builder.vertices[0]
		)
		_check(first_cross == -normal, "winding primer triángulo cara %d" % face)
		_check(second_cross == -normal, "winding segundo triángulo cara %d" % face)

func _test_chunk_mesher_flat() -> void:
	var data: ChunkData = ChunkData.new()
	data.fill_flat()
	var result: Dictionary = ChunkMesher.build(data, {})
	var solid: MeshBuilder = result["solid"] as MeshBuilder
	var water: MeshBuilder = result["water"] as MeshBuilder
	_check(solid.face_count() == 1600, "chunk plano sin vecinos genera 1600 caras sólidas")
	_check(solid.vertices.size() == 6400, "chunk plano sin vecinos genera 6400 vértices sólidos")
	_check(solid.indices.size() == 9600, "chunk plano sin vecinos genera 9600 índices sólidos")
	_check(water.is_empty(), "chunk plano no genera malla de agua")

func _test_chunk_mesher_neighbors() -> void:
	var data: ChunkData = ChunkData.new()
	data.fill_flat()
	var neighbors: Dictionary = {}
	var west: ChunkData = ChunkData.new(Vector2i(-1, 0))
	var east: ChunkData = ChunkData.new(Vector2i(1, 0))
	var north: ChunkData = ChunkData.new(Vector2i(0, -1))
	var south: ChunkData = ChunkData.new(Vector2i(0, 1))
	west.fill_flat()
	east.fill_flat()
	north.fill_flat()
	south.fill_flat()
	neighbors[Vector2i(-1, 0)] = west
	neighbors[Vector2i(1, 0)] = east
	neighbors[Vector2i(0, -1)] = north
	neighbors[Vector2i(0, 1)] = south

	var result_with_four: Dictionary = ChunkMesher.build(data, neighbors)
	var solid_with_four: MeshBuilder = result_with_four["solid"] as MeshBuilder
	_check(solid_with_four.face_count() == 256, "cuatro vecinos dejan solo 256 caras superiores")

	neighbors.erase(Vector2i(1, 0))
	var result_with_three: Dictionary = ChunkMesher.build(data, neighbors)
	var solid_with_three: MeshBuilder = result_with_three["solid"] as MeshBuilder
	_check(solid_with_three.face_count() == 592, "tres vecinos dejan 592 caras expuestas")

	var result_without_neighbors: Dictionary = ChunkMesher.build(data, {})
	var solid_without_neighbors: MeshBuilder = result_without_neighbors["solid"] as MeshBuilder
	_check(solid_without_neighbors.face_count() == 1600, "sin vecinos quedan 1600 caras expuestas")

func _test_shared_block_material() -> void:
	var chunk_a: Chunk = Chunk.new(Vector2i(0, 0))
	var chunk_b: Chunk = Chunk.new(Vector2i(1, 0))
	var solid_mesh_a: MeshInstance3D = chunk_a.get_node("SolidMesh") as MeshInstance3D
	var solid_mesh_b: MeshInstance3D = chunk_b.get_node("SolidMesh") as MeshInstance3D
	var material_a: StandardMaterial3D = solid_mesh_a.material_override as StandardMaterial3D
	var material_b: StandardMaterial3D = solid_mesh_b.material_override as StandardMaterial3D
	_check(chunk_a.get_instance_id() != chunk_b.get_instance_id(), "los chunks son instancias distintas")
	_check(
		material_a.get_instance_id() == material_b.get_instance_id(),
		"dos chunks comparten la misma instancia de material sólido"
	)
	_check(material_a.shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED, "material sólido unshaded")
	_check(material_a.vertex_color_use_as_albedo, "material sólido usa colores de vértice")
	_check(material_a.texture_filter == BaseMaterial3D.TEXTURE_FILTER_NEAREST, "material sólido usa nearest")
	_check(
		material_a.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR,
		"material sólido usa alpha scissor"
	)
	_check(is_equal_approx(material_a.alpha_scissor_threshold, 0.5), "umbral alpha scissor")
	_check(material_a.cull_mode == BaseMaterial3D.CULL_BACK, "material sólido descarta caras traseras")

func _test_atlas_builder() -> void:
	var atlas_texture: ImageTexture = AtlasBuilder.build()
	var atlas_image: Image = atlas_texture.get_image()
	_check(atlas_image.get_width() == 256, "atlas mide 256 px de ancho")
	_check(atlas_image.get_height() == 256, "atlas mide 256 px de alto")
	_check(atlas_image.get_format() == Image.FORMAT_RGBA8, "atlas usa RGBA8")
	_check(FileAccess.file_exists("user://atlas_debug.png"), "atlas_debug.png guardado")
	_check(
		atlas_image.get_pixel(16 + 8, 8) == atlas_image.get_pixel(2 * Const.TILE_PX + 8, 8),
		"grass_side conserva dirt debajo de las filas verdes"
	)
	var grass_side_top: Color = atlas_image.get_pixel(16 + 8, 1)
	_check(grass_side_top.g > grass_side_top.r, "grass_side tiene hierba en las 4 filas superiores")

	var transparent_leaves: int = 0
	for y: int in range(Const.TILE_PX):
		for x: int in range(Const.TILE_PX):
			if atlas_image.get_pixel(8 * Const.TILE_PX + x, y).a == 0.0:
				transparent_leaves += 1
	var transparent_ratio: float = float(transparent_leaves) / float(Const.TILE_PX * Const.TILE_PX)
	_check(transparent_ratio > 0.20 and transparent_ratio < 0.30, "leaves tiene cerca de 25 % transparente")
	_check(atlas_image.get_pixel(10 * Const.TILE_PX + 8, 8).a == 0.0, "centro de glass transparente")
	_check(atlas_image.get_pixel(10 * Const.TILE_PX, 8).a == 1.0, "borde de glass opaco")
	var water_alpha: float = atlas_image.get_pixel(12 * Const.TILE_PX + 8, 8).a
	_check(water_alpha > 0.0 and water_alpha < 1.0, "water semitransparente")
	_check(atlas_image.get_pixel(13 * Const.TILE_PX, 0).a == 0.0, "tile 13 permanece transparente")

func _test_block_face_tiles() -> void:
	var data: ChunkData = ChunkData.new()
	data.set_block(1, 1, 1, Blocks.GRASS)
	var result: Dictionary = ChunkMesher.build(data, {})
	var solid: MeshBuilder = result["solid"] as MeshBuilder
	var tile_zero_u: float = Const.UV_EPSILON
	var tile_one_u: float = 1.0 / float(Const.ATLAS_TILES) + Const.UV_EPSILON
	var tile_two_u: float = 2.0 / float(Const.ATLAS_TILES) + Const.UV_EPSILON
	_check(solid.face_count() == 6, "bloque GRASS expone seis caras")
	_check(is_equal_approx(solid.uvs[0].x, tile_zero_u), "GRASS TOP usa tile grass_top")
	_check(is_equal_approx(solid.uvs[4].x, tile_two_u), "GRASS BOTTOM usa tile dirt")
	_check(is_equal_approx(solid.uvs[8].x, tile_one_u), "GRASS EAST usa tile grass_side")
	_check(is_equal_approx(solid.uvs[12].x, tile_one_u), "GRASS WEST usa tile grass_side")
	_check(is_equal_approx(solid.uvs[16].x, tile_one_u), "GRASS SOUTH usa tile grass_side")
	_check(is_equal_approx(solid.uvs[20].x, tile_one_u), "GRASS NORTH usa tile grass_side")
	_check(BlockMaterials.solid().albedo_texture is ImageTexture, "material sólido tiene el atlas asignado")

func _test_face_brightness() -> void:
	var data: ChunkData = ChunkData.new()
	data.set_block(1, 1, 1, Blocks.GRASS)
	var result: Dictionary = ChunkMesher.build(data, {})
	var solid: MeshBuilder = result["solid"] as MeshBuilder
	var expected_brightness: Array[float] = [1.0, 0.5, 0.6, 0.6, 0.8, 0.8]
	var face_names: Array[String] = ["TOP", "BOTTOM", "EAST", "WEST", "SOUTH", "NORTH"]
	for face_index: int in range(expected_brightness.size()):
		var color: Color = solid.colors[face_index * 4]
		_check(
			is_equal_approx(color.r, expected_brightness[face_index])
			and is_equal_approx(color.g, expected_brightness[face_index])
			and is_equal_approx(color.b, expected_brightness[face_index]),
			"brillo de vértices cara " + face_names[face_index]
		)
	_check(
		BlockMaterials.solid().shading_mode == BaseMaterial3D.SHADING_MODE_UNSHADED,
		"brillo de cara independiente de la luz"
	)

func _test_face_visibility() -> void:
	_check(ChunkMesher._face_visible(Blocks.STONE, Blocks.AIR), "STONE frente a AIR")
	_check(not ChunkMesher._face_visible(Blocks.STONE, Blocks.STONE), "STONE frente a STONE")
	_check(ChunkMesher._face_visible(Blocks.STONE, Blocks.GLASS), "STONE frente a GLASS")
	_check(not ChunkMesher._face_visible(Blocks.GLASS, Blocks.STONE), "GLASS frente a STONE")
	_check(not ChunkMesher._face_visible(Blocks.GLASS, Blocks.GLASS), "GLASS frente a GLASS")
	_check(ChunkMesher._face_visible(Blocks.GLASS, Blocks.AIR), "GLASS frente a AIR")
	_check(not ChunkMesher._face_visible(Blocks.LEAVES, Blocks.LEAVES), "LEAVES frente a LEAVES")
	_check(not ChunkMesher._face_visible(Blocks.LEAVES, Blocks.STONE), "LEAVES frente a STONE")
	_check(ChunkMesher._face_visible(Blocks.WATER, Blocks.AIR), "WATER frente a AIR")
	_check(not ChunkMesher._face_visible(Blocks.WATER, Blocks.WATER), "WATER frente a WATER")
	_check(not ChunkMesher._face_visible(Blocks.WATER, Blocks.STONE), "WATER frente a STONE")
	_check(ChunkMesher._face_visible(Blocks.STONE, Blocks.WATER), "STONE frente a WATER")
	_check(ChunkMesher._face_visible(Blocks.WATER, Blocks.GLASS), "WATER frente a GLASS")

func _test_world_chunk_manager() -> void:
	var world: World = World.new()
	add_child(world)
	var first_data: ChunkData = world.ensure_chunk(-2, 2)
	_check(first_data.coord == Vector2i(-2, 2), "ensure_chunk conserva coordenadas negativas")
	_check(first_data.get_block(0, 20, 0) == Blocks.GRASS, "ensure_chunk crea datos planos")
	_check(world.ensure_chunk(-2, 2) == first_data, "ensure_chunk reutiliza los datos existentes")
	_check(world.chunks.size() == 1 and world.chunk_nodes.size() == 1, "ensure_chunk no duplica chunks")
	_check(not world.remesh(Vector2i(-2, 2)), "remesh espera a los cuatro vecinos")
	for cz: int in range(-2, 3):
		for cx: int in range(-2, 3):
			world.ensure_chunk(cx, cz)

	var meshed_count: int = 0
	var unmeshed_border_count: int = 0
	for cz: int in range(-2, 3):
		for cx: int in range(-2, 3):
			var coord: Vector2i = Vector2i(cx, cz)
			var remeshed: bool = world.remesh(coord)
			var is_interior: bool = cx >= -1 and cx <= 1 and cz >= -1 and cz <= 1
			var chunk_node: Chunk = world.chunk_nodes[coord] as Chunk
			var solid_mesh: MeshInstance3D = chunk_node.get_node("SolidMesh") as MeshInstance3D
			if is_interior and remeshed and solid_mesh.mesh != null:
				meshed_count += 1
			elif not is_interior and not remeshed and solid_mesh.mesh == null:
				unmeshed_border_count += 1
	_check(meshed_count == 9, "5x5 malla los 9 chunks interiores")
	_check(unmeshed_border_count == 16, "5x5 deja los 16 chunks del borde sin mesh")
	_check(world.get_child_count() == 25, "5x5 crea exactamente 25 nodos Chunk")
	world.free()

func _test_world_generator_deterministic() -> void:
	var generator: WorldGenerator = WorldGenerator.new(12345)
	var first: ChunkData = generator.generate(3, -2)
	var second: ChunkData = generator.generate(3, -2)
	_check(first.coord == Vector2i(3, -2), "generate conserva coordenadas")
	_check(first.generated, "generate marca los datos como generados")
	_check(first.blocks == second.blocks, "generate devuelve bloques idénticos para misma semilla y coordenada")
	_check(first.blocks.size() == Const.CHUNK_SIZE * Const.CHUNK_HEIGHT * Const.CHUNK_SIZE, "generate conserva el tamaño del chunk")

@warning_ignore("shadowed_variable_base_class")
func _check(cond: bool, name: String) -> void:
	if cond:
		print("PASS ", _current_milestone, " ", name) # DEBUG-M1.06 # DEBUG-M2.01 # DEBUG-M2.02 # DEBUG-M2.03 # DEBUG-M2.04 # DEBUG-M2.05 # DEBUG-M3.02 # DEBUG-M3.04 # DEBUG-M3.05 # DEBUG-M3.07 # DEBUG-M3.08 # DEBUG-M3.09 # DEBUG-M3.10 # DEBUG-M3.11 # DEBUG-M4.01 # DEBUG-M4.02
	else:
		push_error("FAIL " + _current_milestone + " " + name) # DEBUG-M1.06 # DEBUG-M2.01 # DEBUG-M2.02 # DEBUG-M2.03 # DEBUG-M2.04 # DEBUG-M2.05 # DEBUG-M3.02 # DEBUG-M3.04 # DEBUG-M3.05 # DEBUG-M3.07 # DEBUG-M3.08 # DEBUG-M3.09 # DEBUG-M3.10 # DEBUG-M3.11 # DEBUG-M4.01 # DEBUG-M4.02
