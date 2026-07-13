extends Node2D

enum State { IDLE, UNIT_SELECTED, UNIT_MOVED, CASTING, RECRUITING }

const AI_TEAM := 1

@onready var map: GameMap            = $GameMap
@onready var villages: Villages      = $Villages
@onready var camera: Camera2D        = $Camera2D
@onready var units_layer: UnitsLayer = $UnitsLayer
@onready var turn_label: Label       = $UI/TurnLabel
@onready var attack_zone_btn: Button = $UI/AttackZoneButton
@onready var end_turn_btn: Button    = $UI/EndTurnButton
@onready var end_screen: ColorRect   = $UI/EndScreen
@onready var end_label: Label        = $UI/EndScreen/EndBox/EndLabel
@onready var gold_label: Label            = $UI/GoldLabel
@onready var recruit_btn: Button          = $UI/RecruitButton
@onready var recruit_panel: PanelContainer = $UI/RecruitPanel
@onready var recruit_box: HBoxContainer   = $UI/RecruitPanel/RecruitBox
@onready var spell_bar: HBoxContainer     = $UI/SpellBar
@onready var level_up_panel: PanelContainer = $UI/LevelUpPanel
@onready var choice_btns: Array[Button] = [
	$UI/LevelUpPanel/LevelBox/Choice1,
	$UI/LevelUpPanel/LevelBox/Choice2,
]

var state := State.IDLE
var selected_unit: Unit      = null
var attackable_enemies: Array[Unit] = []
var current_player := 0
var ai_thinking    := false
var game_over      := false
var turn_count     := 1
var casting_spell  := ""
var _offered_spells: Array[String] = []
var gold: Array[int] = [10, 10]
var recruiting_type: int = -1

func _ready() -> void:
	var mid := map.get_map_size() / 2
	camera.global_position = map.to_global(map.map_to_local(mid))
	for i in choice_btns.size():
		choice_btns[i].pressed.connect(_on_spell_choice.bind(i))
	recruit_btn.pressed.connect(_on_recruit_pressed)
	_start_turn(0)
	_update_turn_label()

# ── Entrées ──────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if ai_thinking or game_over or level_up_panel.visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_end_turn()

func _unhandled_input(event: InputEvent) -> void:
	if ai_thinking or game_over or level_up_panel.visible:
		return
	if not (event is InputEventMouseButton and event.pressed \
			and event.button_index == MOUSE_BUTTON_LEFT):
		return
	var cell := map.local_to_map(map.to_local(get_global_mouse_position()))
	if map.is_in_bounds(cell):
		_handle_click(cell)

# ── Logique de clic ──────────────────────────────────────────────────────────

func _handle_click(cell: Vector2i) -> void:
	match state:
		State.IDLE:
			var unit := units_layer.get_unit_at(cell)
			if unit and unit.team == current_player and not unit.has_moved:
				_select(unit)

		State.UNIT_SELECTED:
			if units_layer.reachable_cells.has(cell):
				units_layer.move_unit(selected_unit, cell)
				_after_move()
			else:
				var clicked := units_layer.get_unit_at(cell)
				if clicked != null and clicked in attackable_enemies:
					var attacker := selected_unit
					units_layer.do_combat(attacker, clicked)
					if is_instance_valid(attacker):
						attacker.has_moved = true
						attacker.queue_redraw()
					_deselect()
					_check_game_over()
					_maybe_show_levelup()
				elif clicked != null and clicked.team == current_player and not clicked.has_moved:
					_deselect()
					_select(clicked)
				else:
					_deselect()

		State.UNIT_MOVED:
			var target := units_layer.get_unit_at(cell)
			if target != null and target in attackable_enemies:
				var attacker := selected_unit
				units_layer.do_combat(attacker, target)
				if is_instance_valid(attacker):
					attacker.has_moved = true
					attacker.queue_redraw()
				_deselect()
				_check_game_over()
				_maybe_show_levelup()
			else:
				_deselect()

		State.CASTING:
			if units_layer.spell_cells.has(cell):
				_execute_cast(cell)
			else:
				_deselect()

		State.RECRUITING:
			if units_layer.spell_cells.has(cell):
				_execute_recruit(cell)
			else:
				_deselect()

# ── Transitions d'état ───────────────────────────────────────────────────────

func _select(unit: Unit) -> void:
	selected_unit = unit
	unit.selected = true
	unit.queue_redraw()
	state = State.UNIT_SELECTED
	units_layer.show_reachable(unit)
	_mark_attackable(units_layer.get_enemies_in_range(unit))
	attack_zone_btn.show()
	attack_zone_btn.text = "Zone d'attaque"
	_update_spell_bar()
	_update_recruit_button()
	_update_turn_label()

func _after_move() -> void:
	attack_zone_btn.hide()
	_mark_attackable(units_layer.get_enemies_in_range(selected_unit))
	# On reste sélectionné s'il y a une cible OU un sort encore lançable
	if attackable_enemies.is_empty() \
			and not (selected_unit.is_hero() and selected_unit.has_ready_spell()):
		_deselect()
		return
	state = State.UNIT_MOVED
	_update_spell_bar()
	_update_recruit_button()
	_update_turn_label()

# Re-sélectionne une unité après une action gratuite (sort, recrutement)
func _reselect(unit: Unit) -> void:
	if not is_instance_valid(unit) or game_over:
		return
	if unit.has_moved:
		selected_unit = unit
		unit.selected = true
		unit.queue_redraw()
		_after_move()
	else:
		_select(unit)

# Remplace les anneaux rouges actuels par ceux des ennemis donnés
func _mark_attackable(enemies: Array[Unit]) -> void:
	for u: Unit in attackable_enemies:
		if is_instance_valid(u):
			u.attackable = false
			u.queue_redraw()
	attackable_enemies = enemies
	for u: Unit in attackable_enemies:
		u.attackable = true
		u.queue_redraw()

func _deselect() -> void:
	if is_instance_valid(selected_unit):
		selected_unit.selected = false
		selected_unit.queue_redraw()
	for u: Unit in attackable_enemies:
		if is_instance_valid(u):
			u.attackable = false
			u.queue_redraw()
	attackable_enemies.clear()
	selected_unit = null
	state = State.IDLE
	casting_spell = ""
	recruiting_type = -1
	units_layer.clear_reachable()
	attack_zone_btn.hide()
	spell_bar.hide()
	recruit_btn.hide()
	recruit_panel.hide()
	_update_turn_label()

func _end_turn() -> void:
	if ai_thinking or game_over:
		return
	_deselect()
	units_layer.reset_team(current_player)
	current_player = 1 - current_player
	if current_player == 0:
		turn_count += 1
	_update_turn_label()
	_start_turn(current_player)
	if current_player == AI_TEAM:
		_run_ai_turn()  # coroutine lancée en arrière-plan
	else:
		_maybe_show_levelup()

# Début de tour d'un camp : revenu des villages + soin des unités qui y stationnent
func _start_turn(team: int) -> void:
	gold[team] += villages.income_for(team)
	for child in units_layer.get_children():
		if child is Unit and (child as Unit).team == team:
			var u := child as Unit
			if villages.owner_of(u.cell) == team and u.hp < u.max_hp:
				u.hp = mini(u.hp + Villages.VILLAGE_HEAL, u.max_hp)
				u.queue_redraw()
	_update_gold_label()

func _update_gold_label() -> void:
	gold_label.text = "Or : %d   |   IA : %d" % [gold[0], gold[AI_TEAM]]

# ── Fin de partie ────────────────────────────────────────────────────────────

func _check_game_over() -> bool:
	if game_over:
		return true
	# Un camp perd si son héros meurt ou s'il n'a plus d'unités
	var player_lost: bool = units_layer.get_hero(0) == null \
			or units_layer.count_team(0) == 0
	var ai_lost: bool = units_layer.get_hero(AI_TEAM) == null \
			or units_layer.count_team(AI_TEAM) == 0
	if not player_lost and not ai_lost:
		return false
	game_over = true
	end_turn_btn.disabled = true
	attack_zone_btn.hide()
	if ai_lost:
		end_label.text = "Victoire !"
		end_label.modulate = Unit.TEAM_COLORS[0]
	else:
		end_label.text = "Défaite…"
		end_label.modulate = Unit.TEAM_COLORS[AI_TEAM]
	end_screen.show()
	return true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

# ── Sorts ────────────────────────────────────────────────────────────────────

func _update_spell_bar() -> void:
	for child in spell_bar.get_children():
		child.queue_free()
	if selected_unit == null or not selected_unit.is_hero() \
			or selected_unit.learned_spells.is_empty():
		spell_bar.hide()
		return
	for id: String in selected_unit.learned_spells:
		var btn := Button.new()
		var cd: int = selected_unit.cooldowns.get(id, 0)
		btn.text = Spells.POOL[id]["name"] + ("" if cd == 0 else " (%d)" % cd)
		btn.tooltip_text = Spells.POOL[id]["desc"] \
				+ (" — n'épuise pas l'attaque" if Spells.POOL[id]["free"] else " — consomme l'attaque")
		btn.disabled = not selected_unit.spell_ready(id)
		btn.pressed.connect(_on_spell_pressed.bind(id))
		spell_bar.add_child(btn)
	spell_bar.show()

func _on_spell_pressed(id: String) -> void:
	if selected_unit == null or not selected_unit.spell_ready(id):
		return
	if id == "warcry":
		_execute_cast(selected_unit.cell, id)
		return
	casting_spell = id
	state = State.CASTING
	units_layer.show_spell_targets(_valid_spell_targets(selected_unit, id))
	_update_turn_label()

func _valid_spell_targets(caster: Unit, id: String) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var r: int = Spells.POOL[id]["range"]
	for cell in Pathfinder.cells_in_range(caster.cell, r):
		if not map.is_in_bounds(cell):
			continue
		match id:
			"heal":
				var u := units_layer.get_unit_at(cell)
				if u != null and u.team == caster.team and u.hp < u.max_hp:
					out.append(cell)
			"fireball":
				out.append(cell)
			"blink":
				if cell != caster.cell and units_layer.get_unit_at(cell) == null \
						and Unit.STATS[caster.type]["costs"].get(map.get_terrain(cell), 99) < 99:
					out.append(cell)
	return out

func _execute_cast(target_cell: Vector2i, id: String = "") -> void:
	var spell: String = id if id != "" else casting_spell
	var caster := selected_unit
	var free_action: bool = Spells.POOL[spell]["free"]
	units_layer.cast_spell(caster, spell, target_cell)
	casting_spell = ""
	if not free_action and is_instance_valid(caster):
		caster.has_moved = true
		caster.queue_redraw()
	_deselect()
	_check_game_over()
	if game_over:
		return
	# Sort gratuit : le héros garde son attaque, on le re-sélectionne
	if free_action:
		_reselect(caster)
	_maybe_show_levelup()

# ── Recrutement ──────────────────────────────────────────────────────────────

func _update_recruit_button() -> void:
	recruit_btn.visible = selected_unit != null and selected_unit.is_hero() \
			and selected_unit.team == 0

func _on_recruit_pressed() -> void:
	if recruit_panel.visible:
		recruit_panel.hide()
		return
	for child in recruit_box.get_children():
		child.queue_free()
	for t: int in [Unit.Type.INFANTRY, Unit.Type.ARCHER, Unit.Type.TANK]:
		var btn := Button.new()
		var cost: int = Unit.STATS[t]["cost"]
		btn.text = "%s — %d or" % [Unit.STATS[t]["name"], cost]
		btn.disabled = gold[0] < cost or _free_adjacent_cells(selected_unit.cell, t).is_empty()
		btn.pressed.connect(_on_recruit_type.bind(t))
		recruit_box.add_child(btn)
	recruit_panel.show()

func _on_recruit_type(type: int) -> void:
	recruit_panel.hide()
	recruiting_type = type
	state = State.RECRUITING
	units_layer.show_spell_targets(_free_adjacent_cells(selected_unit.cell, type))
	_update_turn_label()

func _execute_recruit(cell: Vector2i) -> void:
	var hero := selected_unit
	var u := units_layer.spawn(cell, 0, recruiting_type)
	u.has_moved = true
	u.queue_redraw()
	gold[0] -= Unit.STATS[recruiting_type]["cost"]
	villages.try_capture(u)
	print("%s recruté pour %d or" % [u.unit_name(), Unit.STATS[recruiting_type]["cost"]])
	_update_gold_label()
	_deselect()
	_reselect(hero)   # recruter ne consomme pas l'action du héros

# Cases libres adjacentes où le type demandé peut se tenir
func _free_adjacent_cells(origin: Vector2i, type: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for nb in Pathfinder.get_neighbors(origin):
		if map.is_in_bounds(nb) and units_layer.get_unit_at(nb) == null \
				and Unit.STATS[type]["costs"].get(map.get_terrain(nb), 99) < 99:
			out.append(nb)
	return out

# ── Choix de sort au level-up ────────────────────────────────────────────────

func _maybe_show_levelup() -> void:
	if game_over or ai_thinking or level_up_panel.visible:
		return
	var hero := units_layer.get_hero(0)
	if hero == null or hero.pending_levelups == 0:
		return
	var pool := hero.unlearned_spells()
	if pool.is_empty():
		hero.pending_levelups = 0
		return
	pool.shuffle()
	_offered_spells = pool.slice(0, 2)
	for i in choice_btns.size():
		if i < _offered_spells.size():
			var def: Dictionary = Spells.POOL[_offered_spells[i]]
			choice_btns[i].text = "%s — %s" % [def["name"], def["desc"]]
			choice_btns[i].show()
		else:
			choice_btns[i].hide()
	level_up_panel.show()

func _on_spell_choice(index: int) -> void:
	var hero := units_layer.get_hero(0)
	if hero != null and index < _offered_spells.size():
		hero.learned_spells.append(_offered_spells[index])
		hero.pending_levelups -= 1
		print("Sort appris : %s" % Spells.POOL[_offered_spells[index]]["name"])
	level_up_panel.hide()
	_update_spell_bar()
	_maybe_show_levelup()   # d'autres niveaux en attente ?

# ── IA ───────────────────────────────────────────────────────────────────────

func _run_ai_turn() -> void:
	ai_thinking = true
	end_turn_btn.disabled = true
	_update_turn_label()

	await get_tree().create_timer(0.6).timeout

	# Snapshot des unités IA (la liste peut changer pendant le combat).
	# Le héros agit en dernier : son armée fait écran, il se place ensuite.
	var ai_units: Array[Unit] = []
	for child in units_layer.get_children():
		if child is Unit and (child as Unit).team == AI_TEAM \
				and not (child as Unit).is_hero():
			ai_units.append(child as Unit)
	var ai_hero := units_layer.get_hero(AI_TEAM)
	if ai_hero != null:
		ai_units.append(ai_hero)
		# L'IA apprend ses sorts sans écran de choix
		while ai_hero.pending_levelups > 0:
			var pool := ai_hero.unlearned_spells()
			if pool.is_empty():
				ai_hero.pending_levelups = 0
				break
			pool.shuffle()
			ai_hero.learned_spells.append(pool[0])
			ai_hero.pending_levelups -= 1
			print("IA apprend : %s" % Spells.POOL[pool[0]]["name"])
		_ai_recruit(ai_hero)

	for unit: Unit in ai_units:
		if not is_instance_valid(unit) or unit.has_moved:
			continue
		_ai_act_unit(unit)
		if _check_game_over():
			ai_thinking = false
			return
		await get_tree().create_timer(0.5).timeout

	ai_thinking = false
	end_turn_btn.disabled = false
	_end_turn()

func _ai_act_unit(unit: Unit) -> void:
	if not is_instance_valid(unit):
		return

	# Héros IA : comportement de commandant, sauf s'il est seul (il se bat)
	if unit.is_hero() and units_layer.count_team(AI_TEAM) > 1:
		_ai_act_hero(unit)
		return

	var target := AIPlayer.find_nearest_enemy(unit, units_layer)
	if target == null:
		unit.has_moved = true
		unit.queue_redraw()
		return

	# Attaque sur place si déjà à portée (le héros adverse en priorité)
	var in_range := units_layer.get_enemies_in_range(unit)
	if not in_range.is_empty():
		units_layer.do_combat(unit, AIPlayer.pick_attack_target(in_range))
		if is_instance_valid(unit):
			unit.has_moved = true
			unit.queue_redraw()
		return

	var reachable := Pathfinder.get_reachable(unit.cell, unit.remaining_mp, map, unit.type)

	# Village capturable à portée de déplacement : priorité territoriale
	if unit.can_capture():
		var vcell := AIPlayer.nearest_capturable_village(unit, reachable, villages, units_layer)
		if vcell != Vector2i(-99, -99):
			units_layer.move_unit(unit, vcell, reachable.get(vcell, 0))
			if is_instance_valid(unit):
				var after_cap := units_layer.get_enemies_in_range(unit)
				if not after_cap.is_empty():
					units_layer.do_combat(unit, AIPlayer.pick_attack_target(after_cap))
				if is_instance_valid(unit):
					unit.has_moved = true
					unit.queue_redraw()
			return

	# Déplacement vers la cible
	var dest := AIPlayer.best_move_towards(unit, target.cell, reachable, units_layer)

	if dest != unit.cell:
		var cost: int = reachable.get(dest, 0)
		units_layer.move_unit(unit, dest, cost)
	else:
		unit.has_moved = true
		unit.queue_redraw()

	# Attaque après déplacement
	if is_instance_valid(unit):
		var enemies_after := units_layer.get_enemies_in_range(unit)
		if not enemies_after.is_empty():
			units_layer.do_combat(unit, AIPlayer.pick_attack_target(enemies_after))
			if is_instance_valid(unit):
				unit.has_moved = true
				unit.queue_redraw()

# L'IA recrute autour de son héros : le type le moins représenté qu'elle peut payer
func _ai_recruit(hero: Unit) -> void:
	while true:
		var type := AIPlayer.pick_recruit(units_layer, AI_TEAM, gold[AI_TEAM])
		if type == -1:
			break
		var free := _free_adjacent_cells(hero.cell, type)
		if free.is_empty():
			break
		var u := units_layer.spawn(free[0], AI_TEAM, type)
		u.has_moved = true
		u.queue_redraw()
		gold[AI_TEAM] -= Unit.STATS[type]["cost"]
		villages.try_capture(u)
		print("IA recrute : %s" % u.unit_name())
	_update_gold_label()

# Héros IA en mode commandant : il ne mène jamais la charge.
# 1. PV bas → repli. 2. Cible achevable à portée → il prend le kill (sans
# riposte, +2 XP). 3. Sinon il escorte son armée hors du contact ennemi.
func _ai_act_hero(unit: Unit) -> void:
	if unit.hp < unit.max_hp * 0.4:
		var flee := Pathfinder.get_reachable(unit.cell, unit.remaining_mp, map, unit.type)
		var safe := AIPlayer.best_retreat(unit, flee, units_layer)
		if safe != unit.cell:
			units_layer.move_unit(unit, safe, flee.get(safe, 0))
		unit.has_moved = true
		unit.queue_redraw()
		return

	# Sorts : se soigner, ou boule de feu sur un groupe (jamais sur les siens)
	if unit.spell_ready("heal") and unit.hp <= unit.max_hp - Spells.HEAL_AMOUNT:
		units_layer.cast_spell(unit, "heal", unit.cell)
		unit.has_moved = true
		unit.queue_redraw()
		return
	if unit.spell_ready("fireball"):
		var center := AIPlayer.best_fireball_center(unit, units_layer)
		if center != Vector2i(-99, -99):
			units_layer.cast_spell(unit, "fireball", center)
			if is_instance_valid(unit):
				unit.has_moved = true
				unit.queue_redraw()
			_check_game_over()
			return

	var in_range := units_layer.get_enemies_in_range(unit)
	var kill := AIPlayer.pick_killable_target(unit, in_range, map)
	if kill != null:
		units_layer.do_combat(unit, kill)
		if is_instance_valid(unit):
			unit.has_moved = true
			unit.queue_redraw()
		return

	var reachable := Pathfinder.get_reachable(unit.cell, unit.remaining_mp, map, unit.type)
	var dest := AIPlayer.best_hero_position(unit, reachable, units_layer)
	if dest != unit.cell:
		units_layer.move_unit(unit, dest, reachable.get(dest, 0))

	# Après placement : ne frappe que si ça achève une cible
	if is_instance_valid(unit):
		var after := units_layer.get_enemies_in_range(unit)
		var kill_after := AIPlayer.pick_killable_target(unit, after, map)
		if kill_after != null:
			units_layer.do_combat(unit, kill_after)
		if is_instance_valid(unit):
			unit.has_moved = true
			unit.queue_redraw()

# ── UI ───────────────────────────────────────────────────────────────────────

func _on_attack_zone_pressed() -> void:
	units_layer.toggle_attack_zone()
	var showing := units_layer._show_attack_zone
	attack_zone_btn.text = "Masquer zone" if showing else "Zone d'attaque"

func _update_turn_label() -> void:
	var player_names := ["Joueur 1 (Bleu)", "IA (Rouge)"]
	var unit_label := ""
	if is_instance_valid(selected_unit):
		unit_label = selected_unit.unit_name()
	var spell_name: String = Spells.POOL[casting_spell]["name"] if casting_spell != "" else ""
	var hints := {
		State.IDLE:          "",
		State.UNIT_SELECTED: " — %s : déplacer ou attaquer" % unit_label,
		State.UNIT_MOVED:    " — %s : attaquer ou cliquer ailleurs" % unit_label,
		State.CASTING:       " — %s : choisir la cible" % spell_name,
		State.RECRUITING:    " — Recrutement : choisir la case",
	}
	var suffix: String = " — Réflexion…" if ai_thinking else hints.get(state, "")
	turn_label.text = "Tour %d — %s%s" % [turn_count, player_names[current_player], suffix]
	turn_label.modulate = Unit.TEAM_COLORS[current_player]
