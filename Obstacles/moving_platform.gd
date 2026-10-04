class_name MovingPlaform
extends Node2D

@export var reversed: bool = false

@onready var animation: AnimationPlayer = $AnimatableBody2D/AnimationPlayer

func _ready() -> void:
	if (reversed):
		animation.play("reverse_triangle_movement")
	else:
		animation.play("triangle_movement")
