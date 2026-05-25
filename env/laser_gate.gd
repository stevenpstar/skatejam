extends Node3D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func _on_player_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		player.game_state.set_dead()
		player.game_state.state = player.game_state.GameState.DIED
		player.stop_sounds_and_particles()
