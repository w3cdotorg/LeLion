extends Area2D

func _ready():
	add_to_group("gerbe_traceuse")
	monitoring = true
	set_process(true)

#func _process(_delta):
	#for area in get_overlapping_areas():
		#if area.name == "PeintureZone":
			#var ville = area.get_parent()
			#if not ville or not ville.has_method("peindre"):
				#continue
#
			#var lion = get_tree().get_nodes_in_group("lion")[0]
			#if lion and lion.couleurs_debloquees.size() > 0:
				#var couleur = lion.couleurs_debloquees[randi() % lion.couleurs_debloquees.size()]
				#var local_pos = ville.get_node("Sprite2D").to_local(global_position)
				#print("🖌️ [GerbeTraceuse] Peinture demandée à :", local_pos, "avec couleur :", couleur)
				#ville.peindre(local_pos, couleur, 5)  # 5 = rayon
func _process(_delta):
	for area in get_overlapping_areas():
		print("🎯 Zone touchée :", area.name)

		# Recherche de la Ville (en remontant les parents)
		var ville = area
		while ville and not ville.has_method("peindre"):
			ville = ville.get_parent()

		if ville and ville.has_method("peindre"):
			var lion = get_tree().get_nodes_in_group("lion")[0]
			if lion and lion.couleurs_debloquees.size() > 0:
				var couleur = lion.couleurs_debloquees[randi() % lion.couleurs_debloquees.size()]
				var local_pos = ville.get_node("Sprite2D").to_local(global_position)

				var nb_couleurs = lion.couleurs_debloquees.size()
				var radius = clamp(2 + nb_couleurs, 2, 6)

				print("🖌️ [GerbeTraceuse] Peinture à :", local_pos, "rayon :", radius)
#				ville.peindre(local_pos, couleur, radius)
				ville.peindre(local_pos, couleur, radius, lion.couleurs_debloquees)
