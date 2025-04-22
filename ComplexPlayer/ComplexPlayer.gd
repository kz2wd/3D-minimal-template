extends CharacterBody3D
class_name ComplexPlayer

var current_speed = 5.0

const walking_speed = 9.0
const sprinting_speed = 12.0
const crouching_speed = 5.0

@export var jump_velocity = 6

const mouse_sensitivity = 0.2

@onready var head: Node3D = $Head
@onready var upper_body: CollisionShape3D = $UpperBody
@onready var lower_body: CollisionShape3D = $LowerBody
@onready var lower_body_base: Node3D = $LowerBodyBase
@onready var ray_cast_3d: RayCast3D = $RayCast3D

var acceleration = 5.0

var direction = Vector3.ZERO

var current_crouching = 0.0
@export var max_crouching = 0.5
@export var head_height = 1.8

const lerp_speed = 7.5

@export var gravity_force = 1.7

var jump_pull_time = 0
@export var bunny_jump_time_tolerance_ms = 80
@export var out_of_floor_tolerance_ms = 80
var out_of_floor_time = 0


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _input(event) -> void:
	if event is InputEventMouseMotion:
		if Input.get_mouse_mode() != Input.MOUSE_MODE_CAPTURED: return
		rotate_y(deg_to_rad(-event.relative.x * mouse_sensitivity))
		head.rotate_x(deg_to_rad(-event.relative.y * mouse_sensitivity))
		head.rotation.x = clamp(head.rotation.x, deg_to_rad(-89), deg_to_rad(89))
		
	if Input.is_action_just_pressed("escape"):
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _physics_process(delta: float) -> void:
	
	if Input.is_action_pressed("crouch"):
		var target_speed = crouching_speed
		current_speed = lerp(current_speed, target_speed, delta * lerp_speed)
		lower_body.position.y = lerp(lower_body.position.y, lower_body_base.position.y + max_crouching, lerp_speed * delta)
		
	elif not ray_cast_3d.is_colliding():
		lower_body.position.y = lerp(lower_body.position.y, lower_body_base.position.y, lerp_speed * delta)
		if Input.is_action_pressed("sprint"):
			current_speed = sprinting_speed
			
		else:
			current_speed = walking_speed
	

	# Add the gravity.
	if not is_on_floor():
		velocity += get_gravity() * delta * gravity_force
		out_of_floor_time += delta * 1000 # convert to ms
	else:
		out_of_floor_time = 0
	# player wants to jump
	if Input.is_action_just_pressed("jump"):
		jump_pull_time = Time.get_ticks_msec()
		
	if abs(Time.get_ticks_msec() - jump_pull_time) <= bunny_jump_time_tolerance_ms and out_of_floor_time <= out_of_floor_tolerance_ms:
		# Reset jump pull time
		jump_pull_time = 0
		velocity.y = jump_velocity
	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var input_dir := Input.get_vector("left", "right", "forward", "backward")
	direction = lerp(direction, (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized(), acceleration * delta)
	if direction:
		velocity.x = direction.x * current_speed
		velocity.z = direction.z * current_speed
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)

	move_and_slide()
