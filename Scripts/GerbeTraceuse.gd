extends Area2D
## Zone qui suit la gerbe et peint la ville quand elle la recouvre.

const RAYON_MIN := 2
const RAYON_MAX := 6


func _process(_delta: float) -> void:
	if not monitoring or GameState.couleurs_debloquees.is_empty():
		return
	for area in get_overlapping_areas():
		var ville: Node = area.get_parent()
		if ville == null or not ville.has_method("peindre"):
			continue
		var radius: int = clamp(RAYON_MIN + GameState.couleurs_debloquees.size(), RAYON_MIN, RAYON_MAX)
		ville.peindre(global_position, radius, GameState.couleurs_debloquees)
