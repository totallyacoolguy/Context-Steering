class_name Wasp
extends CharacterBody2D

@export var character_data: WaspCharacterData
@export var death_particle: PackedScene

@onready var player: Player = get_tree().get_first_node_in_group("Player")
@onready var raycast: RayCast2D = $RayCast2D

@onready var past_direction: bool = $Sprite2D.flip_h
@onready var sprite: Sprite2D = $Sprite2D

@onready var enemy_collision: CollisionShape2D = $WorldCollision
@onready var dead_collision: CollisionPolygon2D = $DeadCollision

@onready var detection: Node2D = $Detection
@onready var damage_detectionHB: CollisionShape2D  = $Detection/DamageDetection/DamageDetectionHB
@onready var player_detectionHB: CollisionShape2D = $Detection/PlayerDetection/PlayerDectectionHB
@onready var tackle_detection_HB: CollisionShape2D = $Detection/TackleDetection/TackleDetectionHB
@onready var slam_detection_HB: CollisionShape2D = $Detection/SlamDetection/SlamDetectionHB
@onready var damage_detection: Area2D = $Detection/DamageDetection
@onready var player_detection: Area2D = $Detection/PlayerDetection
@onready var tackle_detection: Area2D = $Detection/TackleDetection
@onready var slam_detection: Area2D = $Detection/SlamDetection

@onready var fsm: FiniteStateMachine = $FiniteStateMachine
@onready var wasp_idle: WaspIdle = $FiniteStateMachine/WaspIdle
@onready var wasp_chase: WaspChase = $FiniteStateMachine/WaspChase
@onready var wasp_surround: WaspSurround = $FiniteStateMachine/WaspSurround
@onready var wasp_tackle: WaspTackle = $FiniteStateMachine/WaspTackle
@onready var wasp_out_of_sight: WaspOutOfSight = $FiniteStateMachine/WaspOutOfSight

@onready var iframe_damage: Timer = $Timers/iFrameDamage
@onready var kb_timer: Timer = $Timers/KBTimer

var gravity: float = ProjectSettings.get_setting("physics/2d/default_gravity")
var pending_impulses: Dictionary = {} # Dictionary to track pending impulses per body
var debug_rays: Array = []

func _ready() -> void:
	print(player)
	Chase_Signals()
	Idle_Signals()
	Surround_Signals()
	Tackle_Signals()
	Out_Of_Sight_Signals()
	slam_detection_HB.disabled = true
	resize_arrays()
	set_direction()
	set_physics_process(true)

func Chase_Signals() -> void:
	wasp_chase.out_of_sight.connect(fsm.change_state.bind(wasp_out_of_sight))
	wasp_chase.idle.connect(fsm.change_state.bind(wasp_idle))
	wasp_chase.in_attack_range.connect(fsm.change_state.bind(wasp_surround))

func Idle_Signals() -> void:
	wasp_idle.chase.connect(fsm.change_state.bind(wasp_chase))

func Surround_Signals() -> void:
	wasp_surround.out_of_sight.connect(fsm.change_state.bind(wasp_chase))
	wasp_surround.attack.connect(fsm.change_state.bind(wasp_tackle))

func Out_Of_Sight_Signals() -> void:
	wasp_out_of_sight.idle.connect(fsm.change_state.bind(wasp_idle))
	wasp_out_of_sight.chase.connect(fsm.change_state.bind(wasp_chase))

func Tackle_Signals() -> void:
	wasp_tackle.out_of_range.connect(fsm.change_state.bind(wasp_surround))

func _physics_process(delta: float) -> void:
	got_hit()
	if (character_data.HP <= 0): apply_gravity(delta)
	move_and_slide()
	entity_impulse()

func _process(_delta: float) -> void:
	var player_pos = player.global_position
	dir_flip(player_pos)

func _draw() -> void:
	for ray in debug_rays:
		var color = Color.RED if ray[2] else Color.GREEN
		draw_line(ray[0], ray[1], color, 2)

func apply_gravity(delta: float) -> void: 
	if (not is_on_floor() and velocity.y < character_data.gravity_limit):
		velocity.y += gravity * character_data.gravity_scale * delta

func apply_impulse(collision: KinematicCollision2D, other_body: Object) -> void:
	var impulse_direction := -collision.get_normal() * character_data.push
	if (not pending_impulses.has(other_body)):
		pending_impulses[other_body] = Vector2.ZERO
	pending_impulses[other_body] += impulse_direction
	var impulse_to_apply = pending_impulses[other_body] * character_data.impulse_application_rate # Apply a fraction of the pending impulse
	other_body.velocity += impulse_to_apply
	pending_impulses[other_body] -= impulse_to_apply
	other_body.velocity *= character_data.damp # Damp

func chase_player(flip: int, delta: float):
	velocity.x = move_toward(velocity.x, flip * character_data.speed, character_data.acceleration * delta)

func dir_flip(player_pos):
	if (raycast.is_colliding()): return
	var direction_to_player = player_pos - self.global_position
	if (direction_to_player.x > character_data.flip_threshold): $Sprite2D.flip_h = true
	elif (direction_to_player.x < -character_data.flip_threshold): $Sprite2D.flip_h = false
	if ($Sprite2D.flip_h != past_direction):
		past_direction = true if $Sprite2D.flip_h == true else false
		detection.scale.x *= -1
		dead_collision.scale.x *= -1
		enemy_collision.position.x *= -1

func disable_all() -> void:
	damage_detectionHB.disabled = true
	player_detectionHB.disabled = true
	tackle_detection_HB.disabled = true

func entity_impulse() -> void:
	for index in get_slide_collision_count():
		var collision := get_slide_collision(index)
		var other_body := collision.get_collider()
		if (other_body.is_in_group("Bodies")):
			apply_impulse(collision, other_body)

func got_hit() -> void:
	if (damage_detection.has_overlapping_areas()):
		hit_flash()
		if (character_data.HP > 1):
			#HitstunManager.hit_stop_short()
			CamerashakeManager.shake_screen(0.5)
			damage_detectionHB.disabled = true
			make_death_particle()
			knock_back()
			iframe_damage.start()
			await iframe_damage.timeout
			damage_detectionHB.disabled = false
			character_data.HP -= 1
		else:
			character_data.HP -= 1
			knock_back()
			show_death()

func hit_flash() -> void:
	var tween := create_tween()
	tween.tween_property(sprite, "modulate", Color.RED, 0.1)
	tween.chain().tween_property(sprite, "modulate", Color.WHITE, 0.1)

func show_death() -> void:
	set_process(false)
	disable_all()
	enemy_collision.disabled = true
	dead_collision.scale.y *= -1
	$Sprite2D.flip_v = true
	make_death_particle()
	CamerashakeManager.shake_screen(1)
	HitstunManager.slow_motion_short()

func knock_back() -> void:
	var direction_L: int = -1 if player.animated_sprite.flip_h else 1
	velocity.x = direction_L * character_data.Ldamage_bounce
	var direction_H: int = -1 if player.global_position.y > self.global_position.y else 1
	velocity.y = direction_H * character_data.Hdamage_bounce
	kb_timer.start()

func make_death_particle() -> void:
	var clone = death_particle.instantiate()
	clone.emitting = true
	add_child(clone)

func set_direction() -> void:
	var forward_direction: Vector2 = velocity.normalized() if velocity != Vector2.ZERO else Vector2.RIGHT
	for i in character_data.num_arrays:
		var angle = i * 2 * PI / character_data.num_arrays
		character_data.ray_direction[i] = forward_direction.rotated(angle) + character_data.ray_skew

func resize_arrays() -> void:
	character_data.interest.resize(character_data.num_arrays)
	character_data.danger.resize(character_data.num_arrays)
	character_data.ray_direction.resize(character_data.num_arrays)

func update_debug_rays(rays: Array, show: bool) -> void:
	if (not show): return
	debug_rays = rays
	queue_redraw()
