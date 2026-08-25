shader_type canvas_item;

// Écume de berge, appliquée sur des bandes posées le long du contour du plan
// d'eau (l'union des hexagones, voir Rivers) — la géométrie fait donc tout le
// travail de placement, le shader ne s'occupe que de l'animation.
//
// UV.y : 0 sur l'arête côté terre, 1 vers l'intérieur de l'eau.
// UV.x : position le long de l'arête (0 -> 1), qui porte l'ondulation.
uniform float wave_speed : hint_range(0.0, 6.0) = 1.6;
uniform float wave_freq : hint_range(0.0, 20.0) = 4.0;
uniform float foam_strength : hint_range(0.0, 1.0) = 0.5;
// Décalage de phase selon la position : sans lui toutes les berges de la
// carte pulsent à l'unisson, ce qui se lit comme un clignotement global.
uniform float spatial_scale : hint_range(0.0, 0.5) = 0.05;

varying vec2 v_pos;

void vertex() {
	v_pos = VERTEX;
}

void fragment() {
	float band = clamp(1.0 - UV.y, 0.0, 1.0);
	float phase = (v_pos.x + v_pos.y) * spatial_scale;
	float wave = 0.5 + 0.5 * sin(UV.x * wave_freq + TIME * wave_speed + phase);
	// pow : concentre l'écume contre la berge et la laisse mourir en douceur
	// vers le large, plutôt qu'un dégradé linéaire trop large.
	float a = pow(band, 1.8) * mix(0.4, 1.0, wave) * foam_strength;
	COLOR = vec4(1.0, 1.0, 1.0, a);
}
