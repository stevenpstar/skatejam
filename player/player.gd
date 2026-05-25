class_name Player extends CharacterBody3D

@export var camera: Camera3D
@export var camera_parent: Node3D
@export var rotation_target: Node3D
@export var turn_speed: float = 0.5
@export var max_velocity: float = 9.0
@export var max_total_velocity: float = 15.0
@export var acceleration: float = 0.25
@export var deceleration: float = 0.05
@export var character: Node3D
@export var char_mesh: MeshInstance3D
@export var skater_mesh: Node3D
@export var skateboard_animation_player: AnimationTree
@export var skater_animation_tree: AnimationTree
# used to make the skater crouch when going fast/landing/leaning etc.
@export var skater_position: Node3D
@export var left_foot_pos: Node3D
@export var left_foot_bone: BoneAttachment3D
@export var right_foot_pos: Node3D
@export var right_foot_bone: BoneAttachment3D
@export var game_state: GameStateHandler
var skater_default_position: Vector3 = Vector3(-0.137, 1.054, 0.0)

@onready var front_wheel_origin: Node3D = $CharacterModel/FrontWheelRayOrigin
@onready var front_ramp_origin: Node3D = $CharacterModel/FrontRampOrigin
@onready var back_wheel_origin: Node3D = $CharacterModel/BackWheelRayOrigin
@onready var front_col_shape: CollisionShape3D = $FrontCollisionShape
@onready var back_col_shape: CollisionShape3D = $BackCollisionShape
@onready var rolling_sfx: AudioStreamPlayer3D = $SkateboardOnGround
@onready var grinding_sfx: AudioStreamPlayer3D = $SkateboardGrind
@onready var ollie_sfx: AudioStreamPlayer3D = $SkateboardOllie
@onready var landing_sfx: AudioStreamPlayer3D = $SkateboardLand
@onready var rocket_sfx: AudioStreamPlayer3D = $RocketBoostSound
@onready var boost_particles: GPUParticles3D = $CharacterModel/BoostParticles
@onready var grind_particles: GPUParticles3D = $CharacterModel/GrindParticles
@export var rain_particles: GPUParticles3D
var play_landing_sfx_timer: float = 0.0
var play_landing_sfx_buffer: float = 0.25

@export var UI_jumpbar: ProgressBar
@export var UI_boostbar: ProgressBar
var max_boost: float = 5.0
var boost_value: float = max_boost
@export var UI_stopwatch: Label
var elapsed_time: float = 0.0
@export var player_start: Node3D
@export var coyote_timer: Timer
var can_coyote_jump: bool = false
@export var sketchy_jump_timer: Timer
var sketchy_jump_flag: bool = false
@export var decel_bonus_timer: Timer
var decel_bonus_flag: bool = false

const SPEED = 5.0
const JUMP_VELOCITY = 1.1

#jump timers
var jump_strength: float = JUMP_VELOCITY
var max_jump_strength = 1.8
var charging_jump: bool = false
var just_landed: bool = false
var in_air: bool = false
var grind_input: bool = false
var grind_timer: float = 0.0

var desired_dir: Vector3 = Vector3.ZERO
var ramp_hit: Vector3 = Vector3.ZERO
var desired_rot: Vector3 = Vector3.ZERO
var front_hit_ang_test: float = 0.0
var on_ramp: bool = false
var grinding: bool = false
var is_boosting: bool = false
var grind_follow: Node3D
var grinding_rail: Rail
var alt_vel: Vector3 = Vector3.ZERO
var has_jumped: bool = false
# when we roll off a ledge we need to zero out y/down velocity.
var just_fell: bool = false
var left_half_pipe: bool = false
var is_turning: bool = false
var turning_threshold: float = 0.3
var input_dir_tracking: Vector2 = Vector2.ZERO

var current_velocity: float = 0.0
var bonus_velocity: float = 0.0
var jump_velocity: float = 0.0
var jump_softener: float = 7.5
var actual_decel: float = deceleration

var front_hit_point: Vector3 = Vector3.ZERO
var back_hit_point: Vector3 = Vector3.ZERO

func handle_bonus_decel():
	if is_boosting:
		decel_bonus_flag = false
		decel_bonus_timer.stop()
		decel_bonus_timer.wait_time = 1.0
		return
	if grinding:
		decel_bonus_flag = false
		decel_bonus_timer.stop()
		decel_bonus_timer.wait_time = 1.0
		return
	if character.rotation.x < -0.3: # or character.rotation.x > 0.3:
		decel_bonus_flag = false
		decel_bonus_timer.stop()
		decel_bonus_timer.wait_time = 1.0
		return
	if !is_on_floor():
		decel_bonus_flag = false
		decel_bonus_timer.stop()
		decel_bonus_timer.wait_time = 1.0
		return
	if decel_bonus_timer.is_stopped():
		decel_bonus_timer.wait_time = 1.0
		decel_bonus_timer.start()
		
func handle_boost(delta: float) -> void:
	if grinding:
		add_boost_value(2.0)

func stop_grinding():
	if grinding:
		grinding = false
	if grind_follow:
		grind_follow = null
	if grinding_rail:
		current_velocity += grinding_rail.grind_velocity
		current_velocity = current_velocity + (grinding_rail.entry_velocity / 100.0 + grinding_rail.grind_velocity) * grinding_rail.dir
	grinding_rail = null

func jump(delta: float) -> void:
	ollie_sfx.play()
	if self.velocity.y < 0.0:
		self.velocity.y = 0.0
	charging_jump = false
	has_jumped = true
	jump_velocity = jump_strength
	#self.velocity.y = 0.0
	if skateboard_animation_player:
		skateboard_animation_player.set("parameters/ollie_os/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	stop_grinding()
	jump_strength = JUMP_VELOCITY

func handle_jumping(delta: float) -> void:
	if not is_on_floor():
		play_landing_sfx_timer += delta
		if !has_jumped and !just_fell and !on_ramp and !charging_jump:
			jump_velocity = 0.0
			self.velocity.y = 0.0
			just_fell = true
		in_air = true
		#self.up_direction = Vector3.UP
		jump_velocity += get_gravity().y * delta
		var altered_softener = jump_softener
		if is_boosting:
			altered_softener = 9.8
		if jump_velocity < 0:
			jump_velocity += altered_softener * delta
	else:
		#sketchy_jump_timer.stop()
		just_fell = false
		if in_air:
			just_landed = true
			if play_landing_sfx_timer > play_landing_sfx_buffer:
				landing_sfx.play()
		else:
			just_landed = false
		in_air = false
		if has_jumped and sketchy_jump_flag:
			has_jumped = false
		play_landing_sfx_timer = 0.0
			
	if Input.is_action_pressed("jump") and (is_on_floor() or grinding or can_coyote_jump) and !has_jumped:
		jump_strength += 1.1 * delta
		if jump_strength > max_jump_strength:
			jump_strength = max_jump_strength
		charging_jump = true
	if Input.is_action_just_released("jump") and (is_on_floor() or grinding or can_coyote_jump) and !has_jumped:
		sketchy_jump_flag = false
		
		if sketchy_jump_timer.is_stopped():
			sketchy_jump_timer.start()
		jump(delta)
		
func handle_direction(delta: float) -> void:
	var input_dir := Input.get_vector("ljoy_left", "ljoy_right", "ljoy_backwards", "ljoy_forward")
	var direction = Vector3(input_dir.x, 0.0, -input_dir.y).rotated(Vector3.UP, camera_parent.rotation.y).normalized()
	if grinding and grinding_rail:
		direction = -grinding_rail.follow_object.transform.basis.z
		bonus_velocity += 10.0 * delta
	input_dir_tracking = input_dir
		
	var speed = direction.length() * SPEED
	if direction:
		desired_dir.x = direction.x * SPEED
		desired_dir.z = direction.z * SPEED
		current_velocity += acceleration
		#if current_velocity > max_velocity and !grinding:
		#	current_velocity = max_velocity
		if grinding and grinding_rail:
			if current_velocity < 10.0:
				current_velocity = 10.0
			current_velocity += grinding_rail.accel
	else:
		if !on_ramp:
			current_velocity -= deceleration
		#else:
		#	current_velocity += deceleration
		if current_velocity <= 0.0:
			current_velocity = 0.0
	#current_velocity += bonus_velocity
		if is_on_floor() and current_velocity > 0.0:
			current_velocity -= deceleration
	if current_velocity > max_velocity:
		current_velocity = max_velocity
	if bonus_velocity > max_total_velocity:
		bonus_velocity = max_total_velocity
	if decel_bonus_flag:
		bonus_velocity -= deceleration * 1.0
	if bonus_velocity < 0.0:
		bonus_velocity = 0.0
	
	rayRampPosition()
		
func handle_rotation(delta: float) -> void:
	if rotation_target:
		rotation_target.look_at(Vector3(self.global_position.x, 0.0, self.global_position.z) + Vector3(self.desired_dir.x, self.global_position.y, self.desired_dir.z), Vector3.UP)
		if !is_on_floor():
			character.rotation.y = lerp_angle(character.rotation.y, rotation_target.rotation.y, turn_speed / 3.0)
		else:
			character.rotation.y = lerp_angle(character.rotation.y, rotation_target.rotation.y, turn_speed)
		if is_on_floor():
			# this is haaaacky but it was always returning true so I have programmed everything around that 
			# working so I don't want to change it now in case it breaks a bunch of things. :) =) x) :D =]
			on_ramp = true#character.transform.basis.z.y < -0.3
			#if on_ramp:
				#print("I am on a ramp")
			#else:
				#print("I am not on a ramp thus")
				#decel_bonus_flag = false
			if -character.transform.basis.z.y < 0.0: # if we are going down a ramp, increase current velocity
				bonus_velocity += 5.0 * delta
			var b_rotation := Quaternion(character.transform.basis.y, desired_rot)
			character.transform.basis = lerp(character.transform.basis, Basis(b_rotation * character.transform.basis.get_rotation_quaternion()), 0.25)
		else:
			var b_rotation := Quaternion(character.transform.basis.y, desired_rot)
			character.transform.basis = lerp(character.transform.basis, Basis(b_rotation * character.transform.basis.get_rotation_quaternion()), 0.05)
			
		self.velocity.x = -character.transform.basis.z.x * (current_velocity + bonus_velocity)
		self.velocity.z = -character.transform.basis.z.z * (current_velocity + bonus_velocity)
		if is_on_floor() and !grinding and on_ramp:
			var down_force = -self.up_direction * 9.8
			self.velocity += down_force * delta
		if not is_on_floor() or has_jumped:
			self.velocity += jump_velocity * self.up_direction

func reset_bonus_decel():
	decel_bonus_flag = false
	decel_bonus_timer.wait_time = 1.0
	decel_bonus_timer.stop()

func _ready() -> void:
	coyote_timer.stop()
	reset()

func _process(delta: float) -> void:
	if game_state.state != game_state.GameState.RUNNING:
		return
	if Input.is_action_just_pressed("reset"):
		reset()
	elapsed_time += delta
	if UI_stopwatch:
		UI_stopwatch.text = str(elapsed_time).pad_decimals(2)

func stop_sounds_and_particles() -> void:
	ollie_sfx.stop()
	rolling_sfx.stop()
	landing_sfx.stop()
	grinding_sfx.stop()
	grind_particles.emitting = false
	boost_particles.emitting = false

func reset():
	Input.stop_joy_vibration(0)
	jump_velocity = 0.0
	is_boosting = false
	charging_jump = false
	on_ramp = false
	in_air = false
	current_velocity = 0.0
	bonus_velocity = 0.0
	has_jumped = false
	stop_sounds_and_particles()
	stop_grinding()
	if player_start:
		self.global_position = player_start.global_position
	else:
		self.global_position = Vector3(50.0, 3.0, -40.0)
	elapsed_time = 0.0
	coyote_timer.stop()
	coyote_timer.wait_time = 1.0
	sketchy_jump_timer.stop()
	sketchy_jump_timer.wait_time = 0.2
	sketchy_jump_flag = false
	boost_value = 5.0
	game_state.set_start()
	character.rotation = Vector3(0.0, 0.0, 0.0)
	character.rotate_y(deg_to_rad(-90.0))
	
func handle_sfx() -> void:
	if current_velocity > 2.0 and (is_on_floor() or play_landing_sfx_timer < play_landing_sfx_buffer) and !grinding:
		if !rolling_sfx.playing:
			rolling_sfx.play()
	elif rolling_sfx.playing and (!is_on_floor() or current_velocity <= 2.0 or grinding):
		rolling_sfx.stop()
	if grinding:
		if !grinding_sfx.playing:
			grinding_sfx.play()
	else:
		grinding_sfx.stop()
		
func _physics_process(delta: float) -> void:
	if self.global_position.y < -200.0:
		reset()
	if game_state.state != game_state.GameState.RUNNING:
		return
	handle_sfx()
	handle_boost(delta)
	handle_bonus_decel()
	if UI_jumpbar:
		UI_jumpbar.value = jump_strength
	if char_mesh:
		if is_on_floor() or grinding:
			can_coyote_jump = true
			coyote_timer.stop()
			char_mesh.position.y = lerpf(char_mesh.position.y, 1.07, 0.4)
		else:
			char_mesh.position.y = lerpf(char_mesh.position.y, 1.27, 0.4)
			if coyote_timer.is_stopped():
				coyote_timer.wait_time = 1.0
				coyote_timer.start()
	if is_on_wall():
		#reset velocities
		current_velocity = 0.0
		bonus_velocity = 0.0
	var blend_amount = (current_velocity + 0.01) / 10.0
	if !grinding:
		blend_amount = clampf(blend_amount, 0.0, 0.9)
	else:
		blend_amount = move_toward(blend_amount, 1.0, 0.1)
	skater_animation_tree.set("parameters/pose_blend/blend_position", blend_amount)
		
	character.global_position = Vector3(self.global_position.x, self.global_position.y, self.global_position.z)
	# this is actually going to be a "boost" instead of pushing to make it easier
	# there will be a fuel/energy mechanic related to grinding etc.
	if Input.is_action_pressed("push"):
		if boost_value > 0.0:
			is_boosting = true
			bonus_velocity += 12.0 * delta
			add_boost_value(-5.0)
			if !rocket_sfx.playing:
				rocket_sfx.play()
		else:
			is_boosting = false
			rocket_sfx.stop()

	elif Input.is_action_just_released("push"):
		is_boosting = false
		rocket_sfx.stop()
	boost_particles.emitting = is_boosting
	handle_jumping(delta)
	if !grinding:			
		handle_direction(delta)
		handle_rotation(delta)
	#print("final velocity: ", self.velocity)
	if grinding and grinding_rail:
		Input.start_joy_vibration(0, 0.05, 0.05, 0.1)
		self.velocity = (-grinding_rail.follow_object.global_transform.basis.z * grinding_rail.dir) * (current_velocity + bonus_velocity)
	else:
		Input.stop_joy_vibration(0)
#	print("total velos: ", current_velocity, ", ", bonus_velocity, " total: ", current_velocity + bonus_velocity)
	move_and_slide()
	if grinding and grinding_rail:
			grinding_rail.set_progress(self.global_position)
		#self.velocity.y = 0.0
			self.global_position = lerp(self.global_position, grind_follow.global_position, 1.0)
			if grinding_rail.dir > 0:
				character.global_rotation = lerp(character.global_rotation, grind_follow.global_rotation, 1.0)
			else:
				character.global_rotation = lerp(character.global_rotation, -grind_follow.global_rotation, 1.0)
				#character.global_rotation.y += deg_to_rad(180.0)
	if Input.is_action_just_pressed("grind"):
		grind_input = true
		grind_timer = 100.0
	if grind_timer > 0.0:
		grind_timer -= 20.0 * delta
	else:
		grind_input = false
	grind_particles.emitting = grinding
	if skater_position and skater_mesh:
		if is_on_floor():
			skater_position.position.y = skater_default_position.y - current_velocity * 0.015
			skater_position.position.x = skater_default_position.x + (0.3 * input_dir_tracking.x)
		else:
			skater_position.position.y = skater_default_position.y
			skater_position.position.x = skater_default_position.x
		#skater_position.position.y = clampf(skater_position.position.y, skater_default_position.y, skater_default_position.y - 0.25)
		if (is_on_floor() or grinding) and charging_jump:
			skater_position.position.y = skater_default_position.y - jump_strength * 0.25
		#if just_landed:
		#	skater_position.position.y = skater_default_position.y - 1.0
		skater_mesh.position = lerp(skater_mesh.position, skater_position.position, 0.1)
		if left_foot_pos and left_foot_bone and right_foot_bone and right_foot_pos:
			left_foot_pos.global_position = left_foot_bone.global_position
			right_foot_pos.global_position = right_foot_bone.global_position

func rayRampPosition():
	var space_state = get_world_3d().direct_space_state
	var origin = front_ramp_origin.global_position
	#var end = origin + (-Vector3.UP * 5.0)
	var end = origin + (-self.up_direction * 10.0)
	#look_at_visual.global_position = end
	var query = PhysicsRayQueryParameters3D.create(origin, end, 2, [self])
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if result:
		desired_rot = result.normal
		self.up_direction = result.normal
			#print("des rot: ", desired_rot)
		ramp_hit = result.position
	else:
		space_state = get_world_3d().direct_space_state
		origin = front_ramp_origin.global_position
		end = origin + (-Vector3.UP * 20.0)
		query = PhysicsRayQueryParameters3D.create(origin, end, 2, [self])
		query.collide_with_areas = true
		result = space_state.intersect_ray(query)
		if result:
			desired_rot = result.normal
			self.up_direction = result.normal

func add_boost_value(value: float) -> void:
	boost_value += value * self.get_physics_process_delta_time()
	if boost_value > 5.0:
		boost_value = 5.0
	if boost_value < 0.0:
		boost_value = 0.0
	if UI_boostbar:
		UI_boostbar.value = boost_value

func _on_coyote_timer_timeout() -> void:
	can_coyote_jump = false

func _on_sketchy_jump_timer_timeout() -> void:
	sketchy_jump_flag = true

func _on_decel_bonus_timer_timeout() -> void:
	decel_bonus_flag = true

func _on_gap_1_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		if !is_on_floor():
			# put text on screen
			bonus_velocity += 20.0 * self.get_physics_process_delta_time()
			add_boost_value(5.0)
		

func _on_norainbox_body_entered(body: Node3D) -> void:
	var player = body as Player
	if player:
		rain_particles.emitting = false

func _on_norainbox_body_exited(body: Node3D) -> void:
	var player = body as Player
	if player:
		rain_particles.emitting = true
