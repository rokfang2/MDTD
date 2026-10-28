extends SceneTree

var checks = 0
var failures: Array[String] = []
var entered = 0
var collected = ""
var world

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

func interact() -> void:
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	await frames(2)

func jump_to(player, x: float) -> void:
	var direction = "right" if player.position.x < x else "left"
	Input.action_press(direction)
	Input.action_press("jump")
	for i in range(60):
		if absf(player.position.x-x) < 12:
			Input.action_release(direction)
		await frames(1)
	Input.action_release(direction)
	Input.action_release("jump")
	await frames(5)

func _run() -> void:
	var controller = load("res://scripts/main.gd").new()
	controller._setup_inputs()
	controller.free()
	world = load("res://scripts/world.gd").new()
	world.mode = "trail"
	root.add_child(world)
	world.entered_arena.connect(func(): entered += 1)
	world.memory_found.connect(func(id, _text): collected = id)
	var player = world.player
	player.restore(Vector2(2070, 506))
	await frames(5)
	await interact()
	check(entered == 0, "fim da antiga trilha continua o mapa em vez de entrar no chefe")
	player.restore(Vector2(2000, 506))
	player.invulnerable = 100
	Input.action_press("right")
	await frames(105)
	Input.action_release("right")
	check(player.position.x > 2450 and player.is_on_floor(), "travessia contínua entre primeiro e segundo trecho")
	check(world.camera.position.x > 2000, "câmera acompanha o mapa além do limite anterior")
	player.restore(Vector2(3040, 450))
	player.invulnerable = 100
	await frames(5)
	Input.action_press("right")
	Input.action_press("jump")
	await frames(25)
	Input.action_release("jump")
	await frames(35)
	Input.action_release("right")
	await frames(15)
	check(player.position.x > 3230 and player.is_on_floor() and player.enabled, "salto atravessa o vão da travessia de raízes")
	player.restore(Vector2(2700, 360))
	await frames(5)
	await interact()
	check(collected == "bridge", "desvio elevado contém memória interativa")
	player.restore(Vector2(5310, 506))
	await frames(5)
	await interact()
	check(world.player.motion_state == "pray" and world.checkpoint != Vector2(5310, 506), "oração visível começa antes de salvar")
	await frames(100)
	check(world.checkpoint == Vector2(5310, 506), "segundo lótus guarda checkpoint no terceiro trecho")
	player.hp = 2
	await interact()
	check(player.motion_state == "pray" and player.hp == 2, "lótus já ativado exige nova oração antes de curar")
	await frames(100)
	check(player.hp == 5, "oração repetida conclui cura")
	player.restore(Vector2(1490,506))
	await frames(5)
	await interact()
	player.invulnerable = 0
	player.take_damage(1,Vector2(1400,506))
	# Isolar interrupção por este golpe dos novos perseguidores próximos.
	player.invulnerable = 100
	await frames(100)
	check(world.checkpoint == Vector2(5310,506) and player.hp == 4 and not world.praying, "dano cancela oração sem salvar nem curar")
	# Subida real pela rota alternativa e retorno pelo outro lado.
	player.restore(Vector2(380,490))
	player.invulnerable = 100
	await frames(5)
	await jump_to(player,480)
	await jump_to(player,620)
	await jump_to(player,760)
	check(absf(player.position.y-262) < 3 and player.is_on_floor(), "entrada oeste alcança rota superior por saltos reais")
	Input.action_press("right")
	await frames(90)
	Input.action_release("right")
	check(player.position.x > 1080 and player.position.y < 265, "rota superior percorre caminho alternativo conectado")
	player.restore(Vector2(960,262))
	await frames(5)
	Input.action_press("down")
	Input.action_press("jump")
	await frames(2)
	Input.action_release("jump")
	Input.action_release("down")
	await frames(50)
	check(player.position.y > 430 and player.is_on_floor() and player.enabled, "S + pulo desce pela raiz sem prender o personagem")
	player.restore(Vector2(1510,506))
	player.invulnerable = 100
	await frames(5)
	await jump_to(player,1440)
	await jump_to(player,1300)
	await jump_to(player,1170)
	check(absf(player.position.y-262) < 3 and player.is_on_floor(), "entrada leste permite explorar rota superior no sentido contrário")
	for route in [
		{"start":Vector2(2372,506),"steps":[2500,2570,2700,2860],"top":282},
		{"start":Vector2(3800,490),"steps":[3730,3550,3460],"top":282},
		{"start":Vector2(4460,506),"steps":[4580,4650,4790,5020],"top":278},
		{"start":Vector2(6000,506),"steps":[5900,5730,5650],"top":278}
	]:
		player.restore(route.start)
		player.invulnerable = 100
		await frames(5)
		for x in route.steps:
			await jump_to(player,x)
		check(absf(player.position.y-route.top) < 3 and player.is_on_floor(), "rota alternativa acessível por input a partir de x=%d" % route.start.x)
	# Consultar o mapa interrompe a movimentação, e fechar devolve controle.
	var before = player.position
	Input.action_press("map")
	await frames(2)
	Input.action_release("map")
	Input.action_press("right")
	await frames(20)
	check(world.map_open and player.position == before, "mapa permite consultar rotas com mundo parado")
	Input.action_release("right")
	Input.action_press("map")
	await frames(2)
	Input.action_release("map")
	check(not world.map_open and player.is_physics_processing(), "fechar mapa devolve o controle")
	# IA de patrulha detecta, avisa, ataca e oferece recuperação.
	var scout = world.enemies[3]
	player.restore(Vector2(scout.home+160,scout.y))
	player.invulnerable = 100
	await frames(5)
	scout.state = "patrol"
	scout.timer = 0
	await frames(2)
	check(scout.state == "tell", "batedor anuncia ataque ao detectar jogador")
	await frames(41)
	check(scout.state == "strike", "batedor executa investida depois do aviso")
	await frames(22)
	check(scout.state == "recover", "investida possui janela de recuperação")
	var spitter = world.enemies[4]
	player.restore(Vector2(spitter.home-160,spitter.y))
	player.invulnerable = 100
	spitter.state = "patrol"
	spitter.timer = 0
	world.shots.clear()
	await frames(45)
	check(not world.shots.is_empty(), "inimigo lançador usa projétil após aviso")
	var checkpoint = world.checkpoint
	world.queue_free()
	await frames(2)
	world = load("res://scripts/world.gd").new()
	world.checkpoint = checkpoint
	root.add_child(world)
	await frames(8)
	check(absf(world.player.position.x - 5310) < 2 and world.player.is_on_floor(), "renascimento no segundo lótus em solo válido")
	world.queue_free()
	await frames(2)
	# Percurso principal completo por input; invulnerabilidade isola a geometria.
	world = load("res://scripts/world.gd").new()
	root.add_child(world)
	player = world.player
	player.invulnerable = 100
	await frames(5)
	var jumps = world.Level.MAIN_JUMPS.right
	var next_jump = 0
	var held = 0
	Input.action_press("right")
	for i in range(3600):
		if next_jump < jumps.size() and player.position.x >= jumps[next_jump] and player.is_on_floor():
			Input.action_press("jump")
			held = 25
			next_jump += 1
		if held > 0:
			held -= 1
			if held == 0:
				Input.action_release("jump")
		await frames(1)
		if player.position.x > world.Level.PORTAL_X-40 or not player.enabled:
			break
	Input.action_release("right")
	Input.action_release("jump")
	check(player.position.x > world.Level.PORTAL_X-40 and player.enabled, "percurso principal inteiro ampliado é atravessável por movimento e saltos")
	entered = 0
	world.entered_arena.connect(func(): entered += 1)
	await interact()
	check(entered == 1, "portal final permite entrar na arena ao fim do mapa ampliado")
	world.queue_free()
	await frames(2)
	print("RESULT: ", checks - failures.size(), "/", checks, " map expansion checks passed")
	quit(0 if failures.is_empty() else 1)
