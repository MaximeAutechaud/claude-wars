class_name DialogueBox
extends Control

# Boîte de dialogue façon Phoenix Wright : un portrait qui "parle" (bump
# vertical) pendant que le texte se révèle lettre par lettre avec un blip
# sonore généré à la volée (pas d'asset audio requis), boîte de nom, flèche
# pour continuer, pause plus longue sur la ponctuation. Système générique :
# `play()` prend un script de dialogue en données (voir dialogue_demo.gd
# pour un exemple), aucun contenu narratif en dur ici.
#
# Format attendu pour une ligne : {"speaker": String, "text": String,
# "color": Color (optionnel — sinon assignée automatiquement par locuteur)}.

signal finished

const CHAR_INTERVAL := 0.026       # secondes entre deux lettres révélées
const PUNCT_PAUSE := 0.20          # pause supplémentaire sur . ! ?
const COMMA_PAUSE := 0.10          # pause supplémentaire sur ,
const BUMP_AMPLITUDE := 5.0        # px de tremblement du portrait qui parle
const BUMP_SPEED := 14.0

# Un blip toutes les BLIP_EVERY lettres (pas une par lettre) : à la vitesse
# du typewriter, un blip par caractère se chevauche et sonne comme une
# mitraillette plutôt que des blips distincts façon Animal Crossing.
const BLIP_EVERY := 2
const BLIP_VOLUME_DB := -6.0

const PALETTE := [
	Color(0.30, 0.60, 1.0), Color(1.0, 0.35, 0.35), Color(0.45, 0.85, 0.55),
	Color(1.0, 0.75, 0.25), Color(0.75, 0.55, 1.0), Color(0.35, 0.85, 0.85),
]

@onready var portrait: DialoguePortrait = $Portrait
@onready var name_label: Label = $NameTag/NameMargin/NameLabel
@onready var text_label: RichTextLabel = $TextPanel/TextMargin/TextLabel
@onready var continue_arrow: Label = $TextPanel/ContinueArrow
@onready var blip_player: AudioStreamPlayer = $Blip

var lines: Array = []
var index: int = -1
var total_chars: int = 0
var chars_shown: int = 0
var line_done: bool = false
var char_timer: float = 0.0
var pause_timer: float = 0.0
var talk_time: float = 0.0
var speaker_colors: Dictionary = {}
var blip_wav: AudioStreamWAV
var _blip_count := 0

func _ready() -> void:
	blip_wav = _make_blip_wav()
	blip_player.volume_db = BLIP_VOLUME_DB
	visible = false
	continue_arrow.visible = false
	set_process(false)

func play(script_lines: Array) -> void:
	lines = script_lines
	index = -1
	speaker_colors.clear()
	visible = true
	set_process(true)
	_advance_line()

func _process(delta: float) -> void:
	if index < 0 or index >= lines.size():
		return
	if pause_timer > 0.0:
		pause_timer -= delta
		return
	if not line_done:
		talk_time += delta
		portrait.bob_offset = sin(talk_time * BUMP_SPEED) * BUMP_AMPLITUDE
		portrait.queue_redraw()
		char_timer += delta
		while char_timer >= CHAR_INTERVAL and not line_done:
			char_timer -= CHAR_INTERVAL
			_reveal_next_char()

func _reveal_next_char() -> void:
	chars_shown += 1
	var finishing := chars_shown >= total_chars
	if finishing:
		chars_shown = total_chars
	text_label.visible_characters = chars_shown
	var ch := _char_at(chars_shown - 1)
	if ch != "" and ch != " " and ch != "\n":
		_blip_count += 1
		if _blip_count % BLIP_EVERY == 0:
			_play_blip()
	if finishing:
		_end_line()
	elif ch == "." or ch == "!" or ch == "?":
		pause_timer = PUNCT_PAUSE
	elif ch == ",":
		pause_timer = COMMA_PAUSE

func _end_line() -> void:
	line_done = true
	portrait.bob_offset = 0.0
	portrait.queue_redraw()
	continue_arrow.visible = true

func _char_at(i: int) -> String:
	var t := text_label.get_parsed_text()
	return t[i] if i >= 0 and i < t.length() else ""

func advance() -> void:
	if index < 0:
		return
	if not line_done:
		chars_shown = total_chars
		text_label.visible_characters = chars_shown
		_end_line()
	else:
		_advance_line()

func _advance_line() -> void:
	index += 1
	if index >= lines.size():
		visible = false
		set_process(false)
		finished.emit()
		return
	var line: Dictionary = lines[index]
	var speaker: String = str(line.get("speaker", "???"))
	var color: Color = line.get("color", _color_for(speaker))
	var portrait_tex: Texture2D = line.get("portrait", Portraits.for_speaker(speaker))
	name_label.text = speaker
	name_label.add_theme_color_override("font_color", color)
	portrait.set_speaker(speaker, color, portrait_tex)
	_pop_portrait()
	text_label.text = str(line.get("text", ""))
	total_chars = text_label.get_total_character_count()
	chars_shown = 0
	text_label.visible_characters = 0
	line_done = false
	char_timer = 0.0
	pause_timer = 0.0
	talk_time = 0.0
	_blip_count = 0
	continue_arrow.visible = false

func _pop_portrait() -> void:
	portrait.pivot_offset = portrait.size * 0.5
	portrait.scale = Vector2(0.9, 0.9)
	var tw := create_tween()
	tw.tween_property(portrait, "scale", Vector2(1.03, 1.03), 0.09) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(portrait, "scale", Vector2.ONE, 0.08)

func _color_for(speaker: String) -> Color:
	if not speaker_colors.has(speaker):
		speaker_colors[speaker] = PALETTE[speaker_colors.size() % PALETTE.size()]
	return speaker_colors[speaker]

func _play_blip() -> void:
	blip_player.stream = blip_wav
	var base := 0.85 + float(hash(name_label.text) % 100) / 100.0 * 0.5
	blip_player.pitch_scale = base + randf_range(-0.05, 0.05)
	blip_player.play()

# Blip procédural (pas d'asset audio requis) : ton bref et doux, quasi
# sinusoïdal (un soupçon de 2e harmonique pour le grain, pas de carré —
# trop dur/nasillard à ce volume), attaque courte pour éviter le clic et
# decay exponentiel (plus naturel qu'une rampe linéaire).
func _make_blip_wav() -> AudioStreamWAV:
	var mix_rate := 22050
	var duration := 0.03
	var n := int(mix_rate * duration)
	var attack_n := maxi(1, int(n * 0.12))
	var bytes := PackedByteArray()
	bytes.resize(n * 2)
	var freq := 340.0
	for i in n:
		var t := float(i) / mix_rate
		var decay := exp(-7.0 * float(i) / n)
		var attack := minf(1.0, float(i) / attack_n)
		var env := decay * attack
		var s := sin(TAU * freq * t) + 0.12 * sin(TAU * freq * 2.0 * t)
		var v := int(clampf(s * env * 0.8, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, v)
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = mix_rate
	wav.stereo = false
	wav.data = bytes
	return wav

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		advance()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER \
				or event.keycode == KEY_KP_ENTER or event.keycode == KEY_Z:
			advance()
			get_viewport().set_input_as_handled()
