extends SceneTree

var checks = 0
var failures: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func check(value: bool, message: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", message)
	if not value:
		failures.append(message)

func _run() -> void:
	var controller = load("res://scripts/main.gd").new()
	controller._setup_inputs()
	controller.free()
	# Regressão: usar a marca anunciada para desviar deve evitar o dano real.
	# Falha se apenas a área danosa for deslocada ao limitar sua posição à arena.
	for start_x in [16.0, 1264.0]:
		var world = load("res://scripts/world.gd").new()
		world.mode = "arena"
		root.add_child(world)
		var boss = world.boss
		var player = world.player
		boss.active = false
		player.restore(Vector2(start_x, 590))
		await frames(5)
		boss.pattern = 3
		boss.state = "recover"
		boss.timer = 0.001
		boss.active = true
		await frames(2)
		check(boss.state == "tell" and boss.pattern == 0, "padrão natural anuncia raízes junto à parede %.0f" % start_x)
		var announced_x = boss.target.x
		# A marca tem meia largura 85; desviar 110 px deixa margem de 25 px.
		player.position.x = announced_x + (110 if start_x < 640 else -110)
		player.velocity = Vector2.ZERO
		player.invulnerable = 0
		await frames(90)
		check(player.hp == 5, "desviar da marca evita dano junto à parede %.0f (aviso=%.0f, destino=%.0f, HP=%d)" % [start_x, announced_x, player.position.x, player.hp])
		world.queue_free()
		await frames(2)
	for start_x in [150.0,1250.0]:
		var world = load("res://scripts/world.gd").new()
		world.mode = "arena"
		root.add_child(world)
		world.player.restore(Vector2(start_x,590))
		world.player.invulnerable = 100
		world.boss.phase = 2
		world.boss.pattern = 2
		world.boss.state = "recover"
		world.boss.timer = 0.001
		await frames(2)
		var goal = world.boss.charge_goal
		check(world.boss.state == "tell" and world.boss.pattern == 3 and world.boss.sprite.flip_h == (start_x > 990),"mandíbulas orientadas na direção anunciada da investida")
		await frames(77)
		check(absf(world.boss.position.x-goal) < 5,"trajetória da investida de fase II termina no limite anunciado")
		world.queue_free()
		await frames(2)
	print("RESULT: ", checks - failures.size(), "/", checks, " review regression checks passed")
	quit(0 if failures.is_empty() else 1)
