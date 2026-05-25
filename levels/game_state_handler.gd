class_name GameStateHandler extends Node3D

enum GameState {
	PAUSED,
	START,
	STARTING,
	RUNNING,
	DIED,
	FINISHED
}

var state: GameState = GameState.START
@export var start_ui: Control
@export var start_text: Label
@export var start_timer: Timer

@export var win_ui: Control
@export var win_text: Label
@export var win_time: Label

@export var grade_text: Label

@export var death_ui: Control
@export var death_text: Label

@export var pause_ui: Control
@export var pause_bg: ColorRect
@export var resume_button: Button

@export var how_to_play_screen: Control

@export var player: Player

var old_state: GameState = GameState.START

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("brake"):
		if how_to_play_screen.visible == false:
			if state != GameState.PAUSED:
				set_paused()
			else:
				set_resume()
		else:
			how_to_play_screen.visible = false
	if state == GameState.START:
		if start_ui:
			start_text.text = "Press A to Start"
			start_ui.visible = true
		if Input.is_action_just_pressed("jump"):
			if start_timer:
				start_timer.start()
				state = GameState.STARTING
	elif state == GameState.STARTING:
		start_text.text = str(start_timer.time_left + 1.0).pad_decimals(0) 
	elif state == GameState.DIED:
		if Input.is_action_just_pressed("jump"):
			player.reset()
	elif state == GameState.FINISHED:
		if Input.is_action_just_pressed("jump"):
			player.reset()

func set_paused() -> void:
	old_state = state
	state = GameState.PAUSED
	if pause_ui and pause_bg and resume_button:
		pause_ui.visible = true
		pause_bg.visible = true
		resume_button.grab_focus()

func set_grade(time: float) -> void:
	if time < 60.0:
		grade_text.text = "S"
		grade_text.modulate = Color(1.559, 1.315, 0.031, 1.0)
	elif time < 65:
		grade_text.text = "A"
		grade_text.modulate = Color(0.76, 1.437, 0.0, 1.0)
	elif time < 70:
		grade_text.text = "B"
		grade_text.modulate = Color(0.463, 0.694, 0.518, 1.0)
	elif time < 80:
		grade_text.text = "C"
		grade_text.modulate = Color(0.788, 0.575, 0.463, 1.0)
	elif time < 85:
		grade_text.text = "D"
		grade_text.modulate = Color(0.639, 0.629, 0.604, 1.0)
	else:
		grade_text.text = "F"
		grade_text.modulate = Color(0.577, 0.08, 0.13, 1.0)

func set_dead() -> void:
	if pause_ui and pause_bg and resume_button:
		pause_ui.visible = false
		pause_bg.visible = false
		resume_button.release_focus()
	player.stop_sounds_and_particles()
	death_ui.visible = true
	win_ui.visible = false
	start_ui.visible = false
	state = GameState.DIED

func set_start() -> void:
	if pause_ui and pause_bg and resume_button:
		pause_ui.visible = false
		pause_bg.visible = false
		resume_button.release_focus()
	player.stop_sounds_and_particles()
	death_ui.visible = false
	win_ui.visible = false
	state = GameState.START
	start_text.text = "Press A to Start"
	start_timer.stop()
	start_timer.wait_time = 3.0
	start_ui.visible = true

func set_finished(player: Player) -> void:
	if pause_ui and pause_bg and resume_button:
		pause_ui.visible = false
		pause_bg.visible = false
		resume_button.release_focus()
	player.stop_sounds_and_particles()
	death_ui.visible = false
	win_ui.visible = true
	start_ui.visible = false
	if grade_text:
		set_grade(player.elapsed_time)
	else:
		print("Grade text does not exist")
	win_time.text = str(player.elapsed_time).pad_decimals(2)
	state = GameState.FINISHED

func _on_start_timer_timeout() -> void:
	state = GameState.RUNNING
	start_ui.visible = false

func _on_ending_box_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		set_finished(player)

func _on_resume_pressed() -> void:
	set_resume()

func set_resume() -> void:
	state = old_state
	if pause_ui and pause_bg and resume_button:
		pause_ui.visible = false
		pause_bg.visible = false
		resume_button.release_focus()

func _on_restart_pressed() -> void:
	player.reset()

func _on_quit_pressed() -> void:
	get_tree().quit()

func _on_how_to_play_pressed() -> void:
	how_to_play_screen.visible = true
