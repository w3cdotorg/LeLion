extends Area2D
## Zone qui suit la gerbe et peint la ville quand elle la recouvre.
## Le rayon de peinture est celui de sa forme de collision (réglé par le lion).

@onready var forme: CollisionShape2D = $CollisionShape2D


func _process(_delta: float) -> void:
	if not monitoring or GameState.couleurs_debloquees.is_empty():
		return
	var rayon := int((forme.shape as CircleShape2D).radius)
	for area in get_overlapping_areas():
		var ville: Node = area.get_parent()
		if ville != null and ville.has_method("peindre"):
			ville.peindre(global_position, rayon, GameState.couleurs_debloquees)
