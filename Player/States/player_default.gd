class_name PlayerDefault
extends State

signal dashed
signal jump
signal slide
signal walk

@export var actor: Player
@export var animation: AnimationPlayer
@export var animator: AnimatedSprite2D
@export var dash_timer: Timer
@export var jump_timer: Timer
@export var liquid_detection: Area2D

func _enter_state() -> void:
	set_physics_process(true)

func _exit_state() -> void:
	set_physics_process(false)

func _ready() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	var input_axis: float = Input.get_axis("move_left", "move_right")
	handle_air_resistance(input_axis,delta)
	handle_friction(input_axis,delta)
	animator.play("idle")
	
	if (input_axis != 0): 
		walk.emit()
	elif (Input.is_action_just_pressed("dash") and Input.is_action_pressed("move_down") and dash_timer.time_left == 0): 
		slide.emit()
	elif (Input.is_action_just_pressed("dash") and dash_timer.time_left == 0): 
		dashed.emit()
	elif (Input.is_action_just_pressed("move_up") or jump_timer.time_left > 0): 
		jump.emit()

func handle_air_resistance(input_axis: float, delta: float) -> void:
	if (actor.is_on_floor()): return
	if (input_axis == 0):
		actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.air_resistance * delta)

func handle_friction(input_axis: float, delta: float) -> void:
	if (not actor.is_on_floor()): return
	if (input_axis == 0):
		actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.friction * delta)
