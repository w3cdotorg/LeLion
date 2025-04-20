extends Node2D
@onready var sprite := $Sprite2D

var TEX_SIZE: Vector2i
var image : Image
var texture : ImageTexture

func _ready():
	print("🏙️ Ville ready !")
	sprite.modulate = Color(1, 1, 1, 1)  # au cas où l'alpha serait 0

	print("🎨 Texture sprite de la ville :", sprite.texture)
	print("📏 Texture size :", sprite.texture.get_size())
	print("👁️ Sprite visible :", sprite.visible)
	print("🎨 Modulate :", sprite.modulate)
	print("🔳 Self modulate :", sprite.self_modulate)

	TEX_SIZE = Vector2i(sprite.texture.get_width(), sprite.texture.get_height())
	image = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # tout transparent
	texture = ImageTexture.create_from_image(image)

	var mat = sprite.material as ShaderMaterial
	mat.set_shader_parameter("paint_mask", texture)

func peindre(position_local: Vector2, couleur: Color):
	var adjusted_pos = position_local + (sprite.texture.get_size() / 2)
	var uv = adjusted_pos / Vector2(TEX_SIZE)

	if uv.x < 0.0 or uv.y < 0.0 or uv.x > 1.0 or uv.y > 1.0:
		print("⚠️ UV hors texture :", uv)
		return

	var px = int(uv.x * TEX_SIZE.x)
	var py = int(uv.y * TEX_SIZE.y)

	print("🖌️ Pixel à colorer :", px, py)

	image.set_pixel(px, py, couleur)
	texture.update(image)

func _process(_delta):
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		var pos = sprite.get_local_mouse_position()
		peindre(pos, Color.RED)

func _on_PeintureTimer_timeout():
	var zone = $PeintureZone
	var lions = get_tree().get_nodes_in_group("lion")

	if lions.size() == 0:
		return

	var lion = lions[0]  # on suppose qu'il n'y en a qu'un

	for body in zone.get_overlapping_bodies():
			for emitter in lion.vomi_container.get_children():
				if emitter.emitting:
					var local_pos = sprite.to_local(body.global_position)

					if lion.couleurs_debloquees.size() > 0:
						var couleur = lion.couleurs_debloquees[randi() % lion.couleurs_debloquees.size()]
						peindre(local_pos, couleur)
