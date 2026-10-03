class_name PlayerSlide
extends State

signal slide_stop
signal spear_thrust
signal swinged
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
	animator.play("idle")
	set_physics_process(true)
	actor.velocity.y = 0.0
	damage_detection.disabled = true
	sprite_direction()

func _exit_state() -> void:
	set_physics_process(false)
	damage_detection.disabled = false

func Slide_Switch() -> void:
	slide_stop.emit()
	dash_timer.start() 

func Spear_Thrust_Switch() -> void:
	spear_thrust.emit()
	dash_timer.start() 

func Swing_Switch() -> void:
	swinged.emit()
	dash_timer.start() 

func _physics_process(delta: float) -> void:
	handle_slide_friction(delta)
	
	if (actor.is_on_wall()):
		wall_crash()
	elif (Input.is_action_just_released("dash")):
		stop_slide()
	elif (abs(actor.velocity.x) <= actor.character_data.dash_stop_num and crash_timer.time_left <= 0): 
		Slide_Switch() 
	elif (Input.is_action_just_pressed("swing_attack") and not animation.is_playing()): 
		Spear_Thrust_Switch()
	elif (Input.is_action_just_pressed("spear_thrust") and not animation.is_playing()): 
		Swing_Switch()
	elif (Input.is_action_just_pressed("move_up")): jump.emit()

func handle_slide_friction(delta: float) -> void:
	actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.friction * delta)

func sprite_direction() -> void:
	if(animator.flip_h):
		actor.velocity.x = -actor.character_data.dash_speed
	else:
		actor.velocity.x = actor.character_data.dash_speed

func stop_slide() -> void:
	if (abs(actor.velocity.x) > actor.character_data.dash_speed/2):
		actor.velocity.x = sign(actor.velocity.x) * actor.character_data.dash_speed/2
		Slide_Switch()

func wall_crash() -> void:
	actor.velocity.x = actor.get_wall_normal().x * actor.character_data.wall_crash
	actor.velocity.y = actor.character_data.jump_velocity_crash
	CamerashakeManager.shake_screen(1)
	crash_timer.start()
	GravityManager.full_gravity(actor)
	await crash_timer.timeout
	Slide_Switch() 
