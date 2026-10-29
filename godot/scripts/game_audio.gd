extends Node
## Procedural sound playback; no gameplay decisions.
var muted := false
var _player := AudioStreamPlayer.new()


func _ready() -> void:
	add_child(_player)


func play_tone(frequency: float, duration: float) -> void:
	if muted:
		return
	var audio := AudioStreamWAV.new()
	audio.format = AudioStreamWAV.FORMAT_16_BITS
	audio.mix_rate = 22050
	var samples := int(duration * 22050)
	var bytes := PackedByteArray()
	bytes.resize(samples * 2)
	for i in range(samples):
		var t := float(i) / 22050.0
		var envelope := (1.0 - float(i) / samples) * minf(1, t * 200)
		var value := int(sin(TAU * frequency * t * (1 - t * 2)) * envelope * 5000)
		bytes.encode_s16(i * 2, value)
	audio.data = bytes
	_player.stream = audio
	_player.play()
