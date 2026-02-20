@tool
extends Node3D

@onready var _static_objects: Node3D = $Room/Interactable/Static
@onready var _collision_shape: CollisionShape3D = %CollisionShape3D
@onready var _furniture: Node3D = $Room/Furniture
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
	
	# Set no picked object at beginning
	# commented out as it was causing crashes, on it now
	#Manager.is_all_picked = false
	
	_create_furniture_collisions()
	

func _create_furniture_collisions() -> void:
	for node in _furniture.get_children():
		var meshes: Array[MeshInstance3D] = []
		_collect_meshes(node, meshes)
		if meshes.is_empty():
			continue

		var static_body := StaticBody3D.new()
		node.add_child(static_body)

		for mesh_instance in meshes:
			var shape := mesh_instance.mesh.create_convex_shape()
			var col_shape := CollisionShape3D.new()
			col_shape.shape = shape
			col_shape.transform = node.global_transform.affine_inverse() * mesh_instance.global_transform
			static_body.add_child(col_shape)

func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_collect_meshes(child, result)
