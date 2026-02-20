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
	# Set no picked object at begin
	Manager.is_all_scanned = false
	_create_furniture_collisions()
	
func _create_furniture_collisions() -> void:
	# grabe all mesh
	for node in _furniture.get_children():
		var meshes: Array[MeshInstance3D] = []
		_collect_meshes(node, meshes)
		if meshes.is_empty():
			continue

		# create static body inside node
		var static_body := StaticBody3D.new()
		node.add_child(static_body)
		
		# ok là j'avoue j'ai triché pour combiner tout les mesh :((
		var combined_aabb: AABB
		var first := true
		for mesh_instance in meshes:
			# get_aabb() is in local mesh space, transform to global then to node local
			var local_aabb: AABB = mesh_instance.get_aabb()
			# Convert all 8 corners through the transform chain
			var corners: Array[Vector3] = []
			for x in [local_aabb.position.x, local_aabb.end.x]:
				for y in [local_aabb.position.y, local_aabb.end.y]:
					for z in [local_aabb.position.z, local_aabb.end.z]:
						var world_point := mesh_instance.global_transform * Vector3(x, y, z)
						var node_point = node.global_transform.affine_inverse() * world_point
						corners.append(node_point)

			var mesh_aabb := AABB(corners[0], Vector3.ZERO)
			for corner in corners:
				mesh_aabb = mesh_aabb.expand(corner)

			if first:
				combined_aabb = mesh_aabb
				first = false
			else:
				combined_aabb = combined_aabb.merge(mesh_aabb)

		var shape := BoxShape3D.new()
		shape.size = combined_aabb.size
		
		var col_shape := CollisionShape3D.new()
		col_shape.shape = shape
		col_shape.position = combined_aabb.get_center()
		static_body.add_child(col_shape)

func _collect_meshes(node: Node, result: Array[MeshInstance3D]) -> void:
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		_collect_meshes(child, result)
