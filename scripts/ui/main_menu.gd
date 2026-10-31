class_name MainMenu
extends Control

var _seed_input: LineEdit

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
	panel.custom_minimum_size = Vector2(360.0, 260.0)
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
	var exit_button: Button = Button.new()
	exit_button.text = "Salir"
	exit_button.pressed.connect(_exit_game)
	layout.add_child(exit_button)

func _start_world() -> void:
	var seed_text: String = _seed_input.text.strip_edges()
	if not seed_text.is_empty() and not seed_text.is_valid_int():
		_seed_input.text = ""
		_seed_input.placeholder_text = "Introduce un número entero"
		_seed_input.grab_focus()
		return
	GameSettings.world_seed = int(seed_text) if not seed_text.is_empty() else 0
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _exit_game() -> void:
	get_tree().quit()
