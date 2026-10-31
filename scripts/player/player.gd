class_name Player
extends CharacterBody3D

var head: Node3D
var camera: Camera3D

func _ready() -> void:
	collision_layer = 2
	collision_mask = 1

	var capsule: CapsuleShape3D = CapsuleShape3D.new()
	capsule.radius = Const.PLAYER_WIDTH * 0.5
	capsule.height = Const.PLAYER_HEIGHT
	var collision: CollisionShape3D = CollisionShape3D.new()
	collision.name = "CollisionShape3D"
	collision.shape = capsule
	collision.position.y = Const.PLAYER_HEIGHT * 0.5
	add_child(collision)

	head = Node3D.new()
	head.name = "Head"
	head.position.y = Const.PLAYER_EYE_HEIGHT
	add_child(head)

	camera = Camera3D.new()
	camera.name = "Camera3D"
	head.add_child(camera)

func get_camera() -> Camera3D:
	return camera
