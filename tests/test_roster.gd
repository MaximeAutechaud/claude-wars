extends Node

# Test headless du roster (décision 16, phase 12) :
#   Godot --headless --path . res://tests/test_roster.tscn
# Vérifie : refonte des stats (Guerrier encaisse, Cavalier burst), Charge du
# Cavalier (armée par l'élan, consommée à l'attaque), portée minimale et
# perce-défense du Mage, soin de l'Apothicaire, régénération de l'Éclaireur.

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
	var fog: Fog = main.get_node("Fog")

	# ── Refonte des stats : chacun son thème ─────────────────────────────
	check(Unit.STATS[Unit.Type.INFANTRY]["max_hp"] == 14
			and Unit.STATS[Unit.Type.INFANTRY]["counter"] == 3,
			"le Guerrier encaisse : 14 PV, riposte 3")
	check(Unit.STATS[Unit.Type.TANK]["max_hp"] == 11
			and Unit.STATS[Unit.Type.TANK]["atk"] == 4,
			"le Cavalier rend des PV : 11 PV, atk 4")
	check(Unit.STATS[Unit.Type.SCOUT]["vision"] == 5
			and Unit.STATS[Unit.Type.SCOUT]["costs"][GameMap.Terrain.MOUNTAIN] == 1,
			"l'Éclaireur : vision 5, tout terrain à coût 1")

	# ── Charge du Cavalier : +2 atk après un élan de 3 cases ─────────────
	var cav := units.spawn(Vector2i(4, 4), 0, Unit.Type.TANK)
	fog.recompute()
	check(cav.atk() == 4, "sans élan, atk de base (4)")
	units.move_unit(cav, Vector2i(7, 4), 3)
	check(Pathfinder.distance(Vector2i(4, 4), Vector2i(7, 4)) >= Unit.CHARGE_MIN_DIST,
			"précondition : l'élan couvre bien 3 cases")
	check(cav.charge_ready and cav.atk() == 6, "charge armée : atk 6")
	var prey_cell: Vector2i = Pathfinder.get_neighbors(Vector2i(7, 4))[0]
	var prey := units.spawn(prey_cell, 1, Unit.Type.INFANTRY)
	fog.recompute()
	var expected: int = prey.hp - maxi(1, cav.atk() - units.defense_of(prey))
	units.do_combat(cav, prey)
	check(is_instance_valid(prey) and prey.hp == expected, "les dégâts de charge sont appliqués")
	check(not cav.charge_ready and cav.atk() == 4, "la charge est consommée par l'attaque")
	units.reset_team(0)
	units.move_unit(cav, Pathfinder.get_neighbors(cav.cell)[0], 1)
	check(not cav.charge_ready, "un pas d'une case n'arme pas la charge")
	prey.free()
	cav.free()

	# ── Mage des braises : portée 2-3, nul au corps à corps, perce-défense ─
	var mage := units.spawn(Vector2i(4, 6), 0, Unit.Type.MAGE)
	var close := units.spawn(Pathfinder.get_neighbors(Vector2i(4, 6))[0], 1, Unit.Type.INFANTRY)
	fog.recompute()
	check(not units.get_enemies_in_range(mage).has(close),
			"un ennemi au contact est hors de portée du Mage")
	var p_close := units.preview_combat(close, mage)
	check(int(p_close["counter"]) == 0, "attaqué au contact, le Mage ne riposte pas")
	var far_cell := Vector2i(-99, -99)
	for cell in Pathfinder.cells_in_range(mage.cell, 3):
		if Pathfinder.distance(mage.cell, cell) == 3 and units.get_unit_at(cell) == null \
				and main.get_node("GameMap").is_in_bounds(cell) \
				and main.get_node("GameMap").get_terrain(cell) != GameMap.Terrain.RIVER:
			far_cell = cell
			break
	var far := units.spawn(far_cell, 1, Unit.Type.INFANTRY)
	far.defending = true
	fog.recompute()
	check(units.get_enemies_in_range(mage).has(far), "un ennemi à 3 cases est à portée")
	var p_far := units.preview_combat(mage, far)
	check(int(p_far["damage"]) == mage.atk(),
			"les dégâts du Mage ignorent terrain et posture (perce-défense)")
	check(int(p_far["counter"]) == 0, "pas de riposte à 3 cases")
	far.free()
	close.free()
	mage.free()

	# ── Apothicaire : soin de 4, plafonné aux PV max ─────────────────────
	var medic := units.spawn(Vector2i(5, 5), 0, Unit.Type.MEDIC)
	var wounded := units.spawn(Pathfinder.get_neighbors(Vector2i(5, 5))[0], 0, Unit.Type.INFANTRY)
	wounded.hp -= 6
	units.medic_heal(medic, wounded)
	check(wounded.hp == wounded.max_hp - 2, "soin de +%d PV" % Unit.MEDIC_HEAL)
	units.medic_heal(medic, wounded)
	check(wounded.hp == wounded.max_hp, "le soin ne dépasse pas les PV max")
	wounded.free()

	# ── Éclaireur : Endurci, +2 PV par tour hors village ─────────────────
	var scout := units.spawn(Vector2i(6, 5), 0, Unit.Type.SCOUT)
	scout.hp = 3
	medic.hp = medic.max_hp   # seuls les blessés hors village bougent : le scout
	main._start_turn(0)
	check(scout.hp == 3 + Unit.SCOUT_REGEN, "l'Éclaireur se soigne de +%d" % Unit.SCOUT_REGEN)
	scout.hp = scout.max_hp - 1
	main._start_turn(0)
	check(scout.hp == scout.max_hp, "la régénération est plafonnée aux PV max")
	check(medic.hp == medic.max_hp, "les autres unités ne régénèrent pas hors village")
	scout.free()
	medic.free()

	if failures == 0:
		print("\nRoster — 0 échec(s)")
	else:
		printerr("\nRoster — %d échec(s)" % failures)
	get_tree().quit(failures)
