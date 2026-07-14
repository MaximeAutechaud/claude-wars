extends Node

# Test headless de la phase 10 (brouillard de guerre + IA attentiste) :
#   Godot --headless --path . res://tests/test_phase10.tscn
# Vérifie : voile initial, unités ennemies masquées, exploration en marchant,
# IA qui tient position puis s'alerte (proximité, blessure, perte).

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
	var ai_team: int = main.AI_TEAM

	# ── Voile initial ────────────────────────────────────────────────────
	var hero := units.get_hero(0)
	check(fog.is_explored(hero.cell), "la zone de départ du joueur est explorée")
	check(fog.is_explored(Vector2i(1, 2)), "le village de départ est visible")
	var ai_hero := units.get_hero(ai_team)
	check(not fog.is_explored(ai_hero.cell), "le camp IA est sous le voile")
	check(not ai_hero.visible, "le héros IA est masqué")
	check(hero.visible, "les unités du joueur restent affichées")
	check(not fog.is_explored(Vector2i(1, 8)), "le camp de bandits sud est sous le voile")

	# ── IA attentiste : personne en vue, elle tient position ─────────────
	check(not AIPlayer.detects_player(units, ai_team), "l'IA ne détecte personne au départ")
	var u1 := units.get_unit_at(Vector2i(10, 8))
	var u1_home := u1.cell
	main._ai_act_unit(u1)
	check(u1.cell == u1_home, "unité IA non alertée : tient sa position")
	u1.has_moved = false
	u1.remaining_mp = u1.movement_points()

	# ── Détection par blessure (même à distance) ─────────────────────────
	u1.hp -= 1
	check(AIPlayer.detects_player(units, ai_team), "une unité IA blessée alerte l'armée")
	u1.hp += 1
	check(not AIPlayer.detects_player(units, ai_team), "PV restaurés : plus de détection")

	# ── Exploration en marchant + détection par proximité ────────────────
	var scout := units.get_unit_at(Vector2i(1, 1))
	scout.cell = Vector2i(8, 6)
	fog.recompute()
	check(fog.is_explored(Vector2i(8, 6)), "la case atteinte est explorée")
	var u_close := units.get_unit_at(Vector2i(9, 6))
	check(u_close.visible, "l'unité IA entrée dans la vision devient visible")
	check(AIPlayer.detects_player(units, ai_team), "le joueur à portée de vision est détecté")

	# ── Perte d'une unité IA → alerte définitive ─────────────────────────
	check(not main.ai_alerted, "pas encore d'alerte générale")
	var victim := units.spawn(Vector2i(5, 8), ai_team, Unit.Type.INFANTRY)
	victim.hp = 1
	var tank := units.spawn(Vector2i(5, 9), 0, Unit.Type.TANK)
	units.do_combat(tank, victim)
	await get_tree().process_frame
	check(main.ai_alerted, "perdre une unité alerte l'armée IA")

	# ── Alertée, l'unité IA bouge/attaque ────────────────────────────────
	var scout_hp: int = scout.hp
	main._ai_act_unit(u1)
	check(u1.cell != u1_home or scout.hp < scout_hp,
			"unité IA alertée : elle avance ou attaque")

	print("")
	print("Phase 10 — %d échec(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)
