extends SceneTree
## Capture d'écran pilotée : godot --script tests/screenshots.gd (rendu réel requis, pas headless)
## Écrit dans le dossier passé par --dossier=<chemin> (défaut : user://).

var dossier := "user://"
var GS: Node


func _init() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--dossier="):
			dossier = arg.trim_prefix("--dossier=")
	call_deferred("_run")


func _attendre(secondes: float) -> void:
	await create_timer(secondes).timeout


func _shot(nom: String) -> void:
	await RenderingServer.frame_post_draw
	var img := root.get_viewport().get_texture().get_image()
	img.save_png(dossier.path_join(nom + ".png"))
	print("📸 ", nom)


func _run() -> void:
	GS = root.get_node("GameState")
	var titre: Control = load("res://Scenes/Titre.tscn").instantiate()
	root.add_child(titre)
	await _attendre(0.2)
	await _shot("00_titre")
	titre.free()
	var main: Node = load("res://Scenes/Main.tscn").instantiate()
	root.add_child(main)
	current_scene = main
	await _attendre(0.15)
	main.get_node("Spawner").spawn_pickup(0, Vector2(900, 250))
	await _attendre(0.1)
	await _shot("01_depart")

	var lion: CharacterBody2D = main.get_node("Lion")
	var spawner: Node = main.get_node("Spawner")
	var ville: Node2D = main.get_node("Ville")
	for i in range(3):
		GS.debloquer_couleur(i)
	await _attendre(0.1)
	lion.global_position = Vector2(500, ville.position.y - 330)
	Input.action_press("vomir")
	await _attendre(1.00)
	await _shot("02_vomi_droite_3_couleurs")
	Input.action_press("deplacer_droite")
	await _attendre(1.50)
	Input.action_release("deplacer_droite")
	Input.action_release("vomir")
	await _attendre(0.1)
	for i in range(3, 7):
		GS.debloquer_couleur(i)
	Input.action_press("deplacer_gauche")
	await _attendre(0.1)
	Input.action_press("vomir")
	await _attendre(0.83)
	Input.action_release("deplacer_gauche")
	spawner.spawn_soucoupe(300)
	spawner.spawn_coccinelle(250)
	spawner.spawn_bonus(Vector2(1300, 220))
	GS.activer_bonus(8.0)
	await _attendre(0.75)
	await _shot("03_vomi_gauche_7_couleurs_ennemis")
	Input.action_release("vomir")
	GS.terminer_partie(false)
	await _attendre(0.1)
	await _shot("04_game_over")
	paused = false
	main.free()
	quit(0)
