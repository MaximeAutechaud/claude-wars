class_name AIPlayer
extends RefCounted

# Renvoie l'ennemi le plus proche (distance Manhattan)
static func find_nearest_enemy(unit: Unit, units_layer: UnitsLayer) -> Unit:
	var nearest: Unit = null
	var best_dist := 999999
	for child in units_layer.get_children():
		if not (child is Unit):
			continue
		var u := child as Unit
		if u.team == unit.team:
			continue
		var d := _manhattan(u.cell, unit.cell)
		if d < best_dist:
			best_dist = d
			nearest = u
	return nearest

# Renvoie la case atteignable la plus proche de target_cell.
# Évite les cases déjà occupées par une autre unité.
static func best_move_towards(unit: Unit, target_cell: Vector2i,
		reachable: Dictionary, units_layer: UnitsLayer) -> Vector2i:
	var best_cell := unit.cell
	var best_dist := _manhattan(unit.cell, target_cell)
	for cell: Vector2i in reachable:
		if cell == unit.cell:
			continue
		if units_layer.get_unit_at(cell) != null:
			continue  # case occupée (allié ou ennemi)
		var d := _manhattan(cell, target_cell)
		if d < best_dist:
			best_dist = d
			best_cell = cell
	return best_cell

static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return abs(a.x - b.x) + abs(a.y - b.y)
