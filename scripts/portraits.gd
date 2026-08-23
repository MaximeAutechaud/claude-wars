class_name Portraits

# Portraits illustrés (détourés) pour les personnages nommés de la boîte de
# dialogue (dialogue_box.gd) — à défaut d'entrée ici, DialoguePortrait
# retombe sur sa silhouette générique de secours.
const BY_SPEAKER: Dictionary = {
	"Le Héros": preload("res://assets/portraits/heros.png"),
}

static func for_speaker(speaker: String) -> Texture2D:
	return BY_SPEAKER.get(speaker)
