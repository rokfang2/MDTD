extends SceneTree

var directory = "res://review/captures"

func _initialize() -> void:
	_run.call_deferred()

func snap(name: String, delay: float = 0.18) -> void:
	await create_timer(delay).timeout
	await RenderingServer.frame_post_draw
	var path = directory.path_join(name + ".png")
	var error = root.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Capture failed: " + path)
		quit(1)
	print("CAPTURE: ", ProjectSettings.globalize_path(path))

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture-dir="):
			directory = arg.trim_prefix("--capture-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var game = load("res://Scenes/main.tscn").instantiate()
	game.persist_progress = false
	root.add_child(game)
	await process_frame
	await snap("01_menu")
	game.new_game()
	await snap("02_trail")
	game.world.player.restore(Vector2(1490, 506))
	game.world.player.invulnerable = 0
	await snap("03_lotus")
	game.show_pause()
	await snap("04_pause")
	game.resume_game()
	game.start_world("arena")
	game.world.player.position = Vector2(710, 590)
	game.world.boss.pattern = 0
	game.world.boss.state = "tell"
	game.world.boss.timer = 0.8
	game.world.boss.target = Vector2(710, 590)
	await snap("05_arena")
	game.world.boss.pattern = 3
	game.world.boss.state = "tell"
	game.world.boss.timer = 0.8
	game.world.boss.charge_goal = 710
	await snap("14_charge_warning")
	game.world.boss.state = "strike"
	game.world.boss.timer = 0.48
	await snap("15_charge",0.16)
	game.world.boss.position.x = 990
	game.world.boss.active = false
	game.world.player.position = Vector2(550, 590)
	game.world.player.facing = 1
	game.world.player.try_attack()
	await snap("06_slash", 0.09)
	await create_timer(0.25).timeout
	game.world.player.try_dash()
	await snap("07_dash", 0.065)
	await create_timer(0.3).timeout
	game.world.player.restore(Vector2(990, 590))
	game.world.player.invulnerable = 0
	game.world.boss.active = true
	game.world.boss.receive_hit(game.world.boss.hp)
	await snap("08_reward")
	game.start_world("trail")
	game.world.player.restore(Vector2(2700,360))
	await snap("10_crossing")
	game.world.map_open = true
	await snap("11_routes_map")
	game.world.map_open = false
	game.world.player.restore(Vector2(5310,506))
	await create_timer(0.1).timeout
	game.world.activate_lotus(Vector2(5310,506))
	await snap("12_prayer",0.6)
	await create_timer(1).timeout
	game.world.player.restore(Vector2(5500,278))
	await snap("13_upper_route")
	game.world.player.restore(Vector2(2172,506))
	await snap("16_connection_west",0.8)
	game.world.player.restore(Vector2(4344,506))
	await snap("17_connection_east",0.8)
	game.world.player.restore(Vector2(1770,506))
	game.world.player.invulnerable = 100
	await snap("18_scout_walk_a",0.6)
	await snap("19_scout_walk_b",0.2)
	game.world.player.restore(Vector2(5310,506))
	await create_timer(0.1).timeout
	game.world.activate_lotus(Vector2(5310,506))
	await create_timer(0.35).timeout
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.world.camera.position = Vector2(5390,450)
	game.world.camera.offset = Vector2.ZERO
	game.hud.visible = false
	game.ui.visible = false
	root.content_scale_size = Vector2i(640,360)
	root.size = Vector2i(640,360)
	await snap("20_prayer_closeup")
	root.content_scale_size = Vector2i(1280,720)
	root.size = Vector2i(1280,720)
	game.world.process_mode = Node.PROCESS_MODE_INHERIT
	# Enquadramento 1:1 do conjunto para julgar densidade de pixels e encaixe.
	game.start_world("trail")
	game.world.player.restore(Vector2(1570, 506))
	game.world.player.invulnerable = 0
	await create_timer(0.12).timeout
	game.world.process_mode = Node.PROCESS_MODE_DISABLED
	game.world.camera.position = Vector2(1580, 452)
	game.world.camera.offset = Vector2.ZERO
	game.hud.visible = false
	game.ui.visible = false
	root.content_scale_size = Vector2i(640, 360)
	root.size = Vector2i(640, 360)
	await snap("09_cohesion")
	await game.shutdown()
