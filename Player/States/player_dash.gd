class_name PlayerDash
extends State

signal dashed_stop
signal jump

@export var actor: Player
@export var damage_detection: CollisionShape2D
@export var animator: AnimatedSprite2D
@export var animation: AnimationPlayer
@export var dash_timer: Timer
@export var crash_timer: Timer

func _ready() -> void:
	set_physics_process(false)

func _enter_state() -> void:
	GravityManager.no_gravity(actor)
	animator.play("idle")
	set_physics_process(true)
	actor.velocity.y = 0.0
	damage_detection.disabled = true
	sprite_direction()

func _exit_state() -> void:
	GravityManager.full_gravity(actor)
	set_physics_process(false)
	damage_detection.disabled = false
	actor.character_data.air_resistance = 1000

func Dash_Switch() -> void:
	dashed_stop.emit()
	dash_timer.start() 

func _physics_process(delta: float) -> void:
	handle_dash_friction(delta)
	
	if (actor.is_on_wall()):
		wall_crash()
	elif Input.is_action_just_released("dash"):
		stop_dash()
	elif (abs(actor.velocity.x) <= actor.character_data.dash_stop_num and crash_timer.time_left <= 0): 
		Dash_Switch() 
	elif (Input.is_action_just_pressed("move_up")): 
		jump.emit()

func handle_dash_friction(delta: float) -> void:
	actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.friction * delta)

func sprite_direction() -> void:
	if (animator.flip_h):
		actor.velocity.x = -actor.character_data.dash_speed
	else:
		actor.velocity.x = actor.character_data.dash_speed

func stop_dash() -> void:
	if (abs(actor.velocity.x) > actor.character_data.dash_speed / 2):
		actor.velocity.x = sign(actor.velocity.x) * actor.character_data.dash_speed / 2
		Dash_Switch()

func wall_crash() -> void:
	actor.velocity.x = actor.get_wall_normal().x * actor.character_data.wall_crash
	actor.velocity.y = actor.character_data.jump_velocity_crash
	CamerashakeManager.shake_screen(1)
	crash_timer.start()
	GravityManager.full_gravity(actor)
	await crash_timer.timeout
	Dash_Switch() 
