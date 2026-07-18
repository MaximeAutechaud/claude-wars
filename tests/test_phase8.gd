extends Node

# Test headless de la phase 8 (vétérance) :
#   Godot --headless --path . res://tests/test_phase8.tscn
# Vérifie : promotion à 3 kills (+1 atk, +2 PV max remplis), héros exclu,
# creeps éligibles, nom « vétéran ».

var failures := 0

func check(cond: bool, label: String) -> void:
	if cond:
		print("OK   — " + label)
	else:
		failures += 1
		printerr("FAIL — " + label)

func _ready() -> void:
	var main: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().process_frame

	var units: UnitsLayer = main.get_node("UnitsLayer")
	var creeps: Creeps = main.get_node("Creeps")
	var map: GameMap = main.get_node("GameMap")

	# ── Promotion d'une infanterie joueur après 3 kills ──────────────────
	var attacker := units.spawn(Vector2i(8, 8), 0, Unit.Type.INFANTRY)
	var cells: Array[Vector2i] = [Vector2i(8, 9), Vector2i(9, 8), Vector2i(7, 8)]
	for i in 3:
		if i == 2:
			attacker.hp = 5   # usé avant le 3e kill, pour tester le remplissage
			check(not attacker.veteran, "pas encore vétéran à %d kill(s)" % attacker.kills)
		var victim := units.spawn(cells[i], 1, Unit.Type.INFANTRY)
		victim.hp = 1
		units.do_combat(attacker, victim)
		await get_tree().process_frame
	check(attacker.veteran, "vétéran après %d kills" % Unit.VETERAN_KILLS)
	check(attacker.max_hp == Unit.STATS[Unit.Type.INFANTRY]["max_hp"] + Unit.VETERAN_HP,
			"+%d PV max" % Unit.VETERAN_HP)
	check(attacker.hp == 5 + Unit.VETERAN_HP, "les PV de promotion arrivent remplis")
	check(attacker.atk() == Unit.STATS[Unit.Type.INFANTRY]["atk"] + Unit.VETERAN_ATK,
			"+%d atk" % Unit.VETERAN_ATK)
	check(attacker.unit_name() == "Guerrier vétéran", "nom « Guerrier vétéran »")

	# ── Le héros est exclu (il a ses niveaux d'XP) ───────────────────────
	var hero := units.get_hero(0)
	var v := units.spawn(Vector2i(9, 9), 1, Unit.Type.INFANTRY)
	v.hp = 1
	units.do_combat(hero, v)
	await get_tree().process_frame
	check(hero.kills == 0 and not hero.veteran, "le héros ne cumule pas de vétérance")

	# ── Un creep peut devenir vétéran (« ne nourris pas le camp ») ───────
	var creep: Unit = creeps.alive_units(creeps.camps[0])[0]
	var prey_cells: Array[Vector2i] = []
	for nb in Pathfinder.get_neighbors(creep.cell):
		if prey_cells.size() < 3 and map.is_in_bounds(nb) \
				and units.get_unit_at(nb) == null:
			prey_cells.append(nb)
	for cell in prey_cells:
		var prey := units.spawn(cell, 0, Unit.Type.INFANTRY)
		prey.hp = 1
		units.do_combat(creep, prey)
		await get_tree().process_frame
	check(creep.veteran, "un creep passe vétéran après 3 kills")
	check(creep.unit_name() == "Bandit — Guerrier vétéran", "nom du bandit vétéran")

	print("")
	print("Phase 8 — %d échec(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)
