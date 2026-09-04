extends Node
## Meilleurs temps par niveau et préférences (difficulté, dernier niveau), dans un ConfigFile.

const NB_MAX := 5

var chemin := "user://scores.cfg"
var _cfg := ConfigFile.new()


func _ready() -> void:
	charger()


func charger() -> void:
	_cfg = ConfigFile.new()
	_cfg.load(chemin)  # absent au premier lancement : on garde un fichier vide


func meilleurs_temps(niveau_id: String) -> Array:
	var temps: Array = _cfg.get_value("temps", niveau_id, [])
	return temps.duplicate()


func meilleur_temps(niveau_id: String) -> float:
	var temps := meilleurs_temps(niveau_id)
	return temps[0] if not temps.is_empty() else -1.0


## Enregistre un temps et renvoie son rang (0 = record), ou -1 s'il n'entre pas dans le top.
func enregistrer(niveau_id: String, temps: float) -> int:
	var liste := meilleurs_temps(niveau_id)
	liste.append(temps)
	liste.sort()
	var rang := liste.find(temps)
	if rang >= NB_MAX:
		return -1
	_cfg.set_value("temps", niveau_id, liste.slice(0, NB_MAX))
	_cfg.save(chemin)
	return rang


func preference(cle: String, defaut: Variant) -> Variant:
	return _cfg.get_value("preferences", cle, defaut)


func definir_preference(cle: String, valeur: Variant) -> void:
	_cfg.set_value("preferences", cle, valeur)
	_cfg.save(chemin)


func effacer() -> void:
	_cfg = ConfigFile.new()
	_cfg.save(chemin)
