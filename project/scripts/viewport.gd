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
	
	Manager.globPlayer.action_back.connect(_on_game_paused)
	%SettingsMenu.closed.connect(_on_pause_menu_closed)

func _input(event):
	if viewport and is_inside_tree():
		if is_scanning and event.is_action_pressed("interact"):
			_unscan()
			get_viewport().set_input_as_handled()
			return
		viewport.push_input(event)


func _process(delta: float) -> void:
	%ColorMaskCamera3D.global_transform = Manager.globPlayer.get_camera.global_transform
	if use_camera_2:
		$PlayingView.texture = $CanvasLayer/MaskViewport.get_texture()
	else:
		$PlayingView.texture = $CanvasLayer/SubViewport.get_texture()
	
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
				interactable_information.text = "[font_size=35][i][E] to interact %s[/i][/font_size]" % interactable.title
			elif interactable.get_parent().has_been_scanned and Manager.current_room.all_objects_scanned():
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
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	interactable_information.clear()
	interactable_information.text = ""

func _unscan() -> void:
	is_scanning = false
	current_scanned_interactable = null
	ScanInteractableLayer.scan_interactable.end_scan()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
