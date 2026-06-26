class_name UnitsLayer
extends Node2D

@onready var map: GameMap = $"../GameMap"

var reachable_cells: Dictionary = {}
var attack_cells: Dictionary = {}   # cases hors portée de mouvement mais attaquables
var _show_attack_zone := false

const HIGHLIGHT        := Color(0.35, 0.65, 1.0, 0.40)
const ATTACK_HIGHLIGHT := Color(1.0,  0.25, 0.25, 0.35)

const BASE_DAMAGE    := 3
const COUNTER_DAMAGE := 2

var _unit_scene: PackedScene = preload("res://scenes/unit.tscn")

func _ready() -> void:
	y_sort_enabled = true
	_spawn_test_units()

func _spawn_test_units() -> void:
	spawn(Vector2i(1, 1), 0, 3)
	spawn(Vector2i(10, 8), 1, 3)

func spawn(cell: Vector2i, team: int, mp: int) -> Unit:
	var u: Unit = _unit_scene.instantiate()
	u.team = team
	u.movement_points = mp
	u.cell = cell
	add_child(u)
	u.position = to_local(map.to_global(map.map_to_local(cell)))
	u.remaining_mp = mp
	return u

func get_unit_at(cell: Vector2i) -> Unit:
	for child in get_children():
		if child is Unit and (child as Unit).cell == cell:
			return child as Unit
	return null

func show_reachable(unit: Unit) -> void:
	var candidates: Dictionary = Pathfinder.get_reachable(unit.cell, unit.remaining_mp, map)
	for child in get_children():
		if child is Unit and child != unit:
			candidates.erase((child as Unit).cell)
	reachable_cells = candidates

	# Cases adjacentes à la zone de mouvement mais hors portée : zone d'attaque exclusive
	attack_cells.clear()
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

func get_adjacent_enemies(unit: Unit) -> Array[Unit]:
	var enemies: Array[Unit] = []
	for nb in Pathfinder.get_neighbors(unit.cell):
		var u := get_unit_at(nb)
		if u != null and u.team != unit.team:
			enemies.append(u)
	return enemies

func do_combat(attacker: Unit, defender: Unit) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	var atk_dmg := maxi(1, BASE_DAMAGE - map.get_defense_bonus(defender.cell))
	defender.hp -= atk_dmg
	print("Attaque : -%d PV  →  défenseur à %d PV" % [atk_dmg, defender.hp])
	defender.queue_redraw()

	if defender.hp <= 0:
		print("Défenseur éliminé !")
		defender.queue_free()
		return

	# Contre-attaque pondérée par les PV restants du défenseur
	var ratio := defender.hp / float(defender.max_hp)
	var def_dmg := maxi(1, roundi((COUNTER_DAMAGE - map.get_defense_bonus(attacker.cell)) * ratio))
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
			u.remaining_mp = u.movement_points
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
		_draw_diamond(map_to_screen(cell), hw, hh, HIGHLIGHT)

	if _show_attack_zone:
		for cell: Vector2i in attack_cells:
			_draw_diamond(map_to_screen(cell), hw, hh, ATTACK_HIGHLIGHT)

func map_to_screen(cell: Vector2i) -> Vector2:
	return to_local(map.to_global(map.map_to_local(cell)))

func _draw_diamond(p: Vector2, hw: float, hh: float, color: Color) -> void:
	draw_colored_polygon(PackedVector2Array([
		p + Vector2(0,  -hh),
		p + Vector2(hw,   0),
		p + Vector2(0,   hh),
		p + Vector2(-hw,  0),
	]), color)
