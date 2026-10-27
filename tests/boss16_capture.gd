extends SceneTree

var game
var world
var directory = "res://review/borders_boss/boss_captures"
var trace: FileAccess

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func snap(label: String) -> void:
	world.player.sprite.modulate = Color.WHITE
	await RenderingServer.frame_post_draw
	var result = root.get_texture().get_image().save_png(directory.path_join(label+".png"))
	if result != OK:
		push_error("CAPTURE FAILED: "+label)
		quit(1)
	trace.store_csv_line(PackedStringArray([label,world.boss.state,str(world.boss.phase),str(world.boss.position.x),str(world.player.position.x),str(world.boss.target.x),str(world.boss.death_frame),str(world.boss.death_elapsed),str(world.reward_ready),str(world.player.inverted)]))
	trace.flush()
	print("CAPTURE: ",label," state=",world.boss.state," death=",world.boss.death_frame," time=",world.boss.death_elapsed," reward=",world.reward_ready)

func arena(player_at: Vector2 = Vector2(400,590)) -> void:
	game.start_world("arena")
	world = game.world
	world.sound.disconnect(game.play_sound)
	world.boss.position.x = 760
	world.player.restore(player_at)
	world.player.invulnerable = 100
	await frames(6)

func prepare(pattern: int, player_at: Vector2) -> void:
	await arena(player_at)
	world.boss.pattern = posmod(pattern-1,4)
	world.boss.state = "recover"
	world.boss.timer = 0.001
	await frames(2)

func wait_strike() -> void:
	for i in range(120):
		if world.boss.state == "strike":
			return
		await frames(1)
	push_error("Timed out waiting for natural strike")
	quit(1)

func _run() -> void:
	if not OS.get_user_data_dir().ends_with("MushroomsBordersBossPreviewQA"):
		push_error("Refusing capture outside isolated preview namespace")
		quit(1)
		return
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
	await frames(2)
	game.ambience.stop()
	game.ambience.stream = null
	trace = FileAccess.open(directory.path_join("sequence.csv"),FileAccess.WRITE)
	trace.store_csv_line(PackedStringArray(["capture","state","phase","boss_x","player_x","locked_target_x","death_frame","death_elapsed","reward_ready","inversion"]))
	await prepare(0,Vector2(400,590))
	await frames(25)
	await snap("01_roots_tell")
	Input.action_press("right")
	await frames(35)
	Input.action_release("right")
	await wait_strike()
	await frames(8)
	await snap("02_roots_locked_target")
	for side in [-1,1]:
		await prepare(1,Vector2(760+side*300,590))
		await frames(20)
		await snap("03_spores_tell_"+str(side))
		await wait_strike()
		await frames(5)
		await snap("04_spores_strike_"+str(side))
	await prepare(2,Vector2(400,590))
	await frames(42)
	await snap("05_pulse_tell")
	Input.action_press("jump")
	await wait_strike()
	Input.action_release("jump")
	await frames(3)
	await snap("06_pulse_airborne")
	await prepare(3,Vector2(260,590))
	await frames(25)
	await snap("07_charge_tell")
	await wait_strike()
	await frames(12)
	await snap("08_charge_motion")
	await frames(24)
	await snap("09_recovery")
	world.boss.receive_hit(96)
	await frames(15)
	await snap("10_phase_shift")
	await arena(Vector2(590,590))
	world.boss.hp = 12
	world.boss.state = "recover"
	world.boss.timer = 20
	world.player.facing = 1
	await snap("11_before_finishing_cut")
	Input.action_press("attack")
	await frames(5)
	Input.action_release("attack")
	for i in range(20):
		if world.boss.state == "dying":
			break
		await frames(1)
	if world.boss.state != "dying":
		push_error("Finishing sword input did not begin death")
		quit(1)
		return
	var timings = [0.05,0.28,0.64,1.08,1.66,2.22,2.85,4.0]
	var started = world.boss.clock-world.boss.death_elapsed
	for i in range(timings.size()):
		while world.boss.clock-started < timings[i]:
			await frames(1)
		await snap("12_collapse_"+str(i))
	trace.close()
	print("BOSS_CAPTURE_COMPLETE")
	await game.shutdown()
