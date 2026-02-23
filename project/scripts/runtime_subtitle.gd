extends Node

signal dialog_finished
signal dialog_started

@onready var skip_dialog: bool = false

#@export var audio_player: AudioStreamPlayer
#@export var subtitle_label: Label

@onready var audio_player: AudioStreamPlayer = $DialogPlayer
@onready var subtitle_label: Label = $SubLabel

var subtitle_data: Subtitles = Subtitles.new()
var current_time: float = 0.0

func _ready() -> void:
	pass
	#je sais c'est moche et je devrai créer un audio controller
	#self.subtitle_label = get_child(0)
	#audio_player = get_child(1)
	#if audio_player and not audio_player.finished.is_connected(_on_dialog_finished):
	#	audio_player.finished.connect(_on_dialog_finished)


func _on_dialog_finished() -> void:
	if subtitle_label:
		subtitle_label.text = ""
	dialog_finished.emit()

# Load and play audio dialog
func play_dialog(dialog : AudioStream, is_entering_lvl: bool) -> void:
	if audio_player == null:
		return
	if dialog == null:
		print("Dialog : failed to load audio stream", )
		return

	audio_player.stream = dialog
	if not skip_dialog:
		audio_player.play()
	
	print("Dialog : Playing ", audio_player.stream)
	#if is_entering_lvl:
		#Manager.lock_door.emit()
	
	dialog_started.emit()
	if not skip_dialog:
		await audio_player.finished
	else:
		await get_tree().create_timer(1).timeout
	dialog_finished.emit()
	
	#if is_entering_lvl:
		#Manager.unlock_door.emit()
	

# Load and parse a subtitle file at runtime
func sub_load_from_file(srt_path : String) -> void:
	var subtitle_path: String = srt_path

	# loadng subs for web
	var loaded_resource: Resource = ResourceLoader.load(subtitle_path)
	if loaded_resource != null and loaded_resource is Subtitles:
		subtitle_data = loaded_resource
		_last_entry_id = -1
		print("Sub : Successfully loaded subtitle resource")
		#print("  Entries: ", subtitle_data.get_entry_count())
		#print("  Duration: ", subtitle_data.get_total_duration(), " seconds")
		return



## Example 4: Sync subtitles with audio playback (optimized with entry ID caching)
var _last_entry_id: int = -1


func _process(_p_delta: float) -> void:
	if audio_player == null or subtitle_label == null:
		return

	# Get current playback position
	current_time = audio_player.get_playback_position()

	# Optimized approach: Use get_entry_id_at_time() to avoid string allocations
	# Only update the label text when the subtitle actually changes
	var current_entry_id: int = subtitle_data.get_entry_id_at_time(current_time)

	if current_entry_id != _last_entry_id:
		_last_entry_id = current_entry_id

		if current_entry_id == -1:
			# No subtitle active
			subtitle_label.text = ""
		else:
			# Get the subtitle text only when it changed
			subtitle_label.text = subtitle_data.get_entry_text(current_entry_id)
