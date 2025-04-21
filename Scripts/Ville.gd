extends Node2D

@onready var sprite := $Sprite2D

var TEX_SIZE: Vector2i
var image: Image
var texture: ImageTexture

func _ready():
	print("🏙️ Ville ready !")
	sprite.modulate = Color(1, 1, 1, 1)  # au cas où

	# Debug infos
	print("🎨 Texture sprite de la ville :", sprite.texture)
	print("📏 Texture size :", sprite.texture.get_size())
	print("👁️ Sprite visible :", sprite.visible)
	print("🎨 Modulate :", sprite.modulate)
	print("🔳 Self modulate :", sprite.self_modulate)

	# Création de la texture de peinture (masque)
	TEX_SIZE = Vector2i(sprite.texture.get_width(), sprite.texture.get_height())
	image = Image.create(TEX_SIZE.x, TEX_SIZE.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))  # totalement transparent
	texture = ImageTexture.create_from_image(image)

	# Liaison au shader
	var mat = sprite.material as ShaderMaterial
	mat.set_shader_parameter("paint_mask", texture)


#func peindre(position_local: Vector2, couleur: Color, radius: int = 3) -> void:
	#var texture_size = sprite.texture.get_size()
	#var uv = (position_local + texture_size / 2) / texture_size
#
	#if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		#print("⚠️ UV hors texture :", uv)
		#return
#
	#var px = int(uv.x * TEX_SIZE.x)
	#var py = int(uv.y * TEX_SIZE.y)
#
	#for dx in range(-radius, radius + 1):
		#for dy in range(-radius, radius + 1):
			#if dx * dx + dy * dy <= radius * radius:
				#var nx = clamp(px + dx, 0, TEX_SIZE.x - 1)
				#var ny = clamp(py + dy, 0, TEX_SIZE.y - 1)
				#image.set_pixel(nx, ny, couleur)
#
	#texture.update(image)
	#print("🖌️ Zone peinte autour de :", px, py)
	
func peindre(position_local: Vector2, couleur: Color, radius: int = 3, couleurs_disponibles := []):
	var texture_size = sprite.texture.get_size()
	var uv = (position_local + texture_size / 2) / texture_size

	if uv.x < 0.0 or uv.x > 1.0 or uv.y < 0.0 or uv.y > 1.0:
		print("⚠️ UV hors texture :", uv)
		return

	var px = int(uv.x * TEX_SIZE.x)
	var py = int(uv.y * TEX_SIZE.y)

	for dx in range(-radius, radius + 1):
		for dy in range(-radius, radius + 1):
			if dx * dx + dy * dy <= radius * radius:
				var nx = clamp(px + dx, 0, TEX_SIZE.x - 1)
				var ny = clamp(py + dy, 0, TEX_SIZE.y - 1)

				# 🎲 Couleur aléatoire dans la liste si dispo, sinon couleur fixe
				var final_color = couleur
				if couleurs_disponibles.size() > 0:
					final_color = couleurs_disponibles[randi() % couleurs_disponibles.size()]

				image.set_pixel(nx, ny, final_color)

	texture.update(image)
	print("🌈 Zone multicolore peinte autour de :", px, py)


func _process(_delta):
	#var bodies = $PeintureZone.get_overlapping_bodies()
	#for body in $PeintureZone.get_overlapping_bodies():
		#print("👀 Body détecté :", body.name)
	#for body in bodies:
		#if body.name == "GerbeTraceuse2":  # ou "GerbeTraceuse" selon le nom
			#print("💥 Collision avec traceuse détectée")
			#var lion = get_tree().get_nodes_in_group("lion")[0]
			#if lion:
				#var couleur = lion.couleurs_debloquees[randi() % lion.couleurs_debloquees.size()]
				#var local_pos = sprite.to_local(body.global_position)
				#peindre(local_pos, couleur)
	pass


func _on_PeintureZone_body_entered(body: Node) -> void:
	if body is CPUParticles2D:
		var pos = sprite.to_local(body.global_position)
		var couleur = Color.RED  # tu peux choisir dynamiquement
		peindre(pos, couleur)
