@tool
extends Node
@onready var level = $"../../../../.."
@onready var backpack = $".."
@export var sound_after: AudioStream
@export var music_after: AudioStream
@export var subs_path: String

func _ready():
	backpack.scan_ended.connect(_on_scan_ended)

func _on_scan_ended() -> void:
	backpack.pick()
	level._connect_portals_to_end()
	level.portal_door_1.close_instant()
	level.portal_door_2.close_instant()
	
	for portal in [level.portal_door_1, level.portal_door_2]:
		portal.opened.connect(_on_portal_opened)

func _on_portal_opened() -> void:
	var tree = get_tree()
	
	# Fade to black over 2 seconds
	var tween = create_tween()
	tree.paused = false
	tween.tween_method(
		func(v: float): tree.root.get_viewport().canvas_item.modulate.a = v,
		1.0, 0.0, 2.0
	)
	await tween.finished
	
	# Teleport to haiku scene
	tree.change_scene_to_file("res://scenes/haiku.tscn")
