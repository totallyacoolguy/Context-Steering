class_name Player
extends CharacterBody2D

@export var character_data: PlayerCharacterData
@export var death_particles: PackedScene

@onready var past_direction: bool = $AnimatedSprite2D.flip_h
@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var player_collision: CollisionShape2D = $WorldCollision
@onready var camera: Camera2D = $Camera2D

@onready var detection: Node2D = $Detection
@onready var hazzard_detection: Area2D = $Detection/HazzardDetection
@onready var hazzard_detectionHB: CollisionShape2D = $Detection/HazzardDetection/HazzardDetectionHB
@onready var liquid_detection: Area2D = $Detection/LiquidDetection
@onready var liquid_detectionHB: CollisionShape2D = $Detection/LiquidDetection/LiquidDetectionHB
@onready var movement_obj_detection: Area2D = $Detection/MovementObjDetection
@onready var movement_obj_detectionHB: CollisionShape2D = $Detection/MovementObjDetection/MovementObjDetectionHB
@onready var sword_swing_detection: Area2D = $Detection/SwordSwingDetection
@onready var sword_swingHB: CollisionShape2D = $Detection/SwordSwingDetection/SwordSwingHB

@onready var fsm: FiniteStateMachine = $FiniteStateMachine
@onready var player_default: PlayerDefault = $FiniteStateMachine/PlayerDefault
@onready var player_dash: PlayerDash = $FiniteStateMachine/PlayerDash
@onready var player_movement: PlayerMovement = $FiniteStateMachine/PlayerMovement
@onready var player_jump: PlayerJump = $FiniteStateMachine/PlayerJump
@onready var player_slide: PlayerSlide = $FiniteStateMachine/PlayerSlide

@onready var coyote_jump_timer: Timer = $Timers/CoyoteJumpTimer
@onready var crash_timer: Timer = $Timers/CrashTimer
@onready var dash_timer: Timer = $Timers/DashTimer
@onready var iframe_timer: Timer = $Timers/iFrameTimer
@onready var jump_timer: Timer = $Timers/JumpTimer
@onready var quick_fall_timer: Timer = $Timers/QuickFallTimer
@onready var slide_timer: Timer = $Timers/SlideTimer
@onready var through_platform_timer: Timer = $Timers/ThroughPlatformTimer
@onready var wall_jump_timer: Timer = $Timers/WallJumpTimer
@onready var water_jump_timer: Timer = $Timers/WaterJumpTimer

var able_double_jump: bool = true
var wall_jump_start: bool = true
var able_wall_jump: bool = false
var could_quick_fall: bool = false
var drop_through_platform: bool = false
var was_wall_normal: Vector2 = Vector2.ZERO
var pending_impulses: Dictionary = {} # Dictionary to track pending impulses per body
var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")

func _ready() -> void:
	character_data.HP = 3
	CamerashakeManager.set_current_camera(camera)
	
	Dash_Signals()
	Default_Signals()
	Jump_Signals()
	Movement_Signals()
	Slide_Signals()

func Default_Signals() -> void:
	player_default.dashed.connect(fsm.change_state.bind(player_dash))
	player_default.jump.connect(fsm.change_state.bind(player_jump))
	player_default.slide.connect(fsm.change_state.bind(player_slide))
	player_default.walk.connect(fsm.change_state.bind(player_movement))

func Dash_Signals() -> void:
	player_dash.dashed_stop.connect(fsm.change_state.bind(player_movement))
	player_dash.jump.connect(fsm.change_state.bind(player_jump))

func Jump_Signals() -> void:
	player_jump.dashed.connect(fsm.change_state.bind(player_dash))
	player_jump.grounded.connect(fsm.change_state.bind(player_default))

func Movement_Signals() -> void:
	player_movement.dashed.connect(fsm.change_state.bind(player_dash))
	player_movement.default.connect(fsm.change_state.bind(player_default))
	player_movement.jump.connect(fsm.change_state.bind(player_jump))
	player_movement.slide.connect(fsm.change_state.bind(player_slide))

func Slide_Signals() -> void:
	player_slide.jump.connect(fsm.change_state.bind(player_jump))
	player_slide.slide_stop.connect(fsm.change_state.bind(player_movement))


func _physics_process(delta: float) -> void:
	apply_gravity(delta)
	touching_hazzard()
	handle_jump_timer()
	var was_on_floor: bool = is_on_floor()
	var was_on_wall: bool = is_on_wall_only()
	if (was_on_wall): 
		was_wall_normal = get_wall_normal()
	move_and_slide()
	
	var just_left_edge: bool = was_on_floor and not is_on_floor() and velocity.y >= 0  
	var just_left_wall: bool = was_on_wall and not is_on_wall() and velocity.y >= 0
	if (just_left_wall): 
		wall_jump_timer.start()
	elif (just_left_edge):
		coyote_jump_timer.start()
	quick_fall()
	drop_down()

func _process(_delta: float) -> void:
	var input_axis: float = Input.get_axis("move_left", "move_right")
	dir_flip(input_axis)

func apply_gravity(delta: float) -> void:
	if (not is_on_floor() and velocity.y < character_data.gravity_limit):
		if (Input.is_action_just_pressed("move_down") and could_quick_fall and not liquid_detection.has_overlapping_areas()):
			velocity.y = character_data.gravity_limit
		else:
			velocity.y += gravity * character_data.gravity_scale * delta
	elif (not is_on_floor()):
		velocity.y = character_data.gravity_limit
	if (liquid_detection.has_overlapping_areas() and velocity.y >= character_data.water_gravity_limit):
		velocity.y = move_toward(velocity.y, character_data.water_gravity_limit, character_data.water_acceleration * delta)
	if (Input.is_action_just_pressed("move_down") and drop_through_platform):
		position.y += character_data.platform_fallthrough_num

func dir_flip(input_axis: float) -> void:
	if (input_axis != 0):
		animated_sprite.flip_h = input_axis <= 0
	if (animated_sprite.flip_h != past_direction):
		past_direction = true if animated_sprite.flip_h == true else false
		detection.scale.x *= -1
		player_collision.position.x *= -1

func drop_down() -> void:
	if (Input.is_action_just_pressed("move_down") and is_on_floor()):
		drop_through_platform = true
		through_platform_timer.start()
	elif (through_platform_timer.time_left <= 0):
		drop_through_platform = false

func handle_jump_timer() -> void:
	if (Input.is_action_just_pressed("move_up") and not liquid_detection.has_overlapping_areas()):
		jump_timer.start() 

func quick_fall() -> void:
	if (Input.is_action_just_pressed("move_down") and not is_on_floor()):
		could_quick_fall = true
	elif (is_on_floor()):
		could_quick_fall = false

func show_death() -> void:
	var clone := death_particles.instantiate()
	get_tree().current_scene.add_child.call_deferred(clone)
	clone.emitting = true
	clone.global_position = global_position
	await clone.finished
	clone.queue_free()

func take_damage() -> void:
	if (iframe_timer.time_left <= 0):
		character_data.HP -= 1
		iframe_timer.start()
		show_death()

func touching_hazzard() -> void:
	if (hazzard_detection.has_overlapping_areas() or hazzard_detection.has_overlapping_bodies()):
		take_damage()
		if (character_data.HP <= 0):
			HitstunManager.slow_motion_short()
			show_death()
			call_deferred("set_process_mode", 4) # Disabled
			animated_sprite.set_visible(false)
