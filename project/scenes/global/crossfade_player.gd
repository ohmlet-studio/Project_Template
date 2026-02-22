extends Node

@onready var players = [$Player1, $Player2]
var current = 0

func play(stream: AudioStream, duration: float = 1.0):
	print("CrossFading new track: ", stream.resource_path)
	var next = 1 - current

	players[next].stream = stream
	players[next].volume_db = -80.0
	players[next].play()

	var tween = create_tween().set_parallel(true)
	tween.tween_property(players[current], "volume_db", -80.0, duration)
	tween.tween_property(players[next], "volume_db", 0.0, duration)
	await tween.finished

	players[current].stop()
	current = next

func stop(duration: float = 1.0):
	var tween = create_tween()
	tween.tween_property(players[current], "volume_db", -80.0, duration)
	await tween.finished
	players[current].stop()
