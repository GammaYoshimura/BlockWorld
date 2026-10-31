class_name BlockInteraction
extends Node

var player: Player
var camera: Camera3D
var world: World
var slots: Array[int] = [
	Blocks.GRASS,
	Blocks.DIRT,
	Blocks.STONE,
	Blocks.COBBLESTONE,
	Blocks.PLANKS,
	Blocks.LOG,
	Blocks.LEAVES,
	Blocks.SAND,
	Blocks.GLASS
]
var selected: int = 0
var _repeat_timer: float = 0.0

func setup(player_node: Player, player_camera: Camera3D, target_world: World) -> void:
	player = player_node
	camera = player_camera
	world = target_world

func _process(delta: float) -> void:
	var breaking: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed(&"break_block")
	var placing: bool = Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed(&"place_block")
	if not breaking and not placing:
		_repeat_timer = 0.0
		return
	_repeat_timer -= delta
	if _repeat_timer > 0.0:
		return
	if breaking:
		_break_target_block()
	if placing:
		_place_selected_block()
	_repeat_timer = Const.ACTION_REPEAT_SECONDS

func _unhandled_input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event.is_action_pressed(&"break_block"):
		_break_target_block()
		_repeat_timer = Const.ACTION_REPEAT_SECONDS
	elif event.is_action_pressed(&"place_block"):
		_place_selected_block()
		_repeat_timer = Const.ACTION_REPEAT_SECONDS
	elif event.is_action_pressed(&"pick_block"):
		_pick_target_block()
	elif event.is_action_pressed(&"hotbar_next"):
		_select_slot(posmod(selected + 1, slots.size()))
	elif event.is_action_pressed(&"hotbar_prev"):
		_select_slot(posmod(selected - 1, slots.size()))
	else:
		for slot_index: int in range(slots.size()):
			var action: StringName = StringName("hotbar_%d" % (slot_index + 1))
			if event.is_action_pressed(action):
				_select_slot(slot_index)
				return

func _break_target_block() -> void:
	var hit: Dictionary = _raycast_target()
	if hit.is_empty() or int(hit["block_id"]) == Blocks.BEDROCK:
		return
	var block: Vector3i = hit["block"]
	world.set_block(block.x, block.y, block.z, Blocks.AIR)
	get_viewport().set_input_as_handled()

func _place_selected_block() -> void:
	var hit: Dictionary = _raycast_target()
	if hit.is_empty():
		return
	var target: Vector3i = hit["prev"]
	if target.y < 0 or target.y >= Const.CHUNK_HEIGHT:
		return
	var target_block: int = world.get_block(target.x, target.y, target.z)
	if target_block != Blocks.AIR and target_block != Blocks.WATER:
		return
	if _intersects_player(target):
		return
	world.set_block(target.x, target.y, target.z, slots[selected])
	get_viewport().set_input_as_handled()

func _pick_target_block() -> void:
	var hit: Dictionary = _raycast_target()
	if hit.is_empty():
		return
	var block_id: int = int(hit["block_id"])
	var slot_index: int = slots.find(block_id)
	if slot_index >= 0:
		_select_slot(slot_index)
	else:
		slots[selected] = block_id
		print("Hotbar replaced slot ", selected + 1, ": ", Blocks.name_of(block_id))
		get_viewport().set_input_as_handled()

func _raycast_target() -> Dictionary:
	if camera == null or world == null:
		return {}
	var hit: Dictionary = VoxelRaycast.cast(
		camera.global_position,
		-camera.global_transform.basis.z,
		Const.PLAYER_REACH,
		Callable(world, "get_block")
	)
	return hit if bool(hit["hit"]) else {}

func _intersects_player(block: Vector3i) -> bool:
	var player_bounds: AABB = AABB(
		player.global_position + Vector3(-Const.PLAYER_WIDTH * 0.5, 0.0, -Const.PLAYER_WIDTH * 0.5),
		Vector3(Const.PLAYER_WIDTH, Const.PLAYER_HEIGHT, Const.PLAYER_WIDTH)
	)
	var block_bounds: AABB = AABB(Vector3(block), Vector3.ONE)
	var player_end: Vector3 = player_bounds.end
	var block_end: Vector3 = block_bounds.end
	return (
		player_bounds.position.x < block_end.x
		and player_end.x > block_bounds.position.x
		and player_bounds.position.y < block_end.y
		and player_end.y > block_bounds.position.y
		and player_bounds.position.z < block_end.z
		and player_end.z > block_bounds.position.z
	)

func _select_slot(slot_index: int) -> void:
	selected = posmod(slot_index, slots.size())
	print("Hotbar selected slot ", selected + 1, ": ", Blocks.name_of(slots[selected]))
	get_viewport().set_input_as_handled()
