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
	var file: FileAccess = FileAccess.open("%s/world.json" % relative_directory, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(JSON.stringify(save_data, "\t"))
	var write_error: Error = file.get_error()
	file.close()
	return write_error

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
	var file_path: String = "%s/%d_%d.bin" % [directory, data.coord.x, data.coord.y]
	var file: FileAccess = FileAccess.open(file_path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	var compressed: PackedByteArray = data.blocks.compress(FileAccess.COMPRESSION_ZSTD)
	file.store_buffer("BWCH".to_ascii_buffer())
	file.store_8(1)
	file.store_32(data.blocks.size())
	file.store_buffer(compressed)
	var write_error: Error = file.get_error()
	file.close()
	return write_error

static func load_chunk(world_name: String, coord: Vector2i) -> ChunkData:
	var file_path: String = "%s/chunks/%d_%d.bin" % [
		_save_directory(world_name), coord.x, coord.y
	]
	if not FileAccess.file_exists(file_path):
		return null
	var file: FileAccess = FileAccess.open(file_path, FileAccess.READ)
	if file == null:
		return null
	var magic: PackedByteArray = file.get_buffer(4)
	var version: int = file.get_8()
	var original_size: int = file.get_32()
	var expected_size: int = Const.CHUNK_SIZE * Const.CHUNK_HEIGHT * Const.CHUNK_SIZE
	if magic.get_string_from_ascii() != "BWCH" or version != 1 or original_size != expected_size:
		file.close()
		return null
	var compressed_size: int = int(file.get_length() - file.get_position())
	var compressed: PackedByteArray = file.get_buffer(compressed_size)
	file.close()
	var blocks: PackedByteArray = compressed.decompress(expected_size, FileAccess.COMPRESSION_ZSTD)
	if blocks.size() != expected_size:
		return null
	var data: ChunkData = ChunkData.new(coord)
	data.blocks = blocks
	data.generated = true
	data.modified = true
	return data

static func _save_directory(world_name: String) -> String:
	return "user://saves/%s" % _safe_save_name(world_name)
