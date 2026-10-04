class_name Conveyor
extends StaticBody2D

@export var reversed = false

@onready var animation: AnimationPlayer = $AnimationPlayer

func _ready() -> void:
	if (reversed):
		animation.play("Backward")
	else:
		animation.play("Forward")
