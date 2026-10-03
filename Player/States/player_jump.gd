class_name PlayerJump
extends State

signal dashed
signal grounded

@export var actor: Player
@export var jump_timer: Timer
@export var coyote_jump_timer: Timer
@export var wall_jump_timer: Timer
@export var dash_timer: Timer
@export var animation: AnimationPlayer
@export var animator: AnimatedSprite2D
@export var movement_obj_detection: Area2D
@export var liquid_detection: Area2D

func _enter_state() -> void:
	handle_enter_jump()
	set_physics_process(true)

func _exit_state() -> void:
	set_physics_process(false)

func Ground_Switch() -> void:
	wall_jump_timer.stop()
	actor.wall_jump_start = true
	grounded.emit()

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	var input_axis: float = Input.get_axis("move_left", "move_right")
	handle_acceleration(input_axis,delta) 
	handle_air_acceleration(input_axis,delta)
	handle_air_resistance(input_axis,delta)
	handle_friction(input_axis,delta)
	handle_wall_jump()
	handle_jump()
	animator.play("idle")
	
	if (Input.is_action_just_pressed("dash") and dash_timer.time_left == 0): 
		dashed.emit()
	elif (actor.is_on_floor()): 
		Ground_Switch()

func double_jump() -> void:
	if (Input.is_action_just_pressed("move_up")):
		if (not actor.is_on_wall_only() or not actor.able_wall_jump):
			actor.able_double_jump = false
			actor.velocity.y = actor.character_data.jump_velocity

func handle_acceleration(input_axis: float, delta: float) -> void:
	if (not actor.is_on_floor()): return
	if (input_axis != 0):
		actor.velocity.x = move_toward(actor.velocity.x, input_axis * actor.character_data.speed, actor.character_data.acceleration * delta)

func handle_air_acceleration(input_axis: float, delta: float) -> void:
	if (actor.is_on_floor()): return
	if (input_axis != 0):
		actor.velocity.x = move_toward(actor.velocity.x, input_axis * actor.character_data.speed, actor.character_data.air_acceleration * delta)

func handle_air_resistance(input_axis: float, delta: float) -> void:
	if (actor.is_on_floor()): return
	if (input_axis == 0):
		actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.air_resistance * delta)

func handle_enter_jump() -> void:
	if (actor.is_on_floor()):
		jump_timer.start()
		jump()
	elif (not actor.is_on_floor()):
		if (wall_jump_timer.is_stopped() and actor.able_double_jump):
			if (not actor.is_on_wall_only() or not actor.able_wall_jump):
				actor.able_double_jump = false
				actor.velocity.y = actor.character_data.jump_velocity
				if (not Input.is_action_pressed("move_up")):
					actor.velocity.y *= actor.character_data.short_jump_scalar

func handle_friction(input_axis: float, delta: float) -> void:
	if (not actor.is_on_floor()): return
	if (input_axis == 0):
		actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.friction * delta)

func handle_jump() -> void:
	if (actor.is_on_floor() or actor.velocity.y >= 0): 
		actor.character_data.air_resistance = actor.character_data.original_air_resistance
	if (actor.is_on_floor() or coyote_jump_timer.time_left > 0.0):
		actor.able_double_jump = true
		jump()
	elif (not actor.is_on_floor()):
		if (wall_jump_timer.is_stopped() and coyote_jump_timer.is_stopped() and actor.able_double_jump): 
			double_jump()
		if (actor.velocity.y < 0):
			short_hop()

func handle_wall_jump() -> void:
	var wall_normal := actor.get_wall_normal()
	if (wall_jump_timer.time_left > 0.0):
		wall_normal = actor.was_wall_normal
	elif (actor.is_on_floor()): 
		wall_jump_timer.stop()
		actor.wall_jump_start = true
	else:
		actor.able_wall_jump = false
	if (actor.wall_jump_start and actor.is_on_wall_only() or wall_jump_timer.time_left > 0.0):
		actor.able_wall_jump = true
		wall_jump(wall_normal)

func jump() -> void:
	if (jump_timer.time_left > 0.0):
		if (movement_obj_detection.has_overlapping_bodies()): 
			actor.character_data.air_resistance = actor.character_data.launch_air_resistance
		jump_timer.stop()
		coyote_jump_timer.stop()
		actor.velocity.y = actor.character_data.jump_velocity

func short_hop() -> void:
	if (Input.is_action_just_released("move_up")):
		actor.velocity.y *= 0.7

func wall_jump(wall_normal: Vector2) -> void:
	if (Input.is_action_just_pressed("move_up")):
		actor.velocity.x = wall_normal.x * actor.character_data.wall_bounce
		actor.velocity.y = actor.character_data.jump_velocity
		actor.wall_jump_start = false
