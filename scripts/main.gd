extends Node2D

enum State { IDLE, UNIT_SELECTED, UNIT_MOVED }

const AI_TEAM := 1

@onready var map: GameMap            = $GameMap
@onready var camera: Camera2D        = $Camera2D
@onready var units_layer: UnitsLayer = $UnitsLayer
@onready var turn_label: Label       = $UI/TurnLabel
@onready var attack_zone_btn: Button = $UI/AttackZoneButton
@onready var end_turn_btn: Button    = $UI/EndTurnButton

var state := State.IDLE
var selected_unit: Unit      = null
var attackable_enemies: Array[Unit] = []
var current_player := 0
var ai_thinking    := false

func _ready() -> void:
	var mid := map.get_map_size() / 2
	camera.global_position = map.to_global(map.map_to_local(mid))
	_update_turn_label()

# ── Entrées ──────────────────────────────────────────────────────────────────

func _input(event: InputEvent) -> void:
	if ai_thinking:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE]:
			_end_turn()

func _unhandled_input(event: InputEvent) -> void:
	if ai_thinking:
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
				if clicked != null and clicked.team != current_player \
						and cell in Pathfinder.get_neighbors(selected_unit.cell):
					var attacker := selected_unit
					units_layer.do_combat(attacker, clicked)
					if is_instance_valid(attacker):
						attacker.has_moved = true
						attacker.queue_redraw()
					_deselect()
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

# ── Transitions d'état ───────────────────────────────────────────────────────

func _select(unit: Unit) -> void:
	selected_unit = unit
	unit.selected = true
	unit.queue_redraw()
	state = State.UNIT_SELECTED
	units_layer.show_reachable(unit)
	attack_zone_btn.show()
	attack_zone_btn.text = "Zone d'attaque"
	_update_turn_label()

func _after_move() -> void:
	attack_zone_btn.hide()
	attackable_enemies = units_layer.get_adjacent_enemies(selected_unit)
	if attackable_enemies.is_empty():
		_deselect()
		return
	for u: Unit in attackable_enemies:
		u.attackable = true
		u.queue_redraw()
	state = State.UNIT_MOVED
	_update_turn_label()

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
	units_layer.clear_reachable()
	attack_zone_btn.hide()
	_update_turn_label()

func _end_turn() -> void:
	if ai_thinking:
		return
	_deselect()
	units_layer.reset_team(current_player)
	current_player = 1 - current_player
	_update_turn_label()
	if current_player == AI_TEAM:
		_run_ai_turn()  # coroutine lancée en arrière-plan

# ── IA ───────────────────────────────────────────────────────────────────────

func _run_ai_turn() -> void:
	ai_thinking = true
	end_turn_btn.disabled = true
	_update_turn_label()

	await get_tree().create_timer(0.6).timeout

	# Snapshot des unités IA (la liste peut changer pendant le combat)
	var ai_units: Array[Unit] = []
	for child in units_layer.get_children():
		if child is Unit and (child as Unit).team == AI_TEAM:
			ai_units.append(child as Unit)

	for unit: Unit in ai_units:
		if not is_instance_valid(unit) or unit.has_moved:
			continue
		_ai_act_unit(unit)
		await get_tree().create_timer(0.5).timeout

	ai_thinking = false
	end_turn_btn.disabled = false
	_end_turn()

func _ai_act_unit(unit: Unit) -> void:
	if not is_instance_valid(unit):
		return

	var target := AIPlayer.find_nearest_enemy(unit, units_layer)
	if target == null:
		unit.has_moved = true
		unit.queue_redraw()
		return

	# Attaque sur place si déjà adjacent
	var adjacent := units_layer.get_adjacent_enemies(unit)
	if not adjacent.is_empty():
		units_layer.do_combat(unit, adjacent[0])
		if is_instance_valid(unit):
			unit.has_moved = true
			unit.queue_redraw()
		return

	# Déplacement vers la cible
	var reachable := Pathfinder.get_reachable(unit.cell, unit.remaining_mp, map)
	var dest := AIPlayer.best_move_towards(unit, target.cell, reachable, units_layer)

	if dest != unit.cell:
		var cost: int = reachable.get(dest, 0)
		units_layer.move_unit(unit, dest, cost)
	else:
		unit.has_moved = true
		unit.queue_redraw()

	# Attaque après déplacement
	if is_instance_valid(unit):
		var enemies_after := units_layer.get_adjacent_enemies(unit)
		if not enemies_after.is_empty():
			units_layer.do_combat(unit, enemies_after[0])
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
	var hints := {
		State.IDLE:          "",
		State.UNIT_SELECTED: " — Déplacer",
		State.UNIT_MOVED:    " — Attaquer ou cliquer ailleurs",
	}
	var suffix: String = " — Réflexion…" if ai_thinking else hints.get(state, "")
	turn_label.text = player_names[current_player] + suffix
	turn_label.modulate = Unit.TEAM_COLORS[current_player]
