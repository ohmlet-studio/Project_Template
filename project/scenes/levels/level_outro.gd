@tool
extends LevelRoom

@export var credits_scene_door: PortalDoor
@onready var stream3d = $AudioStreamPlayer3D

var clic_sound = preload("res://assets/audio/AUTRES/FX/Clic.mp3")

func _ready() -> void:
	super._ready()

func _on_teleport():
	super._on_teleport()
	Manager.globPlayer.color_view = true

func _connect_portals_to_end():
	for portal: PortalDoor in [portal_door_1, portal_door_2]:
		portal.other_door = credits_scene_door
		portal.activate()

func _play_transition_end():
	stream3d.stream = clic_sound
	stream3d.playing = true
