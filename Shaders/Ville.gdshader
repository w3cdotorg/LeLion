shader_type canvas_item;

uniform sampler2D paint_mask : source_color;
uniform vec4 base_color : source_color = vec4(0.2, 0.2, 0.2, 1.0);

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec4 mask = texture(paint_mask, UV);

	// Si rien dans le masque, afficher la texture en gris
	vec4 color = base * base_color;

	// Si le masque contient quelque chose (alpha > 0), le mélanger à la couleur
	if (mask.a > 0.01) {
		color.rgb = mix(color.rgb, mask.rgb, mask.a);
	}

	COLOR = color;
}