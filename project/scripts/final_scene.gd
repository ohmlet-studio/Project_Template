extends Control

@export var pickable_slot: Pickable
@export var pickable_slot2: Pickable
@export var pickable_slot3: Pickable
@onready var slots = [$SubViewportContainer/SubViewport/Node3D/Slot, $SubViewportContainer/SubViewport/Node3D/Slot2, $SubViewportContainer/SubViewport/Node3D/Slot3]

func _ready() -> void:
	var slot_id = 0
	for memory in [pickable_slot, pickable_slot2, pickable_slot3]:
		if not memory:
			continue
		 
		var path = memory.object_to_scan.resource_path
		var object_room1: Node3D = load(path).instantiate()
		object_room1.scale = Vector3.ONE * memory.inspect_scale
		slots[slot_id].add_child(object_room1)
		slot_id += 1
