extends Node3D
class_name PortalDoor

signal opened
signal closed

@onready var portal = $Portal
@onready var door = $Door3D
@onready var door_lid = $Pivot/lid
@onready var door_lid_collider = $Pivot/lid/StaticBody3D/CollisionShape3D
@onready var collision_shape = $Pivot/lid/StaticBody3D/CollisionShape3D

@export var other_door: PortalDoor:
	set(value):
		other_door = value
		if is_node_ready():
			_connect_portals.call_deferred(value)

func _ready() -> void:
	door.opened.connect(func(): opened.emit())
	door.closed.connect(func(): closed.emit())

	if not Engine.is_editor_hint() and Manager.globPlayer:
		portal.player_camera = Manager.globPlayer.get_camera()

	portal.on_teleport.connect(_on_portal_teleport)

	_connect_portals.call_deferred(other_door)

func _on_portal_teleport(teleportable: Node3D) -> void:
	await get_tree().create_timer(1.5).timeout
	close()
	other_door.close_instant()

func _connect_portals(target: PortalDoor) -> void:
	print("connect portal")
	if not target:
		return
	if not target.is_node_ready():
		await target.ready

	var target_portal := target.get_node_or_null("Portal") as Portal3D
	if not target_portal:
		push_error(self.name + ": could not find Portal on " + target.name)
		return

	portal.exit_portal = target_portal
	portal.activate()

	print(self.name, " connecting portal ", portal, " to ", target_portal)


func open_instant():
	door.is_open = true
	door_lid.visible = false
	collision_shape.disabled = true


func close_instant():
	door.is_open = false
	door_lid.visible = true
	collision_shape.disabled = false

func open() -> void:
	door.open()
	other_door.open_instant()
	collision_shape.disabled = true

func close() -> void:
	door.close()
	other_door.close_instant()
	collision_shape.disabled = false
