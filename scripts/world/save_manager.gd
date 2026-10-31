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
