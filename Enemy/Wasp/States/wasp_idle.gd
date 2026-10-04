class_name WaspIdle
extends State

signal chase

@export var actor: Wasp
@export var kb_timer: Timer
@export var player_detection: Area2D
@export var player_detectionHB: CollisionShape2D
@export var raycast: RayCast2D

@onready var player := get_tree().get_first_node_in_group("Player")

func _ready() -> void:
	set_physics_process(false)

func _enter_state() -> void:
	set_physics_process(true)

func _exit_state() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	var player_pos = player.global_position
	var direction_to_player = player_pos - actor.global_position
	handle_friction(delta)
	direction_to_player = direction_to_player.limit_length(player_detectionHB.shape.radius)
	raycast.set_target_position(direction_to_player)
	
	if (kb_timer.time_left <= 0 and player_detection.has_overlapping_bodies() and not raycast.is_colliding()):
		chase.emit()

func handle_friction(delta: float) -> void:
	actor.velocity.x = move_toward(actor.velocity.x, 0, actor.character_data.friction * delta)
