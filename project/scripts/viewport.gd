extends Node

@onready var viewport = $CanvasLayer/SubViewport
@onready var settings_menu = %SettingsMenu

func _input(event):
	if Input.is_key_pressed(KEY_ESCAPE):
		settings_menu.visible != settings_menu.visible
	
	if viewport and is_inside_tree():
		viewport.push_input(event)

func _unhandled_input(event):
	if viewport and is_inside_tree():
		viewport.push_unhandled_input(event)
	
