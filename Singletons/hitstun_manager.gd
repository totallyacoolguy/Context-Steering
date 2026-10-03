extends Node

func hit_stop_short():
	Engine.time_scale = 0
	await get_tree().create_timer(0.15, true, false, true).timeout
	Engine.time_scale = 1

func hit_stop_medium():
	Engine.time_scale = 0
	await get_tree().create_timer(0.25, true, false, true).timeout
	Engine.time_scale = 1

func hit_stop_long():
	Engine.time_scale = 0
	await get_tree().create_timer(0.5, true, false, true).timeout
	Engine.time_scale = 1

func slow_motion_short():
	Engine.time_scale = 0.25
	await get_tree().create_timer(0.25, true, false, true).timeout
	Engine.time_scale = 1
