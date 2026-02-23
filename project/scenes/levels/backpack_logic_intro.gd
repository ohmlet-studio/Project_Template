@tool
extends Node

@onready var level = $"../../../../.."
@onready var backpack = $".."
@export var sound_after: AudioStream
@export var music_after: AudioStream
@export var subs_path: String

func _ready():
	backpack.scan_started.connect(_on_scan_started)
	backpack.scan_ended.connect(_on_scan_ended)

func _on_scan_started() -> void:
	await get_tree().create_timer(2.0).timeout
	Manager.globPlayer.color_view = false

func _on_scan_ended() -> void:
	print("BACKPACK SCAN ENDED")
	SubtitleScene.sub_load_from_file(subs_path)
	SubtitleScene.play_dialog(sound_after)

	CrossfadePlayer.play(music_after, 2.0)
	level.link_next_room()
