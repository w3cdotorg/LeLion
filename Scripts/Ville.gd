extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

var tex_size: Vector2i
var image: Image
var texture: ImageTexture
var pixels_peints := 0
var total_pixels := 0
var victoire_declenchee := false


func _ready() -> void:
	tex_size = Vector2i(sprite.texture.get_width(), sprite.texture.get_height())
	total_pixels = tex_size.x * tex_size.y
	image = Image.create(tex_size.x, tex_size.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	texture = ImageTexture.create_from_image(image)

	var mat := sprite.material as ShaderMaterial
	mat.set_shader_parameter("paint_mask", texture)


func peindre(position_local: Vector2, couleur: Color, radius: int = 3, couleurs_disponibles: Array = []) -> void:
	var texture_size := sprite.texture.get_size()
	var uv := (position_local + texture_size / 2) / texture_size

	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		return

	var px := int(uv.x * tex_size.x)
	var py := int(uv.y * tex_size.y)

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy > radius * radius:
				continue
			var nx: int = clamp(px + dx, 0, tex_size.x - 1)
			var ny: int = clamp(py + dy, 0, tex_size.y - 1)

			if image.get_pixel(nx, ny).a == 0.0:
				pixels_peints += 1

			var final_color := couleur
			if couleurs_disponibles.size() > 0:
				final_color = couleurs_disponibles[randi() % couleurs_disponibles.size()]
			final_color.a = 1.0
			image.set_pixel(nx, ny, final_color)

	texture.update(image)

	if not victoire_declenchee and pixels_peints > total_pixels * 0.9:
		victoire_declenchee = true
		afficher_victoire()


func afficher_victoire() -> void:
	pass
