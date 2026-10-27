extends SceneTree

# Render-only staging in an isolated copy. Never write the player's progress.
var game
var world
var directory = "res://review/art_cohesion/captures"
var trace: FileAccess

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func snap(label: String) -> void:
	if world != null:
		world.player.sprite.modulate = Color.WHITE
	await RenderingServer.frame_post_draw
	var error = root.get_texture().get_image().save_png(directory.path_join(label+".png"))
	if error != OK:
		push_error("CAPTURE FAILED: "+label)
		quit(1)
	var position = world.player.position if world != null else Vector2.ZERO
	trace.store_csv_line(PackedStringArray([label,str(position.x),str(position.y)]))
	trace.flush()
	print("CAPTURE: ",label," ",position)

func place(at: Vector2) -> void:
	world.player.restore(at)
	world.player.invulnerable = 100
	world.player.facing = 1
	world.shots.clear()
	world.hazards.clear()
	world.camera_target = clampf(at.x,640,world.Level.WIDTH-640) if world.mode == "trail" else 640.0
	world.camera_target_y = clampf(at.y-210,360,480) if world.mode == "trail" else 360.0
	await frames(8)

func _run() -> void:
	if not OS.get_user_data_dir().ends_with("MushroomsArtCohesionPreviewQA"):
		push_error("Refusing captures outside isolated preview namespace")
		quit(1)
		return
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			directory = arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	DisplayServer.window_set_position(Vector2i(-32000,-32000))
	AudioServer.set_bus_mute(0,true)
	trace = FileAccess.open(directory.path_join("action_positions.csv"),FileAccess.WRITE)
	trace.store_csv_line(PackedStringArray(["capture","x","y"]))
	game = load("res://Scenes/main.tscn").instantiate()
	game.persist_progress = false
	root.add_child(game)
	await frames(2)
	game.ambience.stop()
	game.ambience.stream = null
	await snap("16_menu")
	game.start_world("trail")
	world = game.world
	world.sound.disconnect(game.play_sound)
	await place(Vector2(1770,506))
	await snap("17_trail_idle")
	Input.action_press("right")
	for i in range(4):
		await frames(6)
		await snap("18_run_"+str(i))
	Input.action_release("right")
	await frames(15)
	Input.action_press("attack")
	await frames(5)
	await snap("19_horizontal_attack")
	Input.action_release("attack")
	await frames(20)
	await place(Vector2(1435,506))
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	await frames(32)
	await snap("20_prayer")
	await frames(65)
	game.start_world("arena")
	world = game.world
	world.sound.disconnect(game.play_sound)
	world.boss.active = false
	await place(Vector2(550,590))
	await snap("21_arena")
	Input.action_press("attack")
	await frames(5)
	await snap("22_arena_attack")
	Input.action_release("attack")
	trace.close()
	print("ACTION_CAPTURE_COMPLETE: menu, trail, run, attack, prayer, arena")
	await game.shutdown()
