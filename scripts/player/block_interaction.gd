class_name BlockInteraction
extends Node

var player: Player
var camera: Camera3D
var world: World

func setup(player_node: Player, player_camera: Camera3D, target_world: World) -> void:
	player = player_node
	camera = player_camera
	world = target_world

func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed(&"break_block"):
		return
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if camera == null or world == null:
		return
	var hit: Dictionary = VoxelRaycast.cast(
		camera.global_position,
		-camera.global_transform.basis.z,
		Const.PLAYER_REACH,
		Callable(world, "get_block")
	)
	if not bool(hit["hit"]) or int(hit["block_id"]) == Blocks.BEDROCK:
		return
	var block: Vector3i = hit["block"]
	world.set_block(block.x, block.y, block.z, Blocks.AIR)
	get_viewport().set_input_as_handled()
