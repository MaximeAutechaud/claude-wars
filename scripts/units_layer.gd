class_name UnitsLayer
extends Node2D

@onready var map: GameMap = $"../GameMap"

var reachable_cells: Dictionary = {}
var attack_cells: Dictionary = {}   # cases hors portée de mouvement mais attaquables
var _show_attack_zone := false

const HIGHLIGHT        := Color(0.35, 0.65, 1.0, 0.40)
const ATTACK_HIGHLIGHT := Color(1.0,  0.25, 0.25, 0.35)

var _unit_scene: PackedScene = preload("res://scenes/unit.tscn")

func _ready() -> void:
	y_sort_enabled = true
	_spawn_armies()

func _spawn_armies() -> void:
	# Joueur (bleu) — coin haut-gauche
	spawn(Vector2i(1, 1), 0, Unit.Type.INFANTRY)
	spawn(Vector2i(2, 3), 0, Unit.Type.INFANTRY)
	spawn(Vector2i(1, 4), 0, Unit.Type.TANK)
	spawn(Vector2i(0, 2), 0, Unit.Type.ARCHER)

	# IA (rouge) — coin bas-droit
	spawn(Vector2i(10, 8), 1, Unit.Type.INFANTRY)
	spawn(Vector2i(9, 6),  1, Unit.Type.INFANTRY)
	spawn(Vector2i(10, 5), 1, Unit.Type.TANK)
	spawn(Vector2i(11, 7), 1, Unit.Type.ARCHER)

func spawn(cell: Vector2i, team: int, type: Unit.Type) -> Unit:
	var u: Unit = _unit_scene.instantiate()
	u.setup(type, team)
	u.cell = cell
	add_child(u)
	u.position = to_local(map.to_global(map.map_to_local(cell)))
	return u

# Unités vivantes d'une équipe (ignore celles en cours de suppression)
func count_team(team: int) -> int:
	var n := 0
	for child in get_children():
		if child is Unit and not child.is_queued_for_deletion() \
				and (child as Unit).team == team:
			n += 1
	return n

func get_unit_at(cell: Vector2i) -> Unit:
	for child in get_children():
		if child is Unit and (child as Unit).cell == cell:
			return child as Unit
	return null

func show_reachable(unit: Unit) -> void:
	var candidates: Dictionary = Pathfinder.get_reachable(
			unit.cell, unit.remaining_mp, map, unit.type)
	for child in get_children():
		if child is Unit and child != unit:
			candidates.erase((child as Unit).cell)
	reachable_cells = candidates

	# Zone d'attaque :
	# - unité à distance : losange de portée autour de la case ACTUELLE
	#   (elle tire d'où elle est, pas après déplacement)
	# - mêlée : cases attaquables après déplacement (bordure de la zone de mouvement)
	attack_cells.clear()
	var r := unit.attack_range()
	if r > 1:
		for dx in range(-r, r + 1):
			for dy in range(-r, r + 1):
				var target := unit.cell + Vector2i(dx, dy)
				if target != unit.cell and map.is_in_bounds(target) \
						and Pathfinder.distance(unit.cell, target) <= r:
					attack_cells[target] = true
	else:
		for cell: Vector2i in reachable_cells:
			for nb in Pathfinder.get_neighbors(cell):
				if not reachable_cells.has(nb) and map.is_in_bounds(nb):
					attack_cells[nb] = true

	_show_attack_zone = false
	queue_redraw()

func toggle_attack_zone() -> void:
	_show_attack_zone = not _show_attack_zone
	queue_redraw()

func clear_reachable() -> void:
	reachable_cells.clear()
	attack_cells.clear()
	_show_attack_zone = false
	queue_redraw()

# Ennemis attaquables par `unit` depuis sa case (distance Manhattan <= portée)
func get_enemies_in_range(unit: Unit) -> Array[Unit]:
	var enemies: Array[Unit] = []
	for child in get_children():
		if not (child is Unit):
			continue
		var u := child as Unit
		if u.team == unit.team:
			continue
		var d := Pathfinder.distance(unit.cell, u.cell)
		if d >= 1 and d <= unit.attack_range():
			enemies.append(u)
	return enemies

func do_combat(attacker: Unit, defender: Unit) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	var dist := Pathfinder.distance(attacker.cell, defender.cell)
	var atk_dmg := maxi(1, attacker.atk() - map.get_defense_bonus(defender.cell))
	defender.hp -= atk_dmg
	print("%s attaque %s : -%d PV  →  défenseur à %d PV"
			% [attacker.unit_name(), defender.unit_name(), atk_dmg, defender.hp])
	defender.queue_redraw()

	if defender.hp <= 0:
		print("Défenseur éliminé !")
		defender.queue_free()
		return

	# Contre-attaque : seulement si le défenseur a la portée pour riposter,
	# pondérée par ses PV restants
	if dist > defender.attack_range():
		print("Pas de riposte (hors de portée)")
		return
	var ratio := defender.hp / float(defender.max_hp)
	var def_dmg := maxi(1, roundi((defender.counter_atk() - map.get_defense_bonus(attacker.cell)) * ratio))
	attacker.hp -= def_dmg
	print("Contre-attaque : -%d PV (ratio %.2f)  →  attaquant à %d PV" % [def_dmg, ratio, attacker.hp])
	attacker.queue_redraw()

	if attacker.hp <= 0:
		print("Attaquant éliminé !")
		attacker.queue_free()

func reset_team(team: int) -> void:
	for child in get_children():
		if child is Unit and (child as Unit).team == team:
			var u := child as Unit
			u.has_moved = false
			u.remaining_mp = u.movement_points()
			u.queue_redraw()

# cost = -1 → lu depuis reachable_cells (flow joueur)
# cost >= 0 → fourni par l'appelant (flow IA)
func move_unit(unit: Unit, target: Vector2i, cost: int = -1) -> void:
	var actual_cost: int = reachable_cells.get(target, 0) if cost < 0 else cost
	unit.cell = target
	unit.remaining_mp -= actual_cost
	unit.has_moved = (unit.remaining_mp == 0)
	unit.position = to_local(map.to_global(map.map_to_local(target)))
	unit.queue_redraw()
	clear_reachable()

func _draw() -> void:
	if reachable_cells.is_empty() or not map.tile_set:
		return
	var hw := map.tile_set.tile_size.x * 0.5
	var hh := map.tile_set.tile_size.y * 0.5

	for cell: Vector2i in reachable_cells:
		_draw_hex(map_to_screen(cell), hw, hh, HIGHLIGHT)

	if _show_attack_zone:
		for cell: Vector2i in attack_cells:
			_draw_hex(map_to_screen(cell), hw, hh, ATTACK_HIGHLIGHT)

func map_to_screen(cell: Vector2i) -> Vector2:
	return to_local(map.to_global(map.map_to_local(cell)))

func _draw_hex(p: Vector2, hw: float, hh: float, color: Color) -> void:
	draw_colored_polygon(GameMap.hex_corners(p, hw, hh), color)
