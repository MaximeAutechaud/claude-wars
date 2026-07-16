extends Node

# Test headless de la phase 7 + 7bis (camps de bandits et prisonniers) :
#   Godot --headless --path . res://tests/test_phase7.tscn
# Vérifie : spawn des camps, réveil (proximité + dégâts), leash, XP de kill,
# libération du prisonnier, camp de repos qui soigne, camps isolés endormis,
# pas de capture de village par les creeps.

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
	var villages: Villages = main.get_node("Villages")
	var map: GameMap = main.get_node("GameMap")
	var no_stop := func() -> bool: return false

	# ── Spawn (contenu lu depuis le scénario courant) ────────────────────
	var expected_creeps := 0
	for def: Dictionary in Scenario.CURRENT["camps"]:
		expected_creeps += (def["units"] as Array).size()
	check(units.count_team(Unit.NEUTRAL_TEAM) == expected_creeps,
			"%d creeps sur la carte" % expected_creeps)
	check(creeps.camps.size() == (Scenario.CURRENT["camps"] as Array).size(),
			"tous les camps du scénario sont posés")
	var all_asleep := true
	for camp: Dictionary in creeps.camps:
		if camp["awake"] or int(camp["owner"]) >= 0:
			all_asleep = false
	check(all_asleep, "tous les camps dorment, aucun conquis")
	check(not main._check_game_over(), "les creeps n'affectent pas la fin de partie")
	var a_creep: Unit = creeps.alive_units(creeps.camps[0])[0]
	check(not a_creep.can_capture(), "un creep ne peut pas capturer de village")
	check(creeps.camps[2]["prize"] == Unit.Type.TANK, "le camp du pont garde un Char")
	var camp0_center: Vector2i = creeps.camps[0]["center"]
	check(creeps.rest_owner_of(camp0_center) == -2, "pas de camp de repos au départ")

	# ── XP : un char joueur tue un creep du camp 0 ───────────────────────
	var xp_before: int = units.get_hero(0).xp
	var victim: Unit = creeps.alive_units(creeps.camps[0])[0]
	victim.hp = 1
	var tank := units.spawn(_free_neighbor(victim.cell, units, map), 0, Unit.Type.TANK)
	units.do_combat(tank, victim)
	await get_tree().process_frame
	check(units.get_hero(0).xp == xp_before + 1, "XP de kill créditée au héros")
	check(int(creeps.camps[0]["owner"]) == -1, "camp entamé mais pas conquis")

	# ── Réveil par dégâts + riposte du camp ──────────────────────────────
	await creeps.run_turn(units, no_stop)
	check(creeps.camps[0]["awake"], "le camp attaqué se réveille")
	check(tank.hp < tank.max_hp, "les creeps réveillés ripostent")
	check(not creeps.camps[4]["awake"], "le camp du gué non approché reste endormi")

	# ── Camp vaincu : prisonnier libéré + camp de repos ──────────────────
	var team0_before: int = units.count_team(0)
	var last: Unit = creeps.alive_units(creeps.camps[0])[0]
	last.hp = 1
	units.do_combat(tank, last)
	await get_tree().process_frame
	check(int(creeps.camps[0]["owner"]) == 0, "camp conquis par le joueur")
	check(units.count_team(0) == team0_before + 1, "le prisonnier rejoint l'armée")
	# Le prisonnier apparaît sur le centre du camp ou une case voisine
	var prize: Unit = null
	for child in units.get_children():
		if child is Unit and (child as Unit).team == 0 \
				and (child as Unit).type == creeps.camps[0]["prize"] \
				and Pathfinder.distance((child as Unit).cell, camp0_center) <= 1:
			prize = child as Unit
	check(prize != null, "prisonnier (%s) libéré sur le camp"
			% Unit.STATS[creeps.camps[0]["prize"]]["name"])
	check(creeps.rest_owner_of(camp0_center) == 0, "le camp devient un camp de repos")

	# ── Le camp de repos soigne en début de tour ─────────────────────────
	if prize != null:
		prize.cell = camp0_center
		prize.hp = 1
		main._start_turn(0)
		check(prize.hp == 1 + Creeps.REST_HEAL, "repos au camp conquis : +%d PV" % Creeps.REST_HEAL)

	# ── Réveil par proximité (fin de tour à <= 2 cases) ──────────────────
	check(not creeps.camps[1]["awake"], "le camp du nord dort encore")
	var near_camp1: Vector2i = creeps.camps[1]["center"] + Vector2i(0, 2)
	var scout := units.spawn(near_camp1, 0, Unit.Type.INFANTRY)
	await creeps.run_turn(units, no_stop)
	check(creeps.camps[1]["awake"], "une unité à 2 cases réveille le camp")
	check(is_instance_valid(scout) == false or scout.hp < scout.max_hp \
			or _creep_moved(creeps.camps[1]),
			"le camp réveillé réagit (attaque ou se rapproche)")

	# ── Leash : personne ne s'éloigne à plus de LEASH_RADIUS du camp ─────
	await creeps.run_turn(units, no_stop)
	var leash_ok := true
	for camp: Dictionary in creeps.camps:
		for u: Unit in creeps.alive_units(camp):
			if Pathfinder.distance(u.cell, camp["center"]) > Creeps.LEASH_RADIUS:
				leash_ok = false
	check(leash_ok, "aucun creep ne dépasse le leash de %d cases" % Creeps.LEASH_RADIUS)

	# ── Les villages n'ont pas changé de main pendant les tours neutres ──
	var owners_ok := true
	for cell: Vector2i in villages.owners:
		if villages.owners[cell] != Scenario.CURRENT["villages"][cell]:
			owners_ok = false
	check(owners_ok, "aucun village capturé par les creeps")

	print("")
	print("Phase 7/7bis — %d échec(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)

func _creep_moved(camp: Dictionary) -> bool:
	for u: Unit in (camp["units"] as Array):
		if is_instance_valid(u) and u.cell != u.home_cell:
			return true
	return false

# Première case voisine praticable et libre (pour poser une unité de test)
func _free_neighbor(cell: Vector2i, units: UnitsLayer, map: GameMap) -> Vector2i:
	for nb in Pathfinder.get_neighbors(cell):
		if map.is_in_bounds(nb) and units.get_unit_at(nb) == null \
				and map.get_terrain(nb) != GameMap.Terrain.RIVER:
			return nb
	return cell
