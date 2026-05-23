class_name GameStateHandler extends Node3D

enum GameState {
	PAUSED,
	START,
	STARTING,
	RUNNING,
	DIED
}

var state: GameState = GameState.START
@export var start_ui: Control
@export var start_text: Label
@export var start_timer: Timer

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if state == GameState.PAUSED:
		print("show menu")
	elif state == GameState.START:
		if start_ui:
			start_text.text = "Press A to Start"
			start_ui.visible = true
		if Input.is_action_just_pressed("jump"):
			if start_timer:
				start_timer.start()
				state = GameState.STARTING
	elif state == GameState.STARTING:
		start_text.text = str(start_timer.time_left + 1.0).pad_decimals(0) 
	#elif state == GameState.DIED:
	#	print("player died, pause, show death menu")


func set_start() -> void:
	state = GameState.START
	start_text.text = "Press A to Start"
	start_timer.stop()
	start_timer.wait_time = 3.0
	start_ui.visible = true

func _on_start_timer_timeout() -> void:
	state = GameState.RUNNING
	start_ui.visible = false
