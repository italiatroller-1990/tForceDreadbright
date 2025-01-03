extends CharacterBody3D

# movement constants
const ACCEL = 10.0
const AIR_ACCEL = 0.3
const GROUND_FRICTION = 6.0
const AIR_FRICTION = 0.1
const MAX_SPEED = 10.0
const JUMP_VELOCITY = 7.0
const BUNNY_HOP_MAX_SPEED = 20.0
const GRAVITY = 9.8

# camera refs
@onready var head := $head
@onready var camera := $head/camera
@onready var weapons := $hud/weapons

# move vars
var wish_dir := Vector3.ZERO
var prev_velocity := Vector3.ZERO

# bunny hop vars
var can_bunny_hop = true
var consecutive_jumps = 0
const MAX_CONSECUTIVE_JUMPS = 5

# sway params
@export var sway_amount : float = 0.02
@export var sway_smoothness : float = 10.0
var mouse_input : Vector2 = Vector2.ZERO
# weapon vars
@export var max_weapon_pullback: float = 0.5
# weapon bob
var start_y = 0.0
var time = 0.0
@export var bob_height = 100.0
@export var bob_speed = 2.0
var camera_default_pos : Vector3
var weapons_default_pos : Vector2
@export var weapon_group : Control

func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera_default_pos = camera.position
	weapons_default_pos = weapons.position

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * 0.01)
		head.rotate_x(-event.relative.y * 0.01)
		head.rotation.x = clamp(head.rotation.x, -deg_to_rad(90), deg_to_rad(90))
		mouse_input = event.relative
		
func _physics_process(delta):
	var input_dir := Input.get_vector("left", "right", "up", "down")
	# convert input to world space
	wish_dir = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	
	# gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	# bunny hopping logic
	if Input.is_action_pressed("jump"):
		handle_bunny_hop()
	
	# ground movement
	if is_on_floor():
		velocity = quake_accelerate(velocity, wish_dir, ACCEL, MAX_SPEED, delta)
		velocity = apply_friction(velocity, GROUND_FRICTION, delta)
		# Reset bunny hop when touching ground
		can_bunny_hop = true
		consecutive_jumps = 0
	else:
		# air control
		velocity = quake_accelerate(velocity, wish_dir, AIR_ACCEL, BUNNY_HOP_MAX_SPEED, delta)
		velocity = apply_friction(velocity, AIR_FRICTION, delta)
	
	# move
	move_and_slide()
	
	# weapon bob and sway
	handle_weapon_bob(delta)
	handle_weapon_sway(delta)
	controls()
func handle_bunny_hop():
	if can_bunny_hop and consecutive_jumps < MAX_CONSECUTIVE_JUMPS:
		if not is_on_floor():
			# Prevent holding jump for continuous height
			can_bunny_hop = false
		
		velocity.y = JUMP_VELOCITY
		consecutive_jumps += 1

func quake_accelerate(current_velocity: Vector3, wish_direction: Vector3, accel: float, max_speed: float, delta: float) -> Vector3:
	var current_speed = current_velocity.dot(wish_direction)
	var add_speed = max_speed - current_speed
	
	if add_speed <= 0:
		return current_velocity
	
	var accel_speed = min(accel * delta * max_speed, add_speed)
	return current_velocity + wish_direction * accel_speed

func apply_friction(velocity_to_modify: Vector3, friction: float, delta: float) -> Vector3:
	var speed = velocity_to_modify.length()
	
	if speed <= 0.1:
		return Vector3.ZERO
	
	var drop = speed * friction * delta
	var new_speed = max(speed - drop, 0)
	
	return velocity_to_modify * (new_speed / speed)

func handle_weapon_bob(delta):
	time += delta
	var speed = velocity.length()
	
	# Only bob weapons when moving on the ground
	if speed > 0.1 and is_on_floor():
		var bob_amount = sin(time * bob_speed) * bob_height * (speed / MAX_SPEED)
		weapons.position.y = weapons_default_pos.y + bob_amount
		# Add slight horizontal bob for more natural movement
		# Smoothly return to default position when not moving
		weapons.position = weapons.position.lerp(Vector2(weapons_default_pos.x, weapons_default_pos.y), delta * 5.0)

func handle_weapon_sway(delta):
	# Weapon sway based on mouse movement
	var target_pos = Vector2.ZERO
	target_pos.y = -mouse_input.y * sway_amount
	
	# Apply sway with smoothing
	weapons.position += (target_pos - weapons.position) * sway_smoothness * delta
	
	# Reset mouse input
	mouse_input = mouse_input.lerp(Vector2.ZERO, delta * 10.0)
func controls():
	if Input.is_action_just_pressed("ui_cancel") and get_tree().paused == false:
		get_tree().paused = true
	if Input.is_action_just_pressed("ui_cancel") and get_tree().paused == true:
		get_tree().paused = false
