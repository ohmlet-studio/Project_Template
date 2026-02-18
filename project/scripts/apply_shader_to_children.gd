extends Node3D

@export var material: Material

func _ready() -> void:
	var children = get_children()
	for child in children:
		var mesh = child.get_child(0)
		if mesh is MeshInstance3D:
			var mesh_instance: MeshInstance3D = mesh
			for i in mesh_instance.mesh.get_surface_count():
				var og_material = mesh_instance.get_active_material(i)
				var color = og_material.albedo_color
				var texture = og_material.albedo_texture
				var new_material = material.duplicate()
				new_material.set_shader_parameter("color", color)
				new_material.set_shader_parameter("texture", texture)
				mesh_instance.set_surface_override_material(i, new_material)

func _process(delta: float) -> void:
	pass
