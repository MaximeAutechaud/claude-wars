shader_type canvas_item;

// Palette-swap de la couleur d'équipe : les sprites sont peints en couleurs
// réalistes, avec les éléments de faction (bouclier, capuche, pennon…) en
// magenta pur — une couleur absente du reste de la palette. Ce shader
// remplace la famille des magentas par la couleur d'équipe en conservant
// l'ombrage : la luminosité du magenta (via max(r, b)) donne la valeur,
// sa part de vert donne la désaturation vers le blanc.
uniform vec4 team_color : source_color = vec4(0.5, 0.5, 0.5, 1.0);

void fragment() {
	vec4 c = COLOR; // texture * modulate déjà appliqués
	float m = clamp((min(c.r, c.b) - c.g) * 5.0, 0.0, 1.0);
	float v = max(c.r, c.b);
	float whiteness = clamp(c.g / max(v, 0.001) * 0.8, 0.0, 1.0);
	vec3 accent = mix(team_color.rgb * v, vec3(v), whiteness);
	COLOR.rgb = mix(c.rgb, accent, m);
}
