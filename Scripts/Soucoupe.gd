extends Area2D

@export var speed: float = 150.0  # Vitesse de la soucoupe
@export var game_over_scene: PackedScene  # assigné dans l’inspecteur

func _physics_process(delta):
	position.y = 324
	position.x += speed * delta
	if position.x > 2000:  # Supprimer quand elle quitte l'écran
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	print("💥 Le lion a été désintégré !")
	body.queue_free()

	# Afficher l'écran de Game Over par-dessus
	var overlay = game_over_scene.instantiate()
	get_tree().current_scene.add_child(overlay)

	# Option : arrêter tout mouvement
	get_tree().paused = true
