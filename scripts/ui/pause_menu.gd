class_name PauseMenu
extends Control

var _panel: PanelContainer

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	_build()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"pause"):
		if visible:
			_resume()
		else:
			_pause()
		get_viewport().set_input_as_handled()

func _pause() -> void:
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	visible = true

func _resume() -> void:
	visible = false
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _build() -> void:
	var shade: ColorRect = ColorRect.new()
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0.0, 0.0, 0.0, 0.55)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	_panel = PanelContainer.new()
	_panel.set_anchors_and_offsets_preset(Control.PRESET_CENTER)
	_panel.offset_left = -150.0
	_panel.offset_top = -104.0
	_panel.offset_right = 150.0
	_panel.offset_bottom = 104.0
	shade.add_child(_panel)
	var layout: VBoxContainer = VBoxContainer.new()
	layout.alignment = BoxContainer.ALIGNMENT_CENTER
	layout.add_theme_constant_override("separation", 12)
	_panel.add_child(layout)
	var title: Label = Label.new()
	title.text = "Pausa"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 24)
	layout.add_child(title)
	var continue_button: Button = Button.new()
	continue_button.text = "Continuar"
	continue_button.custom_minimum_size.x = 220.0
	continue_button.pressed.connect(_resume)
	layout.add_child(continue_button)
	var exit_button: Button = Button.new()
	exit_button.text = "Salir"
	exit_button.custom_minimum_size.x = 220.0
	exit_button.pressed.connect(_exit_game)
	layout.add_child(exit_button)

func _exit_game() -> void:
	get_tree().paused = false
	get_tree().quit()
