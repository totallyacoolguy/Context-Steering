class_name WaspSurround
extends State

signal out_of_sight
signal attack

@export var actor: Wasp
@export var tackle_detection: Area2D
@export var player_detectionHB: CollisionShape2D
@export var tackle_random: Timer
@export var raycast: RayCast2D

@onready var player := get_tree().get_first_node_in_group("Player")

func _ready() -> void:
	set_physics_process(false)

func _enter_state() -> void:
	set_physics_process(true)
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	var random_number: float = rng.randf_range(1.0, 3.0)
	tackle_random.wait_time = random_number
	tackle_random.start()

func _exit_state() -> void:
	set_physics_process(false)
	tackle_random.stop()

func _physics_process(delta: float) -> void:
	var direction_to_player: Vector2 = player.global_position - actor.global_position
	direction_to_player = direction_to_player.limit_length(player_detectionHB.shape.radius)
	raycast.set_target_position(direction_to_player)
	set_interest(direction_to_player)
	set_danger()
	choose_direction()
	chase_player(delta)
	
	if (tackle_random.time_left <= 0):
		pass#attack.emit()
	if (not tackle_detection.has_overlapping_bodies()):
		out_of_sight.emit()

func choose_direction() -> void:
	for i in actor.character_data.num_arrays:
		if (actor.character_data.danger[i] > 0):
			actor.character_data.interest[i] = -actor.character_data.danger[i]
	actor.character_data.chosen_dir = Vector2.ZERO
	for i in actor.character_data.num_arrays:
		var direction_to_player: Vector2 = player.global_position - actor.global_position
		if (abs(direction_to_player.length()) > actor.character_data.halt_distance and actor.character_data.danger[i] >= 0):
			var scaled_interest: float = actor.character_data.interest[i]/actor.character_data.interest_scalar
			actor.character_data.chosen_dir += actor.character_data.ray_direction[i] * scaled_interest
		else:
			var scaled_interest: float = actor.character_data.interest[i]/actor.character_data.interest_scalar
			actor.character_data.chosen_dir += actor.character_data.ray_direction[i] * scaled_interest
	actor.character_data.chosen_dir = actor.character_data.chosen_dir.normalized().rotated(actor.rotation)

func chase_player(delta: float) -> void:
	var desired_velocity: Vector2 = actor.character_data.chosen_dir * actor.character_data.speed
	var input_axis_x: float = Input.get_axis("move_left", "move_right")
	var input_axis_y: float = Input.get_axis("move_up", "move_down")
	## Stop movement when close enough
	if (abs(actor.velocity.x) < 3 and abs(actor.velocity.y) < 3 and input_axis_x == 0 and input_axis_y == 0):
		actor.velocity = Vector2.ZERO
	else:
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
		if (collided):
			var distance_to_collision = result.position.distance_to(ray_origin)
			var max_distance = actor.character_data.danger_ray_length
			if (result.collider is World): 
				actor.character_data.danger[i] = (max_distance / distance_to_collision) * 200 ## World Scaler
			if (result.collider is Player): 
				actor.character_data.danger[i] = (max_distance / distance_to_collision) * 200 ## Player Scaler
			if (result.collider is Wasp): 
				actor.character_data.danger[i] = (max_distance / distance_to_collision) * .3 ## Wasp Scaler
			else: 
				actor.character_data.danger[i] = (max_distance / distance_to_collision)
		else:
			actor.character_data.danger[i] = 0.0
		draw_debug_rays(ray_origin, ray_end, collided, rays_to_draw)
	actor.update_debug_rays(rays_to_draw, actor.character_data.show_debug_rays)

func set_interest(player_dir: Vector2) -> void:
	for i in actor.character_data.num_arrays:
		var normalized_player_dir: Vector2 = player_dir.normalized()
		var dot: float = actor.character_data.ray_direction[i].dot(normalized_player_dir)
		actor.character_data.interest[i] = max(actor.character_data.min_dot_chase, dot)
