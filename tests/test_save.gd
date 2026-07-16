extends Node

# Test de la sauvegarde/chargement (décision 15) : on maltraite une partie,
# on la capture, on la fait passer par le JSON (aller-retour disque), puis on
# la recharge dans une scène neuve et on compare l'état :
#   Godot --headless --path . res://tests/test_save.tscn

const TEST_PATH := "user://test_save.json"

var failures := 0

func check(cond: bool, label: String) -> void:
	if cond:
		print("OK   — " + label)
	else:
		failures += 1
		printerr("FAIL — " + label)

func _ready() -> void:
	Engine.time_scale = 20.0   # accélère les pauses visuelles de l'IA
	var main: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main)
	await get_tree().process_frame

	# ── On sculpte un état de partie reconnaissable ──────────────────────
	var hero: Unit = main.units_layer.get_hero(0)
	hero.add_xp(2)                      # niveau 2, un choix de sort en attente
	hero.learned_spells.append("blink")
	hero.cooldowns["blink"] = 2
	hero.hp -= 5

	var tank: Unit = null
	for child in main.units_layer.get_children():
		if child is Unit and (child as Unit).team == 0 \
				and (child as Unit).type == Unit.Type.TANK:
			tank = child
	tank.hp -= 3
	tank.defending = true
	tank.kills = 2
	tank.has_moved = true
	tank.remaining_mp = 0

	main.villages.owners[Vector2i(6, 2)] = 0    # village neutre capturé
	main.turn_count = 7
	main.ai_alerted = true

	# Camp 0 vaincu : creeps libérés, propriété au joueur (état simulé)
	var camp: Dictionary = main.creeps.camps[0]
	for u: Unit in main.creeps.alive_units(camp):
		main.units_layer.remove_child(u)
		u.queue_free()
	camp["owner"] = 0
	camp["units"] = []
	# Camp 4 réveillé, un creep blessé
	var camp4: Dictionary = main.creeps.camps[4]
	camp4["awake"] = true
	var creep: Unit = main.creeps.alive_units(camp4)[0]
	creep.hp -= 4

	main.fog.recompute()
	var explored_before: int = main.fog.explored.size()
	var units_before: int = main.units_layer.count_team(0) \
			+ main.units_layer.count_team(1) \
			+ main.units_layer.count_team(Unit.NEUTRAL_TEAM)
	# Valeurs mémorisées avant de libérer la première scène
	var hero_cell: Vector2i = hero.cell
	var tank_cell: Vector2i = tank.cell
	var creep_cell: Vector2i = creep.cell
	var creep_max: int = creep.max_hp

	# ── Capture → JSON sur disque → relecture ────────────────────────────
	SaveGame.write(SaveGame.capture(main), TEST_PATH)
	check(SaveGame.has_save(TEST_PATH), "le fichier de sauvegarde existe")
	var data := SaveGame.read(TEST_PATH)
	check(not data.is_empty(), "la sauvegarde se relit en JSON")
	check(str(data["scenario"]) == Scenario.CURRENT["name"], "nom du scénario stocké")

	remove_child(main)
	main.free()

	# ── Chargement dans une scène neuve ──────────────────────────────────
	SaveGame.pending = data
	var main2: Node2D = (load("res://scenes/main.tscn") as PackedScene).instantiate()
	add_child(main2)
	await get_tree().process_frame
	check(SaveGame.pending.is_empty(), "la sauvegarde en attente a été consommée")

	check(main2.turn_count == 7, "compteur de tours restauré")
	check(main2.ai_alerted, "alerte IA restaurée")

	var units_after: int = main2.units_layer.count_team(0) \
			+ main2.units_layer.count_team(1) \
			+ main2.units_layer.count_team(Unit.NEUTRAL_TEAM)
	check(units_after == units_before,
			"même nombre d'unités (%d = %d)" % [units_after, units_before])

	var hero2: Unit = main2.units_layer.get_hero(0)
	check(hero2 != null and hero2.cell == hero_cell, "héros à sa case")
	check(hero2.level == 2 and hero2.xp == 2, "niveau et XP du héros")
	check(hero2.pending_levelups == 1, "choix de sort en attente conservé")
	check(hero2.learned_spells.has("blink"), "sort appris conservé")
	check(int(hero2.cooldowns.get("blink", 0)) == 2, "cooldown de sort conservé")
	# 20 PV de base + 4 du niveau 2 (remplis), puis -5 infligés avant capture
	check(hero2.hp == int(Unit.STATS[Unit.Type.HERO]["max_hp"]) + Unit.LEVELUP_HP - 5,
			"PV du héros restaurés")

	var tank2: Unit = main2.units_layer.get_unit_at(tank_cell)
	check(tank2 != null and tank2.type == Unit.Type.TANK, "char à sa case")
	check(tank2.hp == Unit.STATS[Unit.Type.TANK]["max_hp"] - 3, "PV du char")
	check(tank2.defending, "posture Défendre conservée")
	check(tank2.kills == 2 and not tank2.veteran, "compteur de kills conservé")
	check(tank2.has_moved and tank2.remaining_mp == 0, "char déjà joué ce tour")

	check(main2.villages.owner_of(Vector2i(6, 2)) == 0, "village capturé restauré")
	check(main2.creeps.rest_owner_of(main2.creeps.camps[0]["center"]) == 0,
			"camp vaincu = camp de repos du joueur")
	check(main2.creeps.alive_units(main2.creeps.camps[0]).is_empty(),
			"camp vaincu sans creeps")
	var camp4b: Dictionary = main2.creeps.camps[4]
	check(bool(camp4b["awake"]), "camp du gué toujours réveillé")
	var creep2: Unit = main2.units_layer.get_unit_at(creep_cell)
	check(creep2 != null and creep2.is_creep() and creep2.hp == creep_max - 4,
			"creep blessé restauré dans son camp")
	check((camp4b["units"] as Array).has(creep2), "le creep appartient à son camp")

	check(main2.fog.explored.size() >= explored_before,
			"brouillard exploré restauré (%d >= %d)"
			% [main2.fog.explored.size(), explored_before])

	var boss: Unit = main2.units_layer.get_leader(1)
	check(boss != null and boss.is_boss() and boss.display_name == "Le Fossoyeur",
			"le Fossoyeur mène toujours l'armée IA")
	check(boss.scale.x > 1.2, "échelle du boss restaurée")

	# Le jeu continue : fin de tour joueur sans erreur
	main2._end_turn()
	var guard := 0
	while (main2.ai_thinking or main2.current_player != 0) and guard < 600:
		await get_tree().process_frame
		guard += 1
	check(guard < 600, "un tour complet se joue après chargement")
	check(main2.turn_count == 8, "le compteur reprend à 8")

	SaveGame.erase(TEST_PATH)
	check(not SaveGame.has_save(TEST_PATH), "fichier de test nettoyé")

	print("")
	print("Sauvegarde — %d échec(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)
