class_name MainMenu
extends Control

const SaveManagerScript = preload("res://scripts/world/save_manager.gd")
var _seed_input: LineEdit
var _saved_worlds: VBoxContainer
var _delete_dialog: ConfirmationDialog
var _pending_delete_name: String = ""

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build()

func _build() -> void:
	var background: ColorRect = ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.30, 0.52, 0.72)
	add_child(background)
	var center: CenterContainer = CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel: PanelContainer = PanelContainer.new()
	panel.custom_minimum_size = Vector2(440.0, 520.0)
	center.add_child(panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 14)
	panel.add_child(layout)
	var title: Label = Label.new()
	title.text = "BlockWorld"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 30)
	layout.add_child(title)
	var seed_label: Label = Label.new()
	seed_label.text = "Semilla (vacío = aleatoria)"
	layout.add_child(seed_label)
	_seed_input = LineEdit.new()
	_seed_input.placeholder_text = "Semilla opcional"
	_seed_input.max_length = 12
	layout.add_child(_seed_input)
	var start_button: Button = Button.new()
	start_button.text = "Nuevo mundo"
	start_button.custom_minimum_size.y = 40.0
	start_button.pressed.connect(_start_world)
	layout.add_child(start_button)
	var worlds_title: Label = Label.new()
	worlds_title.text = "Mundos guardados"
	layout.add_child(worlds_title)
	var scroll: ScrollContainer = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(380.0, 160.0)
	layout.add_child(scroll)
	_saved_worlds = VBoxContainer.new()
	_saved_worlds.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	scroll.add_child(_saved_worlds)
	var exit_button: Button = Button.new()
	exit_button.text = "Salir"
	exit_button.pressed.connect(_exit_game)
	layout.add_child(exit_button)
	_delete_dialog = ConfirmationDialog.new()
	_delete_dialog.title = "Borrar mundo"
	_delete_dialog.confirmed.connect(_delete_selected_world)
	add_child(_delete_dialog)
	_refresh_saved_worlds()

func _start_world() -> void:
	var seed_text: String = _seed_input.text.strip_edges()
	if not seed_text.is_empty() and not seed_text.is_valid_int():
		_seed_input.text = ""
		_seed_input.placeholder_text = "Introduce un número entero"
		_seed_input.grab_focus()
		return
	GameSettings.world_seed = int(seed_text) if not seed_text.is_empty() else 0
	GameSettings.world_name = ""
	GameSettings.pending_world_data.clear()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _refresh_saved_worlds() -> void:
	for child: Node in _saved_worlds.get_children():
		child.queue_free()
	var worlds: Array[Dictionary] = SaveManagerScript.list_saved_worlds()
	if worlds.is_empty():
		var empty_label: Label = Label.new()
		empty_label.text = "No hay mundos guardados"
		_saved_worlds.add_child(empty_label)
		return
	for world_info: Dictionary in worlds:
		var row: HBoxContainer = HBoxContainer.new()
		var world_label: Label = Label.new()
		world_label.text = "%s  ·  semilla %d" % [world_info["name"], world_info["seed"]]
		world_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(world_label)
		var load_button: Button = Button.new()
		load_button.text = "Cargar"
		load_button.pressed.connect(_load_world.bind(str(world_info["directory"])))
		row.add_child(load_button)
		var delete_button: Button = Button.new()
		delete_button.text = "Borrar"
		delete_button.pressed.connect(_request_delete.bind(str(world_info["directory"]), str(world_info["name"])))
		row.add_child(delete_button)
		_saved_worlds.add_child(row)

func _load_world(directory_name: String) -> void:
	var metadata: Dictionary = SaveManagerScript.load_world_metadata(directory_name)
	if metadata.is_empty():
		_refresh_saved_worlds()
		return
	GameSettings.world_name = directory_name
	GameSettings.world_seed = int(metadata.get("seed", 0))
	GameSettings.pending_world_data = metadata
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _request_delete(directory_name: String, display_name: String) -> void:
	_pending_delete_name = directory_name
	_delete_dialog.dialog_text = "¿Borrar el mundo «%s» y todos sus archivos?" % display_name
	_delete_dialog.popup_centered()

func _delete_selected_world() -> void:
	var delete_error: Error = SaveManagerScript.delete_world(_pending_delete_name)
	if delete_error != OK:
		push_warning("No se pudo borrar el mundo; error %d" % delete_error)
	_pending_delete_name = ""
	_refresh_saved_worlds()

func _exit_game() -> void:
	get_tree().quit()
