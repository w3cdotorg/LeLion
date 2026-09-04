extends CanvasLayer
## Overlay de fin de partie (victoire ou défaite) : record, niveau suivant, rejouer, menu.

const COULEUR_VICTOIRE := Color(1.0, 0.85, 0.2)
const COULEUR_DEFAITE := Color(1.0, 0.35, 0.35)
const SCENE_TITRE := "res://Scenes/Titre.tscn"
const TEXTURE_CONFETTI := preload("res://Assets/Sprites/circle_white.png")

@onready var titre: Label = $Centre/Colonne/Titre
@onready var sous_titre: Label = $Centre/Colonne/SousTitre
@onready var bouton_suivant: Button = $Centre/Colonne/Boutons/Suivant
@onready var bouton_rejouer: Button = $Centre/Colonne/Boutons/Rejouer


func afficher(victoire: bool, progression: float, temps: float) -> void:
	titre.text = tr("VICTOIRE") if victoire else tr("GAME_OVER")
	titre.add_theme_color_override("font_color", COULEUR_VICTOIRE if victoire else COULEUR_DEFAITE)
	var pourcent := int(round(progression * 100))
	if victoire:
		var rang: int = Scores.enregistrer(GameState.cle_score(), temps)
		sous_titre.text = tr("VILLE_PEINTE_TEMPS") % [pourcent, GameState.formater_temps(temps)]
		if rang == 0:
			sous_titre.text += "   ·   " + tr("NOUVEAU_RECORD")
	else:
		sous_titre.text = tr("VILLE_PEINTE") % pourcent

	if victoire:
		_lancer_confettis()
	bouton_suivant.visible = victoire and GameState.niveau_suivant_existe()
	(bouton_suivant if bouton_suivant.visible else bouton_rejouer).grab_focus()


func _on_suivant_pressed() -> void:
	GameState.passer_au_niveau_suivant()
	Scores.definir_preference("niveau", GameState.niveau_courant)
	_relancer()


func _on_rejouer_pressed() -> void:
	_relancer()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_TITRE)


func _relancer() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()


## Explosion de confettis arc-en-ciel depuis le bas de l'écran.
func _lancer_confettis() -> void:
	var gradient := Gradient.new()
	var couleurs := GameState.COULEURS_ARC_EN_CIEL
	for i in range(couleurs.size()):
		if i < 2:
			gradient.set_color(i, couleurs[i])
		else:
			gradient.add_point(float(i) / (couleurs.size() - 1), couleurs[i])
	gradient.set_offset(1, 1.0 / (couleurs.size() - 1))
	var rampe := GradientTexture1D.new()
	rampe.gradient = gradient

	var materiau := ParticleProcessMaterial.new()
	materiau.color_initial_ramp = rampe
	materiau.direction = Vector3(0, -1, 0)
	materiau.spread = 55.0
	materiau.initial_velocity_min = 700.0
	materiau.initial_velocity_max = 1100.0
	materiau.gravity = Vector3(0, 900, 0)
	materiau.scale_min = 1.5
	materiau.scale_max = 3.0
	materiau.angular_velocity_min = -360.0
	materiau.angular_velocity_max = 360.0

	var taille := get_viewport().get_visible_rect().size
	for x in [taille.x * 0.25, taille.x * 0.5, taille.x * 0.75]:
		var confettis := GPUParticles2D.new()
		confettis.texture = TEXTURE_CONFETTI
		confettis.process_material = materiau
		confettis.amount = 160
		confettis.lifetime = 2.5
		confettis.one_shot = true
		confettis.explosiveness = 0.9
		confettis.position = Vector2(x, taille.y + 10)
		confettis.z_index = -1
		add_child(confettis)
		confettis.emitting = true
