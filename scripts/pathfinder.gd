class_name Pathfinder

# Retourne un dict { Vector2i cell -> int cost } pour toutes les cases
# atteignables depuis `start` avec `mp` points de mouvement.
# Dijkstra simplifié — cartes petites, pas besoin de priority queue.
static func get_reachable(start: Vector2i, mp: int, map: GameMap) -> Dictionary:
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

		var cur_cost: int = dist[cell]

		for nb in get_neighbors(cell):
			if not map.is_in_bounds(nb):
				continue
			var move_cost := map.get_movement_cost(nb)
			if move_cost >= 99:
				continue
			var new_cost := cur_cost + move_cost
			if new_cost <= mp and (not dist.has(nb) or new_cost < dist[nb]):
				dist[nb] = new_cost
				open.append(nb)

	return dist

static func get_neighbors(cell: Vector2i) -> Array[Vector2i]:
	return [
		cell + Vector2i( 1,  0),
		cell + Vector2i(-1,  0),
		cell + Vector2i( 0,  1),
		cell + Vector2i( 0, -1),
	]
