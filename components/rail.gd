class_name Rail extends Area3D

@export var p: Player
@export var follow_object: Node3D
@export var follow_path: PathFollow3D
@export var path: Path3D
var entry_velocity: float = 0.0
var grind_velocity: float = 0.0
var max_grind_velocity: float = 0.25
var accel: float = 0.005
var dir: int = 1
var prev_position: Vector3 = Vector3.ZERO
var current_position: Vector3 = Vector3.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
	
func _physics_process(delta: float) -> void:
	if p.grinding and p.grinding_rail == self:
		grind_velocity += accel
		if grind_velocity > max_grind_velocity:
			grind_velocity = max_grind_velocity
	#	follow_path.progress += (entry_velocity / 100.0 + grind_velocity) * dir
		if p.grinding_rail.follow_path.progress <= 0.0 or p.grinding_rail.follow_path.progress >= p.grinding_rail.path.curve.get_baked_length():
			p.jump(delta)
			#follow_path.progress_ratio = 0.1

func set_progress(player_position: Vector3) -> void:
	var local_pos = path.to_local(player_position)
	var offset = path.curve.get_closest_offset(local_pos)
	follow_path.progress = offset

func _on_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player and player.grinding == false:
		grind_velocity = 0.0
		player.grind_input = false
		var next_position = player.global_position + player.velocity
		var local_pos = path.to_local(player.global_position)
		var next_local_pos = path.to_local(next_position)
		var offset = path.curve.get_closest_offset(local_pos)
		var next_offset = path.curve.get_closest_offset(next_local_pos)
		player.grinding = true
		player.has_jumped = false
		player.grind_follow = follow_object
		player.grinding_rail = self
		follow_path.progress = offset
		self.entry_velocity = player.current_velocity
		if next_offset < offset:
			dir = -1
		else:
			dir = 1
