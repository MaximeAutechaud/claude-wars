class_name AIPlayer
extends RefCounted

# Renvoie l'ennemi le plus proche (distance en cases)
static func find_nearest_enemy(unit: Unit, units_layer: UnitsLayer) -> Unit:
	var nearest: Unit = null
	var best_dist := 999999
	for child in units_layer.get_children():
		if not (child is Unit):
			continue
		var u := child as Unit
		if u.team == unit.team:
			continue
		var d := Pathfinder.distance(u.cell, unit.cell)
		if d < best_dist:
			best_dist = d
			nearest = u
	return nearest

# Renvoie la case atteignable idéale pour attaquer target_cell :
# vise une distance égale à la portée de l'unité (un archer garde ses
# distances, une unité de mêlée vient au contact). À écart de portée égal,
# préfère la case la plus éloignée (plus sûre).
# Évite les cases déjà occupées par une autre unité.
static func best_move_towards(unit: Unit, target_cell: Vector2i,
		reachable: Dictionary, units_layer: UnitsLayer) -> Vector2i:
	var r := unit.attack_range()
	var best_cell := unit.cell
	var best_gap := absi(Pathfinder.distance(unit.cell, target_cell) - r)
	var best_d := Pathfinder.distance(unit.cell, target_cell)
	for cell: Vector2i in reachable:
		if cell == unit.cell:
			continue
		if units_layer.get_unit_at(cell) != null:
			continue  # case occupée (allié ou ennemi)
		var d := Pathfinder.distance(cell, target_cell)
		var gap := absi(d - r)
		if gap < best_gap or (gap == best_gap and d > best_d):
			best_gap = gap
			best_d = d
			best_cell = cell
	return best_cell
