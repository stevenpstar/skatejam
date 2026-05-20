extends Node3D

@export var target_position: Player
@export var camera_spring: SpringArm3D
@export var position_delay: float
@export var camera_speed: float = 2.0
@export var vertical_offset: float = 1.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	var rjoy = Input.get_vector("rjoy_left", "rjoy_right", "rjoy_backwards", "rjoy_forward")
	if rjoy.y > 0.36 or rjoy.y < -0.36:
		camera_spring.rotate_x(rjoy.y * camera_speed * delta)
		#camera_lerp_speed = 1.0
	
	if target_position:
		var adjusted_position: Vector3 = Vector3(target_position.global_position.x, target_position.global_position.y + vertical_offset, target_position.global_position.z)
		self.global_position = lerp(self.global_position, adjusted_position, position_delay)
		if target_position.grinding:
			self.rotation = lerp(Vector3(0.0, self.rotation.y, self.rotation.z), Vector3(self.rotation.x, target_position.character.rotation.y, target_position.character.rotation.z), 0.2)
		else:
			self.rotate_y(-rjoy.x * camera_speed * delta)
	
	
