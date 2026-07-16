class_name Fog
extends Node2D

# Brouillard de guerre du joueur (l'IA voit tout mais joue attentiste —
# décision 13/14 de DESIGN.md) :
# - voile noir  : cases jamais explorées, terrain caché
# - brouillard gris : cases explorées hors de vue — terrain et bâtiments
#   visibles, unités ennemies/creeps cachées
# La vision d'équipe est l'union des visions des unités du joueur
# (rayon "vision" de Unit.STATS), recalculée à chaque changement du plateau.

const SHROUD_COLOR := Color(0.07, 0.08, 0.10, 1.0)
const FOG_COLOR := Color(0.08, 0.09, 0.12, 0.45)

const PLAYER_TEAM := 0

@onready var map: GameMap = $"../GameMap"
@onready var units_layer: UnitsLayer = $"../UnitsLayer"
@onready var villages: Villages = get_node_or_null("../Villages")
@onready var creeps: Creeps = get_node_or_null("../Creeps")

var explored: Dictionary = {}      # cases vues au moins une fois
var visible_now: Dictionary = {}   # cases dans la vision actuelle

func is_visible_now(cell: Vector2i) -> bool:
	return visible_now.has(cell)

func is_explored(cell: Vector2i) -> bool:
	return explored.has(cell)

# À appeler après tout changement du plateau (déplacement, spawn, mort…)
func recompute() -> void:
	if not is_node_ready():
		return   # spawns initiaux : main._ready fera le premier recompute
	visible_now.clear()
	for child in units_layer.get_children():
		if not (child is Unit) or child.is_queued_for_deletion():
			continue
		var u := child as Unit
		if u.team != PLAYER_TEAM:
			continue
		for cell in Pathfinder.cells_in_range(u.cell, u.vision()):
			if map.is_in_bounds(cell):
				visible_now[cell] = true
				explored[cell] = true

	# Les unités non joueur ne sont affichées que dans la vision actuelle
	for child in units_layer.get_children():
		if child is Unit:
			var u := child as Unit
			u.visible = u.team == PLAYER_TEAM or visible_now.has(u.cell)

	queue_redraw()
	if villages:
		villages.queue_redraw()
	if creeps:
		creeps.queue_redraw()

func _draw() -> void:
	var hw := GameMap.TILE_W * 0.5 + 0.5
	var hh := GameMap.TILE_H * 0.5 + 0.5
	var size := map.get_map_size()
	for col in size.x:
		for row in size.y:
			var cell := Vector2i(col, row)
			if visible_now.has(cell):
				continue
			var p := to_local(map.to_global(map.map_to_local(cell)))
			var color := FOG_COLOR if explored.has(cell) else SHROUD_COLOR
			draw_colored_polygon(GameMap.hex_corners(p, hw, hh), color)
