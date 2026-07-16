extends Node

# Test headless des outils de survie (décision 14) :
#   Godot --headless --path . res://tests/test_survival.tscn
# Vérifie : zone de contrôle (arrêt du mouvement, cases ennemies bloquées,
# ZoC invisible sous brouillard ignorée pour le joueur, PM coupés à l'entrée),
# posture Défendre (+2 déf, cassée par le mouvement, garnison IA),
# prévision de dégâts identique au combat réel.

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
	var map: GameMap = main.get_node("GameMap")
	var fog: Fog = main.get_node("Fog")

	# ── ZoC : un mur de deux ennemis contrôle le couloir entre eux ───────
	# Ennemis en (7,4) et (7,6), couloir libre en (7,5) : une infanterie en
	# (6,5) peut entrer dans le couloir mais pas le traverser.
	var wall_a := units.spawn(Vector2i(7, 4), 1, Unit.Type.INFANTRY)
	var wall_b := units.spawn(Vector2i(7, 6), 1, Unit.Type.INFANTRY)
	var runner := units.spawn(Vector2i(6, 5), 0, Unit.Type.INFANTRY)
	fog.recompute()
	var ctx := units.move_context(runner)
	check((ctx["blocked"] as Dictionary).has(wall_a.cell), "case ennemie infranchissable")
	check((ctx["zoc"] as Dictionary).has(Vector2i(7, 5)), "le couloir est sous contrôle ennemi")
	var reach := Pathfinder.get_reachable(runner.cell, 3, map, runner.type, ctx)
	check(reach.has(Vector2i(7, 5)), "on peut entrer en zone de contrôle")
	check(not reach.has(Vector2i(8, 5)), "mais pas la traverser : le mur bloque")
	check(not reach.has(wall_a.cell), "on ne passe pas à travers un ennemi")

	# ── Entrer en ZoC coupe les PM restants ──────────────────────────────
	units.move_unit(runner, Vector2i(7, 5), 1)
	check(runner.remaining_mp == 0 and runner.has_moved,
			"finir en zone de contrôle stoppe net le mouvement")

	# ── Brouillard : un ennemi invisible n'exerce pas de ZoC visible ─────
	var sneaky := units.spawn(Vector2i(14, 10), 1, Unit.Type.INFANTRY)
	fog.recompute()
	if not fog.is_visible_now(sneaky.cell):
		var ctx2 := units.move_context(runner)
		check(not (ctx2["zoc"] as Dictionary).has(Vector2i(14, 9)),
				"un ennemi caché dans le brouillard n'exerce pas de ZoC")
	else:
		check(false, "précondition : l'unité test aurait dû être hors de vue")
	sneaky.queue_free()
	await get_tree().process_frame

	# ── Défendre : +2 de défense, cassée par le mouvement ────────────────
	var guard := units.spawn(Vector2i(3, 10), 0, Unit.Type.INFANTRY)   # plaine, déf +0
	var bully := units.spawn(Vector2i(3, 11), 1, Unit.Type.TANK)
	fog.recompute()
	guard.defending = true
	var expected: int = maxi(1, bully.atk() - Unit.DEFEND_BONUS)
	var hp_before: int = guard.hp
	units.do_combat(bully, guard)
	check(guard.hp == hp_before - expected,
			"en garde : dégâts réduits de %d" % Unit.DEFEND_BONUS)
	check(guard.defending, "riposter ne casse pas la garde")
	guard.has_moved = false
	guard.remaining_mp = guard.movement_points()
	units.move_unit(guard, Vector2i(2, 10), 1)
	check(not guard.defending, "bouger casse la garde")

	# ── Garnison : une unité IA non alertée sans menace se met en garde ──
	var idle_ai := units.get_unit_at(Vector2i(19, 14))
	check(not main.ai_alerted, "l'IA n'est pas alertée")
	main._ai_act_unit(idle_ai)
	check(idle_ai.defending, "la garnison IA prend la posture Défendre")

	# ── Prévision de dégâts = combat réel (déterminisme) ─────────────────
	var atk_u := units.spawn(Vector2i(5, 9), 0, Unit.Type.ARCHER)
	var def_u := units.spawn(Vector2i(5, 10), 1, Unit.Type.INFANTRY)
	var p := units.preview_combat(atk_u, def_u)
	var atk_hp: int = atk_u.hp
	var def_hp: int = def_u.hp
	units.do_combat(atk_u, def_u)
	check(def_u.hp == def_hp - int(p["damage"]), "prévision : dégâts exacts")
	check(atk_u.hp == atk_hp - int(p["counter"]), "prévision : riposte exacte")
	check(bool(p["kill"]) == (def_u.hp <= 0), "prévision : issue fatale exacte")

	print("")
	print("Survie — %d échec(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)
