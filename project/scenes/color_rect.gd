extends ColorRect

# ── Configuration ──────────────────────────────────────────────────
# Fill this array with the Node3D nodes that are your "colored spheres".
# Their world position + a radius you define here will be used.
@export var sphere_nodes  : Array[Node3D]
@export var sphere_radius : float = 2.0   # same radius for all, adjust as needed

# Or use per-sphere radii by using a custom resource — but this is the simple path.

# ── Internal ───────────────────────────────────────────────────────
var _mat : ShaderMaterial

func _ready():
	_mat = material as ShaderMaterial

func _process(_delta):
	if not _mat:
		return

	var cam : Camera3D = get_viewport().get_camera_3d()
	if not cam:
		return

	# ── Screen size ────────────────────────────────────────────────
	var vp_size : Vector2 = get_viewport().get_visible_rect().size
	_mat.set_shader_parameter("screen_size", vp_size)

	# ── Camera matrices ────────────────────────────────────────────
	var proj     : Projection = cam.get_camera_projection()
	var proj_mat : Basis      = _projection_to_basis(proj)

	# Godot doesn't expose Projection.inverse() directly to shader uniforms easily,
	# so we pass inv_projection as a mat4 built from the Projection type.
	_mat.set_shader_parameter("inv_projection", _inv_projection_matrix(cam))
	_mat.set_shader_parameter("inv_view",       cam.global_transform)  # mat4 from Transform3D

	# ── Sphere data ────────────────────────────────────────────────
	var spheres : Array = []
	for node in sphere_nodes:
		if node and is_instance_valid(node):
			var p := node.global_position
			spheres.append(Vector4(p.x, p.y, p.z, sphere_radius))

	# Pad to 8
	while spheres.size() < 8:
		spheres.append(Vector4(0.0, 0.0, 0.0, 0.0))

	_mat.set_shader_parameter("colored_spheres", spheres)
	_mat.set_shader_parameter("sphere_count",    mini(sphere_nodes.size(), 8))


# ── Helpers ────────────────────────────────────────────────────────

func _inv_projection_matrix(cam: Camera3D) -> Projection:
	return cam.get_camera_projection().inverse()
