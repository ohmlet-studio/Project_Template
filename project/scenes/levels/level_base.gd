@tool
extends Node3D

@onready var _static_objects: Node3D = $Room/Interactable/Static
@onready var _collision_shape: CollisionShape3D = $Room/room/CSGBakedMeshInstance3D/StaticBody3D/CollisionShape3D

@export var show_static_objects: bool = true:
	set(value):
		show_static_objects = value
		if is_node_ready():
			_static_objects.visible = value

@export var enable_hitbox: bool = true:
	set(value):
		enable_hitbox = value
		if is_node_ready():
			_collision_shape.disabled = !value

func _ready() -> void:
	_static_objects.visible = show_static_objects
	_collision_shape.disabled = !enable_hitbox
	# Set no picked object at begin
	Manager.is_all_picked = false
