extends Node

func find_gravity_property() -> Callable:
	return func(p): return p.name

func full_gravity(entity: Node2D) -> void:
	if (has_gravity_property(entity)):
		entity.gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
	else:
		push_error("GravityManager: Missing 'gravity' property on node: ", entity.name, " at path: ", entity.get_path())

func has_gravity_property(entity: Node2D) -> bool:
	return entity.get_script() and "gravity" in entity.get_script().get_script_property_list().map(find_gravity_property())

func no_gravity(entity: Node2D) -> void:
	if (has_gravity_property(entity)):
		entity.gravity = 0
	else:
		push_error("GravityManager: Missing 'gravity' property on node: ", entity.name, " at path: ", entity.get_path())

func water_gravity(entity: Node2D) -> void:
	if (has_gravity_property(entity)):
		entity.gravity *= 0.5
	else:
		push_error("GravityManager: Missing 'gravity' property on node: ", entity.name, " at path: ", entity.get_path())
