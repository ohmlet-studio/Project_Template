@tool
extends Pickable

@export var sound_after: AudioStream
@export var music_after: AudioStream

func _on_scan_started() -> void:
	# make things go grey grey
	$"../../../MeshInstance3D".hide()

func _on_scan_ended(scanned_object: Node3D) -> void:
	super._on_scan_ended(scanned_object)
	
	SubtitlesScene.play_dialog(sound_after)
	CrossfadePlayer.play(music_after, 2.0)
