extends Area2D

@export var couleur_index: int = 1

var couleurs_arc_en_ciel: Array[Color] = [
	Color.RED, Color.ORANGE, Color.YELLOW, Color.GREEN,
	Color.CYAN, Color.BLUE, Color.VIOLET,
]


func _ready() -> void:
	$Sprite2D.modulate = couleurs_arc_en_ciel[couleur_index]


func _on_body_entered(body: Node2D) -> void:
	if not body.has_method("debloquer_couleur"):
		return
	body.debloquer_couleur(couleur_index)
	if body.has_method("lancer_pickup_suivant"):
		body.lancer_pickup_suivant(couleur_index)
	queue_free()
