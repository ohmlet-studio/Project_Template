extends Node

var curCamera: Camera3D
var globPlayer: CharacterBody3D
var current_room: LevelRoom
var playing_view_rect: TextureRect
var subtitles: Control

signal lock_door
signal unlock_door

## Object pick handle
signal object_picked
var pickObj_count = 0

## Current pick object name
var is_one_picked: bool
var pick_obj: Pickable:
	set(value):
		pick_obj = value
var all_picked_object: Array[Pickable] = []
