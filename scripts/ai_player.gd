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
# Choisit la cible d'attaque : le héros adverse en priorité, sinon la plus faible
static func pick_attack_target(candidates: Array[Unit]) -> Unit:
	var best: Unit = candidates[0]
	for u: Unit in candidates:
		if u.is_hero():
			return u
		if u.hp < best.hp:
			best = u
	return best

# Cible tuable en un coup (attaque sans riposte + XP), la plus forte d'abord
static func pick_killable_target(unit: Unit, candidates: Array[Unit],
		map: GameMap) -> Unit:
	var best: Unit = null
	for u: Unit in candidates:
		var dmg := maxi(1, unit.atk() - map.get_defense_bonus(u.cell))
		if dmg >= u.hp and (best == null or u.max_hp > best.max_hp):
			best = u
	return best

# Position d'escorte du héros : proche de son armée, hors du contact ennemi.
# Score = coller aux alliés en priorité, puis garder ses distances (plafonnées
# à 3 pour ne pas fuir la carte) ; malus fort pour une case au contact.
static func best_hero_position(unit: Unit, reachable: Dictionary,
		units_layer: UnitsLayer) -> Vector2i:
	var best_cell := unit.cell
	var best_score := -INF
	for cell: Vector2i in reachable:
		if cell != unit.cell and units_layer.get_unit_at(cell) != null:
			continue
		var da := _nearest_ally_dist(cell, unit, units_layer)
		var de := _nearest_enemy_dist(cell, unit.team, units_layer)
		var score := -da * 2.0 + minf(de, 3.0)
		if de <= 1:
			score -= 10.0
		if score > best_score:
			best_score = score
			best_cell = cell
	return best_cell

static func _nearest_ally_dist(cell: Vector2i, unit: Unit,
		units_layer: UnitsLayer) -> float:
	var best := 999999
	for child in units_layer.get_children():
		if child is Unit and child != unit \
				and (child as Unit).team == unit.team \
				and not (child as Unit).is_hero():
			best = mini(best, Pathfinder.distance(cell, (child as Unit).cell))
	return float(best) if best < 999999 else 0.0

# Case atteignable maximisant la distance à l'ennemi le plus proche (repli)
static func best_retreat(unit: Unit, reachable: Dictionary,
		units_layer: UnitsLayer) -> Vector2i:
	var best_cell := unit.cell
	var best_dist := _nearest_enemy_dist(unit.cell, unit.team, units_layer)
	for cell: Vector2i in reachable:
		if cell == unit.cell or units_layer.get_unit_at(cell) != null:
			continue
		var d := _nearest_enemy_dist(cell, unit.team, units_layer)
		if d > best_dist:
			best_dist = d
			best_cell = cell
	return best_cell

static func _nearest_enemy_dist(cell: Vector2i, team: int,
		units_layer: UnitsLayer) -> int:
	var best := 999999
	for child in units_layer.get_children():
		if child is Unit and (child as Unit).team != team:
			best = mini(best, Pathfinder.distance(cell, (child as Unit).cell))
	return best

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
