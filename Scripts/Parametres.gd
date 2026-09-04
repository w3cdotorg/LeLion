extends Node
## Réglages persistants : volumes, plein écran, langue. Appliqués au démarrage et à chaque
## changement ; sauvegardés via Scores (ConfigFile dans user://, IndexedDB sur le Web).

signal volumes_changes()
signal langue_changee(langue: String)

const LANGUES := ["fr", "en"]
const SHADER_CRT := preload("res://Shaders/Crt.gdshader")

var musique := 0.7
var effets := 1.0
var plein_ecran := false
var langue := "en"
var crt := false
var couche_crt: CanvasLayer


func _ready() -> void:
	musique = clampf(float(Scores.preference("musique", musique)), 0.0, 1.0)
	effets = clampf(float(Scores.preference("effets", effets)), 0.0, 1.0)
	plein_ecran = bool(Scores.preference("plein_ecran", false))
	langue = str(Scores.preference("langue", _langue_systeme()))
	TranslationServer.set_locale(langue)
	crt = bool(Scores.preference("crt", false))
	_creer_couche_crt()
	# Sur le Web, le plein écran exige un geste de l'utilisateur : on ne l'applique qu'au clic.
	if plein_ecran and not OS.has_feature("web"):
		_appliquer_plein_ecran()


func _langue_systeme() -> String:
	return "fr" if OS.get_locale_language() == "fr" else "en"


func definir_musique(valeur: float) -> void:
	musique = clampf(valeur, 0.0, 1.0)
	Scores.definir_preference("musique", musique)
	volumes_changes.emit()


func definir_effets(valeur: float) -> void:
	effets = clampf(valeur, 0.0, 1.0)
	Scores.definir_preference("effets", effets)
	volumes_changes.emit()


func definir_plein_ecran(actif: bool) -> void:
	plein_ecran = actif
	Scores.definir_preference("plein_ecran", actif)
	_appliquer_plein_ecran()


func definir_langue(nouvelle: String) -> void:
	if not nouvelle in LANGUES:
		return
	langue = nouvelle
	Scores.definir_preference("langue", langue)
	TranslationServer.set_locale(langue)
	langue_changee.emit(langue)


## Le filtre CRT est un ColorRect plein écran au-dessus de tout, qui relit l'écran rendu.
func _creer_couche_crt() -> void:
	couche_crt = CanvasLayer.new()
	couche_crt.name = "FiltreCrt"
	couche_crt.layer = 100
	var rect := ColorRect.new()
	rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var materiau := ShaderMaterial.new()
	materiau.shader = SHADER_CRT
	rect.material = materiau
	couche_crt.add_child(rect)
	add_child(couche_crt)
	couche_crt.visible = crt


func definir_crt(actif: bool) -> void:
	crt = actif
	Scores.definir_preference("crt", actif)
	couche_crt.visible = actif


func _appliquer_plein_ecran() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if plein_ecran else DisplayServer.WINDOW_MODE_WINDOWED)


## dB à appliquer à un lecteur pour un volume linéaire 0..1 (silence total à 0).
static func en_db(volume: float) -> float:
	return linear_to_db(volume) if volume > 0.001 else -80.0
