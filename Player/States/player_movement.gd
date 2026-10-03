class_name PlayerMovement
extends State

signal dashed
signal default
signal jump
signal slide

@export var actor: Player
@export var animator: AnimatedSprite2D
@export var animation: AnimationPlayer
@export var coyote_timer: Timer
@export var dash_timer: Timer
@export var jump_timer: Timer
@export var liquid_detection: Area2D

func _ready() -> void:
	set_physics_process(false)
	set_process(false)

func _enter_state() -> void:
	set_physics_process(true)
	set_process(true)

func _exit_state() -> void:
	set_process(false)
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	var input_axis: float = Input.get_axis("move_left", "move_right")
	handle_acceleration(input_axis,delta) 
	handle_air_acceleration(input_axis,delta)
	
	if (Input.is_action_just_pressed("dash") and Input.is_action_pressed("move_down") and dash_timer.time_left == 0):
		slide.emit()
	elif (Input.is_action_just_pressed("dash") and dash_timer.time_left == 0): 
		dashed.emit()
	elif (input_axis == 0): 
		default.emit()
	elif (Input.is_action_just_pressed("move_up") or jump_timer.time_left > 0): 
		jump.emit()

func _process(_delta: float) -> void:
	animator.play("walk")

func handle_acceleration(input_axis: float, delta: float) -> void:
	if (not actor.is_on_floor()): return
	if (input_axis != 0):
		actor.velocity.x = move_toward(actor.velocity.x, input_axis * actor.character_data.speed, actor.character_data.acceleration * delta)

func handle_air_acceleration(input_axis: float, delta: float) -> void:
	if (actor.is_on_floor()): return
	if (input_axis != 0):
		actor.velocity.x = move_toward(actor.velocity.x, input_axis * actor.character_data.speed, actor.character_data.air_acceleration * delta)
