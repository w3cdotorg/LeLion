extends Node
## Réglages persistants : volumes, plein écran, langue. Appliqués au démarrage et à chaque
## changement ; sauvegardés via Scores (ConfigFile dans user://, IndexedDB sur le Web).

signal volumes_changes()
signal langue_changee(langue: String)

const LANGUES := ["fr", "en"]

var musique := 0.7
var effets := 1.0
var plein_ecran := false
var langue := "en"


func _ready() -> void:
	musique = clampf(float(Scores.preference("musique", musique)), 0.0, 1.0)
	effets = clampf(float(Scores.preference("effets", effets)), 0.0, 1.0)
	plein_ecran = bool(Scores.preference("plein_ecran", false))
	langue = str(Scores.preference("langue", _langue_systeme()))
	TranslationServer.set_locale(langue)
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


func _appliquer_plein_ecran() -> void:
	DisplayServer.window_set_mode(
		DisplayServer.WINDOW_MODE_FULLSCREEN if plein_ecran else DisplayServer.WINDOW_MODE_WINDOWED)


## dB à appliquer à un lecteur pour un volume linéaire 0..1 (silence total à 0).
static func en_db(volume: float) -> float:
	return linear_to_db(volume) if volume > 0.001 else -80.0
