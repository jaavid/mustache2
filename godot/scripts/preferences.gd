extends RefCounted
## Storage adapter: the round model has no filesystem or browser dependencies.
const FILE := "user://preferences.cfg"
var best := 0
var muted := false
var reduced_motion := false
var _config := ConfigFile.new()


func _init() -> void:
	_config.load(FILE)
	best = int(_config.get_value("game", "best", 0))
	muted = bool(_config.get_value("game", "muted", false))
	reduced_motion = bool(_config.get_value("game", "reduced_motion", false))


func toggle_sound() -> void:
	muted = not muted
	_save("muted", muted)


func toggle_motion() -> void:
	reduced_motion = not reduced_motion
	_save("reduced_motion", reduced_motion)


func record_score(score: int) -> void:
	if score <= best:
		return
	best = score
	_save("best", best)


func _save(key: String, value: Variant) -> void:
	_config.set_value("game", key, value)
	_config.save(FILE)
