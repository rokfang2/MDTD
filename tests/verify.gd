extends SceneTree

var game
var failures: Array[String] = []
var checks = 0
var original_save = ""
var had_save = false

func _initialize() -> void:
	_run.call_deferred()

func check(condition: bool, message: String) -> void:
	checks += 1
	if not condition:
		failures.append(message)
		print("FAIL: ", message)
	else:
		print("PASS: ", message)

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func press(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func _run() -> void:
	had_save = FileAccess.file_exists("user://progress.json")
	if had_save:
		original_save = FileAccess.get_file_as_string("user://progress.json")
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	await frames(2)
	check(game.state == "menu", "menu inicial")
	game.new_game()
	await frames(20)
	var player = game.world.player
	check(player.is_on_floor(), "personagem nasce sobre o chão")
	var start_x = player.position.x
	Input.action_press("right")
	await frames(20)
	Input.action_release("right")
	check(player.position.x > start_x + 50, "movimento por input real")
	await frames(5)
	var floor_y = player.position.y
	await press("jump")
	await frames(7)
	check(player.position.y < floor_y - 30, "salto por input real")
	await frames(65)
	player.numb = 1.7
	check(not player.try_dash(), "dormência impede dash")
	player.numb = 0
	player.dash_cooldown = 0
	check(player.try_dash(), "dash liberado sem dormência")
	var hp = player.hp
	player.take_damage(1, Vector2.ZERO)
	check(player.hp == hp, "dash concede invulnerabilidade")
	await frames(70)
	# Travessia real do desnível e do vão da trilha.
	player.restore(Vector2(630, 490))
	player.invulnerable = 100 # Isolar a geometria do dano de contato do inimigo do platô.
	await frames(5)
	Input.action_press("right")
	Input.action_press("jump")
	await frames(24)
	Input.action_release("jump")
	await frames(30)
	Input.action_release("right")
	await frames(15)
	check(player.position.x > 800 and player.is_on_floor() and player.position.y < 450, "subida ao platô por salto")
	player.restore(Vector2(990, 444))
	await frames(4)
	Input.action_press("right")
	Input.action_press("jump")
	await frames(24)
	Input.action_release("jump")
	await frames(25)
	Input.action_release("right")
	await frames(20)
	check(player.position.x > 1140 and player.is_on_floor(), "travessia do vão por salto")
	# Combate contra inimigo: dano somente dentro do arco.
	var enemy = game.world.enemies[0]
	player.restore(Vector2(enemy.x - 70, enemy.y))
	player.facing = 1
	await frames(2)
	player.try_attack()
	check(enemy.hp == 24, "dano espera o início do corte visível")
	await frames(5)
	check(enemy.hp == 12, "lâmina acerta inimigo próximo")
	await frames(22)
	player.position = Vector2(enemy.x - 70, enemy.y)
	player.try_attack()
	await frames(5)
	check(enemy.hp == 0, "inimigo derrotado após dois golpes")
	player.restore(Vector2(1490, 506))
	await frames(4)
	await press("interact")
	await frames(100)
	check(game.checkpoint == Vector2(1490, 506) and player.hp == 5, "lótus ativa checkpoint e cura")
	check(FileAccess.file_exists("user://progress.json"), "progresso salvo em disco")
	player.position = Vector2(1900, 506)
	await frames(4)
	await press("interact")
	check(game.state == "memory" and "border" in game.memories, "interação coleta memória e pausa o mundo")
	game.resume_game()
	player.position = Vector2(game.world.Level.PORTAL_X, 506)
	await frames(3)
	await press("interact")
	check(game.world.mode == "arena", "passagem E entra na arena")
	await frames(5)
	player = game.world.player
	var boss = game.world.boss
	check(boss.active and boss.hp == 180, "guardião inicia com vida completa")
	game.show_pause()
	var timer = boss.timer
	await frames(20)
	check(is_equal_approx(boss.timer, timer), "pausa congela o chefe")
	game.resume_game()
	# Testar os três padrões por seus efeitos reais.
	player.invulnerable = 0
	game.world._boss_attack("invert", player.position, 1)
	check(player.inverted > 0, "ataque sensorial aplica inversão temporária")
	player.velocity = Vector2.ZERO
	var previous = player.position.x
	Input.action_press("right")
	await frames(12)
	Input.action_release("right")
	check(player.position.x < previous, "inversão altera a direção real do movimento")
	game.world.hazards.clear()
	game.world._boss_attack("spores", player.position, 1)
	check(game.world.shots.size() == 3, "padrão de esporos cria projéteis")
	game.world.shots.clear()
	player.invulnerable = 0
	player.inverted = 0
	player.position = Vector2(400, 590)
	player.velocity = Vector2.ZERO
	game.world._boss_attack("roots", player.position, 1)
	await frames(15)
	check(player.hp == 4, "raízes causam dano na área marcada")
	game.world.hazards.clear()
	player.invulnerable = 0
	player.numb = 0
	game.world.shots.append({"pos": player.position + Vector2(0, -40), "vel": Vector2.ZERO, "life": 2.0, "radius": 12.0})
	await frames(2)
	check(player.numb > 0 and player.hp == 3, "esporo causa dano e dormência")
	game.world.flower = true
	check(game.world.use_flower() and player.numb == 0, "Calêndula cura dormência")
	check(not game.world.use_flower(), "Calêndula respeita recarga")
	player.invulnerable = 0
	player.take_damage(5, boss.position)
	check(game.state == "dead", "morte abre renascimento e congela arena")
	game.start_world("trail")
	await frames(5)
	check(absf(game.world.player.position.x - 1490) < 2, "renascimento no último lótus")
	game.start_world("arena")
	await frames(5)
	player = game.world.player
	boss = game.world.boss
	# Vitória usando o mesmo caminho de dano da lâmina.
	player.position = Vector2(850, 590)
	player.facing = 1
	player.invulnerable = 100
	for i in range(15):
		player.attack_cooldown = 0
		player.try_attack()
		await frames(5)
	check(boss.phase == 2, "vida baixa ativa segunda fase")
	check(boss.hp == 0 and boss.state == "dying" and not game.world.reward_ready,"golpe letal inicia colapso antes de liberar recompensa")
	await frames(170)
	check(boss.hp == 0 and game.world.reward_ready, "derrota limpa ataques e libera altar")
	check(game.world.shots.is_empty() and game.world.hazards.is_empty(), "arena segura após vitória")
	player.position = game.world.reward_position+Vector2(0,-60)
	player.velocity = Vector2.ZERO
	await frames(2)
	await press("interact")
	check(not game.world.praying and game.state != "victory", "altar não permite oração enquanto personagem está no ar")
	player.position = game.world.reward_position
	await frames(3)
	await press("interact")
	check(game.state != "victory" and game.world.praying, "recompensa também exige oração antes de salvar")
	await frames(100)
	check(game.state == "victory" and game.flower, "altar entrega fragmento e Calêndula")
	game._read_save()
	check(game.save_data.get("flower", false), "recompensa persiste no save")
	# Restaurar exatamente o save anterior aos testes.
	if had_save:
		var file = FileAccess.open("user://progress.json", FileAccess.WRITE)
		file.store_string(original_save)
	else:
		DirAccess.remove_absolute(ProjectSettings.globalize_path("user://progress.json"))
	print("RESULT: ", checks - failures.size(), "/", checks, " checks passed")
	game.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
