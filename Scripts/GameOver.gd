extends CanvasLayer
## Overlay de fin de partie (victoire ou défaite) avec bouton Rejouer.

const COULEUR_VICTOIRE := Color(1.0, 0.85, 0.2)
const COULEUR_DEFAITE := Color(1.0, 0.35, 0.35)

@onready var titre: Label = $Centre/Colonne/Titre
@onready var sous_titre: Label = $Centre/Colonne/SousTitre
@onready var bouton_rejouer: Button = $Centre/Colonne/Rejouer


func _ready() -> void:
	bouton_rejouer.grab_focus()


func afficher(victoire: bool, progression: float, temps: float) -> void:
	titre.text = "VICTOIRE !" if victoire else "GAME OVER"
	titre.add_theme_color_override("font_color", COULEUR_VICTOIRE if victoire else COULEUR_DEFAITE)
	var pourcent := int(round(progression * 100))
	if victoire:
		sous_titre.text = "Ville peinte à %d %% en %s" % [pourcent, GameState.formater_temps(temps)]
	else:
		sous_titre.text = "Ville peinte à %d %%" % pourcent


func _on_rejouer_pressed() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
