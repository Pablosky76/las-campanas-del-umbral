extends Node

const PUEBLO = preload("res://arte/audio/valdebronce.wav")
const MINA = preload("res://arte/audio/mina.wav")
const SAVE := "user://audio.cfg"
const VOLUMEN := -5.0
const SILENCIO := -72.0

var pistas: Array[AudioStreamPlayer] = []
var destino := 0
var silenciado := false
var mezcla: Tween

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE) == OK:
		silenciado = config.get_value("audio", "silenciado", false) == true
	for original: AudioStreamWAV in [PUEBLO, MINA]:
		var pista := AudioStreamPlayer.new()
		var bucle: AudioStreamWAV = original.duplicate()
		bucle.loop_mode = AudioStreamWAV.LOOP_FORWARD
		bucle.loop_end = roundi(bucle.get_length() * bucle.mix_rate)
		pista.stream = bucle
		pista.volume_db = SILENCIO
		add_child(pista)
		pistas.append(pista)
		pista.play()
	cambiar_zona(false)

func cambiar_zona(en_mina: bool) -> void:
	destino = int(en_mina)
	if mezcla and mezcla.is_running():
		mezcla.kill()
	mezcla = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE)
	for index in pistas.size():
		mezcla.tween_property(pistas[index], "volume_db", VOLUMEN if index == destino and not silenciado else SILENCIO, 1.45)

func alternar() -> void:
	silenciado = not silenciado
	cambiar_zona(destino == 1)
	var config := ConfigFile.new()
	config.set_value("audio", "silenciado", silenciado)
	config.save(SAVE)
