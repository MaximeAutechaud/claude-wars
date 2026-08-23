extends Control

# Démo jouable de la boîte de dialogue (premier jet, personnages et
# portraits placeholder) — accessible depuis l'écran d'accueil pour
# playtester le feel sans passer par une vraie scène narrative.

const TITLE_SCENE := "res://scenes/title.tscn"
const DIALOGUE_BOX := preload("res://scenes/dialogue_box.tscn")

const DEMO_LINES: Array = [
	{"speaker": "Le Héros", "text": "Voilà donc le fameux Fossoyeur... Je ne pensais pas te trouver si vite."},
	{"speaker": "Le Fossoyeur", "text": "Tu me cherchais, petit Chroniqueur ? Voilà une erreur que tu ne referas pas deux fois."},
	{"speaker": "Le Héros", "text": "J'ai vu ce que tu fais à tes propres soldats. Ce n'est pas de la stratégie. C'est un sacrifice."},
	{"speaker": "Le Fossoyeur", "text": "Un sacrifice librement consenti, Chroniqueur. Chacun d'eux savait ce qu'il faisait en jurant sous mes ordres."},
	{"speaker": "???", "text": "(Ceci est un texte de test — personnages, portraits et noms définitifs restent à faire.)"},
]

@onready var dialogue: DialogueBox = $DialogueBox

func _ready() -> void:
	dialogue.finished.connect(_on_finished)
	dialogue.play(DEMO_LINES)

func _on_finished() -> void:
	get_tree().change_scene_to_file(TITLE_SCENE)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		get_tree().change_scene_to_file(TITLE_SCENE)

# Même filigrane hexagonal que l'écran d'accueil, pour un décor de fond
# cohérent tant qu'il n'y a pas de vrai arrière-plan de scène
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
