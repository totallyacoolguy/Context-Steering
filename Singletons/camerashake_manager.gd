extends Node

@export var max_angle = 15
@export var max_offset = 10
@export var max_shake = 1
@export var is_shake_locked: bool = false
@export var is_use_noise: bool = true
@export var is_use_tween: bool = true
@export var is_use_rotation: bool = true
@export var is_use_offset: bool = true
@export var cool_down_speed: float = 0.5
@export var shake_speed: float = 0.05

@onready var timer = Timer.new()
@onready var movement_tween
@onready var rotation_tween

var current_camera: Camera2D = null
var current_shake: float = 0.0
var noise = FastNoiseLite.new()
var noise_offset = 0

func _ready():
	randomize()
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	noise.seed = randi()
	noise.frequency = 2.0
	
	add_child(timer)
	
	timer.timeout.connect(_on_ShakeTimer_timeout)
	timer.wait_time = shake_speed

func _process(_delta):
	if current_shake > 0:
		_screen_shake_loop()

func set_current_camera(camera:Camera2D):
	current_camera = camera
	current_camera.ignore_rotation = true

func shake_screen(shake:float):
	current_shake = clamp(current_shake + shake, 0, max_shake)
	_move_camera_to(_get_random_position())

# SCREEN SHAKE
func _move_camera_to(position:Vector3):
	movement_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	rotation_tween = get_tree().create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	movement_tween.finished.connect(_on_tween_all_completed)
	rotation_tween.finished.connect(_on_tween_all_completed)
	if is_use_tween:
		if is_use_offset:
			movement_tween.tween_property(
				current_camera, 
				"offset", 
				Vector2(position.x, position.y), 
				shake_speed, 
			)
		if is_use_rotation:
			rotation_tween.tween_property(
				current_camera, 
				"rotation_degrees", 
				position.z, 
				shake_speed, 
			)
		else:
			current_camera.rotation_degrees = position.z
	else:
		if is_use_offset:
			current_camera.offset.x = position.x
			current_camera.offset.y = position.y
		if is_use_rotation:
			current_camera.rotation_degrees = position.z
		else:
			current_camera.rotation_degrees = 0
		timer.start()

func _screen_shake_loop():
	if !is_shake_locked:
		if current_shake > 0.01:
			current_shake = lerpf(current_shake, 0, cool_down_speed)
		else:
			current_shake = 0

func _get_random_position():
	if is_use_noise:
		noise_offset += 30
		noise.seed = noise.seed + 1
		var angle = max_angle * current_shake * noise.get_noise_1d(noise_offset)
		
		noise_offset += 30
		noise.seed = noise.seed + 1
		var offsetx = max_offset * current_shake * noise.get_noise_1d(noise_offset)	
		
		noise.seed = noise.seed + 1
		var offsety = max_offset * current_shake * noise.get_noise_1d(noise_offset)
		return Vector3(offsetx, offsety, angle)
	else:
		var angle = max_angle * current_shake * randf_range(-1,1)
		var offsetx = max_offset * current_shake * randf_range(-1,1)
		var offsety = max_offset * current_shake * randf_range(-1,1)
		return Vector3(offsetx, offsety, angle)
		

func _on_tween_all_completed():
	if current_shake > 0:
		#print(current_shake)
		_move_camera_to(_get_random_position())

func _on_ShakeTimer_timeout():
	if current_shake > 0:
		_move_camera_to(_get_random_position())
