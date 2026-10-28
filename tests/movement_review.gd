extends SceneTree

var world
var player
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

func reset(at: Vector2 = Vector2(400, 590)) -> void:
	for action in ["left", "right", "jump", "dash", "attack"]:
		Input.action_release(action)
	player.restore(at)
	player.invulnerable = 100
	await frames(5)

func jump_height(hold: int) -> float:
	await reset()
	var lowest = player.position.y
	Input.action_press("jump")
	for i in range(70):
		if i == hold:
			Input.action_release("jump")
		await frames(1)
		lowest = minf(lowest, player.position.y)
	return 590 - lowest

func _run() -> void:
	# Somente configurar o InputMap; não carregar jogo/save nem chamar _ready do menu.
	var controller = load("res://scripts/main.gd").new()
	controller._setup_inputs()
	controller.free()
	world = load("res://scripts/world.gd").new()
	world.mode = "arena"
	root.add_child(world)
	world.boss.active = false
	player = world.player
	await reset()
	Input.action_press("right")
	await frames(6)
	check(player.velocity.x > 200 and player.velocity.x <= player.SPEED, "aceleração responde nos primeiros 100 ms")
	await frames(5)
	check(is_equal_approx(player.velocity.x, player.SPEED), "atinge velocidade de corrida")
	var stop_at = player.position.x
	Input.action_release("right")
	await frames(8)
	check(absf(player.velocity.x) < 1 and player.position.x - stop_at < 22, "parada em menos de 22 px sem deslizar")
	var short_height = await jump_height(2)
	var long_height = await jump_height(35)
	print("METRIC: salto curto=", short_height, " px; longo=", long_height, " px")
	check(short_height > 20 and long_height > short_height + 50, "altura do salto responde ao tempo de comando")
	await reset()
	player.facing = 1
	Input.action_press("dash")
	await frames(2)
	Input.action_release("dash")
	Input.action_press("left")
	var x_before = player.position.x
	await frames(5)
	check(player.position.x > x_before and player.dash_direction == 1, "comando oposto não vira o dash no meio")
	Input.action_release("left")
	await frames(5)
	check(player.dash_time == 0 and absf(player.velocity.x) <= player.SPEED, "fim do dash remove velocidade excedente")
	await reset()
	player.facing = 1
	var start = player.position.x
	player.try_dash()
	await frames(10)
	var distance = player.position.x - start
	print("METRIC: distância dash=", distance)
	check(distance > 120 and distance < 155, "distância de dash entre 120 e 155 px")
	await reset(Vector2(1240, 590))
	player.facing = 1
	player.try_dash()
	await frames(10)
	check(player.position.x < 1270 and player.dash_time == 0, "parede encerra o dash sem atravessar colisão")
	await reset()
	player.dash_cooldown = 0.07
	Input.action_press("dash")
	await frames(1)
	Input.action_release("dash")
	await frames(5)
	check(player.dash_time > 0, "dash antecipado é guardado até terminar recarga")
	await reset()
	player.numb = 0.8
	Input.action_press("dash")
	await frames(1)
	Input.action_release("dash")
	await frames(8)
	check(player.dash_time == 0, "buffer não ignora dormência")
	await reset()
	player.invulnerable = 0
	player.take_damage(1, Vector2(500, 540))
	Input.action_press("right")
	await frames(5)
	check(player.velocity.x < -200 and player.hurt_lock > 0, "recuo resiste ao comando contrário durante dano")
	check(not player.try_dash() and not player.try_attack(), "dano interrompe dash e ataque durante recuo")
	Input.action_release("right")
	await frames(15)
	check(player.hurt_lock == 0, "controle volta após recuo curto")
	await reset()
	player.invulnerable = 0
	player.try_attack()
	player.take_damage(1, Vector2(500, 540))
	check(not player.attack_pending, "dano cancela golpe ainda não disparado")
	await reset()
	player.try_attack()
	player.try_dash()
	check(not player.attack_pending, "dash cancela golpe pendente sem dano atrasado")
	await reset()
	player.attack_cooldown = 0.07
	Input.action_press("attack")
	await frames(1)
	Input.action_release("attack")
	await frames(5)
	check(player.attack_time > 0, "ataque antecipado é guardado até terminar recarga")
	await reset(Vector2(400, 550))
	player.velocity.y = 300
	player.coyote = 0
	await frames(1)
	Input.action_press("jump")
	await frames(9)
	Input.action_release("jump")
	check(player.velocity.y < 0, "pulo antecipado é executado ao aterrissar")
	# Verificar os três padrões emitidos pelo estado natural do chefe.
	await reset(Vector2(200, 590))
	var patterns: Array[String] = []
	world.boss.attack.connect(func(kind, _target, _phase): patterns.append(kind))
	world.boss.active = true
	for i in range(820):
		player.invulnerable = 10
		await frames(1)
	check("spores" in patterns and "invert" in patterns and "roots" in patterns and "charge" in patterns, "IA natural percorre os quatro ataques com telegráficos")
	world.boss.active = false
	world.queue_free()
	await frames(2)
	world = load("res://scripts/world.gd").new()
	world.mode = "trail"
	root.add_child(world)
	player = world.player
	await reset(Vector2(1025, 444))
	Input.action_press("right")
	var left_edge = false
	for i in range(15):
		await frames(1)
		if not player.is_on_floor():
			left_edge = true
			break
	await frames(2)
	Input.action_press("jump")
	await frames(2)
	check(left_edge and player.velocity.y < -400, "tolerância permite pular logo após sair da borda")
	Input.action_release("jump")
	Input.action_release("right")
	print("RESULT: ", checks - failures.size(), "/", checks, " movement checks passed")
	world.queue_free()
	await frames(2)
	quit(0 if failures.is_empty() else 1)
