extends Node

@export var has_been_scanned: bool = true

@onready var origObj = $Lighter
@onready var handObjView = $inHandUI
@onready var inter = $Interactable3D
@onready var picked: bool

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	# duplicate material for handled obj
	origObj.set_surface_override_material(0, origObj.get_active_material(0).duplicate())
	inter.interacted.connect(_on_interact)
	picked = false

func _on_interact() -> void:
	if has_been_scanned and Manager.is_all_picked:
		picked = not picked
		_origin_obj_transparency(picked)
		_show_hand_obj(picked)

#### Called when object picked or dropped
func _origin_obj_transparency(pick: bool) -> void:
	if pick:
		# set origin obj transparent
		origObj.get_surface_override_material(0).albedo_color.a = 0.1
		origObj.get_surface_override_material(0).transparency = true
	else:
		origObj.get_surface_override_material(0).albedo_color.a = 1
		origObj.get_surface_override_material(0).transparency = false

func _show_hand_obj(pick: bool) -> void:
	if pick:
		handObjView.show()
	else:
		handObjView.hide()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
