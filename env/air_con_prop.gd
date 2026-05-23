extends Node3D

@onready var aircon_fan: Node3D = $aircon_fan

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	aircon_fan.rotate_y(deg_to_rad(5.0))
