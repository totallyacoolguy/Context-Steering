class_name PlayerCharacterData
extends Resource

# Player Character Vars
@export_group("Stats")
@export var HP: int = 3
@export var speed: float = 100.0
@export var dash_speed: float = 500.0
@export var gravity_scale: float = 1.0
@export var gravity_limit: int = 350
@export var water_gravity_limit: int = 100
@export var jump_velocity: float = -300.0
@export var short_jump_scalar: float = 0.7
@export var wall_bounce: float = 100.0
@export_group("Physics value")
@export_subgroup("Acceleration & Friction")
@export var acceleration: float = 3000.0
@export var friction: float = 1000.0
@export var air_resistance: float = 200.0
@export var air_acceleration: float = 400.0
@export var water_acceleration: float = 2500.0
@export var launch_air_resistance: float = 200.0
@export var original_air_resistance: float = 1000.0
@export_subgroup("Impulse")
@export var push: float = 15.0
@export var impulse_application_rate: float = 0.25 # Fraction of impulse applied per frame
@export_subgroup("Wall Crash")
@export var jump_velocity_crash: float = -100.0
@export var wall_crash: float = 50.0
@export_group("Misc")
@export var platform_fallthrough_num: int = 5
@export var dash_stop_num: int = 150
@export var slide_stop_num: int = 150
