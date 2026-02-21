extends Node

var curCamera: Camera3D
var globPlayer: CharacterBody3D
var current_room: LevelRoom

## Object pick handle
signal object_picked
var pickObj_count = 0

## Current pick object name
var is_one_picked: bool
var pick_obj_name: String:
	set(value):
		pick_obj_name = value
var all_picked_object: Array[String] = []
