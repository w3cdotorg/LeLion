extends CanvasLayer
## Overlay de fin de partie (victoire ou défaite) : record, niveau suivant, rejouer, menu.

const COULEUR_VICTOIRE := Color(1.0, 0.85, 0.2)
const COULEUR_DEFAITE := Color(1.0, 0.35, 0.35)
const SCENE_TITRE := "res://Scenes/Titre.tscn"

@onready var titre: Label = $Centre/Colonne/Titre
@onready var sous_titre: Label = $Centre/Colonne/SousTitre
@onready var bouton_suivant: Button = $Centre/Colonne/Boutons/Suivant
@onready var bouton_rejouer: Button = $Centre/Colonne/Boutons/Rejouer


func afficher(victoire: bool, progression: float, temps: float) -> void:
	titre.text = "VICTOIRE !" if victoire else "GAME OVER"
	titre.add_theme_color_override("font_color", COULEUR_VICTOIRE if victoire else COULEUR_DEFAITE)
	var pourcent := int(round(progression * 100))
	if victoire:
		var rang: int = Scores.enregistrer(GameState.cle_score(), temps)
		sous_titre.text = "Ville peinte à %d %% en %s" % [pourcent, GameState.formater_temps(temps)]
		if rang == 0:
			sous_titre.text += "   ·   Nouveau record !"
	else:
		sous_titre.text = "Ville peinte à %d %%" % pourcent

	bouton_suivant.visible = victoire and GameState.niveau_suivant_existe()
	(bouton_suivant if bouton_suivant.visible else bouton_rejouer).grab_focus()


func _on_suivant_pressed() -> void:
	GameState.passer_au_niveau_suivant()
	_relancer()


func _on_rejouer_pressed() -> void:
	_relancer()


func _on_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file(SCENE_TITRE)


func _relancer() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
