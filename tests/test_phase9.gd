extends Node

# Test headless de la phase 9 (tableau en données + grande carte + boss) :
#   Godot --headless --path . res://tests/test_phase9.tscn
# Vérifie : chargement du scénario (terrain, armées, villages, camps),
# le boss chef d'armée (Le Fossoyeur : victoire à sa mort, phases/sacrifice
# sur sa propre armée, malédiction télégraphiée, XP bonus), prisonnier vétéran.

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

	# ── Chargement du scénario ───────────────────────────────────────────
	var rows: Array = Scenario.CURRENT["terrain"]
	var expected_size := Vector2i((rows[0] as String).length(), rows.size())
	check(map.get_map_size() == expected_size,
			"carte %d×%d chargée depuis le scénario" % [expected_size.x, expected_size.y])
	check(map.get_terrain(Vector2i(10, 5)) == GameMap.Terrain.RIVER, "le fleuve coule")
	check(map.get_terrain(Vector2i(10, 3)) == GameMap.Terrain.ROAD, "le pont nord est une route")
	check(map.get_terrain(Vector2i(10, 12)) == GameMap.Terrain.ROAD, "le pont sud est une route")
	check(map.get_terrain(Vector2i(15, 1)) == GameMap.Terrain.MOUNTAIN, "les montagnes du nord-est")

	var armies: Dictionary = Scenario.CURRENT["armies"]
	check(units.count_team(0) == (armies[0] as Array).size(), "armée joueur au complet")
	check(units.count_team(1) == (armies[1] as Array).size(), "armée IA au complet")
	check(villages.owners.size() == (Scenario.CURRENT["villages"] as Dictionary).size(),
			"tous les villages posés")
	check(villages.owner_of(Vector2i(2, 2)) == 0, "village de départ au joueur")
	check(villages.owner_of(Vector2i(19, 12)) == 1, "village de base à l'IA")

	# ── Le boss est le chef de l'armée ennemie ───────────────────────────
	var boss: Unit = units.get_leader(1)
	check(boss != null and boss.is_boss(), "l'armée IA est menée par un boss")
	check(boss.unit_name() == "Le Fossoyeur", "il s'appelle Le Fossoyeur")
	check(units.get_hero(1) == null, "pas de héros IA classique")
	check(units.get_leader(0) == units.get_hero(0), "le chef du joueur reste son héros")
	check(not main._check_game_over(), "partie en cours tant que les deux chefs vivent")

	# ── Malédiction : télégraphe puis frappe au tour suivant ─────────────
	var bait := units.spawn(Vector2i(17, 10), 0, Unit.Type.INFANTRY)
	Boss.telegraph_doom(boss, units, map)
	check(boss.doom_armed == true, "malédiction télégraphiée")
	check(boss.doom_cells.has(bait.cell), "la zone maudite couvre l'appât (pas ses alliés)")
	var bait_hp: int = bait.hp
	Boss.resolve_doom(boss, units)
	check(bait.hp == bait_hp - Boss.DOOM_DAMAGE,
			"la malédiction inflige %d dégâts" % Boss.DOOM_DAMAGE)
	check(boss.doom_armed == false, "la zone est consommée après la frappe")

	# ── Phase 66 % : sacrifice d'un soldat de sa propre armée ────────────
	# (le boss joue son tour IA complet — il faut que l'armée soit alertée)
	main.ai_alerted = true
	var team1_before: int = units.count_team(1)
	var atk_before: int = boss.atk()
	boss.hp = int(boss.max_hp * 0.6)
	var hp_before: int = boss.hp
	main._ai_act_unit(boss)
	await get_tree().process_frame
	check(boss.boss_phase == 1, "phase 1 déclenchée sous 66 % de PV")
	check(units.count_team(1) == team1_before - 1, "un soldat de son armée a été sacrifié")
	check(boss.hp > hp_before, "le boss s'est soigné en sacrifiant")
	check(boss.atk() >= atk_before + Boss.ENRAGE_ATK, "le boss s'enrage")

	# ── Prisonnier premium du camp du gué : l'Apothicaire (décision 16) ──
	var gue: Dictionary = creeps.camps[4]
	check(gue["prize"] == Unit.Type.MEDIC, "le camp du gué promet l'Apothicaire")
	var slayer := units.spawn(Vector2i(11, 5), 0, Unit.Type.TANK)
	var team0_before: int = units.count_team(0)
	while not creeps.alive_units(gue).is_empty():
		var victim: Unit = creeps.alive_units(gue)[0]
		victim.hp = 1
		units.do_combat(slayer, victim)
		await get_tree().process_frame
	check(int(gue["owner"]) == 0, "le camp du gué est conquis")
	check(units.count_team(0) == team0_before + 1, "le prisonnier rejoint l'armée")
	var prize: Unit = null
	for child in units.get_children():
		if child is Unit and (child as Unit).team == 0 \
				and (child as Unit).type == gue["prize"] and (child as Unit) != slayer \
				and Pathfinder.distance((child as Unit).cell, gue["center"]) <= 1:
			prize = child as Unit
	check(prize != null and prize.type == Unit.Type.MEDIC, "et c'est bien elle")

	# ── Tuer le boss : XP bonus + victoire immédiate ─────────────────────
	var xp_before: int = units.get_hero(0).xp
	boss.hp = 1
	units.do_combat(slayer, boss)
	await get_tree().process_frame
	check(units.get_hero(0).xp == xp_before + 1 + Unit.BOSS_XP_BONUS,
			"tuer le boss rapporte +%d XP bonus" % Unit.BOSS_XP_BONUS)
	check(main._check_game_over(), "la mort du Fossoyeur met fin au tableau")
	check(main.end_label.text == "Victoire !", "et c'est une victoire")

	print("")
	print("Phase 9 — %d échec(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)
