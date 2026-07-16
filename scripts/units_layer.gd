class_name UnitsLayer
extends Node2D

# Émis à chaque unité tuée (combat, riposte ou sort) — sert à détecter
# les camps de bandits vaincus (libération du prisonnier)
signal unit_killed(victim: Unit, killer: Unit)

# Émis par les mécaniques de boss (boss.gd) : sacrifice, malédiction…
signal boss_event(cell: Vector2i, text: String)

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
const DOOM_FILL        := Color(0.55, 0.1, 0.75, 0.28)
const DOOM_EDGE        := Color(0.78, 0.25, 0.95, 0.9)

var _unit_scene: PackedScene = preload("res://scenes/unit.tscn")

func _ready() -> void:
	y_sort_enabled = true
	_spawn_armies()

# Armées de départ décrites par le scénario courant (décision 12 : l'IA
# reçoit son armée complète à la création, elle ne recrute pas).
# Une armée peut être menée par un boss ("type": "boss", "name": …) :
# c'est alors lui le chef à abattre.
func _spawn_armies() -> void:
	var armies: Dictionary = Scenario.CURRENT["armies"]
	for team: int in armies:
		for udef: Dictionary in armies[team]:
			var u := spawn(udef["cell"], team, Unit.TYPE_BY_ID[udef["type"]])
			if udef.has("name"):
				u.display_name = udef["name"]
			if u.is_boss():
				u.scale = Vector2(1.35, 1.35)

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

# Chef d'une équipe : son héros, sinon son boss. Le perdre = défaite
# (victoire par assassinat, décision 2).
func get_leader(team: int) -> Unit:
	var boss: Unit = null
	for child in get_children():
		if child is Unit and not child.is_queued_for_deletion():
			var u := child as Unit
			if u.team != team:
				continue
			if u.is_hero():
				return u
			if u.is_boss():
				boss = u
	return boss

# Comptabilise un kill : compteur de vétérance du tueur, XP au héros du
# camp du tueur (2 s'il a tué lui-même, 1 sinon ; abattre un boss rapporte
# BOSS_XP_BONUS de plus) + signal unit_killed
func _on_kill(victim: Unit, killer: Unit) -> void:
	killer.add_kill()
	var hero := get_hero(killer.team)
	if hero != null:
		var xp := 2 if killer == hero else 1
		if victim.is_boss():
			xp += Unit.BOSS_XP_BONUS
		hero.add_xp(xp)
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

# Contexte de déplacement pour la zone de contrôle (décision 14) :
# - "blocked" : cases occupées par un ennemi (infranchissables) ;
# - "zoc"     : cases voisines d'un ennemi (le mouvement s'y arrête).
# Pour le joueur, seuls les ennemis VISIBLES comptent — un ennemi caché dans
# le brouillard ne doit pas trahir sa position en déformant la zone bleue.
func move_context(unit: Unit) -> Dictionary:
	var zoc: Dictionary = {}
	var blocked: Dictionary = {}
	for child in get_children():
		if not (child is Unit) or child.is_queued_for_deletion():
			continue
		var u := child as Unit
		if u.team == unit.team:
			continue
		if unit.team == Fog.PLAYER_TEAM and fog and not fog.is_visible_now(u.cell):
			continue
		blocked[u.cell] = true
		for nb in Pathfinder.get_neighbors(u.cell):
			zoc[nb] = true
	return { "zoc": zoc, "blocked": blocked }

func show_reachable(unit: Unit) -> void:
	var candidates: Dictionary = Pathfinder.get_reachable(
			unit.cell, unit.remaining_mp, map, unit.type, move_context(unit))
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
	caster.defending = false   # lancer un sort casse la posture Défendre
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
			# Atterrir en zone de contrôle ennemie coupe le mouvement restant
			if (move_context(caster)["zoc"] as Dictionary).has(target_cell):
				caster.remaining_mp = 0
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

# Défense totale d'une unité : terrain + posture Défendre
func defense_of(u: Unit) -> int:
	return map.get_defense_bonus(u.cell) + (Unit.DEFEND_BONUS if u.defending else 0)

func attack_damage(attacker: Unit, defender: Unit) -> int:
	return maxi(1, attacker.atk() - defense_of(defender))

# Riposte : 0 si le défenseur n'a pas la portée, sinon pondérée par les PV
# qui lui resteraient après le coup
func counter_damage(attacker: Unit, defender: Unit, defender_hp_after: int) -> int:
	if Pathfinder.distance(attacker.cell, defender.cell) > defender.attack_range():
		return 0
	var ratio := defender_hp_after / float(defender.max_hp)
	return maxi(1, roundi((defender.counter_atk() - defense_of(attacker)) * ratio))

# Prévision exacte d'un combat (le combat est déterministe — décision 8) :
# { damage, kill, counter, death }. Partage les mêmes calculs que do_combat.
func preview_combat(attacker: Unit, defender: Unit) -> Dictionary:
	var dmg := attack_damage(attacker, defender)
	var hp_after := defender.hp - dmg
	var out := { "damage": dmg, "kill": hp_after <= 0, "counter": 0, "death": false }
	if hp_after > 0:
		out["counter"] = counter_damage(attacker, defender, hp_after)
		out["death"] = attacker.hp - int(out["counter"]) <= 0
	return out

func do_combat(attacker: Unit, defender: Unit) -> void:
	if not is_instance_valid(attacker) or not is_instance_valid(defender):
		return

	attacker.defending = false   # attaquer casse la posture Défendre
	var atk_dmg := attack_damage(attacker, defender)
	defender.hp -= atk_dmg
	print("%s attaque %s : -%d PV  →  défenseur à %d PV"
			% [attacker.unit_name(), defender.unit_name(), atk_dmg, defender.hp])
	defender.queue_redraw()
	attacker.queue_redraw()

	if defender.hp <= 0:
		print("Défenseur éliminé !")
		defender.queue_free()
		_on_kill(defender, attacker)
		return

	# Contre-attaque : seulement si le défenseur a la portée pour riposter,
	# pondérée par ses PV restants
	var def_dmg := counter_damage(attacker, defender, defender.hp)
	if def_dmg == 0:
		print("Pas de riposte (hors de portée)")
		return
	attacker.hp -= def_dmg
	print("Contre-attaque : -%d PV  →  attaquant à %d PV" % [def_dmg, attacker.hp])
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
	unit.defending = false   # bouger casse la posture Défendre
	unit.cell = target
	unit.remaining_mp -= actual_cost
	# Finir en zone de contrôle ennemie stoppe net le mouvement (décision 14)
	if (move_context(unit)["zoc"] as Dictionary).has(target):
		unit.remaining_mp = 0
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

	# Zones maudites télégraphiées par les boss (sous les unités)
	for child in get_children():
		if not (child is Unit) or not (child as Unit).doom_armed:
			continue
		for cell: Vector2i in (child as Unit).doom_cells:
			if fog and not fog.is_explored(cell):
				continue
			var pts := GameMap.hex_corners(map_to_screen(cell), hw - 2.0, hh - 2.0)
			draw_colored_polygon(pts, DOOM_FILL)
			pts.append(pts[0])
			draw_polyline(pts, DOOM_EDGE, 2.0)

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
