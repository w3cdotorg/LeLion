shader_type canvas_item;
// Filtre « écran cathodique » : courbure, lignes de balayage, décalage chromatique, vignettage.

uniform sampler2D ecran : hint_screen_texture, filter_linear;
uniform float courbure : hint_range(0.0, 0.2) = 0.045;
uniform float lignes : hint_range(0.0, 1.0) = 0.28;
uniform float aberration : hint_range(0.0, 4.0) = 1.2;
uniform float vignette : hint_range(0.0, 1.0) = 0.35;
uniform float nb_lignes = 648.0;

void fragment() {
	vec2 c = SCREEN_UV * 2.0 - 1.0;
	c *= 1.0 + courbure * dot(c, c);
	vec2 uv = c * 0.5 + 0.5;
	if (uv.x < 0.0 || uv.x > 1.0 || uv.y < 0.0 || uv.y > 1.0) {
		COLOR = vec4(0.0, 0.0, 0.0, 1.0);
	} else {
		vec2 decal = vec2(aberration / 2000.0, 0.0);
		vec3 col;
		col.r = texture(ecran, uv + decal).r;
		col.g = texture(ecran, uv).g;
		col.b = texture(ecran, uv - decal).b;
		float ligne = 0.5 + 0.5 * sin(uv.y * nb_lignes * 3.14159);
		col *= 1.0 - lignes * ligne;
		float v = 1.0 - vignette * dot(c * 0.7, c * 0.7);
		col *= clamp(v, 0.0, 1.0);
		COLOR = vec4(col, 1.0);
	}
}
