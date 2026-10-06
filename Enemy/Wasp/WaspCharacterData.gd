class_name WaspCharacterData
extends Resource

# Drone Character Var
@export_group("Stats")
@export var HP: int = 3
@export var gravity_scale: float = 1.0
@export var speed: float = 100.0
@export_group("Physics value")
@export_subgroup("Acceleration & Friction")
@export var friction: float = 1000.0
@export var acceleration: float = 3000.0
@export_subgroup("KnockBack")
@export var Hdamage_bounce: int = 100
@export var Ldamage_bounce: int = 200
@export_subgroup("Impulse")
@export var push: float = 15.0
@export var impulse_application_rate: float = 0.25 # Fraction of impulse applied per frame
@export var damp: float = 0.6
@export_group("Context Steering")
@export var num_arrays: int = 8
@export var ray_direction: Array = []
@export var interest: Array = []
@export var danger: Array = []
@export var danger_ray_length: float = 25.0
@export var chosen_dir: Vector2 = Vector2.ZERO
@export var ray_orgin_displacement: Vector2 = Vector2.ZERO
@export var ray_skew: Vector2 = Vector2.ZERO
@export var interest_scalar: float = 2
@export var danger_scalar: float = 1
@export var danger_curve: Curve
@export var min_dot_chase: float = -0.01
@export_group("Misc")
@export var gravity_limit: int = 350
@export var flip_threshold: int = 3
@export var out_of_sight_threshold: int = 10
@export var tackle_finish_threshold: int = 8
@export var stopping_threshold: int = 10
@export var halt_distance: int = 30
@export var show_debug_rays: bool = false
