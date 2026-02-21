@tool
extends Node3D
class_name LevelRoom

@onready var _static_objects: Node3D = $Room/Interactable/Static
@onready var _furniture: Node3D = $Room/Furniture
@export var show_static_objects: bool = true:
	set(value):
		show_static_objects = value
		if is_node_ready():
			_static_objects.visible = value

@export var next_room: LevelRoom

@export var teleports_to: LevelRoom = null

@export_category("audio")

@export var entering_sound: AudioStream
@export var subtitles_path: String
@export var level_musics: Array[AudioStream]

@onready var portal_door_1: PortalDoor = $Room/Interactable/Static/PortalDoorMain
@onready var portal_door_2: PortalDoor = $Room/Interactable/Static/PortalDoorBed
@onready var pickable_parent = $Room/Interactable/Grabbable

var number_of_object_scanned = 0
var is_player_never_entered = true

func _ready() -> void:
	_static_objects.visible = show_static_objects
	
	# Set no picked object at beginning
	# commented out as it was causing crashes, on it now
	#Manager.is_all_picked = false
	
	_create_furniture_collisions()
	_link_portals(teleports_to)
	for child: Pickable in pickable_parent.get_children():
		child.scan_ended.connect(_on_scan_ended.bind(child))

func _on_teleport():
	# level finished
	if teleports_to == next_room:
		await get_tree().create_timer(1.0)
		_remove_layer_recursive(self, 2) # remove all things colored
	elif is_player_never_entered:
		SubtitlesScene.sub_load_from_file(subtitles_path)
		SubtitlesScene.play_dialog(entering_sound)
		is_player_never_entered = false
		CrossfadePlayer.play(level_musics[0], 2.0)

func all_objects_scanned():
	for child: Pickable in pickable_parent.get_children():
		if not child.scanned:
			return false
	return true

func _link_portals(other_room: LevelRoom):
	await get_tree().process_frame
	
	if other_room == null:
		other_room = self
		
	print("Linking room ", self.name, " to ", other_room.name)
	
	print("Link portal 1 to ", other_room.portal_door_2)
	self.portal_door_1.other_door = other_room.portal_door_2
	self.portal_door_1.teleported_player.connect(_on_teleport)
	
	print("Link portal 2 to ", other_room.portal_door_2)
	self.portal_door_2.other_door = other_room.portal_door_1
	self.portal_door_2.teleported_player.connect(_on_teleport)
	
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

func _on_scan_ended(pickable: Pickable):
	if pickable.scan_tween:
		await pickable.scan_tween.finished
	
	print("_on_scan_ended")
	
	number_of_object_scanned += 1
	CrossfadePlayer.play(level_musics[number_of_object_scanned], 2.0)
	
	if all_objects_scanned():
		_bring_color_back()

func _set_layer_recursive(node: Node, layer_mask: int):
	if node is MeshInstance3D:
		node.layers |= layer_mask
	for child in node.get_children():
		_set_layer_recursive(child, layer_mask)

func _remove_layer_recursive(node: Node, layer_mask: int):
	if node is MeshInstance3D:
		node.layers &= ~layer_mask
	for child in node.get_children():
		_remove_layer_recursive(child, layer_mask)

func _bring_color_back():
	$AnimationPlayer.play("bring_color")
	
	await $AnimationPlayer.animation_finished
	
	for object in _static_objects.get_children():
		_set_layer_recursive(object, 2)
		
	teleports_to = next_room
	_link_portals(next_room)
