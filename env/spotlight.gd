extends Node3D

@export var target: Node3D
@export var range: float = 100.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if self.global_position.distance_to(target.global_position) < range:
		self.look_at(target.global_position, Vector3.UP)
