extends Control

# Écran d'accueil (décision 15) : Continuer (si une sauvegarde existe),
# Nouvelle partie, Quitter. C'est la scène principale du projet ; le jeu
# lui-même (main.tscn) est chargé par-dessus.

const MAIN_SCENE := "res://scenes/main.tscn"

@onready var continue_btn: Button = $Center/Box/ContinueButton
@onready var sub_label: Label = $Center/Box/SubLabel

func _ready() -> void:
	sub_label.text = "Acte I — " + Scenario.CURRENT["name"]
	var save := SaveGame.read()
	if save.is_empty():
		continue_btn.disabled = true
		continue_btn.text = "Continuer"
	else:
		continue_btn.text = "Continuer  (tour %d)" % int(save["turn"])
	# Fondu d'entrée
	modulate.a = 0.0
	create_tween().tween_property(self, "modulate:a", 1.0, 0.5)

func _on_continue_pressed() -> void:
	var save := SaveGame.read()
	if save.is_empty():
		return
	Scenario.active = Scenario.CURRENT
	SaveGame.pending = save
	get_tree().change_scene_to_file(MAIN_SCENE)

func _on_new_game_pressed() -> void:
	Scenario.active = Scenario.CURRENT
	SaveGame.pending = {}
	get_tree().change_scene_to_file(MAIN_SCENE)

# Carte de test : petit tableau sans brouillard avec le roster complet des
# deux côtés — pour vérifier sprites, animations et mécaniques en jouant
func _on_test_map_pressed() -> void:
	Scenario.active = Scenario.SANDBOX
	SaveGame.pending = {}
	get_tree().change_scene_to_file(MAIN_SCENE)

func _on_quit_pressed() -> void:
	get_tree().quit()

# Démo de la boîte de dialogue façon Phoenix Wright (premier jet, texte et
# portraits placeholder) — pour playtester le feel indépendamment d'un tableau
func _on_dialogue_test_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/dialogue_demo.tscn")

# Fond : la trame hexagonale du jeu, en filigrane sur le fond sombre
func _draw() -> void:
	var size := get_viewport_rect().size
	var hw := GameMap.TILE_W * 0.5
	var hh := GameMap.TILE_H * 0.5
	var line := Color(0.35, 0.55, 1.0, 0.06)
	var col := 0
	var x := 0.0
	while x < size.x + hw:
		var y_off := hh if col % 2 == 1 else 0.0
		var y := y_off
		while y < size.y + hh:
			var pts := GameMap.hex_corners(Vector2(x, y), hw - 1.5, hh - 1.5)
			pts.append(pts[0])
			draw_polyline(pts, line, 1.5)
			y += GameMap.TILE_H
		x += GameMap.TILE_W * 0.75
		col += 1
