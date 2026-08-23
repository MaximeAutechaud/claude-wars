class_name Rivers
extends Node2D

# Même principe que Roads (voir ce fichier) : un ruban de matière plutôt
# qu'une tuile par configuration de voisinage. La rivière est bien plus
# large (quasi toute la case, juste un peu de berge — l'herbe de la
# plaine — visible aux coins) puisqu'elle occupe tout l'hexagone
# contrairement au filet étroit de la route.

const RIBBON_HALF_WIDTH := 23.0
const HUB_SIDES := 12

@onready var map: GameMap = $"../GameMap"
@onready var fog: Fog = get_node_or_null("../Fog")

var _tex: Texture2D = preload("res://assets/tiles/river.png")
var _cells: Array[Vector2i] = []

func _ready() -> void:
	for col in map.map_size.x:
		for row in map.map_size.y:
			var c := Vector2i(col, row)
			if map.get_terrain(c) == GameMap.Terrain.RIVER:
				_cells.append(c)
	queue_redraw()

func _draw() -> void:
	var hw := GameMap.TILE_W * 0.5
	var hh := GameMap.TILE_H * 0.5
	for cell in _cells:
		if fog and not fog.is_explored(cell):
			continue
		_draw_cell(cell, hw, hh)

func _draw_cell(cell: Vector2i, hw: float, hh: float) -> void:
	var center := to_local(map.to_global(map.map_to_local(cell)))
	var corners := GameMap.hex_corners(center, hw, hh)
	var mids: Array[Vector2] = []
	for i in 6:
		mids.append((corners[i] + corners[(i + 1) % 6]) * 0.5)

	var connected: Array[Vector2] = []
	for n in Pathfinder.get_neighbors(cell):
		if map.get_terrain(n) != GameMap.Terrain.RIVER:
			continue
		var dir := (to_local(map.to_global(map.map_to_local(n))) - center).normalized()
		var best_i := 0
		var best_dot := -INF
		for i in 6:
			var d := (mids[i] - center).normalized().dot(dir)
			if d > best_dot:
				best_dot = d
				best_i = i
		connected.append(mids[best_i])

	for mid in connected:
		_draw_stub(center, mid)
	_draw_hub(center)

func _draw_stub(center: Vector2, mid: Vector2) -> void:
	var dir := (mid - center).normalized()
	var perp := Vector2(-dir.y, dir.x) * RIBBON_HALF_WIDTH
	var pts := PackedVector2Array([
		center - perp, center + perp, mid + perp, mid - perp,
	])
	var uvs := PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1),
	])
	var white := Color.WHITE
	draw_polygon(pts, PackedColorArray([white, white, white, white]), uvs, _tex)

func _draw_hub(center: Vector2) -> void:
	var r := RIBBON_HALF_WIDTH
	var pts := PackedVector2Array()
	var uvs := PackedVector2Array()
	var colors := PackedColorArray()
	for i in HUB_SIDES:
		var a := TAU * i / float(HUB_SIDES)
		var offset := Vector2(cos(a), sin(a))
		pts.append(center + offset * r)
		uvs.append(Vector2(0.5, 0.5) + offset * 0.5)
		colors.append(Color.WHITE)
	draw_polygon(pts, colors, uvs, _tex)
