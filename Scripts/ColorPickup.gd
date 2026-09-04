extends Area2D
## Pastille qui débloque une couleur de l'arc-en-ciel quand le lion la touche.

@export var couleur_index: int = 0


func _ready() -> void:
	$Sprite2D.modulate = GameState.couleur(couleur_index)


func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("lion"):
		return
	GameState.debloquer_couleur(couleur_index)
	queue_free()
