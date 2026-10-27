extends SceneTree

# Cena mínima: não instancia Main nem lê/escreve progresso.
var player
var failures: Array[String] = []
var checks = 0
var slashes = 0

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures.append(label)

func reset() -> void:
	for action in ["left", "right", "jump", "down", "dash", "attack"]:
		Input.action_release(action)
	player.restore(Vector2(400, 590))
	await frames(6)

func _run() -> void:
	for action in ["left", "right", "jump", "down", "dash", "attack"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	var floor_body = StaticBody2D.new()
	var shape = CollisionShape2D.new()
	var rectangle = RectangleShape2D.new()
	rectangle.size = Vector2(4000, 40)
	shape.shape = rectangle
	shape.position = Vector2(1000, 610)
	floor_body.add_child(shape)
	root.add_child(floor_body)
	player = load("res://scripts/player.gd").new()
	root.add_child(player)
	player.slash.connect(func(_origin, _direction): slashes += 1)
	await reset()
	Input.action_press("right")
	var run_textures: Dictionary = {}
	# Observar um ciclo completo mais o tempo de aceleração, sem impor a
	# janela curta da cadência antiga ao novo ritmo da corrida.
	var run_ticks = ceili((player.RUN_CYCLE_DISTANCE/player.SPEED + player.SPEED/player.GROUND_ACCEL)*60) + 2
	for i in range(run_ticks):
		await frames(1)
		run_textures[hash(player.sprite.texture.get_image().get_data())] = true
	check(run_textures.size() >= 12, "corrida percorre pelo menos12 desenhos distintos no ciclo")
	Input.action_release("right")
	await frames(1)
	check(player.motion_state != "run", "soltar direção interrompe imediatamente a animação de corrida")
	check(player.motion_state == "brake" and player.sprite.texture != player.idle_frame and absf(player.velocity.x) > 20, "desaceleração mostra freio enquanto ainda existe deslocamento")
	await frames(8)
	check(player.motion_state == "idle" and absf(player.velocity.x) < 1, "repouso aparece quando a frenagem termina")
	await reset()
	var idle = player.sprite.texture
	Input.action_press("down")
	await frames(1)
	check(player.sprite.texture != idle and player.sprite.texture != load("res://scripts/pixel_art.gd").prayer(), "agachar possui pose própria sem reutilizar oração")
	var crouch_images: Dictionary = {}
	for i in range(9):
		crouch_images[hash(player.sprite.texture.get_image().get_data())] = true
		await frames(1)
	check(crouch_images.size() == 2, "agachar mostra entrada e pose assentada")
	await reset()
	player.try_attack()
	var attack_images: Dictionary = {}
	var windup: Texture2D
	var active: Texture2D
	var forward_cut_synced = true
	for i in range(13):
		await frames(1)
		attack_images[hash(player.sprite.texture.get_image().get_data())] = true
		if not player.attack_pending and player.attack_time > player.ATTACK_RECOVERY:
			forward_cut_synced = forward_cut_synced and player.sprite.texture == load("res://scripts/pixel_art.gd").motion("attack",2)
		if i == 0:
			windup = player.sprite.texture
			check(player.attack_pending and slashes == 0, "preparação aparece antes do disparo de dano")
		if i == 3:
			active = player.sprite.texture
			check(not player.attack_pending and slashes == 1 and active != windup, "pose ativa acompanha o único disparo do golpe")
		if i == 9:
			check(player.attack_time > 0 and player.sprite.texture != active and player.sprite.texture != windup, "recuperação tem desenho próprio antes de liberar o golpe")
	check(attack_images.size() == 6, "ataque real percorre seis poses sem alongar os230ms")
	check(forward_cut_synced,"corte frontal ocupa a janela ativa e follow-through cruzado fica na recuperação")
	await reset()
	player.try_attack()
	player.try_dash()
	await frames(1)
	check(player.motion_state == "dash" and player.sprite.texture != idle and not player.attack_pending, "dash tem pose própria e cancela preparação")
	var dash_images: Dictionary = {}
	dash_images[hash(player.sprite.texture.get_image().get_data())] = true
	for i in range(15):
		await frames(1)
		if player.dash_time <= 0:
			break
		dash_images[hash(player.sprite.texture.get_image().get_data())] = true
	check(dash_images.size() == 3, "dash percorre início extensão e saída nos160ms existentes")
	check(player.motion_state == "brake" and absf(player.velocity.x) > 20, "saída do dash sem direção usa freio em vez de repouso deslizante")
	await reset()
	Input.action_press("jump")
	await frames(3)
	var rise = player.sprite.texture
	var rise_images: Dictionary = {}
	rise_images[hash(rise.get_image().get_data())] = true
	Input.action_release("jump")
	for i in range(60):
		await frames(1)
		if player.motion_state == "fall":
			break
		rise_images[hash(player.sprite.texture.get_image().get_data())] = true
	check(player.motion_state == "fall" and player.sprite.texture != rise, "subida e queda têm silhuetas distintas")
	check(rise_images.size() == 3, "subida curta percorre três poses sem alterar o salto")
	var fall_images: Dictionary = {}
	fall_images[hash(player.sprite.texture.get_image().get_data())] = true
	for i in range(60):
		await frames(1)
		if player.is_on_floor():
			break
		fall_images[hash(player.sprite.texture.get_image().get_data())] = true
	check(fall_images.size() == 2, "queda percorre duas poses antes do contato")
	check(player.motion_state == "land" and player.sprite.texture != idle, "contato com chão mostra aterrissagem dedicada")
	var land_images: Dictionary = {}
	for i in range(8):
		if player.motion_state == "land":
			land_images[hash(player.sprite.texture.get_image().get_data())] = true
		await frames(1)
	check(land_images.size() == 3, "aterrissagem mostra contato compressão e recuperação")
	check(player.motion_state == "idle", "aterrissagem retorna ao repouso sem manter pose comprimida")
	var idle_images: Dictionary = {}
	for i in range(60):
		idle_images[hash(player.sprite.texture.get_image().get_data())] = true
		await frames(1)
	check(idle_images.size() == 4, "repouso percorre quatro poses de respiração sem deformar escala")
	player.invulnerable = 0
	player.take_damage(1,player.position+Vector2(60,0))
	var hurt_images: Dictionary = {}
	for i in range(12):
		await frames(1)
		if player.motion_state == "hurt":
			hurt_images[hash(player.sprite.texture.get_image().get_data())] = true
	check(hurt_images.size() == 2, "recuo real percorre duas poses próprias de dano")
	await reset()
	player.praying = true
	var prayer_images: Dictionary = {}
	var prayer_at = player.position
	for i in range(90):
		await frames(1)
		prayer_images[hash(player.sprite.texture.get_image().get_data())] = true
	check(prayer_images.size() == 4 and player.position == prayer_at, "oração respira em quatro poses com apoio imóvel durante1.4s")
	print("RESULT: ", checks - failures.size(), "/", checks, " motion animation checks passed")
	quit(0 if failures.is_empty() else 1)
