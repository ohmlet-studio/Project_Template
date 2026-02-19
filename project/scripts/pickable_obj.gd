extends Node

@export var has_been_scanned: bool = true

@onready var origObj = $Mug
@onready var handObj = $inHandUI/SubViewport/Mug2
@onready var inter = $Interactable3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# duplicate material for handled obj
	origObj.set_surface_override_material(0, origObj.get_active_material(0).duplicate())
	inter.interacted.connect(_on_interact)

func _on_interact() -> void:
	#if has_been_scanned :
		#print("gogogogo")
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
