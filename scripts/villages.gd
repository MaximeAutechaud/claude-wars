class_name Villages
extends Node2D

# Soin d'une unité qui commence son tour sur un village allié
const VILLAGE_HEAL := 3

@onready var map: GameMap = $"../GameMap"
@onready var fog: Fog = get_node_or_null("../Fog")

var owners: Dictionary = {}
var _tex: Texture2D = preload("res://assets/tiles/village.png")

# Décalage local (depuis l'ancre de la case) jusqu'au conduit de la cheminée
# sur village.png, repéré par inspection des pixels de l'image.
const CHIMNEY_OFFSET := Vector2(34, -49)

static var _smoke_tex: Texture2D

func _ready() -> void:
	# cell -> propriétaire initial (-1 = neutre), depuis le scénario courant
	owners = (Scenario.active["villages"] as Dictionary).duplicate()
	for cell: Vector2i in owners:
		_add_chimney_smoke(cell)
	queue_redraw()

func _add_chimney_smoke(cell: Vector2i) -> void:
	var p := to_local(map.to_global(map.map_to_local(cell)))
	var smoke := CPUParticles2D.new()
	smoke.position = p + CHIMNEY_OFFSET
	smoke.texture = _get_smoke_texture()
	smoke.amount = 8
	smoke.lifetime = 3.0
	smoke.preprocess = 3.0
	smoke.direction = Vector2(0, -1)
	smoke.spread = 12.0
	smoke.gravity = Vector2(0, -6)
	smoke.initial_velocity_min = 6.0
	smoke.initial_velocity_max = 12.0
	smoke.scale_amount_min = 0.4
	smoke.scale_amount_max = 0.7
	var scale_curve := Curve.new()
	scale_curve.add_point(Vector2(0.0, 0.3))
	scale_curve.add_point(Vector2(1.0, 1.4))
	smoke.scale_amount_curve = scale_curve
	var ramp := Gradient.new()
	ramp.set_color(0, Color(0.7, 0.7, 0.7, 0.85))
	ramp.set_color(1, Color(0.7, 0.7, 0.7, 0.0))
	smoke.color_ramp = ramp
	add_child(smoke)

# Texture de particule partagée : un disque radial blanc->transparent,
# généré en code (pas besoin d'asset pour un simple nuage flou).
static func _get_smoke_texture() -> Texture2D:
	if _smoke_tex:
		return _smoke_tex
	var grad := Gradient.new()
	grad.set_color(0, Color(1, 1, 1, 0.85))
	grad.set_color(1, Color(1, 1, 1, 0.0))
	var tex := GradientTexture2D.new()
	tex.gradient = grad
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(1.0, 0.5)
	tex.width = 32
	tex.height = 32
	_smoke_tex = tex
	return _smoke_tex

func is_village(cell: Vector2i) -> bool:
	return owners.has(cell)

func owner_of(cell: Vector2i) -> int:
	return owners.get(cell, -2)

# Capture instantanée par les unités à pied qui terminent leur mouvement dessus
func try_capture(unit: Unit) -> bool:
	if not owners.has(unit.cell) or owners[unit.cell] == unit.team:
		return false
	if not unit.can_capture():
		return false
	owners[unit.cell] = unit.team
	print("Village %s capturé par %s" % [unit.cell, unit.unit_name()])
	queue_redraw()
	return true

func _draw() -> void:
	for cell: Vector2i in owners:
		# Sous le voile noir, le village n'existe pas encore pour le joueur
		if fog and not fog.is_explored(cell):
			continue
		var p := to_local(map.to_global(map.map_to_local(cell)))
		draw_texture(_tex, p - Vector2(50.0, 60.0))
		_draw_ownership_flag(p, owners[cell])

# Fanion de propriétaire : même logique que le rendu des unités (couleur
# d'équipe, gris pour neutre) mais peint en dégradé + contour sombre plutôt
# qu'un triangle vectoriel plat, pour se fondre dans le style peint de la
# carte au lieu d'y trancher.
func _draw_ownership_flag(p: Vector2, owner_team: int) -> void:
	var col := Color(0.62, 0.62, 0.62)
	if owner_team >= 0:
		col = Unit.TEAM_COLORS[owner_team]
	var top := p + Vector2(36, -60)
	var base := p + Vector2(36, -40)
	# Hampe : ombre + éclat pour donner un peu de volume à un simple trait
	draw_line(top, base, Color(0.20, 0.15, 0.10), 2.0)
	draw_line(top + Vector2(-0.5, 0), base + Vector2(-0.5, 0), Color(0.45, 0.35, 0.24), 0.75)
	# Silhouette légèrement échancrée (tissu qui ondule) + dégradé clair->foncé
	var pts := PackedVector2Array([
		top,
		top + Vector2(15, -2),
		top + Vector2(10, 5),
		top + Vector2(15, 10),
		top + Vector2(0, 9),
	])
	var colors := PackedColorArray([
		col.lightened(0.1), col.lightened(0.35), col.darkened(0.3),
		col.darkened(0.15), col,
	])
	draw_polygon(pts, colors)
	var outline := pts.duplicate()
	outline.append(pts[0])
	draw_polyline(outline, Color(0, 0, 0, 0.4), 0.75, true)
