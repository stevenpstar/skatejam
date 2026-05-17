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
# used to make the skater crouch when going fast/landing/leaning etc.
@export var skater_position: Node3D
@export var left_foot_pos: Node3D
@export var left_foot_bone: BoneAttachment3D
@export var right_foot_pos: Node3D
@export var right_foot_bone: BoneAttachment3D
var skater_default_position: Vector3 = Vector3(-0.137, 1.054, 0.0)

@onready var front_wheel_origin: Node3D = $CharacterModel/FrontWheelRayOrigin
@onready var front_ramp_origin: Node3D = $CharacterModel/FrontRampOrigin
@onready var back_wheel_origin: Node3D = $CharacterModel/BackWheelRayOrigin
@onready var front_col_shape: CollisionShape3D = $FrontCollisionShape
@onready var back_col_shape: CollisionShape3D = $BackCollisionShape

var desired_dir: Vector3 = Vector3.ZERO
var ramp_hit: Vector3 = Vector3.ZERO
var desired_rot: Vector3 = Vector3.ZERO
var front_hit_ang_test: float = 0.0
var on_ramp: bool = false
var grinding: bool = false
var grind_follow: Node3D
var grinding_rail: Rail
var alt_vel: Vector3 = Vector3.ZERO
var has_jumped: bool = false
var left_half_pipe: bool = false
var is_turning: bool = false
var turning_threshold: float = 0.3
var input_dir_tracking: Vector2 = Vector2.ZERO

const SPEED = 5.0
const JUMP_VELOCITY = 1.05

var current_velocity: float = 0.0
var bonus_velocity: float = 0.0
var jump_velocity: float = 0.0
var jump_softener: float = 6.5

var front_hit_point: Vector3 = Vector3.ZERO
var back_hit_point: Vector3 = Vector3.ZERO

func stop_grinding():
	if grinding:
		grinding = false
	if grind_follow:
		grind_follow = null
	grinding_rail = null

func handle_jumping(delta: float) -> void:
	if not is_on_floor():
		#self.up_direction = Vector3.UP
		jump_velocity += get_gravity().y * delta
		if jump_velocity < 0:
			jump_velocity += jump_softener * delta
	else:
		if has_jumped:
			has_jumped = false
	if Input.is_action_just_pressed("jump") and (is_on_floor() or grinding) and !has_jumped:
		has_jumped = true
		jump_velocity = JUMP_VELOCITY
		if skateboard_animation_player:
			skateboard_animation_player.set("parameters/ollie_os/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
		#self.velocity.x = 0.0
		#self.velocity.z = 0.0
		#current_velocity = 0.0
		stop_grinding()
		
func handle_direction(delta: float) -> void:
	var input_dir := Input.get_vector("ljoy_left", "ljoy_right", "ljoy_backwards", "ljoy_forward")
	print("input_dir: ", input_dir)
	var direction = Vector3(input_dir.x, 0.0, -input_dir.y).rotated(Vector3.UP, camera_parent.rotation.y).normalized()
	input_dir_tracking = input_dir
	var speed = direction.length() * SPEED
	if direction:
		desired_dir.x = direction.x * SPEED
		desired_dir.z = direction.z * SPEED
		current_velocity += acceleration
		if current_velocity > max_velocity:
			current_velocity = max_velocity
	else:
		if !on_ramp:
			current_velocity -= deceleration
		#else:
		#	current_velocity += deceleration
		if current_velocity <= 0.0:
			current_velocity = 0.0
	current_velocity += bonus_velocity
	if current_velocity > max_total_velocity:
		current_velocity = max_total_velocity
	bonus_velocity -= (deceleration * 0.25)
	if bonus_velocity < 0.0:
		bonus_velocity = 0.0
	
	rayRampPosition()
		
func handle_rotation(delta: float) -> void:
	if rotation_target:
		rotation_target.look_at(Vector3(self.global_position.x, 0.0, self.global_position.z) + Vector3(self.desired_dir.x, self.global_position.y, self.desired_dir.z), Vector3.UP)
		if !is_on_floor():
			character.rotation.y = lerp_angle(character.rotation.y, rotation_target.rotation.y, turn_speed / 2.0)
		else:
			character.rotation.y = lerp_angle(character.rotation.y, rotation_target.rotation.y, turn_speed)
		if is_on_floor():
			var a = Vector2(-4.0, back_hit_point.y * 100.0)
			var b = Vector2(4.0, (front_hit_point.y + 10.0) * 100.0)
			var ang = a.angle_to(b)
			var c = b - a
			var ong = atan2(c.x, c.y) - deg_to_rad(90.0)

			if abs(back_hit_point.y) <= 0.01 and abs(front_hit_point.y) <= 0.01:
				ang = 0.0
				character.rotation.x = 0.0
				on_ramp = false
			else:
				on_ramp = true
			var b_rotation := Quaternion(character.transform.basis.y, desired_rot)
			character.transform.basis = lerp(character.transform.basis, Basis(b_rotation * character.transform.basis.get_rotation_quaternion()), 0.5)
		
		#if is_on_floor():
		self.velocity.x = -character.transform.basis.z.x * current_velocity
		self.velocity.z = -character.transform.basis.z.z * current_velocity
		if is_on_floor():
			var down_force = -self.up_direction * 9.8
			self.velocity += down_force * delta

		if not is_on_floor() or has_jumped:
			self.velocity.y += jump_velocity
		
func _physics_process(delta: float) -> void:
	if char_mesh:
		if is_on_floor() or grinding:
			char_mesh.position.y = lerpf(char_mesh.position.y, 1.07, 0.4)
		else:
			char_mesh.position.y = lerpf(char_mesh.position.y, 1.27, 0.4)
	if is_on_wall():
		print("hitting a wall here")
		#reset velocities
		current_velocity = 0.0
		bonus_velocity = 0.0
	character.global_position = Vector3(self.global_position.x, self.global_position.y, self.global_position.z)
	#front_col_shape.global_position = front_wheel_origin.global_position
	#back_col_shape.global_position = back_wheel_origin.global_position
	handle_jumping(delta)
	if !grinding:
		if is_on_floor():
			if Input.is_action_just_pressed("push"):
				print("push")
				# this will play an animation, which will handle changing state of "pushable"
				bonus_velocity += 5.0
		handle_direction(delta)
		handle_rotation(delta)
		move_and_slide()
	if grinding:
		self.global_position = lerp(self.global_position, grind_follow.global_position, 0.4)
		if grinding_rail.dir > 0:
			character.global_rotation = lerp(character.global_rotation, grind_follow.global_rotation, 0.4)
		else:
			character.global_rotation = lerp(character.global_rotation, -grind_follow.global_rotation, 0.4)
			#character.global_rotation.y += deg_to_rad(180.0)
	if skater_position and skater_mesh:
		if is_on_floor():
			skater_position.position.y = skater_default_position.y - current_velocity * 0.015
			skater_position.position.x = skater_default_position.x + (0.3 * input_dir_tracking.x)
		else:
			skater_position.position.y = skater_default_position.y
			skater_position.position.x = skater_default_position.x
		skater_mesh.position = lerp(skater_mesh.position, skater_position.position, 0.1)
		if left_foot_pos and left_foot_bone and right_foot_bone and right_foot_pos:
			left_foot_pos.global_position = left_foot_bone.global_position
			right_foot_pos.global_position = right_foot_bone.global_position
	
	
#func rayFrontWheel():
	#var space_state = get_world_3d().direct_space_state
	#var origin = front_wheel_origin.global_position
	#var end = origin + (-Vector3.UP * 2.0)
	##look_at_visual.global_position = end
	#var query = PhysicsRayQueryParameters3D.create(origin, end, 2, [self])
	#query.collide_with_areas = true
	#var result = space_state.intersect_ray(query)
	#if result:
		#if front_wheel_hit_vis:
			#front_wheel_hit_vis.global_position = result.position
			#front_hit_point = result.position
			#
#func rayFrontWheelForward():
	#var space_state = get_world_3d().direct_space_state
	#var origin = front_wheel_origin.global_position
	#var end = origin + (-character.basis.z * 2.0)
	##look_at_visual.global_position = end
	#var query = PhysicsRayQueryParameters3D.create(origin, end, 2, [self])
	#query.collide_with_areas = true
	#var result = space_state.intersect_ray(query)
	#if result:
		#if front_wheel_hit_vis:
			#back_wheel_hit_vis.global_position = front_wheel_hit_vis.global_position
			#front_wheel_hit_vis.global_position = result.position
			#front_hit_point = result.position
			#
#func rayBackWheel():
	#var space_state = get_world_3d().direct_space_state
	#var origin = back_wheel_origin.global_position
	#var end = origin + (-Vector3.UP * 0.25)
	##look_at_visual.global_position = end
	#var query = PhysicsRayQueryParameters3D.create(origin, end, 2, [self])
	#query.collide_with_areas = true
	#var result = space_state.intersect_ray(query)
	#if result:
		#if back_wheel_hit_vis:
			#back_wheel_hit_vis.global_position = result.position
			#back_hit_point = result.position

func rayRampPosition():
	var space_state = get_world_3d().direct_space_state
	var origin = front_ramp_origin.global_position
	#var end = origin + (-Vector3.UP * 1.0)
	var end = origin + (-self.up_direction * 4.0)
	#look_at_visual.global_position = end
	var query = PhysicsRayQueryParameters3D.create(origin, end, 2, [self])
	query.collide_with_areas = true
	var result = space_state.intersect_ray(query)
	if result:
		desired_rot = result.normal
		self.up_direction = result.normal
			#print("des rot: ", desired_rot)
		ramp_hit = result.position

#func rayFrontWheelPredict():
	#var space_state = get_world_3d().direct_space_state
	#var origin = front_wheel_origin.global_position
	#var end = origin + (-Vector3.UP * 100.0)
	##look_at_visual.global_position = end
	#var query = PhysicsRayQueryParameters3D.create(origin, end, 2, [self])
	#query.collide_with_areas = true
	#var result = space_state.intersect_ray(query)
	#if result:
		#if front_wheel_hit_vis:
			##desired_rot = result.normal
			#ramp_hit = result.position
			##front_wheel_hit_vis.global_position = result.position
			##front_hit_point = result.position
		
