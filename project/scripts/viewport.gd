extends Node

@onready var viewport = $CanvasLayer/SubViewport
@onready var interactable_information: RichTextLabel = %InterInfo
@onready var dot_cursor: Control = $InteractableInfo/Control/CenterContainer/DotCursor
@export var use_camera_2: bool = false

var is_scanning: bool = false
var current_scanned_interactable: Interactable3D = null

func _ready():
	interactable_information.text = ""
	
	GlobalInteractionEvents.interactable_focused.connect(_on_interactable_focused)
	GlobalInteractionEvents.interactable_unfocused.connect(_on_interactable_unfocused)
	GlobalInteractionEvents.interactable_interacted.connect(_on_interactable_interacted)
	ScanInteractableLayer.scan_ended.connect(_on_scan_ended)
	
	get_window().focus_exited.connect(_on_game_paused)
	
	Manager.globPlayer.action_back.connect(_on_game_paused)
	%SettingsMenu.closed.connect(_on_pause_menu_closed)
	
	Manager.playing_view_rect = $PlayingView

func _on_window_focus_exited() -> void:
	_on_game_paused()

func _input(event):
	if viewport and is_inside_tree():
		viewport.push_input(event)


func _process(delta: float) -> void:
	%ColorMaskCamera3D.global_transform = Manager.globPlayer.get_camera.global_transform
	$PlayingView.material.set_shader_parameter("color_mask", $CanvasLayer/MaskViewport.get_texture())

func _on_game_paused():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%SettingsMenu.show()

func _on_pause_menu_closed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _on_interactable_focused(interactable: Interactable3D) -> void:
	if not is_scanning:
		dot_cursor.focused = true

		if "has_been_scanned" in interactable.get_parent():
			if not interactable.get_parent().has_been_scanned:
				interactable_information.text = "[font_size=35][i][E] to interact with %s[/i][/font_size]" % interactable.title
			elif interactable.get_parent().has_been_scanned and interactable.get_parent().room.all_objects_scanned():
				interactable_information.text = "[font_size=35][i][E] to pick %s[/i][/font_size]" % interactable.title

func _on_interactable_unfocused(_interactable: Interactable3D) -> void:
	dot_cursor.focused = false
	interactable_information.clear()
	interactable_information.text = ""


func _on_interactable_interacted(interactable: Interactable3D) -> void:
	if not interactable.scannable:
		return
	# Block player
	is_scanning = true
	
	current_scanned_interactable = interactable
	#Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%Blurring.visible = true
	interactable_information.clear()
	interactable_information.text = ""

func _unscan() -> void:
	ScanInteractableLayer.scan_interactable.end_scan()
	_finish_scan_state()


func _on_scan_ended(_target: Node3D) -> void:
	_finish_scan_state()


func _finish_scan_state() -> void:
	is_scanning = false
	current_scanned_interactable = null
	%Blurring.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_IN:
		_on_game_paused()
		
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_on_game_paused()
