extends SceneTree
## Test de fumée headless : godot --headless --script tests/smoke_test.gd
## Charge Main, débloque une couleur, fait vomir le lion sur la ville, vérifie la
## peinture, puis fait apparaître un ennemi sur le lion et vérifie la défaite.

var _echecs := 0
var GS: Node


func _init() -> void:
	call_deferred("_run")


func _check(cond: bool, msg: String) -> void:
	if cond:
		print("  ✅ ", msg)
	else:
		_echecs += 1
		printerr("  ❌ ", msg)


func _frames(n: int) -> void:
	for i in range(n):
		await physics_frame


func _run() -> void:
	print("== smoke test LeLion ==")
	GS = root.get_node("GameState")
	var scores: Node = root.get_node("Scores")
	scores.chemin = "user://scores_test.cfg"
	scores.effacer()

	# Écran titre : un bouton par niveau, lancer un niveau le sélectionne
	var titre: Control = load("res://Scenes/Titre.tscn").instantiate()
	root.add_child(titre)
	await _frames(1)
	_check(titre.boutons.size() == GS.NIVEAUX.size(), "l'écran titre a un bouton par niveau (%d)" % titre.boutons.size())
	_check(titre.boutons_difficulte.size() == GS.DIFFICULTES.size(), "l'écran titre a un bouton par difficulté (%d)" % titre.boutons_difficulte.size())
	titre.choisir_difficulte(2)
	_check(GS.difficulte_courante == 2 and titre.boutons_difficulte[2].button_pressed, "choisir une difficulté la sélectionne")
	titre.choisir_difficulte(0)
	_check("pas encore peint" in titre.boutons[1].text, "un niveau jamais gagné affiche « pas encore peint »")
	GS.niveau_courant = 1
	titre.free()

	# Scores
	_check(scores.enregistrer("test", 90.0) == 0, "premier temps enregistré = record")
	_check(scores.enregistrer("test", 120.0) == 1, "temps plus lent = rang 1")
	_check(scores.enregistrer("test", 60.0) == 0, "temps plus rapide = nouveau record")
	scores.charger()
	_check(scores.meilleur_temps("test") == 60.0, "les scores sont relus depuis le disque")
	GS.niveau_courant = 0
	var main: Node = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(3)

	var ville: Node = main.get_node("Ville")
	var lion: CharacterBody2D = main.get_node("Lion")
	var spawner: Node = main.get_node("Spawner")
	_check(GS.partie_en_cours, "partie en cours après Main._ready")
	_check(root.get_node_or_null("Audio") != null, "autoload Audio présent")
	_check(root.get_node("Audio")._musique.playing, "la musique tourne en boucle")

	# Pause via l'action "pause"
	var ev := InputEventAction.new()
	ev.action = "pause"
	ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await _frames(2)
	var menu_pause: CanvasLayer = main.get_node("PauseMenu")
	_check(paused and menu_pause.visible, "Échap met en pause et ouvre le menu de pause")
	_check(menu_pause.bouton_continuer.has_focus(), "le bouton Continuer a le focus")
	Input.parse_input_event(ev.duplicate())
	Input.flush_buffered_events()
	await _frames(2)
	_check(not paused and not menu_pause.visible, "Échap relance la partie")
	menu_pause.ouvrir()
	_check(paused, "ouvrir() met en pause")
	menu_pause.reprendre()
	_check(not paused and not menu_pause.visible, "Continuer reprend la partie")
	var nb_cellules: int = ville.grille_taille.x * ville.grille_taille.y
	_check(ville.cellules_peignables > 0 and ville.cellules_peignables < nb_cellules,
		"cellules peignables = zones opaques de la skyline (%d / %d)" % [ville.cellules_peignables, nb_cellules])

	# Pickup : le lion marche dessus
	var pickup: Node = spawner.spawn_pickup(0, lion.global_position + Vector2(68, 66))
	await _frames(3)
	_check(not is_instance_valid(pickup), "le pickup disparaît au contact")
	_check(GS.couleurs_debloquees.size() == 1, "une couleur débloquée via pickup")
	_check(lion.vomi_container.get_child_count() == 1, "un émetteur de particules par couleur")
	var hud: Node = main.get_node("HUD")
	_check(hud.indice.visible == false, "le HUD cache l'indice après la première couleur")
	_check(hud._pastilles[0].color == GS.couleur(0) and hud._pastilles[1].color != GS.couleur(1),
		"le HUD affiche la première pastille débloquée et la deuxième verrouillée")

	# Vomir sur la ville : on place le lion au-dessus de la skyline
	lion.global_position = Vector2(600, ville.position.y - 300)
	Input.action_press("vomir")
	await _frames(30)
	_check(lion.est_en_train_de_vomir, "le lion vomit tant que l'action est maintenue")
	var rayon_normal: float = lion.traceuse_shape.shape.radius
	var bonus: Node = spawner.spawn_bonus(lion.global_position + Vector2(68, 66))
	await _frames(3)
	_check(not is_instance_valid(bonus) and GS.bonus_actif(), "l'étoile ramassée active la gerbe XXL")
	_check(lion.traceuse_shape.shape.radius == rayon_normal * 2.0, "le rayon de peinture est doublé pendant le bonus")
	_check(hud.etiquette_bonus.visible, "le HUD affiche le bonus")
	GS.bonus_restant = 0.01
	await _frames(3)
	_check(not GS.bonus_actif() and lion.traceuse_shape.shape.radius == rayon_normal, "le bonus expire et le rayon revient à la normale")
	_check(root.get_node("Audio")._vomi.playing, "la boucle sonore de vomi tourne")
	_check(ville.cellules_peintes > 0, "la ville a été peinte (%d cellules)" % ville.cellules_peintes)
	_check(GS.progression > 0.0, "la progression est remontée dans GameState (%.4f)" % GS.progression)
	_check(hud.progression.value > 0.0, "la barre de progression du HUD bouge")
	_check(spawner.difficulte() >= 0.0 and spawner.difficulte() <= 1.0, "difficulté bornée (%.3f)" % spawner.difficulte())
	var soucoupe: Node = spawner.spawn_soucoupe(20)
	_check(soucoupe.speed >= spawner.vitesse_soucoupe.x, "la soucoupe reçoit sa vitesse du spawner (%.0f)" % soucoupe.speed)
	soucoupe.queue_free()
	Input.action_release("vomir")
	await _frames(3)
	_check(not lion.est_en_train_de_vomir, "le lion arrête de vomir quand l'action est relâchée")

	# Mode Facile : un coup enlève une vie et rend invulnérable un moment
	_check(GS.vies == 3 and hud._coeurs[2].visible, "mode Facile : 3 vies affichées")
	var coccinelle: Node = spawner.spawn_coccinelle(lion.global_position.y + 66)
	coccinelle.position.x = lion.global_position.x + 68
	await _frames(3)
	_check(GS.partie_en_cours and GS.vies == 2, "un coup coûte une vie, la partie continue (%d vies)" % GS.vies)
	_check(GS.est_invulnerable(), "le lion est invulnérable après un coup")
	_check(lion._recul.length() > 0.0, "le lion est repoussé par le coup (%.0f px/s)" % lion._recul.length())
	_check(hud.flash.color.a > 0.0, "l'écran flashe en rouge")
	_check(main._tremblement_restant > 0.0, "la caméra tremble")
	_check(hud._coeurs[2].modulate == hud.COULEUR_COEUR_PERDU, "le HUD grise le cœur perdu")
	coccinelle.queue_free()
	var soucoupe2: Node = spawner.spawn_soucoupe(lion.global_position.y + 66)
	soucoupe2.position.x = lion.global_position.x + 68
	await _frames(3)
	_check(GS.vies == 2, "un coup pendant l'invulnérabilité ne compte pas")
	soucoupe2.queue_free()
	GS.invulnerable_restant = 0.0

	# Cœur : rend une vie, jamais au-delà du maximum
	var coeur: Node = spawner.spawn_coeur(lion.global_position + Vector2(68, 66))
	await _frames(3)
	_check(not is_instance_valid(coeur) and GS.vies == 3, "un cœur ramassé rend une vie (%d)" % GS.vies)
	_check(not GS.gagner_vie(), "impossible de dépasser le maximum de vies")

	# Défaite : trois coups
	GS.vies = 1
	coccinelle = spawner.spawn_coccinelle(lion.global_position.y + 66)
	coccinelle.position.x = lion.global_position.x + 68
	await _frames(3)
	_check(not GS.partie_en_cours, "la partie se termine quand la dernière vie est perdue")
	_check(paused, "l'arbre est en pause après la défaite")
	var overlay: Node = main.get_node_or_null("GameOver")
	_check(overlay != null, "l'overlay GameOver est affiché")
	_check(overlay != null and overlay.titre.text == "GAME OVER", "l'overlay affiche GAME OVER")
	_check(overlay != null and not overlay.bouton_suivant.visible, "pas de bouton Niveau suivant après une défaite")

	# Victoire sur le niveau Métropole : nouvelle partie, on peint toute la skyline
	paused = false
	main.queue_free()
	await _frames(2)
	GS.niveau_courant = 1
	main = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(2)
	ville = main.get_node("Ville")
	_check(ville.tex_size == Vector2i(2000, 320), "la ville a chargé la skyline du niveau Métropole (%s)" % ville.tex_size)
	GS.debloquer_couleur(0)
	var haut: float = ville.position.y - ville.tex_size.y / 2.0
	for x in range(0, ville.tex_size.x, 40):
		for y in range(0, ville.tex_size.y, 40):
			ville.peindre(Vector2(x, haut + y), 45, GS.couleurs_debloquees)
	await _frames(3)
	_check(GS.progression >= GS.SEUIL_VICTOIRE, "progression >= seuil après avoir tout peint (%.2f)" % GS.progression)
	_check(ville.coulures.size() > 0 or ville.CHANCE_COULURE == 0.0, "des coulures de peinture sont en cours (%d)" % ville.coulures.size())
	_check(not GS.partie_en_cours and paused, "la partie se termine en victoire")
	overlay = main.get_node_or_null("GameOver")
	_check(overlay != null and overlay.titre.text == "VICTOIRE !", "l'overlay affiche VICTOIRE")
	var nb_confettis := 0
	for enfant in overlay.get_children():
		if enfant is GPUParticles2D:
			nb_confettis += 1
	_check(nb_confettis == 3, "la victoire lance des confettis (%d émetteurs)" % nb_confettis)
	_check(overlay != null and "Nouveau record" in overlay.sous_titre.text, "la victoire enregistre un record")
	_check(overlay != null and overlay.bouton_suivant.visible, "le bouton Niveau suivant est proposé")
	_check(scores.meilleur_temps("metropole/facile") >= 0.0, "le record est persisté par niveau et difficulté")
	scores.effacer()

	# Boss sur le niveau Village : cycle d'états accéléré et contact
	paused = false
	main.queue_free()
	await _frames(2)
	GS.niveau_courant = 2
	GS.difficulte_courante = 0
	main = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(2)
	lion = main.get_node("Lion")
	var boss: Node = get_first_node_in_group("boss")
	_check(boss != null, "le niveau Village fait apparaître le boss")
	_check(main.get_node("Spawner")._facteur_ennemis == 2.0, "les autres ennemis sont deux fois moins fréquents avec un boss")
	var nb_polygones := 0
	for enfant in boss.get_children():
		if enfant is CollisionPolygon2D:
			nb_polygones += 1
	_check(nb_polygones > 0, "la collision du boss est générée depuis la silhouette (%d polygones)" % nb_polygones)
	_check(abs(boss.sprite.scale.y * boss.sprite.texture.get_height() - 648 * 0.65) < 1.0, "le boss fait 65 % de la hauteur de l'écran")
	_check(abs(boss.position.y + boss._demi_hauteur - boss.y_sol) < 0.5 and abs(boss.y_sol - (648 - 180)) < 0.5,
		"le boss est posé sur le haut de la skyline (bas=%.1f, sol=%.1f)" % [boss.position.y + boss._demi_hauteur, boss.y_sol])
	_check(boss.etat == boss.Etat.REPOS, "le boss commence hors écran, au repos")
	# on accélère le cycle
	var cote_initial: int = boss.cote
	boss.duree_repos = 0.05
	boss.duree_annonce = 0.05
	boss.duree_entree = 0.2
	boss.duree_pause = 0.05
	boss.duree_sortie = 0.2
	boss._changer_etat(boss.Etat.ANNONCE)
	var etats_vus: Array = []
	boss.etat_change.connect(func(e: int) -> void: etats_vus.append(e))
	lion.global_position = Vector2(1000 - 68, boss.position.y - 66)  # au centre, sur le passage
	var vies_avant: int = GS.vies
	await create_timer(0.9).timeout
	_check(etats_vus.has(boss.Etat.PAUSE) and etats_vus.has(boss.Etat.SORTIE) and etats_vus.has(boss.Etat.REPOS),
		"le boss enchaîne entrée, pause au centre, sortie, repos")
	_check(boss.cote == -cote_initial, "le boss change de côté après un cycle")
	_check(GS.vies < vies_avant, "le boss blesse le lion au passage (%d → %d)" % [vies_avant, GS.vies])
	GS.niveau_courant = 0

	# Hardcore : un seul coup
	paused = false
	main.queue_free()
	await _frames(2)
	GS.niveau_courant = 0
	GS.difficulte_courante = 2
	main = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(2)
	lion = main.get_node("Lion")
	spawner = main.get_node("Spawner")
	hud = main.get_node("HUD")
	_check(GS.vies == 1 and not hud._coeurs[1].visible, "mode Hardcore : un seul cœur affiché")
	_check(spawner._timer_coeur == null, "mode Hardcore : pas de cœurs à ramasser")
	coccinelle = spawner.spawn_coccinelle(lion.global_position.y + 66)
	coccinelle.position.x = lion.global_position.x + 68
	await _frames(3)
	_check(not GS.partie_en_cours, "mode Hardcore : un coup et c'est fini")
	GS.difficulte_courante = 0

	print("== %d échec(s) ==" % _echecs)
	paused = false
	main.free()
	quit(1 if _echecs > 0 else 0)
