class_name ConnectedRibbon
extends Node2D

# Base commune à Roads et Rivers : un ruban de matière (pas une forme)
# dessiné le long d'une courbe lissée passant par le centre de chaque case
# de `terrain_type` et connectée à ses voisines de même terrain
# (`Pathfinder.get_neighbors`). La forme du réseau (ligne, virage,
# embranchement) sort donc de la disposition réelle du scénario, sans art
# à multiplier par cas de figure.
#
# Lissage : plutôt que des segments droits centre → milieu d'arête (zigzag
# visible sur un tracé pourtant rectiligne — le décalage vertical des
# colonnes impaires en odd-q fait que les centres d'une "ligne droite" ne
# sont pas alignés à l'écran), chaque segment centre-à-centre est une
# courbe de Bézier cubique. La tangente en chaque case vient de ses propres
# voisines connectées façon Catmull-Rom : une case "de passage" (2
# connexions) tangente selon l'axe voisin1→voisin2 (lisse la ligne qui la
# traverse) ; une case terminale (1 connexion) tangente vers son unique
# voisine ; un embranchement (3+ connexions, ou 0) n'est pas lissé — les
# rubans y restent des spokes droits depuis le centre, ce qui se lit bien
# comme un carrefour. Chaque arête est dessinée deux fois (une fois depuis
# chaque case) : redondant mais inoffensif pour un tracé statique, et bien
# plus simple qu'un suivi des arêtes déjà visitées.
#
# Sous-classes (Roads, Rivers) : définir terrain_type / ribbon_half_width /
# ribbon_tex dans `_init()` avant l'entrée en scène. `smooth_curve` peut y
# être mis à false pour revenir à des segments droits centre-à-centre — le
# lissage en courbe, très visible et flatteur sur le filet étroit de la
# route, fait des vagues disgracieuses sur le ruban large de la rivière
# (l'effet contraire de ce qui est cherché : de l'eau qui a l'air agitée
# au lieu de couler).

var terrain_type: int = -1
var ribbon_half_width: float = 9.0
var ribbon_tex: Texture2D
var smooth_curve: bool = true

const HUB_SIDES := 12
const CURVE_SEGMENTS := 8
const CTRL_FACTOR := 0.4   # force du lissage, fraction de la distance centre-à-centre

@onready var map: GameMap = $"../GameMap"
@onready var fog: Fog = get_node_or_null("../Fog")

var _cells: Array[Vector2i] = []

func _ready() -> void:
	for col in map.map_size.x:
		for row in map.map_size.y:
			var c := Vector2i(col, row)
			if map.get_terrain(c) == terrain_type:
				_cells.append(c)
	queue_redraw()

func _draw() -> void:
	for cell in _cells:
		if fog and not fog.is_explored(cell):
			continue
		_draw_cell(cell)

func _center_of(cell: Vector2i) -> Vector2:
	return to_local(map.to_global(map.map_to_local(cell)))

func _neighbor_cells(cell: Vector2i) -> Array[Vector2i]:
	var result: Array[Vector2i] = []
	for n in Pathfinder.get_neighbors(cell):
		if map.get_terrain(n) == terrain_type:
			result.append(n)
	return result

# Tangente façon Catmull-Rom : direction voisin1→voisin2 pour une case de
# passage, direction vers l'unique voisine pour une case terminale, nulle
# (pas de lissage) pour un embranchement ou une case isolée.
func _tangent_at(cell: Vector2i, neighbors: Array[Vector2i]) -> Vector2:
	if neighbors.size() == 1:
		return (_center_of(neighbors[0]) - _center_of(cell)).normalized()
	if neighbors.size() == 2:
		return (_center_of(neighbors[1]) - _center_of(neighbors[0])).normalized()
	return Vector2.ZERO

func _draw_cell(cell: Vector2i) -> void:
	var center := _center_of(cell)
	var neighbors := _neighbor_cells(cell)
	var tangent := _tangent_at(cell, neighbors)
	for n in neighbors:
		var n_center := _center_of(n)
		var n_tangent := _tangent_at(n, _neighbor_cells(n))

		var t_here := tangent
		if t_here != Vector2.ZERO and t_here.dot(n_center - center) < 0.0:
			t_here = -t_here
		var t_there := n_tangent
		if t_there != Vector2.ZERO and t_there.dot(center - n_center) < 0.0:
			t_there = -t_there

		var d := center.distance_to(n_center) * CTRL_FACTOR if smooth_curve else 0.0
		var p1 := center + t_here * d
		var p2 := n_center + t_there * d
		_draw_curve_ribbon(center, p1, p2, n_center)
	_draw_hub(center)

static func _cubic_bezier(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * u * p0 + 3.0 * u * u * t * p1 + 3.0 * u * t * t * p2 + t * t * t * p3

func _draw_curve_ribbon(p0: Vector2, p1: Vector2, p2: Vector2, p3: Vector2) -> void:
	var pts: Array[Vector2] = []
	for i in (CURVE_SEGMENTS + 1):
		pts.append(_cubic_bezier(p0, p1, p2, p3, float(i) / CURVE_SEGMENTS))
	var white := Color.WHITE
	for i in CURVE_SEGMENTS:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var dir := (b - a).normalized()
		var perp := Vector2(-dir.y, dir.x) * ribbon_half_width
		var quad := PackedVector2Array([a - perp, a + perp, b + perp, b - perp])
		var v0 := float(i) / CURVE_SEGMENTS
		var v1 := float(i + 1) / CURVE_SEGMENTS
		var uvs := PackedVector2Array([
			Vector2(0, v0), Vector2(1, v0), Vector2(1, v1), Vector2(0, v1),
		])
		draw_polygon(quad, PackedColorArray([white, white, white, white]), uvs, ribbon_tex)

func _draw_hub(center: Vector2) -> void:
	var r := ribbon_half_width
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for i in HUB_SIDES:
		var a := TAU * i / float(HUB_SIDES)
		var offset := Vector2(cos(a), sin(a))
		pts.append(center + offset * r)
		uvs.append(Vector2(0.5, 0.5) + offset * 0.5)
		colors.append(Color.WHITE)
	draw_polygon(pts, colors, uvs, ribbon_tex)
