extends Node2D
## La ville : masque de peinture RGBA appliqué par shader sur la skyline.
## Seuls les pixels opaques de la skyline comptent dans la progression.

@onready var sprite: Sprite2D = $Sprite2D

var tex_size: Vector2i
var image: Image
var texture: ImageTexture
var pixels_peignables := 0
var pixels_peints := 0
var _masque_peignable: PackedByteArray
var _dirty := false


func _ready() -> void:
	tex_size = Vector2i(sprite.texture.get_width(), sprite.texture.get_height())
	_calculer_pixels_peignables()

	image = Image.create(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	texture = ImageTexture.create_from_image(image)

	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("paint_mask", texture)


func _process(_delta: float) -> void:
	if _dirty:
		_dirty = false
		texture.update(image)
		GameState.signaler_progression(progression())


func progression() -> float:
	return float(pixels_peints) / max(pixels_peignables, 1)


func _calculer_pixels_peignables() -> void:
	_masque_peignable.resize(tex_size.x * tex_size.y)
	var source: Image = sprite.texture.get_image()
	if source == null:
		_masque_peignable.fill(1)
		pixels_peignables = tex_size.x * tex_size.y
		return
	for y in range(tex_size.y):
		for x in range(tex_size.x):
			var opaque := source.get_pixel(x, y).a > 0.05
			_masque_peignable[y * tex_size.x + x] = 1 if opaque else 0
			if opaque:
				pixels_peignables += 1


## Peint un disque de rayon `radius` autour d'une position globale, avec une couleur
## tirée au hasard par pixel dans `couleurs`.
func peindre(position_globale: Vector2, radius: int, couleurs: Array[Color]) -> void:
	if couleurs.is_empty():
		return
	var local := sprite.to_local(position_globale)
	var texture_size := sprite.texture.get_size()
	var uv := (local + texture_size / 2) / texture_size
	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return

	var px := int(uv.x * tex_size.x)
	var py := int(uv.y * tex_size.y)
	var r2 := radius * radius

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy > r2:
				continue
			var nx := px + dx
			var ny := py + dy
			if nx < 0 or ny < 0 or nx >= tex_size.x or ny >= tex_size.y:
				continue
			if _masque_peignable[ny * tex_size.x + nx] == 0:
				continue
			if image.get_pixel(nx, ny).a == 0.0:
				pixels_peints += 1
			var c := couleurs[randi() % couleurs.size()]
			c.a = 1.0
			image.set_pixel(nx, ny, c)
	_dirty = true
