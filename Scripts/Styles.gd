class_name Styles
## Styles partagés des menus.

const JAUNE := Color(1.0, 0.85, 0.2)


## Bouton à bascule : bordure jaune quand il est sélectionné.
static func appliquer_selection(bouton: Button) -> void:
	var enfonce := StyleBoxFlat.new()
	enfonce.bg_color = Color(0.32, 0.2, 0.28, 1.0)
	enfonce.border_color = JAUNE
	enfonce.set_border_width_all(4)
	enfonce.set_corner_radius_all(6)
	enfonce.set_content_margin_all(8)
	bouton.add_theme_stylebox_override("pressed", enfonce)
	bouton.add_theme_stylebox_override("hover_pressed", enfonce)
