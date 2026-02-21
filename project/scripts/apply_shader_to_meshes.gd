extends Node

@export var apply_shaders: bool 
@export var material: ShaderMaterial

func get_all_children(in_node, arr := []):
	arr.push_back(in_node)
	for child in in_node.get_children():
		arr = get_all_children(child, arr)
	return arr

func _ready() -> void:
	if not apply_shaders:
		return
	
	for child in get_all_children(get_tree().root):
		if child is MeshInstance3D:
			if child.get_layer_mask_value(3):
				continue  # was "return" — this skipped ALL remaining meshes!

			var mesh_instance: MeshInstance3D = child
			for i in mesh_instance.mesh.get_surface_count():
				var og_material = mesh_instance.get_active_material(i)
				if og_material is StandardMaterial3D:
					var new_material: ShaderMaterial = material.duplicate()
					new_material.set_shader_parameter("color", og_material.albedo_color)
					new_material.set_shader_parameter("albedo", og_material.albedo_texture)  # fixed name
					mesh_instance.set_surface_override_material(i, new_material)
