class_name MainMenu extends Node3D

@export var play_button: Button
@export var how_to_play_button: Button
@export var exit_button: Button
@export var how_to_play_screen: Control

var focused_button: Button
var switched_button: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if play_button:
		play_button.grab_focus()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("pause") or Input.is_action_just_pressed("brake") and how_to_play_screen.visible == true:
		how_to_play_screen.visible = false
		
func _on_play_pressed() -> void:
	get_tree().change_scene_to_file("res://levels/story_scene.tscn")

func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_how_to_play_pressed() -> void:
	how_to_play_screen.visible = true
