extends "res://tests/capture.gd"

# Rodar em snapshot com user:// isolado, sem disputar o foco com o usuário.
func _run() -> void:
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	DisplayServer.window_set_position(Vector2i(-32000,-32000))
	await super._run()
