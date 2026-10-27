extends SceneTree

# Registro da engine com input simulado. Executar em cópia isolada do projeto.
var game
var world
var player
var directory = "res://review/motion/sequence"
var frame_index = 0
var saved_index = 0
var long_run = false
var states: FileAccess
const Art = preload("res://scripts/pixel_art.gd")

func _initialize() -> void:
	_run.call_deferred()

func advance(label: String, count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame
		if long_run:
			world.camera.position.x = roundf(player.position.x / 2.0) * 2.0
			world.camera.force_update_scroll()
		var run_phase = int(player.run_distance / player.RUN_CYCLE_DISTANCE * player.run_frames.size()) % player.run_frames.size()
		var clip = "land" if player.motion_state == "brake" else player.motion_state
		var pose = -1
		if Art.MOTION_CLIPS.has(clip):
			for j in range(Art.motion_count(clip)):
				if player.sprite.texture == Art.motion(clip,j):
					pose = j
		states.store_csv_line(PackedStringArray([str(frame_index),str(player.clock),label,player.motion_state,str(player.position.x),str(player.position.y),str(player.velocity.x),str(player.velocity.y),str(player.is_on_floor()),str(player.attack_pending),str(player.attack_time),str(player.run_distance),str(run_phase),str(player.facing),clip,str(pose),str(world.camera.position.x),str(world.camera.position.y)]))
		await RenderingServer.frame_post_draw
		if true: # Registrar todos os quadros, 60 FPS, inclusive as transições curtas.
			var pixels = root.get_texture().get_image()
			var path = directory.path_join("frame_%04d.png" % saved_index)
			if pixels.is_empty() or pixels.save_png(path) != OK:
				push_error("Motion capture failed: "+path)
				quit(1)
			saved_index += 1
		frame_index += 1
	states.flush()
	print("MOTION: ",label," frames=",frame_index)

func press(action: String) -> void:
	Input.action_press(action)

func release(action: String) -> void:
	Input.action_release(action)

func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg == "--long-run":
			long_run = true
		if arg.begins_with("--motion-dir="):
			directory = arg.trim_prefix("--motion-dir=")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	# Janela auxiliar fora da área de trabalho, sem roubar foco da sessão do usuário.
	DisplayServer.window_set_flag(DisplayServer.WINDOW_FLAG_NO_FOCUS,true)
	DisplayServer.window_set_position(Vector2i(-32000,-32000))
	AudioServer.set_bus_mute(0,true)
	game = load("res://scenes/main.tscn").instantiate()
	game.persist_progress = false
	root.add_child(game)
	await process_frame
	# Dummy + captura acelerada não precisa manter playback ambiente em loop.
	game.ambience.stop()
	game.ambience.stream = null
	game.start_world("arena")
	world = game.world
	world.boss.active = false
	world.boss.visible = false
	world.set_physics_process(false)
	world.camera.position = Vector2(640,450)
	world.camera.offset = Vector2.ZERO
	game.hud.visible = false
	game.ui.visible = false
	root.content_scale_size = Vector2i(640,360)
	root.size = Vector2i(640,360)
	player = world.player
	player.restore(Vector2(490,590))
	player.invulnerable = 0
	states = FileAccess.open(directory.path_join("motion_states.csv"),FileAccess.WRITE)
	states.store_csv_line(PackedStringArray(["frame","clock","segment","state","x","y","vx","vy","grounded","attack_pending","attack_time","run_distance","run_phase","facing","clip","pose","camera_x","camera_y"]))
	await advance("idle",66)
	press("right")
	await advance("run_right",120 if long_run else 42)
	release("right")
	await advance("stop_right",12)
	press("left")
	await advance("run_left",120 if long_run else 42)
	release("left")
	await advance("stop_left",12)
	press("jump")
	await advance("jump_hold",12)
	release("jump")
	await advance("jump_release_land",36)
	press("right")
	await advance("face_right",1)
	release("right")
	press("dash")
	await advance("dash_right",1)
	release("dash")
	await advance("dash_finish",30)
	press("attack")
	await advance("attack_right_start",1)
	release("attack")
	await advance("attack_right",20)
	press("left")
	await advance("face_left",1)
	release("left")
	press("attack")
	await advance("attack_left_start",1)
	release("attack")
	await advance("attack_left",20)
	press("down")
	await advance("crouch",18)
	release("down")
	await advance("idle_before_prayer",12)
	player.praying = true
	await advance("prayer",96)
	player.praying = false
	await advance("idle_after_prayer",12)
	player.take_damage(1, player.position + Vector2(1,0))
	# A captura desliga apenas o piscar para tornar as duas poses de dano legíveis.
	player.invulnerable = 0
	await advance("hurt_and_recover",36)
	states.close()
	states = null
	print("MOTION_COMPLETE: ",saved_index," PNG frames, ",frame_index," physics frames")
	await game.shutdown()
