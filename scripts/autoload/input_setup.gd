extends Node

const ACTION_NAMES: Array[StringName] = [
	&"move_forward",
	&"move_back",
	&"move_left",
	&"move_right",
	&"jump",
	&"sprint",
	&"sneak",
	&"toggle_fly",
	&"break_block",
	&"place_block",
	&"pick_block",
	&"hotbar_next",
	&"hotbar_prev",
	&"hotbar_1",
	&"hotbar_2",
	&"hotbar_3",
	&"hotbar_4",
	&"hotbar_5",
	&"hotbar_6",
	&"hotbar_7",
	&"hotbar_8",
	&"hotbar_9",
	&"toggle_debug",
	&"pause"
]

func _ready() -> void:
	_add_key_action(&"move_forward", KEY_W)
	_add_key_action(&"move_back", KEY_S)
	_add_key_action(&"move_left", KEY_A)
	_add_key_action(&"move_right", KEY_D)
	_add_key_action(&"jump", KEY_SPACE)
	_add_key_action(&"sprint", KEY_CTRL)
	_add_key_action(&"sneak", KEY_SHIFT)
	_add_key_action(&"toggle_fly", KEY_F)
	_add_mouse_action(&"break_block", MOUSE_BUTTON_LEFT)
	_add_mouse_action(&"place_block", MOUSE_BUTTON_RIGHT)
	_add_mouse_action(&"pick_block", MOUSE_BUTTON_MIDDLE)
	_add_mouse_action(&"hotbar_next", MOUSE_BUTTON_WHEEL_DOWN)
	_add_mouse_action(&"hotbar_prev", MOUSE_BUTTON_WHEEL_UP)
	_add_key_action(&"hotbar_1", KEY_1)
	_add_key_action(&"hotbar_2", KEY_2)
	_add_key_action(&"hotbar_3", KEY_3)
	_add_key_action(&"hotbar_4", KEY_4)
	_add_key_action(&"hotbar_5", KEY_5)
	_add_key_action(&"hotbar_6", KEY_6)
	_add_key_action(&"hotbar_7", KEY_7)
	_add_key_action(&"hotbar_8", KEY_8)
	_add_key_action(&"hotbar_9", KEY_9)
	_add_key_action(&"toggle_debug", KEY_F3)
	_add_key_action(&"pause", KEY_ESCAPE)

	for action_name: StringName in ACTION_NAMES:
		print("InputMap.has_action(\"", action_name, "\") = ", InputMap.has_action(action_name)) # DEBUG-M1.04

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed(&"move_forward"):
		print("move_forward") # DEBUG-M1.04

func _add_key_action(action_name: StringName, physical_keycode: Key) -> void:
	_ensure_action(action_name)
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = physical_keycode as Key
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)

func _add_mouse_action(action_name: StringName, button_index: MouseButton) -> void:
	_ensure_action(action_name)
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button_index as MouseButton
	if not InputMap.action_has_event(action_name, event):
		InputMap.action_add_event(action_name, event)

func _ensure_action(action_name: StringName) -> void:
	if not InputMap.has_action(action_name):
		InputMap.add_action(action_name)
