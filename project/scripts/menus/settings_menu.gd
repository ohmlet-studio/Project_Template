extends Control

const BUS_MASTER := "Master"
const BUS_VOICE := "Voice"
const BUS_MUSIC := "Music"
const BUS_SFX := "SFX"
const MUTE_DB := -80.0
const MIN_LINEAR := 0.001

@onready var master_slider: HSlider = %MasterSlider
@onready var voice_slider: HSlider = %VoiceSlider
@onready var music_slider: HSlider = %MusicSlider
@onready var sfx_slider: HSlider = %SfxSlider
@onready var backdrop: ColorRect = $Backdrop
@onready var close_button: Button = $CenterContainer/Panel/Margin/VBox/TitleRow/CloseButton

signal closed

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_sync_sliders_with_buses()
	_connect_signals()
	backdrop.gui_input.connect(_on_backdrop_gui_input)
	close_button.pressed.connect(_close)
	visibility_changed.connect(_on_visibility_changed)
	_apply_pause_state()
	hide()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return

func _on_visibility_changed() -> void:
	_apply_pause_state()

func _apply_pause_state() -> void:
	get_tree().paused = visible

func _sync_sliders_with_buses() -> void:
	master_slider.value = _get_bus_linear(BUS_MASTER)
	voice_slider.value = _get_bus_linear(BUS_VOICE)
	music_slider.value = _get_bus_linear(BUS_MUSIC)
	sfx_slider.value = _get_bus_linear(BUS_SFX)

func _connect_signals() -> void:
	master_slider.value_changed.connect(_on_master_changed)
	voice_slider.value_changed.connect(_on_voice_changed)
	music_slider.value_changed.connect(_on_music_changed)
	sfx_slider.value_changed.connect(_on_sfx_changed)

func _on_backdrop_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_close()
		accept_event()

func _close() -> void:
	closed.emit()
	hide()

func _get_bus_linear(bus_name: String) -> float:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return 1.0
	var db := AudioServer.get_bus_volume_db(index)
	return clamp(db_to_linear(db), 0.0, 1.0)

func _set_bus_volume(bus_name: String, linear: float) -> void:
	var index := AudioServer.get_bus_index(bus_name)
	if index == -1:
		return
	if linear <= 0.0:
		AudioServer.set_bus_volume_db(index, MUTE_DB)
		return
	AudioServer.set_bus_volume_db(index, linear_to_db(clamp(linear, MIN_LINEAR, 1.0)))

func _on_master_changed(value: float) -> void:
	_set_bus_volume(BUS_MASTER, value)

func _on_voice_changed(value: float) -> void:
	_set_bus_volume(BUS_VOICE, value)

func _on_music_changed(value: float) -> void:
	_set_bus_volume(BUS_MUSIC, value)

func _on_sfx_changed(value: float) -> void:
	_set_bus_volume(BUS_SFX, value)
