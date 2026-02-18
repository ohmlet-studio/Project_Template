extends Node2D

@onready var viewport = $CanvasLayer/SubViewport

func _input(event):
	if viewport and is_inside_tree():
		viewport.push_input(event)

func _unhandled_input(event):
	if viewport and is_inside_tree():
		viewport.push_unhandled_input(event)
