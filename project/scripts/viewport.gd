extends Node

@onready var viewport = $CanvasLayer/SubViewport
@onready var dot_cursor: Control = $CanvasLayer/SubViewport/Control/CenterContainer/DotCursor
@export var use_camera_2: bool = false
@onready var player = $CanvasLayer/SubViewport/World/Player

func _ready():
	GlobalInteractionEvents.interactable_focused.connect(_on_interactable_focused)
	GlobalInteractionEvents.interactable_unfocused.connect(_on_interactable_unfocused)
	
	CameraManager.curCamera = $CanvasLayer/SubViewport/World/Player/Head/Camera3D
	player.action_back.connect(_on_game_paused)
	%SettingsMenu.closed.connect(_on_pause_menu_closed)

func _input(event):
	if viewport and is_inside_tree():
		viewport.push_input(event)

func _process(delta: float) -> void:
	%ColorMaskCamera3D.global_transform = %Player.get_camera.global_transform
	if use_camera_2:
		$PlayingView.texture = $CanvasLayer/MaskViewport.get_texture()
	else:
		$PlayingView.texture = $CanvasLayer/SubViewport.get_texture()
	
	$PlayingView.material.set_shader_parameter("color_mask", $CanvasLayer/MaskViewport.get_texture())

func _on_game_paused():
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	%SettingsMenu.show()

func _unhandled_input(event):
	if viewport and is_inside_tree():
		viewport.push_unhandled_input(event)

func _on_pause_menu_closed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func _on_interactable_focused(interactable: Interactable3D) -> void:
	dot_cursor.focused = true

func _on_interactable_unfocused(_interactable: Interactable3D) -> void:
	dot_cursor.focused = false
