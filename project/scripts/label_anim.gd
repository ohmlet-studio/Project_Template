extends Label

func _ready() -> void:
	pass

func _process(delta: float) -> void:
	pass

func char2char(text: String, char_display_speed: float):
	#$".".text = ""
	
	for i in range(text.length()):
		$".".text += text[i]
		await get_tree().create_timer(char_display_speed).timeout
