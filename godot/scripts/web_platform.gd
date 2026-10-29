extends RefCounted


## Optional Telegram adapter. All authentication stays inside the existing JS bridge.
func start_round() -> void:
	_call("start")


func finish_round(result: Dictionary) -> void:
	# Keep the existing backend contract; presentation-only result fields stay local.
	_call(
		"finish",
		{
			"score": result.score,
			"caught": result.caught,
			"shots": result.shots,
			"elapsedSeconds": result.elapsedSeconds,
		}
	)


func _call(action: String, payload: Dictionary = {}) -> void:
	if not OS.has_feature("web"):
		return
	JavaScriptBridge.eval(
		(
			"if(window.mustachePlatform) window.mustachePlatform.call("
			+ JSON.stringify(action)
			+ ","
			+ JSON.stringify(payload)
			+ ");"
		)
	)
