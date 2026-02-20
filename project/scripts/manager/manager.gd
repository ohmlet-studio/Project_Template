extends Node

var curCamera: Camera3D
var globPlayer: CharacterBody3D

## Object pick handle
var maxObj = 1  		## number of object inside level
var is_all_picked: bool
signal object_picked
var pickObj_count = 0

func _ready() -> void:
	object_picked.connect(_handle_pick)

func _handle_pick() -> void:
	pickObj_count += 1
	if pickObj_count == maxObj:
		is_all_picked = true
	else:
		is_all_picked = false
	
