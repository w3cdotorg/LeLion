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
	_check(ville.pixels_peignables > 0 and ville.pixels_peignables < ville.tex_size.x * ville.tex_size.y,
		"pixels peignables = pixels opaques de la skyline (%d / %d)" % [ville.pixels_peignables, ville.tex_size.x * ville.tex_size.y])

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
	_check(ville.pixels_peints > 0, "la ville a été peinte (%d px)" % ville.pixels_peints)
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
	_check(main.get_node_or_null("GameOver") != null, "l'overlay GameOver est affiché")

	print("== %d échec(s) ==" % _echecs)
	quit(1 if _echecs > 0 else 0)
