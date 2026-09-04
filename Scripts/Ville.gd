extends Node2D
## La ville : masque de peinture RGBA appliqué par shader sur la skyline.
## La peinture se fait par tampons multicolores (blit natif). La progression est
## comptée sur une grille de cellules ne couvrant que les zones opaques de la skyline.

const TAILLE_CELLULE := 8
const NB_TAMPONS := 4
const DENSITE_TAMPON := 0.5
const CHANCE_COULURE := 0.3
const COULURES_MAX := 40
const VITESSE_COULURE := 70.0  # px/s

@onready var sprite: Sprite2D = $Sprite2D
@onready var zone_shape: CollisionShape2D = $PeintureZone/CollisionShape2D

var tex_size: Vector2i
var image: Image
var texture: ImageTexture

var grille_taille: Vector2i
var cellules_peignables := 0
var cellules_peintes := 0
var _cellules_peignables: PackedByteArray
var _cellules_peintes: PackedByteArray

var _dirty := false
var coulures: Array[Dictionary] = []
var _tampons: Array[Image] = []
var _tampons_rayon := -1
var _tampons_nb_couleurs := -1


func _ready() -> void:
	charger_skyline(sprite.texture)


## Remplace la skyline : recalcule la grille, le masque de peinture et la zone de collision.
func charger_skyline(nouvelle: Texture2D) -> void:
	sprite.texture = nouvelle
	tex_size = Vector2i(nouvelle.get_width(), nouvelle.get_height())
	cellules_peignables = 0
	cellules_peintes = 0
	coulures.clear()
	_tampons_rayon = -1
	_calculer_cellules_peignables()

	image = Image.create(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	texture = ImageTexture.create_from_image(image)
	(sprite.material as ShaderMaterial).set_shader_parameter("paint_mask", texture)

	var forme := RectangleShape2D.new()
	forme.size = Vector2(tex_size)
	zone_shape.shape = forme
	zone_shape.position = Vector2.ZERO


func _process(delta: float) -> void:
	_avancer_coulures(delta)
	if _dirty:
		_dirty = false
		texture.update(image)
		GameState.signaler_progression(progression())


func progression() -> float:
	return float(cellules_peintes) / max(cellules_peignables, 1)


## Une cellule est peignable si la skyline y est opaque à plus de 15 % (moyenne).
func _calculer_cellules_peignables() -> void:
	grille_taille = Vector2i(ceili(tex_size.x / float(TAILLE_CELLULE)), ceili(tex_size.y / float(TAILLE_CELLULE)))
	var nb := grille_taille.x * grille_taille.y
	_cellules_peignables.resize(nb)
	_cellules_peintes.resize(nb)
	_cellules_peintes.fill(0)

	var source: Image = sprite.texture.get_image()
	if source == null:
		_cellules_peignables.fill(1)
		cellules_peignables = nb
		return

	var reduite: Image = source.duplicate()
	reduite.resize(grille_taille.x, grille_taille.y, Image.INTERPOLATE_TRILINEAR)
	for cy in range(grille_taille.y):
		for cx in range(grille_taille.x):
			var peignable := reduite.get_pixel(cx, cy).a > 0.15
			_cellules_peignables[cy * grille_taille.x + cx] = 1 if peignable else 0
			if peignable:
				cellules_peignables += 1


## Applique un tampon de peinture de rayon `rayon` centré sur une position globale.
func peindre(position_globale: Vector2, rayon: int, couleurs: Array[Color]) -> void:
	if couleurs.is_empty() or rayon <= 0:
		return
	var local := sprite.to_local(position_globale)
	var px := int(local.x + tex_size.x / 2.0)
	var py := int(local.y + tex_size.y / 2.0)
	if px < -rayon or py < -rayon or px >= tex_size.x + rayon or py >= tex_size.y + rayon:
		return

	_assurer_tampons(rayon, couleurs)
	var tampon := _tampons[randi() % _tampons.size()]
	var taille := tampon.get_width()
	image.blit_rect_mask(tampon, tampon, Rect2i(0, 0, taille, taille), Vector2i(px - rayon, py - rayon))
	_marquer_cellules(px, py, rayon)
	if coulures.size() < COULURES_MAX and randf() < CHANCE_COULURE:
		var c := couleurs[randi() % couleurs.size()]
		c.a = 1.0
		coulures.append({
			"x": px + randi_range(-rayon, rayon), "y": float(py + randi_range(0, rayon)),
			"fin": float(py + rayon + randi_range(14, 44)), "couleur": c,
		})
	_dirty = true


## Les coulures descendent d'un trait de 2 px, une ligne à la fois.
func _avancer_coulures(delta: float) -> void:
	if coulures.is_empty():
		return
	var restantes: Array[Dictionary] = []
	for c in coulures:
		var y_avant := int(c.y)
		c.y = min(c.y + VITESSE_COULURE * delta, c.fin)
		for y in range(y_avant, int(c.y) + 1):
			if y < 0 or y >= tex_size.y:
				continue
			for x in [c.x, c.x + 1]:
				if x >= 0 and x < tex_size.x:
					image.set_pixel(x, y, c.couleur)
		if c.y < c.fin:
			restantes.append(c)
	coulures = restantes
	_dirty = true


func _marquer_cellules(px: int, py: int, rayon: int) -> void:
	var r_effectif := rayon * 0.8
	var r2 := r_effectif * r_effectif
	var cx_min: int = max(0, (px - rayon) / TAILLE_CELLULE)
	var cx_max: int = min(grille_taille.x - 1, (px + rayon) / TAILLE_CELLULE)
	var cy_min: int = max(0, (py - rayon) / TAILLE_CELLULE)
	var cy_max: int = min(grille_taille.y - 1, (py + rayon) / TAILLE_CELLULE)
	for cy in range(cy_min, cy_max + 1):
		var dy := (cy + 0.5) * TAILLE_CELLULE - py
		for cx in range(cx_min, cx_max + 1):
			var dx := (cx + 0.5) * TAILLE_CELLULE - px
			if dx * dx + dy * dy > r2:
				continue
			var i := cy * grille_taille.x + cx
			if _cellules_peignables[i] == 1 and _cellules_peintes[i] == 0:
				_cellules_peintes[i] = 1
				cellules_peintes += 1


## Régénère les tampons quand le rayon ou le nombre de couleurs change.
func _assurer_tampons(rayon: int, couleurs: Array[Color]) -> void:
	if rayon == _tampons_rayon and couleurs.size() == _tampons_nb_couleurs:
		return
	_tampons_rayon = rayon
	_tampons_nb_couleurs = couleurs.size()
	_tampons.clear()
	var taille := rayon * 2 + 1
	for t in range(NB_TAMPONS):
		var tampon := Image.create(taille, taille, false, Image.FORMAT_RGBA8)
		tampon.fill(Color(0, 0, 0, 0))
		for y in range(taille):
			for x in range(taille):
				var dx := x - rayon
				var dy := y - rayon
				var d := sqrt(dx * dx + dy * dy) / rayon
				if d > 1.0:
					continue
				# Plus dense au centre, éparse sur les bords.
				if randf() < DENSITE_TAMPON * (1.3 - d):
					var c := couleurs[randi() % couleurs.size()]
					c.a = 1.0
					tampon.set_pixel(x, y, c)
		_tampons.append(tampon)
