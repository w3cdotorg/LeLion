extends Area2D


func _ready() -> void:
	add_to_group("gerbe_traceuse")
	monitoring = true


func _process(_delta: float) -> void:
	if not monitoring:
		return
	for area in get_overlapping_areas():
		var ville: Node = area
		while ville and not ville.has_method("peindre"):
			ville = ville.get_parent()
		if ville == null:
			continue

		var lion: Node = get_tree().get_first_node_in_group("lion")
		if lion == null or lion.couleurs_debloquees.is_empty():
			continue

		var couleur: Color = lion.couleurs_debloquees[randi() % lion.couleurs_debloquees.size()]
		var local_pos: Vector2 = ville.get_node("Sprite2D").to_local(global_position)
		var radius: int = clamp(2 + lion.couleurs_debloquees.size(), 2, 6)
		ville.peindre(local_pos, couleur, radius, lion.couleurs_debloquees)
