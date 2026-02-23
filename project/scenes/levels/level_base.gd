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

@export var is_intro: bool = false
@export var is_outro: bool = false

@export_category("TELEPORT")
@export var dont_link_portals: bool = false
@export var next_room: LevelRoom
@export var teleports_to: LevelRoom = null
@export var is_special_lvl: bool = false

@export_category("audio")

@export var entering_sound: AudioStream
@export var subtitles_path: String
@export var level_musics: Array[AudioStream]

const AIDE_AUDIO_PATH := "res://assets/audio/AUTRES/Aide.mp3"
const AIDE_SUBTITLE_PATH := "res://assets/audio/AUTRES/Aide_ENG.srt"

@export_category("DEBUG")
@export var ready_direct: bool = false
@export var no_anim_color: bool = false

@onready var portal_door_1: PortalDoor = %PortalDoorMain
@onready var portal_door_2: PortalDoor = %PortalDoorBed
@onready var pickable_parent = $Room/Interactable/Grabbable

var number_of_object_scanned = 0
var is_player_never_entered = true
var empty_level = false

func _ready() -> void:
	_static_objects.visible = show_static_objects
	
	# Set no picked object at beginning
	# commented out as it was causing crashes, on it now
	#Manager.is_all_picked = false
	print("ready room ", self)
	
	_create_furniture_collisions()
	_link_portals(teleports_to)
	
	empty_level = pickable_parent.get_children().size() == 0
	
	for child: Pickable in pickable_parent.get_children():
		child.scan_ended.connect(_on_scan_ended.bind(child))
		child.on_picked.connect(_on_object_picked)
		child.on_unpicked.connect(_on_object_unpicked)
		
	#Manager.lock_door.connect(_lock_door_on_entry)
	#Manager.unlock_door.connect(_unlock_door_on_entry)
	
	portal_door_1.open_instant()
	portal_door_2.open_instant()
	
	if not dont_link_portals and not is_special_lvl and empty_level or ready_direct:
		link_next_room()
		for child: Pickable in pickable_parent.get_children():
			child.scanned = true
		
func _set_grabbables_interaction_enabled(enabled: bool) -> void:
	for child: Pickable in pickable_parent.get_children():
		child.color_radius = 1.0 if enabled else 0.0
		if child.interactable_3d:
			child.interactable_3d.can_be_interacted = enabled

func _on_teleport():
	# level finished
	print("\n \n In room ", self.name)
	if next_room == $"../LevelAdulte":
		%LabelCorridor.visible = false
	if teleports_to == next_room:
		await get_tree().create_timer(1.0)
		_remove_layer_recursive(self, 2) # remove all things colored
	elif is_player_never_entered:
		is_player_never_entered = false
		
		if not (is_intro or is_special_lvl):
			if Manager.pick_obj:
				Manager.all_picked_object.append(Manager.pick_obj.duplicate())
				print("OBJ : Picked obj array : ", Manager.all_picked_object)
		
		if level_musics.size() > 0:
			CrossfadePlayer.play(level_musics[0], 0.0)

		if ready_direct:
			set_layer_2()
		
		if not subtitles_path:
			subtitles_path = entering_sound.resource_path.replace(".mp3", "_ENG.srt")
		
		_set_grabbables_interaction_enabled(false)
		SubtitleScene.sub_load_from_file(subtitles_path)
		SubtitleScene.play_dialog(entering_sound, true)
		await SubtitleScene.dialog_finished
		_set_grabbables_interaction_enabled(true)
		
		if level_musics.size() > 0:
			CrossfadePlayer.play(level_musics[0], 0.0)
		
		# no object, link
		if empty_level or ready_direct:
			link_next_room()
	else:
		await SubtitleScene.dialog_finished
		if not Manager.is_one_picked or not is_special_lvl:
			_play_aide_dialog()

func all_objects_scanned():
	for child: Pickable in pickable_parent.get_children():
		if not child.scanned:
			return false
	return true

func _play_aide_dialog() -> void:
	var aide_audio := load(AIDE_AUDIO_PATH) as AudioStream
	SubtitleScene.sub_load_from_file(AIDE_SUBTITLE_PATH)
	SubtitleScene.play_dialog(aide_audio, false)

func _link_portals(other_room: LevelRoom):
	if dont_link_portals:
		return
	
	await get_tree().process_frame
	
	if other_room == null:
		other_room = self
		
	print("Link : ", self.name, " --> ", other_room.name)

	for portal: PortalDoor in [portal_door_1, portal_door_2]:
		portal.show()
		var other_portal = other_room.portal_door_2 if portal == portal_door_1 else other_room.portal_door_1
		portal.other_door = other_portal
		portal.teleported_player.connect(_on_teleport)

		if portal.is_opened:
			other_portal.open_instant()
	
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
	#if not is_intro_outro:
		#Manager.all_picked_object.append(Manager.pick_obj)
		#print("On pick / All obj : ", Manager.all_picked_object)
	link_next_room()

func _on_object_unpicked():
	#if not is_intro_outro:
		#Manager.all_picked_object.pop_back()
		#print("On unpick / All obj : ", Manager.all_picked_object)
	unlink_next_room()
	
func _lock_door_on_entry():
	for door in _static_objects.get_children():
		for child in door.get_children():
			if child is Door3D:
				print("lock door")
				child.is_locked = true

func _unlock_door_on_entry():
	for door: PortalDoor in _static_objects.get_children():
		for child in door.get_children():
			if child is Door3D:
				print("unlock door")
				child.is_locked = false

func unlink_next_room():
	teleports_to = null
	_link_portals(self)

func link_next_room():
	teleports_to = next_room
	_link_portals(next_room)

func set_layer_2():
	for object in _static_objects.get_children():
		_set_layer_recursive(object, 2)
		
	var room_parent = $Room/Interactable/Static/room
	_set_layer_recursive(room_parent, 2)
