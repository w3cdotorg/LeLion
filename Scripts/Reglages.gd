extends CanvasLayer
## Écran de réglages (overlay) : volumes, plein écran, langue. Se ferme avec Fermer ou Échap.

signal ferme()

const NOMS_LANGUES := {"fr": "Français", "en": "English"}

@onready var musique: HSlider = $Centre/Colonne/Grille/Musique
@onready var effets: HSlider = $Centre/Colonne/Grille/Effets
@onready var plein_ecran: Button = $Centre/Colonne/Grille/PleinEcran
@onready var langues: HBoxContainer = $Centre/Colonne/Grille/Langues
@onready var bouton_fermer: Button = $Centre/Colonne/Fermer

var boutons_langue: Dictionary = {}


func _ready() -> void:
	musique.set_value_no_signal(Parametres.musique)
	effets.set_value_no_signal(Parametres.effets)
	plein_ecran.set_pressed_no_signal(Parametres.plein_ecran)
	plein_ecran.text = "ON" if Parametres.plein_ecran else "OFF"
	for code in Parametres.LANGUES:
		var bouton := Button.new()
		bouton.toggle_mode = true
		bouton.text = NOMS_LANGUES[code]
		bouton.custom_minimum_size = Vector2(160, 44)
		bouton.add_theme_font_size_override("font_size", 26)
		bouton.pressed.connect(_choisir_langue.bind(code))
		langues.add_child(bouton)
		boutons_langue[code] = bouton
	_rafraichir_langues()
	musique.grab_focus()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") or event.is_action_pressed("ui_cancel"):
		fermer()
		get_viewport().set_input_as_handled()


func _on_musique_value_changed(valeur: float) -> void:
	Parametres.definir_musique(valeur)


func _on_effets_value_changed(valeur: float) -> void:
	Parametres.definir_effets(valeur)
	Audio.jouer("pickup")


func _on_plein_ecran_toggled(actif: bool) -> void:
	plein_ecran.text = "ON" if actif else "OFF"
	Parametres.definir_plein_ecran(actif)


func _choisir_langue(code: String) -> void:
	Parametres.definir_langue(code)
	_rafraichir_langues()


func _rafraichir_langues() -> void:
	for code in boutons_langue:
		boutons_langue[code].set_pressed_no_signal(code == Parametres.langue)


func fermer() -> void:
	ferme.emit()
	queue_free()
