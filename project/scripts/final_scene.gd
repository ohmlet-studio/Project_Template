extends Control

@export var DEBUG: bool = false

const text_speed = 0.08
const timer = 1.5
const timer_dial = 0.5
const audioback_db_lvl = -25

@onready var pickable_slot: Pickable
@onready var pickable_slot2: Pickable
@onready var pickable_slot3: Pickable
@onready var slots = [$SubViewportContainer/SubViewport/Objects/Slot, $SubViewportContainer/SubViewport/Objects/Slot2, $SubViewportContainer/SubViewport/Objects/Slot3]
@onready var haiku_label: Label = $Haiku
@onready var anim1: AnimationPlayer = $"Anim/1stObj"
@onready var anim2: AnimationPlayer = $"Anim/2ndObj"
@onready var anim3: AnimationPlayer = $"Anim/3rdObj"

@onready var is_haiku_finished = false
@onready var is_obj_playing = false

func _ready() -> void:
	
	var slot_id = 0
	
	if not DEBUG:
		Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	
	## Debug label
	var debug_string1: String = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt"
	var debug_string2: String = " ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat."
	var debug_string3: String = " Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur."
	
	haiku_label.text = ""

	pickable_slot = Manager.all_picked_object[2]
	pickable_slot2 = Manager.all_picked_object[1]
	pickable_slot3 = Manager.all_picked_object[0]
	
	if not DEBUG:
		## Clear slots
		for slot in slots:
			for n in slot.get_children():
				slot.remove_child(n)
				n.queue_free() 
		for memory: Pickable in [pickable_slot, pickable_slot2, pickable_slot3]:
			if not memory or DEBUG:
				continue
			var path = memory.object_to_scan.resource_path
			var object_room1: Node3D = load(path).instantiate()
			object_room1.scale = Vector3.ONE * memory.inspect_scale
			object_room1.rotation = memory.default_inspect_rotation
			slots[slot_id].add_child(object_room1)
			slot_id += 1

	# Play 1st haiku
	if DEBUG:
		await haiku_label.char2char(debug_string1, text_speed)
	else:
		await haiku_label.char2char(pickable_slot.haiku, text_speed)
		
	# Play 2nd haiku
	await get_tree().create_timer(timer).timeout
	anim2.play("start")
	if DEBUG:
		await haiku_label.char2char(debug_string2, text_speed)
	else:
		await haiku_label.char2char(pickable_slot2.haiku, text_speed)
	
	# Play last haiku
	await get_tree().create_timer(timer).timeout
	anim3.play("start")
	if DEBUG:
		await haiku_label.char2char(debug_string3, text_speed)
	else:
		await haiku_label.char2char(pickable_slot3.haiku, text_speed)

	$Anim/ExitButton.play("anim")
	is_haiku_finished = true
	
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _on_obj_1_mouse_entered() -> void:
	if is_haiku_finished or DEBUG:
		print("Hover obj1")
		$Anim/Button1.play("anim")
		
func _on_obj_1_mouse_exited() -> void:
	if is_haiku_finished or DEBUG:
		print("Quit obj1")
		$Anim/Button1.play_backwards("anim")

func _on_obj_2_mouse_entered() -> void:
	if is_haiku_finished or DEBUG:
		print("Hover obj2")
		$Anim/Button2.play("anim")

func _on_obj_2_mouse_exited() -> void:
	if is_haiku_finished or DEBUG:
		$Anim/Button2.play_backwards("anim")
		

func _on_obj_3_mouse_entered() -> void:
	if is_haiku_finished or DEBUG:
		print("Hover obj3")
		$Anim/Button3.play("anim")

func _on_obj_3_mouse_exited() -> void:
	if is_haiku_finished or DEBUG:
		$Anim/Button3.play_backwards("anim")
		


func _on_obj_1_pressed() -> void:
	if is_haiku_finished or DEBUG:
		print("Pressed obj1")
		$AudioBack.volume_db = audioback_db_lvl
		if DEBUG:
			$Subtitles.sub_load_from_file("res://assets/audio/PIECE_1/SOUVENIRS/Souvenir_1-2_ENG.srt")
			$Subtitles.play_dialog(load("res://assets/audio/PIECE_1/SOUVENIRS/Souvenir_1-2.mp3"), false)
		else:
			$Subtitles.sub_load_from_file(pickable_slot.dialog_subtitle)
			$Subtitles.play_dialog(pickable_slot.dialog_audio, false)
		

func _on_obj_2_pressed() -> void:
	if is_haiku_finished or DEBUG:
		print("Pressed obj2")
		$AudioBack.volume_db = audioback_db_lvl
		if DEBUG:
			$Subtitles.sub_load_from_file("res://assets/audio/PIECE_1/SOUVENIRS/Souvenir_1-1_ENG.srt")
			$Subtitles.play_dialog(load("res://assets/audio/PIECE_1/SOUVENIRS/Souvenir_1-1.mp3"), false)
		else:
			$Subtitles.sub_load_from_file(pickable_slot2.dialog_subtitle)
			$Subtitles.play_dialog(pickable_slot2.dialog_audio, false)

func _on_obj_3_pressed() -> void:
	if is_haiku_finished or DEBUG:
		print("Pressed obj2")
		$AudioBack.volume_db = audioback_db_lvl
		if DEBUG:
			$Subtitles.sub_load_from_file("res://assets/audio/PIECE_1/SOUVENIRS/Souvenir_1-3_ENG.srt")
			$Subtitles.play_dialog(load("res://assets/audio/PIECE_1/SOUVENIRS/Souvenir_1-3.mp3"), false)
		else:
			$Subtitles.sub_load_from_file(pickable_slot3.dialog_subtitle)
			$Subtitles.play_dialog(pickable_slot3.dialog_audio, false)

func _on_subtitles_dialog_finished() -> void:
	await get_tree().create_timer(timer_dial).timeout
	$AudioBack.volume_db = 0


func _on_exit_button_mouse_entered() -> void:
	if is_haiku_finished or DEBUG:
		$Anim/ExitHover.play("anim")
		

func _on_exit_button_mouse_exited() -> void:
	if is_haiku_finished or DEBUG:
		$Anim/ExitHover.play_backwards("anim")

func _on_exit_button_pressed() -> void:
	if is_haiku_finished or DEBUG:
		$Anim/Leeeeave.play("anim")
		$AudioClick.play()
		$AudioBack.stop()
		$Subtitles.audio_player.stop()
		$FadeTransitionManager.fade_out()
