class_name WaspChase
extends State

signal out_of_sight
signal idle
signal in_attack_range

@export var actor: Wasp
@export var player_detection: Area2D
@export var player_detectionHB: CollisionShape2D
@export var tackle_detection: Area2D
@export var kb_timer: Timer
@export var tackle_cd: Timer
@export var raycast: RayCast2D
@export var raycast_patrol: RayCast2D

@onready var player := get_tree().get_first_node_in_group("Player")

var past_player_position: Vector2 = Vector2.ZERO
var past_actor_position: Vector2 = Vector2.ZERO
var debug_rays = []

func _ready() -> void:
	set_physics_process(false)

func _enter_state() -> void:
	set_physics_process(true)

func _exit_state() -> void:
	set_physics_process(false)

func _physics_process(delta: float) -> void:
	var direction_to_player: Vector2 = player.global_position - actor.global_position
	direction_to_player = direction_to_player.limit_length(player_detectionHB.shape.radius)
	raycast.set_target_position(direction_to_player)
	set_interest(direction_to_player)
	set_danger()
	choose_direction()
	chase_player(delta)
	
	if (raycast.is_colliding() or not player_detection.has_overlapping_bodies() or kb_timer.time_left > 0):
		raycast_patrol.set_target_position(direction_to_player)
		out_of_sight.emit()
	if (kb_timer.time_left > 0):
		idle.emit()
	if (not raycast.is_colliding() and tackle_detection.has_overlapping_bodies() and tackle_cd.time_left <= 0):
		in_attack_range.emit()

func calculate_danger_rays(collided: bool, ray_origin: Vector2, collided_position: Vector2, index: int) -> void:
	if (collided):
		var distance_to_collision = collided_position.distance_to(ray_origin)
		var max_distance = actor.character_data.danger_ray_length
		var closeness = 1.0 - (distance_to_collision / max_distance)
		var non_linear_danger = actor.character_data.danger_curve.sample(closeness)
		actor.character_data.danger[index] = max(0.0, non_linear_danger * actor.character_data.danger_scalar)
	else:
		actor.character_data.danger[index] = 0.0

func choose_direction() -> void:
	for i in actor.character_data.num_arrays:
		if (actor.character_data.danger[i] > 0):
			actor.character_data.interest[i] = -actor.character_data.danger[i]
	
	actor.character_data.chosen_dir = Vector2.ZERO
	for i in actor.character_data.num_arrays:
		actor.character_data.chosen_dir += actor.character_data.ray_direction[i] * actor.character_data.interest[i]
	
	actor.character_data.chosen_dir = actor.character_data.chosen_dir.normalized().rotated(actor.rotation)

func chase_player(delta: float) -> void:
	var desired_velocity = actor.character_data.chosen_dir * actor.character_data.speed
	actor.velocity = actor.velocity.lerp(desired_velocity, actor.character_data.acceleration * delta)

func draw_debug_rays(ray_origin: Vector2, ray_end: Vector2, collided: bool, rays_to_draw: Array) -> void:
	rays_to_draw.append([
			actor.to_local(ray_origin),
			actor.to_local(ray_end),
			collided
	])

func set_danger() -> void:
	var space_state: PhysicsDirectSpaceState2D = actor.get_world_2d().direct_space_state
	var rays_to_draw: Array = []
	var query_params: PhysicsRayQueryParameters2D = PhysicsRayQueryParameters2D.new()
	query_params.collision_mask = (1 << 0) | (1 << 1) | (1 << 2)
	query_params.exclude = [actor]
	for i in actor.character_data.num_arrays:
		var ray_origin: Vector2 = actor.position + actor.character_data.ray_orgin_displacement
		var ray_end: Vector2 = ray_origin + actor.character_data.ray_direction[i].rotated(actor.rotation) * actor.character_data.danger_ray_length 
		query_params.from = ray_origin
		query_params.to = ray_end
		var result = space_state.intersect_ray(query_params)
		var collided: bool = result and result.collider
		var collision_pos: Vector2 = result.get("position", Vector2.ZERO) if collided else Vector2.ZERO
		calculate_danger_rays(collided, ray_origin, collision_pos, i)
		draw_debug_rays(ray_origin, ray_end, collided, rays_to_draw)
	actor.update_debug_rays(rays_to_draw, actor.character_data.show_debug_rays)

func set_interest(player_dir: Vector2) -> void:
	for i in actor.character_data.num_arrays:
		var normalized_player_dir: Vector2 = player_dir.normalized()
		var dot: float = actor.character_data.ray_direction[i].dot(normalized_player_dir)
		actor.character_data.interest[i] = max(actor.character_data.min_dot_chase, dot)
