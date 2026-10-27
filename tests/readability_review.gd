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
	print("PASS: " if value else "FAIL: ",message)
	if not value:
		failures.append(message)

func _run() -> void:
	var main = load("res://scripts/main.gd").new()
	main._setup_inputs()
	main.free()
	var art = load("res://scripts/pixel_art.gd")
	check(art.SCALE == 4 and art.actor(0).get_height() <= 32 and art.insect().get_width() == 36, "estilo A usa sprites de baixa resolução ampliados 4x sem filtro")
	check(art.insect().get_width()*art.SCALE >= 140, "inimigo terrestre tem silhueta maior e legível")
	var world = load("res://scripts/world.gd").new()
	root.add_child(world)
	for enemy in world.enemies:
		enemy.hp = 0
	var ant = world.enemies[2]
	ant.hp = 24
	world.player.restore(Vector2(2050,506))
	world.player.invulnerable = 0
	var furthest = ant.x
	for i in range(400):
		await frames(1)
		furthest = maxf(furthest,ant.x)
	check(furthest > ant.home+150, "batedor persegue além do antigo limite da origem")
	check(world.player.hp < 5, "batedor alcança e acerta jogador parado no mesmo piso")
	ant.hp = 0
	var fly = world.enemies[9]
	fly.hp = 24
	world.player.restore(Vector2(3280,282))
	world.player.invulnerable = 0
	await frames(400)
	check(world.player.hp < 5, "voador mergulha até alcançar jogador na rota elevada")
	fly.hp = 0
	var edge = world.enemies[0]
	edge.hp = 24
	world.player.restore(Vector2(800,444))
	world.player.invulnerable = 100
	var warnings = 0
	for i in range(300):
		await frames(1)
		if edge.state == "tell":
			warnings += 1
	check(warnings == 0, "batedor não repete ataques contra jogador em outro platô")
	world.queue_free()
	await frames(2)
	print("RESULT: ",checks-failures.size(),"/",checks," readability checks passed")
	quit(0 if failures.is_empty() else 1)
