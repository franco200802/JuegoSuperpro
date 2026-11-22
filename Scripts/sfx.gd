extends Node

const RATE: int = 22050
const VOICES: int = 8

var sounds: Dictionary = {}
var voices: Array[AudioStreamPlayer] = []
var next_voice: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in VOICES:
		var voice := AudioStreamPlayer.new()
		voice.volume_db = -6.0
		add_child(voice)
		voices.append(voice)

	sounds = {
		"jump": _synth(0.10, 260.0, 480.0, 0.0, 0.18),
		"double_jump": _synth(0.12, 380.0, 720.0, 0.0, 0.16),
		"dash": _synth(0.14, 900.0, 200.0, 0.8, 0.25),
		"attack": _synth(0.08, 1400.0, 500.0, 0.9, 0.2),
		"pogo": _synth(0.10, 500.0, 950.0, 0.2, 0.22),
		"hit": _synth(0.10, 320.0, 80.0, 0.45, 0.4),
		"block": _synth(0.09, 1100.0, 1000.0, 0.15, 0.2),
		"hurt": _synth(0.22, 420.0, 110.0, 0.3, 0.38),
		"death": _synth(0.70, 300.0, 40.0, 0.35, 0.38),
		"enemy_die": _synth(0.25, 500.0, 60.0, 0.6, 0.3),
		"thud": _synth(0.30, 130.0, 35.0, 0.7, 0.5),
		"gate": _synth(0.25, 170.0, 100.0, 0.5, 0.3),
		"growl": _synth(0.25, 180.0, 330.0, 0.35, 0.28),
		"buzz": _synth(0.35, 190.0, 260.0, 0.25, 0.16),
		"rest": _synth(0.50, 520.0, 1040.0, 0.0, 0.15),
		"unlock": _synth(0.70, 440.0, 880.0, 0.0, 0.2),
		"heal": _synth(0.30, 660.0, 1320.0, 0.0, 0.15),
	}


func play(sound: String) -> void:
	var voice: AudioStreamPlayer = voices[next_voice]
	next_voice = (next_voice + 1) % VOICES
	voice.stream = sounds[sound]
	voice.pitch_scale = randf_range(0.94, 1.06)
	voice.play()


func _synth(duration: float, from_hz: float, to_hz: float, noise: float, volume: float) -> AudioStreamWAV:
	var count: int = int(duration * RATE)
	var data := PackedByteArray()
	data.resize(count * 2)
	var phase: float = 0.0
	var smooth: float = 0.0
	for i in count:
		var t: float = float(i) / count
		phase = fmod(phase + lerpf(from_hz, to_hz, t) / RATE, 1.0)
		var square: float = 1.0 if phase < 0.5 else -1.0
		smooth = lerpf(smooth, lerpf(square, randf_range(-1.0, 1.0), noise), 0.35)
		var envelope: float = minf(1.0, i / (RATE * 0.004)) * pow(1.0 - t, 2.0)
		data.encode_s16(i * 2, int(clampf(smooth * envelope * volume, -1.0, 1.0) * 32767.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.data = data
	return wav
