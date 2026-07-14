class_name UnitsLayer
extends Node2D

# Émis à chaque unité tuée (combat, riposte ou sort) — sert à détecter
# les camps de bandits vaincus (libération du prisonnier)
signal unit_killed(victim: Unit, killer: Unit)

@onready var map: GameMap = $"../GameMap"
@onready var villages: Villages = get_node_or_null("../Villages")
@onready var fog: Fog = get_node_or_null("../Fog")

var reachable_cells: Dictionary = {}
var attack_cells: Dictionary = {}   # cases hors portée de mouvement mais attaquables
var spell_cells: Dictionary = {}    # cibles valides du sort en cours de visée
var _show_attack_zone := false

const HIGHLIGHT        := Color(0.35, 0.65, 1.0, 0.40)
const ATTACK_HIGHLIGHT := Color(1.0,  0.25, 0.25, 0.35)
const SPELL_HIGHLIGHT  := Color(0.65, 0.35, 1.0, 0.45)

var _unit_scene: PackedScene = preload("res://scenes/unit.tscn")

func _ready() -> void:
	y_sort_enabled = true
	_spawn_armies()

func _spawn_armies() -> void:
	# Joueur (bleu) — coin haut-gauche
	spawn(Vector2i(1, 3), 0, Unit.Type.HERO)
	spawn(Vector2i(1, 1), 0, Unit.Type.INFANTRY)
	spawn(Vector2i(2, 3), 0, Unit.Type.INFANTRY)
	spawn(Vector2i(1, 4), 0, Unit.Type.TANK)
	spawn(Vector2i(0, 2), 0, Unit.Type.ARCHER)

	# IA (rouge) — coin bas-droit
	spawn(Vector2i(10, 6), 1, Unit.Type.HERO)
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
	if fog:
		fog.recompute()
	return u

# Héros vivant d'une équipe, ou null s'il est mort
func get_hero(team: int) -> Unit:
	for child in get_children():
		if child is Unit and not child.is_queued_for_deletion():
			var u := child as Unit
			if u.team == team and u.is_hero():
				return u
	return null

# Comptabilise un kill : compteur de vétérance du tueur, XP au héros du
# camp du tueur (2 s'il a tué lui-même, 1 sinon) + signal unit_killed
func _on_kill(victim: Unit, killer: Unit) -> void:
	killer.add_kill()
	var hero := get_hero(killer.team)
	if hero != null:
		hero.add_xp(2 if killer == hero else 1)
	unit_killed.emit(victim, killer)
	if fog:
		fog.recompute()

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
		for target in Pathfinder.cells_in_range(unit.cell, r):
			if target != unit.cell and map.is_in_bounds(target):
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
	spell_cells.clear()
	_show_attack_zone = false
	queue_redraw()

func show_spell_targets(cells: Array[Vector2i]) -> void:
	reachable_cells.clear()
	attack_cells.clear()
	spell_cells.clear()
	for cell in cells:
		spell_cells[cell] = true
	queue_redraw()

# Applique l'effet du sort et arme son cooldown
func cast_spell(caster: Unit, id: String, target_cell: Vector2i) -> void:
	var def: Dictionary = Spells.POOL[id]
	print("%s lance %s" % [caster.unit_name(), def["name"]])
	match id:
		"heal":
			var t := get_unit_at(target_cell)
			if t != null:
				t.hp = mini(t.hp + Spells.HEAL_AMOUNT, t.max_hp)
				t.queue_redraw()
		"fireball":
			for cell in Pathfinder.cells_in_range(target_cell, Spells.FIREBALL_RADIUS):
				var u := get_unit_at(cell)
				if u == null:
					continue
				u.hp -= Spells.FIREBALL_DAMAGE
				u.queue_redraw()
				print("  %s touché : -%d PV → %d PV" % [u.unit_name(), Spells.FIREBALL_DAMAGE, u.hp])
				if u.hp <= 0:
					u.queue_free()
					if u.team != caster.team:
						_on_kill(u, caster)
		"blink":
			caster.cell = target_cell
			caster.position = to_local(map.to_global(map.map_to_local(target_cell)))
			if villages:
				villages.try_capture(caster)
		"warcry":
			for cell in Pathfinder.cells_in_range(caster.cell, Spells.WARCRY_RADIUS):
				var u := get_unit_at(cell)
				if u != null and u.team == caster.team and u != caster:
					u.temp_atk_bonus = Spells.WARCRY_BONUS
					u.queue_redraw()
	caster.cooldowns[id] = def["cooldown"]
	caster.has_cast = true
	caster.queue_redraw()
	if fog:
		fog.recompute()   # Bond déplace le lanceur, la vision bouge

# Ennemis attaquables par `unit` depuis sa case (distance <= portée).
# Le joueur ne peut viser que ce qu'il voit ; l'IA et les creeps voient tout.
func get_enemies_in_range(unit: Unit) -> Array[Unit]:
	var enemies: Array[Unit] = []
	for child in get_children():
		if not (child is Unit):
			continue
		var u := child as Unit
		if u.team == unit.team:
			continue
		if unit.team == Fog.PLAYER_TEAM and fog and not fog.is_visible_now(u.cell):
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
		_on_kill(defender, attacker)
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
		_on_kill(attacker, defender)

func reset_team(team: int) -> void:
	for child in get_children():
		if child is Unit and (child as Unit).team == team:
			var u := child as Unit
			u.has_moved = false
			u.has_cast = false
			u.remaining_mp = u.movement_points()
			u.temp_atk_bonus = 0
			for id in u.cooldowns:
				u.cooldowns[id] = maxi(0, u.cooldowns[id] - 1)
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
	if villages:
		villages.try_capture(unit)
	if fog:
		fog.recompute()
	clear_reachable()

func _draw() -> void:
	if not map.tile_set:
		return
	var hw := map.tile_set.tile_size.x * 0.5
	var hh := map.tile_set.tile_size.y * 0.5

	for cell: Vector2i in reachable_cells:
		_draw_hex(map_to_screen(cell), hw, hh, HIGHLIGHT)

	if _show_attack_zone:
		for cell: Vector2i in attack_cells:
			_draw_hex(map_to_screen(cell), hw, hh, ATTACK_HIGHLIGHT)

	for cell: Vector2i in spell_cells:
		_draw_hex(map_to_screen(cell), hw, hh, SPELL_HIGHLIGHT)

func map_to_screen(cell: Vector2i) -> Vector2:
	return to_local(map.to_global(map.map_to_local(cell)))

func _draw_hex(p: Vector2, hw: float, hh: float, color: Color) -> void:
	draw_colored_polygon(GameMap.hex_corners(p, hw, hh), color)
