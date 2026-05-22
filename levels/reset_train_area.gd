extends Area3D

@export var train_anim_player: AnimationPlayer
var play_train_anim: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		train_anim_player.stop()
		print("hit play box")
		train_anim_player.play("train_a_1")
