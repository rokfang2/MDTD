extends SceneTree

var game
var world
var directory = "res://review/large_map/captures"
var trace: FileAccess

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func snap(label: String) -> void:
	# Invulnerabilidade isola os cenários; só o piscar é suprimido na foto.
	world.player.sprite.modulate = Color.WHITE
	await RenderingServer.frame_post_draw
	var result = root.get_texture().get_image().save_png(directory.path_join(label+".png"))
	if result != OK:
		push_error("Capture failed: "+label)
		quit(1)
	trace.store_csv_line(PackedStringArray([label,str(world.player.position.x),str(world.player.position.y),str(world.camera.position.x),str(world.camera.position.y),game.region_label.text]))
	trace.flush()
	print("CAPTURE: ",label," player=",world.player.position," camera=",world.camera.position)

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
	world.sound.disconnect(game.play_sound)
	trace = FileAccess.open(directory.path_join("positions.csv"),FileAccess.WRITE)
	trace.store_csv_line(PackedStringArray(["capture","x","y","camera_x","camera_y","region"]))
	var scenes = [
		["01_old_new_connection",Vector2(6500,506)],
		["02_gallery_descent",Vector2(6850,578)],
		["03_gallery_lower",Vector2(7360,650)],
		["04_gallery_upper",Vector2(7470,278)],
		["05_third_lotus",Vector2(8525,506)],
		["06_canopy_gap",Vector2(9020,506)],
		["07_old_canopy",Vector2(9500,220)],
		["08_canopy_lower",Vector2(9950,578)],
		["09_fourth_lotus",Vector2(10635,450)],
		["10_vestibule_lower",Vector2(11620,610)],
		["11_vestibule_branch",Vector2(11850,222)],
		["12_vestibule_crossroads",Vector2(11680,298)],
		["13_final_gap",Vector2(12330,450)],
		["14_nest_portal",Vector2(world.Level.PORTAL_X-40,506)]
	]
	for scene in scenes:
		world.player.restore(scene[1])
		world.player.invulnerable = 100
		world.player.facing = 1
		world.shots.clear()
		world.hazards.clear()
		world.camera_target = clampf(scene[1].x,640,world.Level.WIDTH-640)
		world.camera_target_y = clampf(scene[1].y-210,360,480)
		await frames(10)
		await snap(scene[0])
	# Tab usa o mesmo caminho de input do jogo; o portal e os seis setores
	# devem caber no painel mesmo com a câmera no extremo novo da fase.
	world.player.restore(Vector2(11530,298))
	await frames(5)
	Input.action_press("map")
	await frames(2)
	Input.action_release("map")
	await frames(2)
	await snap("15_complete_map")
	Input.action_press("map")
	await frames(2)
	Input.action_release("map")
	trace.close()
	trace = null
	print("CAPTURE_COMPLETE: 15 scenes")
	await game.shutdown()
