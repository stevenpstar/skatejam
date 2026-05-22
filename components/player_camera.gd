class_name PlayerCamera extends Camera3D

@export var player: Player
@export var target_position: Node3D
@export var target_look_at: Node3D
@export var camera_delay: float
@export var spring_arm: SpringArm3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if target_look_at:
		self.look_at(target_look_at.global_position)
	if target_position:
		self.global_position = lerp(self.global_position, target_position.global_position, camera_delay)
	#spring_arm.spring_length = lerpf(spring_arm.spring_length, 3.2 + (0.00 * player.current_velocity), 0.05)
	#spring_arm.spring_length = clampf(spring_arm.spring_length, 2.2, 3.4)
	spring_arm.spring_length = 3.2
	self.fov = lerpf(self.fov, 70.0 + (0.2 * player.current_velocity), 0.05)
	#self.fov = clampf(self.fov, 70.0, 110.0)
