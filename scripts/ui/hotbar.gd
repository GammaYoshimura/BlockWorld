class_name Hotbar
extends Control

var _atlas: Texture2D
var _interaction: BlockInteraction
var _slot_panels: Array[PanelContainer] = []
var _slot_icons: Array[TextureRect] = []
var _slot_numbers: Array[Label] = []
var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat
var _last_slots: Array[int] = []
var _last_selected: int = -1

func setup(atlas: Texture2D, interaction: BlockInteraction) -> void:
	_atlas = atlas
	_interaction = interaction
	_build()

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _process(_delta: float) -> void:
	if _interaction == null:
		return
	if _last_slots != _interaction.slots or _last_selected != _interaction.selected:
		_refresh()

func _build() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_normal_style = _make_style(Color(0.08, 0.08, 0.08, 0.78), Color(0.28, 0.28, 0.28))
	_selected_style = _make_style(Color(0.18, 0.18, 0.18, 0.92), Color(1.0, 1.0, 1.0))
	var bar: HBoxContainer = HBoxContainer.new()
	bar.name = "Slots"
	bar.add_theme_constant_override("separation", 2)
	bar.set_anchors_and_offsets_preset(Control.PRESET_CENTER_BOTTOM)
	bar.offset_left = -226.0
	bar.offset_top = -66.0
	bar.offset_right = 226.0
	bar.offset_bottom = -8.0
	add_child(bar)
	for index: int in range(9):
		var panel: PanelContainer = PanelContainer.new()
		panel.custom_minimum_size = Vector2(48.0, 58.0)
		panel.add_theme_stylebox_override("panel", _normal_style)
		var column: VBoxContainer = VBoxContainer.new()
		column.alignment = BoxContainer.ALIGNMENT_CENTER
		column.add_theme_constant_override("separation", 0)
		panel.add_child(column)
		var icon: TextureRect = TextureRect.new()
		icon.custom_minimum_size = Vector2(32.0, 32.0)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_SCALE
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		column.add_child(icon)
		var number: Label = Label.new()
		number.text = str(index + 1)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.add_theme_font_size_override("font_size", 10)
		number.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85))
		column.add_child(number)
		bar.add_child(panel)
		_slot_panels.append(panel)
		_slot_icons.append(icon)
		_slot_numbers.append(number)
	_refresh()

func _refresh() -> void:
	if _interaction == null or _atlas == null:
		return
	for index: int in range(mini(_interaction.slots.size(), _slot_icons.size())):
		var block_id: int = _interaction.slots[index]
		if _last_slots.size() != _interaction.slots.size() or _last_slots[index] != block_id:
			var tile: int = Blocks.tile_for_face(block_id, Blocks.Face.TOP if block_id == Blocks.GRASS or block_id == Blocks.LOG else Blocks.Face.EAST)
			var icon_texture: AtlasTexture = AtlasTexture.new()
			icon_texture.atlas = _atlas
			icon_texture.region = Rect2(Vector2(float(tile * Const.TILE_PX), 0.0), Vector2(Const.TILE_PX, Const.TILE_PX))
			_slot_icons[index].texture = icon_texture
			_slot_numbers[index].tooltip_text = Blocks.name_of(block_id)
		_slot_panels[index].add_theme_stylebox_override(
			"panel", _selected_style if index == _interaction.selected else _normal_style
		)
	_last_slots = _interaction.slots.duplicate()
	_last_selected = _interaction.selected

func _make_style(background: Color, border: Color) -> StyleBoxFlat:
	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(2)
	style.content_margin_left = 4.0
	style.content_margin_right = 4.0
	style.content_margin_top = 3.0
	style.content_margin_bottom = 2.0
	return style
