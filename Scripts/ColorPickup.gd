extends Area2D

@export var couleur_index: int = 1  # orange
var couleurs_arc_en_ciel := [
	Color.RED,
	Color.ORANGE,
	Color.YELLOW,
	Color.GREEN,
	Color.CYAN,
	Color.BLUE,
	Color.VIOLET
]

func _ready():
	if $Sprite2D:
		$Sprite2D.modulate = couleurs_arc_en_ciel[couleur_index]

#func _on_ColorPickup_body_entered(body):
	#print("👋 Body touché :", body)
	#if body.has_method("debloquer_couleur"):
		#body.debloquer_couleur(couleur_index)
		#queue_free()
	#else:
		#print("❌ Le body n'a pas de méthode debloquer_couleur :", body)


#func _on_body_entered(body: Node2D) -> void:
	#print("👋 Body touché :", body)
	#if body.has_method("debloquer_couleur"):
		#body.debloquer_couleur(couleur_index)
		#queue_free()
	#else:
		#print("❌ Le body n'a pas de méthode debloquer_couleur :", body)

func _on_body_entered(body: Node2D) -> void:
	if body.has_method("debloquer_couleur"):
		body.debloquer_couleur(couleur_index)

		# ⚠️ Nouveau : démarrer le timer du pickup suivant
		#if couleur_index == 1:  # orange
			#var scene = get_tree().current_scene
			#if scene.has_node("SecondPickupTimer"):
				#scene.get_node("SecondPickupTimer").start()
				
		var scene = get_tree().current_scene
		if body.has_method("lancer_pickup_suivant"):
			body.lancer_pickup_suivant(couleur_index)

		queue_free()
