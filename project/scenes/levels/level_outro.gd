@tool
extends LevelRoom

@export var credits_scene_door: PortalDoor
@onready var stream3d = $AudioStreamPlayer3D

func _ready() -> void:
	super._ready()

func _on_teleport():
	super._on_teleport()
	Manager.globPlayer.color_view = true

func _connect_portals_to_end():
	for portal: PortalDoor in [portal_door_1, portal_door_2]:
		portal.other_door = credits_scene_door

func _play_transition_end():
	pass
	# TODO CLICK ICI
	# stream3d.stream = "click"
