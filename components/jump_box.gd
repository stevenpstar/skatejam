class_name JumpBox extends Area3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node3D) -> void:
	var player = body as Player
	print("body ody ody")
	if player:
		print("found player")
		if player.charging_jump:
			print("trying to jump")
			print("delta time: ", self.get_physics_process_delta_time())
			player.jump(self.get_physics_process_delta_time())
