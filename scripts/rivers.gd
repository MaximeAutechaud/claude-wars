class_name Rivers
extends Node2D

# Rendu de l'eau : remplissage, berge de sable et écume animée.
#
# Le principe : plutôt que de dessiner case par case, on calcule **l'union**
# des hexagones de toutes les cases d'eau visibles (Geometry2D.merge_polygons)
# et tout se déduit de ce contour unique. C'est ce qui rend le résultat propre,
# et la version case par case ne pouvait pas y arriver : chaque case dessinait
# son bout de rivage avec sa propre géométrie (décalages depuis *son* centre,
# écumes qui se superposaient aux coins…), donc les raccords entre deux cases
# d'eau restaient forcément approximatifs. Sur un contour unique il n'y a plus
# de raccord du tout — ni couture interne, ni cumul d'alpha, ni cas particulier
# selon que le coin est saillant ou rentrant.
#
# Une seule subtilité en découle, l'arrondi des coins : la même formule (courbe
# de Bézier quadratique de p0 à p1 avec le sommet pour point de contrôle) fait
# spontanément ce qu'il faut dans les deux sens. Sur un sommet saillant le
# triangle p0-sommet-p1 est à l'intérieur du polygone, la courbe **rogne** ;
# sur un sommet rentrant il est à l'extérieur, la courbe **bombe** et l'eau
# vient couvrir la pointe de terre. Rien à distinguer à la main.
#
# Effet de bord assumé : l'eau occupe tout l'hexagone, il n'y a donc plus
# l'herbe de berge qui dépassait aux coins de la case du temps du ruban.
#
# Limite connue : une case de terre entièrement encerclée d'eau (île d'une
# case) produirait un trou dans l'union, que ce code ne gère pas — aucun
# tableau actuel n'en contient.

const WATER_TEX: Texture2D = preload("res://assets/tiles/river.png")
const SAND_TEX: Texture2D = preload("res://assets/tiles/sand.png")
const FOAM_SHADER: Shader = preload("res://assets/water_foam.gdshader")

# Largeurs en pixels, mesurées depuis le rivage (jamais en fraction d'une
# distance à un centre : cf. l'historique, ça donnait des bandes d'épaisseur
# variable selon l'endroit du contour).
const FOAM_WIDTH := 7.0
const BEACH_CORE_WIDTH := 4.0     # sable franc
const BEACH_TOTAL_WIDTH := 13.0   # jusqu'à disparition dans l'herbe
const BEACH_ALPHA := 0.9
# La texture de sable générée est plus claire et plus jaune que la palette de
# la carte : telle quelle, la berge se lit comme un halo lumineux.
const BEACH_TINT := Color(0.86, 0.82, 0.70)

const CORNER_RADIUS := 12.0
const CORNER_STEPS := 5
# Les hexagones voisins ne font que se toucher ; on les dilate d'un poil pour
# que l'union les fusionne vraiment au lieu de les laisser côte à côte.
const HEX_INFLATE := 0.5

@onready var map: GameMap = $"../GameMap"
@onready var fog: Fog = get_node_or_null("../Fog")

var _cells: Array[Vector2i] = []
var _foam: FoamOverlay
var _outlines: Array[PackedVector2Array] = []

func _ready() -> void:
	# Les textures d'eau et de sable sont seamless et mappées en coordonnées
	# monde (voir _world_uvs) : il faut autoriser leur répétition hors de [0,1].
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	for col in map.map_size.x:
		for row in map.map_size.y:
			var c := Vector2i(col, row)
			if map.get_terrain(c) == GameMap.Terrain.RIVER:
				_cells.append(c)
	_foam = FoamOverlay.new()
	_foam.layer = self
	var mat := ShaderMaterial.new()
	mat.shader = FOAM_SHADER
	_foam.material = mat
	add_child(_foam)
	queue_redraw()

func center_of(cell: Vector2i) -> Vector2:
	return to_local(map.to_global(map.map_to_local(cell)))

func corners_of(cell: Vector2i, inflate: float = 0.0) -> PackedVector2Array:
	var center := center_of(cell)
	var pts := GameMap.hex_corners(center, GameMap.TILE_W * 0.5, GameMap.TILE_H * 0.5)
	if is_zero_approx(inflate):
		return pts
	var out := PackedVector2Array()
	for p: Vector2 in pts:
		out.append(p + (p - center).normalized() * inflate)
	return out

# Union des hexagones des cases d'eau, un polygone par plan d'eau distinct.
# `ignore_fog` sert aux nœuds qui ont besoin de la forme réelle du plan d'eau
# plutôt que de la portion révélée (WaterLifeLayer : un banc de poissons ne
# doit pas changer de bassin quand le brouillard s'ouvre).
func build_outlines(ignore_fog: bool = false) -> Array[PackedVector2Array]:
	var acc: Array[PackedVector2Array] = []
	for cell in _cells:
		if not ignore_fog and fog and not fog.is_explored(cell):
			continue
		acc.append(corners_of(cell, HEX_INFLATE))
	# Fusion par passes : une passe suffit presque toujours, mais un polygone
	# qui grossit peut rejoindre un voisin déjà écarté comme disjoint — on
	# répète tant que le nombre de polygones diminue.
	var changed := true
	while changed:
		changed = false
		var merged: Array[PackedVector2Array] = []
		for poly in acc:
			var joined := false
			for k in merged.size():
				var union := Geometry2D.merge_polygons(merged[k], poly)
				if union.size() == 1:
					merged[k] = union[0]
					joined = true
					changed = true
					break
			if not joined:
				merged.append(poly)
		acc = merged
	var out: Array[PackedVector2Array] = []
	for poly in acc:
		out.append(_round_polygon(poly))
	return out

static func _quad_bezier(p0: Vector2, ctrl: Vector2, p1: Vector2, t: float) -> Vector2:
	var u := 1.0 - t
	return u * u * p0 + 2.0 * u * t * ctrl + t * t * p1

# Arrondit tous les sommets du polygone. Voir l'en-tête du fichier : la même
# formule rogne les sommets saillants et bombe les sommets rentrants.
static func _round_polygon(poly: PackedVector2Array) -> PackedVector2Array:
	var n := poly.size()
	if n < 3:
		return poly
	var out := PackedVector2Array()
	for i in n:
		var prev: Vector2 = poly[(i + n - 1) % n]
		var cur: Vector2 = poly[i]
		var nxt: Vector2 = poly[(i + 1) % n]
		# Bridé à la moitié de la plus courte arête voisine : deux arrondis sur
		# une même arête ne doivent pas se manger l'un l'autre.
		var r := minf(CORNER_RADIUS, minf(
			cur.distance_to(prev), cur.distance_to(nxt)) * 0.5)
		if r < 0.5:
			out.append(cur)
			continue
		var p0 := cur + (prev - cur).normalized() * r
		var p1 := cur + (nxt - cur).normalized() * r
		for s in (CORNER_STEPS + 1):
			out.append(_quad_bezier(p0, cur, p1, float(s) / CORNER_STEPS))
	return out

# Décale chaque sommet le long de la bissectrice des normales des deux
# segments qui s'y rejoignent : largeur constante, et deux segments voisins
# aboutissent au même point décalé, donc pas d'encoche dans les angles.
# `dist` positif = vers l'intérieur de l'eau, négatif = vers la terre.
static func _offset_outline(poly: PackedVector2Array, dist: float) -> PackedVector2Array:
	var n := poly.size()
	var normals := PackedVector2Array()
	normals.resize(n)
	for j in n:
		var d := (poly[(j + 1) % n] - poly[j]).normalized()
		normals[j] = Vector2(-d.y, d.x)
	# Le sens de rotation du polygone n'est pas garanti : on le détermine une
	# fois en testant si un point à peine décalé tombe bien dans le polygone.
	var probe: Vector2 = (poly[0] + poly[1]) * 0.5 + normals[0] * 0.5
	var sign := 1.0 if Geometry2D.is_point_in_polygon(probe, poly) else -1.0
	var out := PackedVector2Array()
	out.resize(n)
	for j in n:
		var bisector := (normals[(j + n - 1) % n] + normals[j]).normalized()
		out[j] = poly[j] + bisector * (sign * dist)
	return out

# UV = position monde / taille de texture : une texture seamless se prolonge
# alors d'un polygone au suivant, au lieu de recommencer son motif dans chacun.
static func _world_uvs(points: PackedVector2Array, tex_size: Vector2) -> PackedVector2Array:
	var uvs := PackedVector2Array()
	for p: Vector2 in points:
		uvs.append(p / tex_size)
	return uvs

func outlines() -> Array[PackedVector2Array]:
	return _outlines

func _draw() -> void:
	_outlines = build_outlines()

	# Berge d'abord, eau ensuite : la berge part vers l'extérieur, donc elle ne
	# peut de toute façon pas mordre sur l'eau, mais l'ordre garde le rivage net.
	# La couleur des sommets multiplie la texture : elle porte donc à la fois la
	# teinte et le fondu vers l'herbe.
	var opaque := BEACH_TINT
	opaque.a = BEACH_ALPHA
	var clear := BEACH_TINT
	clear.a = 0.0
	var core_cols := PackedColorArray([opaque, opaque, opaque, opaque])
	var fade_cols := PackedColorArray([opaque, opaque, clear, clear])
	var sand_size := SAND_TEX.get_size()
	for poly in _outlines:
		var n := poly.size()
		var mid := _offset_outline(poly, -BEACH_CORE_WIDTH)
		var outer := _offset_outline(poly, -BEACH_TOTAL_WIDTH)
		for j in n:
			var k := (j + 1) % n
			var core := PackedVector2Array([poly[j], poly[k], mid[k], mid[j]])
			var fade := PackedVector2Array([mid[j], mid[k], outer[k], outer[j]])
			draw_polygon(core, core_cols, _world_uvs(core, sand_size), SAND_TEX)
			draw_polygon(fade, fade_cols, _world_uvs(fade, sand_size), SAND_TEX)

	var water_size := WATER_TEX.get_size()
	for poly in _outlines:
		var white := PackedColorArray()
		for i in poly.size():
			white.append(Color.WHITE)
		draw_polygon(poly, white, _world_uvs(poly, water_size), WATER_TEX)

	# Les enfants ne sont pas redessinés par le queue_redraw() du parent (que
	# Fog déclenche à chaque mouvement d'unité) : il faut le relayer.
	if _foam:
		_foam.queue_redraw()

# Bandes d'écume, dessinées dans un nœud à part uniquement pour porter leur
# propre ShaderMaterial animé sans l'appliquer aussi au remplissage d'eau.
class FoamOverlay extends Node2D:
	var layer: Rivers

	func _draw() -> void:
		if layer == null:
			return
		var white := PackedColorArray([
			Color.WHITE, Color.WHITE, Color.WHITE, Color.WHITE,
		])
		for poly in layer.outlines():
			var n := poly.size()
			var inner := Rivers._offset_outline(poly, Rivers.FOAM_WIDTH)
			# UV.x suit la distance parcourue le long du rivage plutôt que de
			# repartir de 0 à chaque segment : sinon l'ondulation du shader se
			# répète à l'identique dans chaque petit segment d'arrondi.
			var travel := 0.0
			for j in n:
				var k := (j + 1) % n
				var seg: float = poly[j].distance_to(poly[k])
				var u0 := travel / GameMap.TILE_W
				var u1 := (travel + seg) / GameMap.TILE_W
				travel += seg
				var quad := PackedVector2Array([poly[j], poly[k], inner[k], inner[j]])
				var uvs := PackedVector2Array([
					Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1), Vector2(u0, 1),
				])
				# La texture ne sert qu'à rendre les UV disponibles au shader,
				# qui écrase entièrement COLOR — son contenu n'est pas lu.
				draw_polygon(quad, white, uvs, Rivers.WATER_TEX)
