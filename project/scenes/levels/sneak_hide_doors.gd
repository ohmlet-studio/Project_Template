extends Node

@export var door1: Node3D
@export var door2: Node3D
@export var teleporter1: Portal3D

var _timer: float = 0.0
var _waiting: bool = false

func _ready() -> void:
	door1.opened.connect(_on_door_open.bind(door1))
	door2.opened.connect(_on_door_open.bind(door2))
	teleporter1.on_teleport.connect(_on_teleport)
	teleporter1.on_teleport_receive.connect(_on_teleport)
	
func _on_teleport():
	_timer = 0.0
	_waiting = true
	
func _on_door_open(door: Node3D) -> void:
	# Hide the other door
	var other_door = door2 if door == door1 else door1
	other_door.lid_shown = false
	
	_timer = 2.0
	_waiting = true
	
func _process(delta: float) -> void:
	if _waiting:
		_timer -= delta
		if _timer <= 0.0:
			_waiting = false
			# Close both doors
			door1.lid_shown = true
			door2.lid_shown = true
			door1.close()
			door2.close()
