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

const AIDE_AUDIO_PATH := "res://assets/audio/AUTRES/Aide.mp3"
const AIDE_SUBTITLE_PATH := "res://assets/audio/AUTRES/Aide ENG.srt"

@export_category("DEBUG")
@export var ready_direct: bool = false
@export var no_anim_color: bool = false

@onready var portal_door_1: PortalDoor = $Room/Interactable/Static/PortalDoorMain
@onready var portal_door_2: PortalDoor = $Room/Interactable/Static/PortalDoorBed
@onready var pickable_parent = $Room/Interactable/Grabbable

var number_of_object_scanned = 0
var is_player_never_entered = true
var empty_level = false

func _ready() -> void:
	_static_objects.visible = show_static_objects
	
	# Set no picked object at beginning
	# commented out as it was causing crashes, on it now
	#Manager.is_all_picked = false
	
	_create_furniture_collisions()
	_link_portals(teleports_to)
	
	empty_level = pickable_parent.get_children().size() == 0
	
	for child: Pickable in pickable_parent.get_children():
		child.scan_ended.connect(_on_scan_ended.bind(child))
		child.on_picked.connect(_on_object_picked)
		child.on_unpicked.connect(_on_object_unpicked)
		
	portal_door_1.open_instant()
	portal_door_2.open_instant()

func _set_grabbables_interaction_enabled(enabled: bool) -> void:
	for child: Pickable in pickable_parent.get_children():
		child.color_radius = 1.0 if enabled else 0.0
		if child.interactable_3d:
			child.interactable_3d.can_be_interacted = enabled

func _on_teleport():
	# level finished
	if teleports_to == next_room:
		await get_tree().create_timer(1.0)
		_remove_layer_recursive(self, 2) # remove all things colored
	elif is_player_never_entered:
		is_player_never_entered = false
		
		if ready_direct:
			set_layer_2()
		
		if not subtitles_path:
			subtitles_path = entering_sound.resource_path.replace(".mp3", " ENG.srt")
		
		_set_grabbables_interaction_enabled(false)
		SubtitlesScene.sub_load_from_file(subtitles_path)
		SubtitlesScene.play_dialog(entering_sound)
		if SubtitlesScene:
			await SubtitlesScene.dialog_finished
		_set_grabbables_interaction_enabled(true)
		
		if level_musics.size() > 0:
			CrossfadePlayer.play(level_musics[0], 0.0)
		
		# no object, link
		if empty_level or ready_direct:
			link_next_room()
	else:
		if not Manager.is_one_picked:
			_play_aide_dialog()

func all_objects_scanned():
	for child: Pickable in pickable_parent.get_children():
		if not child.scanned:
			return false
	return true

func _play_aide_dialog() -> void:
	var aide_audio := load(AIDE_AUDIO_PATH) as AudioStream
	SubtitlesScene.sub_load_from_file(AIDE_SUBTITLE_PATH)
	SubtitlesScene.play_dialog(aide_audio)

func _link_portals(other_room: LevelRoom):
	await get_tree().process_frame
	
	if other_room == null:
		other_room = self
		
	print("Linking room ", self.name, " to ", other_room.name)
	
	print("Link portal 1 to ", other_room.portal_door_2)
	self.portal_door_1.other_door = other_room.portal_door_2
	self.portal_door_1.teleported_player.connect(_on_teleport)
	if self.portal_door_1.is_opened:
		other_room.portal_door_2.open_instant()
	
	print("Link portal 2 to ", other_room.portal_door_2)
	self.portal_door_2.other_door = other_room.portal_door_1
	self.portal_door_2.teleported_player.connect(_on_teleport)
	if self.portal_door_2.is_opened:
		other_room.portal_door_1.open_instant()

	
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
	number_of_object_scanned = min(number_of_object_scanned, level_musics.size() - 1)
	
	if number_of_object_scanned >= 0:
		CrossfadePlayer.play(level_musics[number_of_object_scanned], 1.0)
	
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
	if no_anim_color:
		return
		
	$AnimationPlayer.play("bring_color")
	
	await $AnimationPlayer.animation_finished
	set_layer_2()

func _on_object_picked():
	link_next_room()

func _on_object_unpicked():
	unlink_next_room()

func unlink_next_room():
	teleports_to = null
	_link_portals(self)

func link_next_room():
	teleports_to = next_room
	_link_portals(next_room)

func set_layer_2():
	for object in _static_objects.get_children():
		_set_layer_recursive(object, 2)
