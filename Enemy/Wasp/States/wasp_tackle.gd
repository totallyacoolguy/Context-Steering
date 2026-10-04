class_name WaspTackle
extends State

signal out_of_range

@export var tackle_detection: Area2D
@export var damage_detection: Area2D
@export var slam_detection: Area2D
@export var slam_detection_HB: CollisionShape2D
@export var actor: Wasp
@export var raycast: RayCast2D
@export var animation: Sprite2D
@export var tackle_interval: Timer
@export var kb_timer: Timer
@export var tackle_cd: Timer

@onready var player := get_tree().get_first_node_in_group("Player")

var past_player: Vector2 = Vector2.ZERO

func _ready() -> void:
	set_physics_process(false)

func _enter_state() -> void:
	actor.velocity = Vector2.ZERO
	slam_detection_HB.disabled = false
	past_player = player.global_position
	set_physics_process(true)

func _exit_state() -> void:
	actor.velocity = Vector2.ZERO
	slam_detection_HB.disabled = true
	past_player = Vector2.ZERO
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	var direction_to_player: Vector2 = past_player - actor.global_position
	actor.velocity = actor.velocity.lerp(direction_to_player.normalized() * actor.character_data.speed, actor.character_data.acceleration * delta)
	
	if (finish_tackle()):
		tackle_cd.start()
		out_of_range.emit()

func finish_tackle() -> bool:
	var reached_x: bool = abs(actor.global_position.x - past_player.x) <= actor.character_data.tackle_finish_threshold
	var reached_y: bool = abs(actor.global_position.y - past_player.y) <= actor.character_data.tackle_finish_threshold
	var reached_target: bool = reached_x and reached_y
	var hit_something: bool = not slam_detection.get_overlapping_areas().is_empty()
	return reached_target or hit_something

func handle_friction(delta: float) -> void:
	actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.friction * delta)
