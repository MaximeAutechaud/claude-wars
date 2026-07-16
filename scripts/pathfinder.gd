class_name Pathfinder

# Retourne un dict { Vector2i cell -> int cost } pour toutes les cases
# atteignables depuis `start` avec `mp` points de mouvement.
# Les coûts de terrain dépendent du type d'unité (Unit.STATS).
# Dijkstra simplifié — cartes petites, pas besoin de priority queue.
#
# `ctx` (optionnel, construit par UnitsLayer.move_context) applique la
# zone de contrôle façon Wesnoth (décision 14) :
# - "blocked" : cases occupées par un ennemi — infranchissables ;
# - "zoc"     : cases voisines d'un ennemi — on peut y entrer, mais le
#   mouvement s'y arrête (la case n'est pas étendue, sauf la case de départ :
#   on peut toujours SORTIR d'une zone de contrôle).
static func get_reachable(start: Vector2i, mp: int, map: GameMap,
		unit_type: Unit.Type = Unit.Type.INFANTRY, ctx: Dictionary = {}) -> Dictionary:
	var costs: Dictionary = Unit.STATS[unit_type]["costs"]
	var zoc: Dictionary = ctx.get("zoc", {})
	var blocked: Dictionary = ctx.get("blocked", {})
	var dist := { start: 0 }
	var open: Array[Vector2i] = [start]

	while not open.is_empty():
		# Pop la case au coût minimal (scan linéaire)
		var best_idx := 0
		for i in open.size():
			if dist[open[i]] < dist[open[best_idx]]:
				best_idx = i
		var cell: Vector2i = open[best_idx]
		open.remove_at(best_idx)

		# Entrer en zone de contrôle ennemie stoppe le mouvement
		if cell != start and zoc.has(cell):
			continue

		var cur_cost: int = dist[cell]

		for nb in get_neighbors(cell):
			if not map.is_in_bounds(nb) or blocked.has(nb):
				continue
			var move_cost: int = costs.get(map.get_terrain(nb), 99)
			if move_cost >= 99:
				continue
			var new_cost := cur_cost + move_cost
			if new_cost <= mp and (not dist.has(nb) or new_cost < dist[nb]):
				dist[nb] = new_cost
				open.append(nb)

	return dist

# Grille hexagonale flat-top, colonnes impaires décalées vers le bas
# (odd-q, aligné sur le TileSet Godot : offset axis vertical).
static func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	var odd := cell.x & 1
	return [
		cell + Vector2i(0, -1),           # N
		cell + Vector2i(0,  1),           # S
		cell + Vector2i(1, -1 + odd),     # NE
		cell + Vector2i(1,  odd),         # SE
		cell + Vector2i(-1, -1 + odd),    # NO
		cell + Vector2i(-1, odd),         # SO
	]

# Toutes les cases à distance <= r de center (center inclus)
static func cells_in_range(center: Vector2i, r: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for dx in range(-r, r + 1):
		for dy in range(-r, r + 1):
			var cell := center + Vector2i(dx, dy)
			if distance(center, cell) <= r:
				out.append(cell)
	return out

# Distance hexagonale (en nombre de cases), via coordonnées cubiques
static func distance(a: Vector2i, b: Vector2i) -> int:
	var ar := a.y - (a.x - (a.x & 1)) / 2
	var br := b.y - (b.x - (b.x & 1)) / 2
	var dq := b.x - a.x
	var dr := br - ar
	return (absi(dq) + absi(dr) + absi(dq + dr)) / 2
