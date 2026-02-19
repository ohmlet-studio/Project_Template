extends Node

@onready var viewport = $CanvasLayer/SubViewport
@export var use_camera_2: bool = false

func _ready():
	%SettingsMenu.closed.connect(_on_pause_menu_closed)

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		%SettingsMenu.show()
	elif viewport and is_inside_tree():
		viewport.push_input(event)

func _process(delta: float) -> void:
	%ColorMaskCamera3D.global_transform = %Player.get_camera.global_transform
	if use_camera_2:
		$PlayingView.texture = $CanvasLayer/MaskViewport.get_texture()
	else:
		$PlayingView.texture = $CanvasLayer/SubViewport.get_texture()
	
	$PlayingView.material.set_shader_parameter("color_mask", $CanvasLayer/MaskViewport.get_texture())

func _unhandled_input(event):
	if viewport and is_inside_tree():
		viewport.push_unhandled_input(event)

func _on_pause_menu_closed():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
