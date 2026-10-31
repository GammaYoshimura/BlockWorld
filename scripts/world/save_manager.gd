class_name SaveManager
extends RefCounted

static func save_world_metadata(
	world_name: String,
	seed_value: int,
	time_of_day: float,
	player_position: Vector3,
	player_yaw: float,
	player_pitch: float,
	player_flying: bool,
	hotbar_slots: Array[int],
	selected_slot: int
) -> Error:
	var safe_name: String = _safe_save_name(world_name)
	var relative_directory: String = "user://saves/%s" % safe_name
	var absolute_directory: String = ProjectSettings.globalize_path(relative_directory)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		return directory_error
	var save_data: Dictionary = {
		"version": 1,
		"name": safe_name,
		"seed": seed_value,
		"time_of_day": time_of_day,
		"player": {
			"pos": [player_position.x, player_position.y, player_position.z],
			"yaw": player_yaw,
			"pitch": player_pitch,
			"fly": player_flying
		},
		"hotbar": hotbar_slots,
		"selected": selected_slot
	}
	var json_bytes: PackedByteArray = JSON.stringify(save_data, "\t").to_utf8_buffer()
	return _write_atomic("%s/world.json" % relative_directory, json_bytes)

static func _safe_save_name(world_name: String) -> String:
	var name: String = world_name.strip_edges()
	if name.is_empty():
		name = "Mundo"
	var invalid_characters: RegEx = RegEx.new()
	invalid_characters.compile("[^A-Za-z0-9_-]")
	name = invalid_characters.sub(name, "_", true)
	return name.substr(0, 48)

static func save_chunk(world_name: String, data: ChunkData) -> Error:
	if not data.modified:
		return OK
	var directory: String = "%s/chunks" % _save_directory(world_name)
	var absolute_directory: String = ProjectSettings.globalize_path(directory)
	var directory_error: Error = DirAccess.make_dir_recursive_absolute(absolute_directory)
	if directory_error != OK:
		return directory_error
	var compressed: PackedByteArray = data.blocks.compress(FileAccess.COMPRESSION_ZSTD)
	var chunk_bytes: PackedByteArray = "BWCH".to_ascii_buffer()
	chunk_bytes.append(1)
	var original_size: int = data.blocks.size()
	for shift: int in [0, 8, 16, 24]:
		chunk_bytes.append((original_size >> shift) & 0xFF)
	chunk_bytes.append_array(compressed)
	var file_path: String = "%s/%d_%d.bin" % [directory, data.coord.x, data.coord.y]
	return _write_atomic(file_path, chunk_bytes)

static func load_chunk(world_name: String, coord: Vector2i) -> ChunkData:
	var file_path: String = "%s/chunks/%d_%d.bin" % [
		_save_directory(world_name), coord.x, coord.y
	]
	if not FileAccess.file_exists(file_path):
		return null
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		push_warning("No se pudo abrir el chunk guardado %s; se regenerará" % file_path)
		return null
	if file.get_length() < 9:
		file.close()
		_warn_invalid_chunk(file_path, "cabecera truncada")
		return null
	var magic: PackedByteArray = file.get_buffer(4)
	var version: int = file.get_8()
	var original_size: int = file.get_32()
	var expected_size: int = Const.CHUNK_SIZE * Const.CHUNK_HEIGHT * Const.CHUNK_SIZE
	if magic.get_string_from_ascii() != "BWCH" or version != 1 or original_size != expected_size:
		file.close()
		_warn_invalid_chunk(file_path, "magia, versión o tamaño inválido")
		return null
	var compressed_size: int = int(file.get_length() - file.get_position())
	var compressed: PackedByteArray = file.get_buffer(compressed_size)
	file.close()
	if compressed.is_empty():
		_warn_invalid_chunk(file_path, "datos comprimidos vacíos")
		return null
	var blocks: PackedByteArray = compressed.decompress(expected_size, FileAccess.COMPRESSION_ZSTD)
	if blocks.size() != expected_size:
		_warn_invalid_chunk(file_path, "descompresión incompleta")
		return null
	var data: ChunkData = ChunkData.new(coord)
	data.blocks = blocks
	data.generated = true
	data.modified = true
	return data

static func _save_directory(world_name: String) -> String:
	return "user://saves/%s" % _safe_save_name(world_name)

static func _warn_invalid_chunk(file_path: String, reason: String) -> void:
	push_warning("Chunk guardado ignorado (%s): %s" % [reason, file_path])

static func _write_atomic(file_path: String, contents: PackedByteArray) -> Error:
	var temporary_path: String = "%s.tmp" % file_path
	var file: FileAccess = FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_buffer(contents)
	file.flush()
	var write_error: Error = file.get_error()
	file.close()
	if write_error != OK:
		return write_error
	var rename_error: Error = DirAccess.rename_absolute(
		ProjectSettings.globalize_path(temporary_path),
		ProjectSettings.globalize_path(file_path)
	)
	if rename_error != OK:
		return rename_error
	return OK
