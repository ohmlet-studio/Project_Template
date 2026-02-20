@tool
extends Node

var object_material : Material
var clone_2d_view: Node3D
var clone_inspect_view: Node3D
var scanned_object_instance: Node3D # never scale this, scale in blender and apply transform
var picked: bool = false

@onready var handObjView = $inHandUI
@onready var subviewport: SubViewport = $inHandUI/SubViewport
@onready var interactable_3d: Interactable3D = $Interactable3D
@onready var color_sphere = $ColorSphere

@export var object_name: String = "":
	set(value):
		object_name = value
		_set_object_name(value)

@export var object_to_scan: PackedScene:
	set(value):
		object_to_scan = value
		_set_object_to_scan(value)

@export var scale_2d_view: float = 1.0:
	set(value):
		scale_2d_view = value
		if clone_2d_view:
			clone_2d_view.scale = Vector3.ONE * value

@export var inspect_scale: float = 1.0:
	set(value):
		inspect_scale = value
		if clone_inspect_view:
			clone_inspect_view.scale = Vector3.ONE * value
			
@export var default_inspect_rotation: Vector3 = Vector3.ZERO:
	set(value):
		default_inspect_rotation = value
		if clone_inspect_view:
			clone_inspect_view.rotation = value

@export var has_been_scanned: bool = false

@export var color_radius: float = 1.0

@export var dialog_audio: AudioStream:
	set(value):
		dialog_audio = value

@export var dialog_subtitle: String :
	set(value):
		dialog_subtitle = value

var _base_radius: float = 0.0
var _breath_time: float = 0.0
var _scan_tween: Tween
var _interact_tween: Tween

func _ready() -> void:
	_set_object_name(object_name)
	_set_object_to_scan(object_to_scan)
	clone_inspect_view.scale = Vector3.ONE * inspect_scale
	clone_2d_view.scale = Vector3.ONE * scale_2d_view
	clone_inspect_view.rotation = default_inspect_rotation
	_base_radius = color_radius

	if Engine.is_editor_hint():
		return
		
	interactable_3d.interacted.connect(_on_interact)
	ScanInteractableLayer.scan_ended.connect(_on_scan_ended)
	interactable_3d.scanned.connect(_on_scan_started)
	picked = false

func _set_object_name(value: String) -> void:
	if not is_node_ready():
		return
	var interactable_3d = get_node_or_null("Interactable3D")
	if not interactable_3d:
		return
	interactable_3d.id = value
	interactable_3d.title = value

func _set_object_to_scan(value: PackedScene) -> void:
	if not is_node_ready():
		return
	var interactable_3d = get_node_or_null("Interactable3D")
	var subviewport = get_node_or_null("inHandUI/SubViewport")
	if not interactable_3d or not subviewport:
		return

	if clone_2d_view:
		clone_2d_view.queue_free()
	if scanned_object_instance:
		scanned_object_instance.queue_free()
	if clone_inspect_view:
		clone_inspect_view.queue_free()
	if not value:
		return

	scanned_object_instance = value.instantiate()
	self.add_child(scanned_object_instance)

	var origMesh = scanned_object_instance.get_child(0)
	print(origMesh)
	object_material = origMesh.get_active_material(0).duplicate()
	origMesh.set_layer_mask_value(2, true)

	clone_2d_view = scanned_object_instance.duplicate()
	subviewport.add_child(clone_2d_view)
	clone_2d_view.scale = Vector3.ONE * scale_2d_view

	clone_inspect_view = scanned_object_instance.duplicate()
	self.add_child(clone_inspect_view)
	clone_inspect_view.scale = Vector3.ONE * inspect_scale
	clone_inspect_view.position = Vector3.DOWN * 100
	clone_inspect_view.set_meta("scan_owner", self)
	interactable_3d.target_scannable_object = clone_inspect_view

func _on_interact() -> void:
	if has_been_scanned and Manager.is_all_scanned:
		picked = not picked
		_origin_obj_transparency(picked)
		_show_hand_obj(picked)
	if picked:
		if not Manager.is_one_picked:
			Manager.is_one_picked = true
		Manager.pick_obj_name = object_name

func _origin_obj_transparency(pick: bool) -> void:
	# legacy code for older shader
	# var mesh = scanned_object_instance.get_child(0)
	# var material: Material = mesh.get_surface_override_material(0)
	# var color: Color = material.get_shader_parameter("color")
	# color.a = 0.5 if pick else 1
	# material.set_shader_parameter("color", color)

	var mesh = scanned_object_instance.get_child(0)
	var material: StandardMaterial3D = mesh.get_surface_override_material(0)
	# or mesh.get_active_material(0) if no override is set

	if material:
		material.albedo_color.a = 0.5 if pick else 1.0
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

func _show_hand_obj(pick: bool) -> void:
	if pick:
		handObjView.show()
	else:
		handObjView.hide()

func _on_scan_started() -> void:
	Manager.object_picked.emit()
	
	has_been_scanned = true
	
	if _scan_tween:
		_scan_tween.kill()
	
	_scan_tween = create_tween()

	_scan_tween.tween_method(
		func(v):
			color_radius = v,
			color_radius, _base_radius * 20.0, 2.0
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	SubtitlesScene.sub_load_from_file(dialog_subtitle)
	SubtitlesScene.play_dialog(dialog_audio)

func _on_scan_ended(scanned_object: Node3D) -> void:
	if scanned_object and scanned_object.get_meta("scan_owner", null) == self:
		if _scan_tween:
			_scan_tween.kill()
		_scan_tween = create_tween()
		_scan_tween.tween_method(
			func(v): color_radius = v,
			_base_radius * 20.0, 0.0, 1.0
		).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	

func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
		
	_breath_time += delta

	var dist = Manager.globPlayer.global_position.distance_to(self.global_position)
	var proximity_factor = clamp(dist / 1.5, 0.0, 1.0) if not has_been_scanned else 1.0
	var breath = sin(_breath_time * 2.0) * 0.1 + 0.9

	color_sphere.scale = Vector3.ONE * (color_radius * proximity_factor * breath)
	
	## Check if another object is picked and if it is self
	if Manager.is_one_picked and not Manager.pick_obj_name.is_empty():
		## double check picked in case, just to make sure there's no knots in code
		if picked and Manager.pick_obj_name != object_name:
			_on_interact()
