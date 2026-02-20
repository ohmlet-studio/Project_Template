extends Node

var curCamera: Camera3D
var globPlayer: CharacterBody3D

## Object pick handle
var maxObj = 3  		## number of object inside level
var is_all_scanned: bool
signal object_picked
var pickObj_count = 0

## Current pick object name
var is_one_picked: bool
var pick_obj_name: String:
	set(value):
		pick_obj_name = value
var all_picked_object: Array[String] = []

func _ready() -> void:
	object_picked.connect(_handle_pick)

func _handle_pick() -> void:
	pickObj_count += 1
	if pickObj_count == maxObj:
		is_all_scanned = true
	else:
		is_all_scanned = false
	
