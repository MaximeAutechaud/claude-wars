extends Control

# Galerie du roster, accessible depuis l'écran d'accueil : toutes les unités
# du jeu côte à côte, dans les deux couleurs de faction, avec l'idle réel du
# jeu (vraies scènes Unit, échelle agrandie) — pour vérifier les sprites et
# les stats d'un coup d'œil sans lancer une partie.

const TITLE_SCENE := "res://scenes/title.tscn"
const UNIT_SCENE := preload("res://scenes/unit.tscn")
const ROSTER: Array = [
	Unit.Type.INFANTRY, Unit.Type.TANK, Unit.Type.ARCHER, Unit.Type.SCOUT,
	Unit.Type.MEDIC, Unit.Type.MAGE, Unit.Type.HERO, Unit.Type.BOSS,
]
const UNIT_SCALE := 2.5
const ROW_BLUE_Y := 210.0
const ROW_RED_Y := 380.0
const LABELS_Y := 480.0

func _ready() -> void:
	var vp := get_viewport_rect().size
	var col_w: float = minf(150.0, (vp.x - 60.0) / ROSTER.size())
	var x0: float = (vp.x - col_w * (ROSTER.size() - 1)) * 0.5
	for i in ROSTER.size():
		var type: int = ROSTER[i]
		var x := x0 + i * col_w
		for team in 2:
			var u: Unit = UNIT_SCENE.instantiate()
			u.setup(type, team)
			var s := UNIT_SCALE * (1.35 if type == Unit.Type.BOSS else 1.0)
			u.scale = Vector2(s, s)
			u.position = Vector2(x, ROW_BLUE_Y + team * (ROW_RED_Y - ROW_BLUE_Y))
			add_child(u)
		_add_label(x, col_w, LABELS_Y, Unit.STATS[type]["name"], 14,
				Color(0.92, 0.94, 1.0))
		_add_label(x, col_w, LABELS_Y + 40.0, _stats_text(type), 11,
				Color(0.65, 0.7, 0.8))

func _stats_text(type: int) -> String:
	var s: Dictionary = Unit.STATS[type]
	var min_r: int = s.get("min_range", 1)
	var range_txt := str(s["range"]) if min_r <= 1 else "%d-%d" % [min_r, s["range"]]
	return "PV %d · PM %d\nAtk %d · Rip %d\nPortée %s · Vis %d" % [
		s["max_hp"], s["mp"], s["atk"], s["counter"], range_txt, s["vision"],
	]

func _add_label(x: float, col_w: float, y: float, text: String, size: int,
		color: Color) -> void:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	lbl.custom_minimum_size = Vector2(col_w, 0)
	lbl.position = Vector2(x - col_w * 0.5, y)
	lbl.size = Vector2(col_w, 0)
	add_child(lbl)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		_on_back_pressed()

# Même filigrane hexagonal que l'écran d'accueil
func _draw() -> void:
	var size := get_viewport_rect().size
	var hw := GameMap.TILE_W * 0.5
	var hh := GameMap.TILE_H * 0.5
	var line := Color(0.35, 0.55, 1.0, 0.06)
	var col := 0
	var x := 0.0
	while x < size.x + hw:
		var y_off := hh if col % 2 == 1 else 0.0
		var y := y_off
		while y < size.y + hh:
			var pts := GameMap.hex_corners(Vector2(x, y), hw - 1.5, hh - 1.5)
			pts.append(pts[0])
			draw_polyline(pts, line, 1.5)
			y += GameMap.TILE_H
		x += GameMap.TILE_W * 0.75
		col += 1
