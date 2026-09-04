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
	GS = root.get_node_or_null("GameState")
	if GS == null:
		GS = load("res://Scripts/GameState.gd").new()
		GS.name = "GameState"
		root.add_child(GS)
		print("  (autoload GameState ajouté manuellement)")
	var main: Node = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(3)

	var ville: Node = main.get_node("Ville")
	var lion: CharacterBody2D = main.get_node("Lion")
	var spawner: Node = main.get_node("Spawner")
	_check(GS.partie_en_cours, "partie en cours après Main._ready")
	var nb_cellules: int = ville.grille_taille.x * ville.grille_taille.y
	_check(ville.cellules_peignables > 0 and ville.cellules_peignables < nb_cellules,
		"cellules peignables = zones opaques de la skyline (%d / %d)" % [ville.cellules_peignables, nb_cellules])

	# Pickup : le lion marche dessus
	var pickup: Node = spawner.spawn_pickup(0, lion.global_position + Vector2(68, 66))
	await _frames(3)
	_check(not is_instance_valid(pickup), "le pickup disparaît au contact")
	_check(GS.couleurs_debloquees.size() == 1, "une couleur débloquée via pickup")
	_check(lion.vomi_container.get_child_count() == 1, "un émetteur de particules par couleur")

	# Vomir sur la ville : on place le lion au-dessus de la skyline
	lion.global_position = Vector2(600, ville.position.y - 300)
	Input.action_press("vomir")
	await _frames(30)
	_check(lion.est_en_train_de_vomir, "le lion vomit tant que l'action est maintenue")
	_check(ville.cellules_peintes > 0, "la ville a été peinte (%d cellules)" % ville.cellules_peintes)
	_check(GS.progression > 0.0, "la progression est remontée dans GameState (%.4f)" % GS.progression)
	Input.action_release("vomir")
	await _frames(3)
	_check(not lion.est_en_train_de_vomir, "le lion arrête de vomir quand l'action est relâchée")

	# Défaite : coccinelle sur le lion
	var coccinelle: Node = spawner.spawn_coccinelle(lion.global_position.y + 66)
	coccinelle.position.x = lion.global_position.x + 68
	await _frames(3)
	_check(not GS.partie_en_cours, "la partie se termine au contact d'un ennemi")
	_check(paused, "l'arbre est en pause après la défaite")
	var overlay: Node = main.get_node_or_null("GameOver")
	_check(overlay != null, "l'overlay GameOver est affiché")
	_check(overlay != null and overlay.titre.text == "GAME OVER", "l'overlay affiche GAME OVER")

	# Victoire : nouvelle partie, on peint toute la skyline
	paused = false
	main.queue_free()
	await _frames(2)
	main = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _frames(2)
	ville = main.get_node("Ville")
	GS.debloquer_couleur(0)
	var haut: float = ville.position.y - ville.tex_size.y / 2.0
	for x in range(0, ville.tex_size.x, 40):
		for y in range(0, ville.tex_size.y, 40):
			ville.peindre(Vector2(x, haut + y), 45, GS.couleurs_debloquees)
	await _frames(3)
	_check(GS.progression >= GS.SEUIL_VICTOIRE, "progression >= seuil après avoir tout peint (%.2f)" % GS.progression)
	_check(not GS.partie_en_cours and paused, "la partie se termine en victoire")
	overlay = main.get_node_or_null("GameOver")
	_check(overlay != null and overlay.titre.text == "VICTOIRE !", "l'overlay affiche VICTOIRE")

	print("== %d échec(s) ==" % _echecs)
	quit(1 if _echecs > 0 else 0)
