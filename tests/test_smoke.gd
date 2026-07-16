extends Node

# Test de fumée : joue deux tours complets (joueur → IA → creeps) sur le
# tableau courant et vérifie que la boucle tourne sans casser :
#   Godot --headless --path . res://tests/test_smoke.tscn

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

	for round_i in 2:
		check(main.current_player == 0 and not main.ai_thinking,
				"tour %d : la main est au joueur" % main.turn_count)
		main._end_turn()
		# Attend la fin du tour IA + tour neutre (drapeau ai_thinking)
		var guard := 0
		while (main.ai_thinking or main.current_player != 0) and guard < 600:
			await get_tree().process_frame
			guard += 1
		check(guard < 600, "le tour IA + creeps s'est terminé")

	check(main.turn_count == 3, "compteur de tours avancé (tour 3)")
	check(not main.game_over, "pas de fin de partie inopinée")
	check(main.units_layer.get_leader(0) != null, "héros joueur en vie")
	check(main.units_layer.get_leader(1) != null, "chef IA (boss) en vie")
	check(not main.ai_alerted, "IA toujours attentiste sans contact")

	# ── Fiche d'unité (panel d'inspection) ───────────────────────────────
	var hero: Unit = main.units_layer.get_hero(0)
	main._show_unit_panel(hero)
	check(main.unit_panel.visible, "la fiche d'unité s'affiche")
	check(main.name_label.text == hero.unit_name(), "nom du héros affiché")
	check(main.hp_label.text == "PV : %d / %d" % [hero.hp, hero.max_hp], "PV affichés")
	check(main.xp_label.visible and not main.grade_label.visible,
			"héros : XP affichée, pas de grade de vétérance")
	var boss: Unit = main.units_layer.get_leader(1)
	main._show_unit_panel(boss)
	check(main.name_label.text == "Le Fossoyeur", "fiche du boss : son nom")
	check(main.grade_label.visible and main.grade_label.text.begins_with("Boss"),
			"fiche du boss : sa phase")
	check(not main.xp_label.visible, "pas d'XP sur un boss")
	main._show_unit_panel(null)
	check(not main.unit_panel.visible, "fiche masquée sans unité")

	print("")
	print("Smoke — %d échec(s)" % failures)
	get_tree().quit(1 if failures > 0 else 0)
