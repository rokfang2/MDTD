extends SceneTree

const Art = preload("res://scripts/pixel_art.gd")
var game
var world
var player
var directory = "res://review/stationary_prayer/captures"
var trace: FileAccess
var camera_at = Vector2(1490,420)

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func snap(label: String) -> void:
	world.camera.position = camera_at
	world.camera.offset = Vector2.ZERO
	world.camera.force_update_scroll()
	await RenderingServer.frame_post_draw
	var result = root.get_texture().get_image().save_png(directory.path_join(label+".png"))
	if result != OK:
		push_error("Capture failed: "+label)
		quit(1)
	trace.store_csv_line(PackedStringArray([label,str(player.position.x),str(player.position.y),str(player.facing),str(player.sprite.flip_h),player.motion_state,str(world.praying)]))
	trace.flush()
	print("CAPTURE: ",label," position=",player.position," facing=",player.facing)

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			directory = arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	DisplayServer.window_set_position(Vector2i(-32000,-32000))
	AudioServer.set_bus_mute(0,true)
	game = load("res://scenes/main.tscn").instantiate()
	game.persist_progress = false
	root.add_child(game)
	await process_frame
	game.ambience.stop()
	game.ambience.stream = null
	game.start_world("trail")
	world = game.world
	# Captura visual acelerada não inicia playback WAV no driver Dummy.
	world.sound.disconnect(game.play_sound)
	world.enemies.clear()
	world.hazards.clear()
	world.shots.clear()
	game.hud.visible = false
	game.ui.visible = false
	root.content_scale_size = Vector2i(640,360)
	root.size = Vector2i(640,360)
	player = world.player
	trace = FileAccess.open(directory.path_join("positions.csv"),FileAccess.WRITE)
	trace.store_csv_line(PackedStringArray(["capture","x","y","facing","flip_h","state","world_praying"]))
	# Apenas o posicionamento inicial dos cenários é controlado. O acionamento
	# do lótus usa a tecla E e o processamento normal do mundo/jogador.
	for side in ["left","right"]:
		world._cancel_prayer()
		player.restore(Vector2(1435 if side == "left" else 1545,506))
		player.invulnerable = 0
		player.facing = -1 if side == "left" else 1
		await frames(8)
		await snap(side+"_before")
		Input.action_press("interact")
		await frames(1)
		Input.action_release("interact")
		await snap(side+"_start")
		await frames(20)
		await snap(side+"_praying")
		await frames(75)
		await snap(side+"_complete")
	player.restore(Vector2(1700,506))
	player.invulnerable = 0
	await frames(8)
	Input.action_press("right")
	await frames(18)
	camera_at = Vector2(player.position.x,420)
	await snap("crouch_before")
	Input.action_press("down")
	await frames(1)
	await snap("crouch_start")
	await frames(30)
	await snap("crouch_held_right")
	Input.action_release("right")
	Input.action_release("down")
	await frames(8)
	Input.action_press("right")
	var seen: Dictionary = {}
	for i in range(70):
		await frames(1)
		var phase = player.run_frames.find(player.sprite.texture)
		if phase >= 0 and not seen.has(phase):
			seen[phase] = true
			camera_at = Vector2(player.position.x,420)
			await snap("run_%02d" % phase)
		if seen.size() == 12:
			break
	Input.action_release("right")
	trace.close()
	trace = null
	print("CAPTURE_COMPLETE: run poses=",seen.size())
	await game.shutdown()
