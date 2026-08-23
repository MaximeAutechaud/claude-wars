class_name DialoguePortrait
extends Control

# Portrait placeholder façon buste : tant qu'il n'y a pas de vrai artwork par
# personnage, on dessine une silhouette (tête + épaules) teintée de la
# couleur du locuteur, avec son initiale. `bob_offset` est piloté par
# DialogueBox pendant qu'un personnage "parle" (léger tremblement vertical).

var accent: Color = Color(0.55, 0.58, 0.65)
var initial: String = "?"
var bob_offset: float = 0.0

func _ready() -> void:
	resized.connect(queue_redraw)

func set_speaker(speaker_name: String, color: Color) -> void:
	accent = color
	initial = _pick_initial(speaker_name)
	queue_redraw()

# Ignore l'article initial ("Le Fossoyeur" -> F, pas L) : les noms de
# personnages du jeu sont typiquement des titres ("Le Héros", "Le Revenant"...)
func _pick_initial(speaker_name: String) -> String:
	var s := speaker_name.strip_edges()
	if s.is_empty():
		return "?"
	var lower := s.to_lower()
	for article in ["l'", "le ", "la ", "les ", "un ", "une ", "des "]:
		if lower.begins_with(article):
			s = s.substr(article.length())
			break
	return s.substr(0, 1).to_upper() if not s.is_empty() else speaker_name.substr(0, 1).to_upper()

func _draw() -> void:
	var s := size
	if s.x <= 0.0 or s.y <= 0.0:
		return
	var cx := s.x * 0.5
	draw_rect(Rect2(Vector2.ZERO, s), Color(0.1, 0.11, 0.14, 0.92), true)
	draw_rect(Rect2(Vector2.ZERO, s), accent, false, 3.0)

	var head_r := s.x * 0.22
	var head_c := Vector2(cx, s.y * 0.32 + bob_offset)
	draw_circle(head_c, head_r, accent.lightened(0.15))

	var sh_top := head_c.y + head_r * 0.7
	var sh_w_top := head_r * 1.5
	var sh_w_bot := s.x * 0.42
	var sh_bot := s.y * 0.98 + bob_offset
	var pts := PackedVector2Array([
		Vector2(cx - sh_w_top, sh_top),
		Vector2(cx + sh_w_top, sh_top),
		Vector2(cx + sh_w_bot, sh_bot),
		Vector2(cx - sh_w_bot, sh_bot),
	])
	draw_colored_polygon(pts, accent.darkened(0.2))

	var font := ThemeDB.fallback_font
	var fsize := int(head_r * 1.1)
	var t_size := font.get_string_size(initial, HORIZONTAL_ALIGNMENT_LEFT, -1, fsize)
	draw_string(font, Vector2(cx - t_size.x * 0.5, head_c.y + fsize * 0.35), initial,
			HORIZONTAL_ALIGNMENT_LEFT, -1, fsize, Color(0.05, 0.05, 0.07))

	var hint := "PORTRAIT PLACEHOLDER"
	var hint_size := font.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 11)
	draw_string(font, Vector2(cx - hint_size.x * 0.5, s.y - 6), hint,
			HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(1, 1, 1, 0.35))
