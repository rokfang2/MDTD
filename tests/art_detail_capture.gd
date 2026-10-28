extends SceneTree

# Quadros reais com input simulado e atores separados, para revisão visual.
# Não escreve progresso nem representa teste humano de sensação de jogo.
var directory = "res://review/style_a_fix/details"

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func snap(name: String) -> void:
	await RenderingServer.frame_post_draw
	var error = root.get_texture().get_image().save_png(directory.path_join(name+".png"))
	if error != OK:
		push_error("Detail capture failed: "+name)
		quit(1)
	print("DETAIL: ",name)

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var game = load("res://Scenes/main.tscn").instantiate()
	game.persist_progress = false
	root.add_child(game)
	await process_frame
	game.new_game()
	await frames(2)
	game.hud.visible = false
	game.ui.visible = false
	root.content_scale_size = Vector2i(640,360)
	root.size = Vector2i(640,360)
	var world = game.world
	# Camera fixa; física dos atores e animação continuam rodando.
	world.set_physics_process(false)
	world.camera.position = Vector2(1870,430)
	world.camera.offset = Vector2.ZERO
	for enemy in world.enemies:
		enemy.hp = 0
	var ant = world.enemies[2]
	ant.hp = 24
	ant.x = 2080.0
	ant.y = 506.0
	ant.home = 2080.0
	ant.base_y = 506.0
	ant.direction = -1.0
	ant.state = "patrol"
	ant.timer = 10.0
	world.player.restore(Vector2(1680,506))
	world.player.invulnerable = 0
	Input.action_press("right")
	for i in range(4):
		for j in range(6):
			world._tick_enemies(1.0/60.0)
			world.queue_redraw()
			await frames(1)
		await snap("walk_%d" % i)
	Input.action_release("right")
	ant.hp = 0
	var fly = world.enemies[9]
	fly.hp = 24
	fly.x = 2090.0
	fly.y = 450.0
	fly.home = 2090.0
	fly.base_y = 450.0
	fly.state = "patrol"
	fly.timer = 10.0
	world.player.restore(Vector2(1700,506))
	world.player.invulnerable = 0
	for i in range(4):
		for j in range(6):
			world._tick_enemies(1.0/60.0)
			world.queue_redraw()
			await frames(1)
		await snap("flight_%d" % i)
	await game.shutdown()
