extends SceneTree

var game
var world
var player
var checks = 0
var failures = 0
var completed = 0
const LOTUS = Vector2(1490,506)

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
		failures += 1

func reset(at: Vector2) -> void:
	for action in ["left","right","down","jump","dash","attack","interact"]:
		Input.action_release(action)
	world._cancel_prayer()
	player.restore(at)
	await frames(8)

func eye_ahead_of_cape(texture: Texture2D, flipped: bool, direction: float) -> bool:
	var image = texture.get_image()
	var eye_x = 0.0
	var eyes = 0
	var cape_x = 0.0
	var cape = 0
	for y in range(11,33):
		for x in range(28,74):
			var color = image.get_pixel(x,y)
			if color.a < 0.5:
				continue
			if color.b > color.r*1.2 and color.g > 0.55 and color.b > 0.55:
				eye_x += x
				eyes += 1
			elif y >= 21 and color.r > 0.65 and color.g > 0.5 and color.r > color.g and color.r > color.b:
				cape_x += x
				cape += 1
	return eyes>0 and cape>0 and (eye_x/eyes-cape_x/cape)*(-1 if flipped else 1)*direction>0

func prayer_case(offset: float) -> void:
	await reset(LOTUS+Vector2(offset,0))
	player.hp = 2
	player.facing = signf(offset) # Começar olhando para longe testa a virada.
	var at = player.position
	var before = completed
	Input.action_press("interact")
	await frames(1)
	Input.action_release("interact")
	var direction = -signf(offset)
	check(world.praying and player.position.is_equal_approx(at), "oração começa sem teleportar no lado%s" % offset)
	check(player.facing == direction and player.sprite.flip_h == (direction<0) and eye_ahead_of_cape(player.sprite.texture,player.sprite.flip_h,direction), "olho/capa e flip reais orientam a pose ao lótus no lado%s" % offset)
	await frames(70)
	check(world.praying and completed == before and player.hp == 2 and player.position.is_equal_approx(at), "oração mantém apoio e aguarda1.4s antes de curar no lado%s" % offset)
	await frames(20)
	check(not world.praying and completed == before+1 and player.hp == 5 and player.position.is_equal_approx(at), "oração termina com cura sem reposicionar no lado%s" % offset)
	var save = JSON.parse_string(FileAccess.get_file_as_string("user://progress.json"))
	check(world.checkpoint == LOTUS and game.checkpoint == LOTUS and save.get("checkpoint",[]) == [LOTUS.x,LOTUS.y], "checkpoint e save usam o lótus e não a posição local no lado%s" % offset)

func _run() -> void:
	var user_dir = OS.get_user_data_dir()
	print("ISOLATED_USER_DIR: ",user_dir)
	if not user_dir.ends_with("MushroomsStationaryPrayerQA"):
		check(false,"teste de save exige namespace exclusivo MushroomsStationaryPrayerQA")
		quit(1)
		return
	game = load("res://Scenes/main.tscn").instantiate()
	root.add_child(game)
	game.start_world("trail")
	world = game.world
	player = world.player
	world.enemies.clear() # Isolar input/progresso de dano de IA não relacionado.
	world.checkpoint_activated.connect(func(_at): completed += 1)
	await reset(Vector2(300,490))
	Input.action_press("right")
	await frames(12)
	var at = player.position
	Input.action_press("down")
	await frames(1)
	check(player.crouching and player.position.is_equal_approx(at) and player.velocity.x == 0, "agachar durante corrida para no mesmo tick sem deslizar")
	await frames(20)
	check(player.position.is_equal_approx(at) and player.velocity.x == 0, "direção segurada não permite caminhar agachado")
	Input.action_press("dash")
	await frames(1)
	Input.action_release("dash")
	check(player.dash_time == 0 and player.position.is_equal_approx(at), "dash não inicia enquanto agachado")
	Input.action_release("down")
	Input.action_release("right")
	await frames(2)
	check(player.dash_time == 0, "dash recusado no agachamento não fica guardado para a soltura")
	await reset(Vector2(300,490))
	player.try_dash()
	await frames(2)
	at = player.position
	Input.action_press("down")
	await frames(1)
	check(player.dash_time == 0 and player.position.is_equal_approx(at), "agachar no chão também interrompe dash sem deslocamento extra")
	await reset(Vector2(500,414))
	Input.action_press("down")
	await frames(1)
	Input.action_press("jump")
	await frames(2)
	check(player.dropping > 0 and player.position.y > 414 and not player.get_collision_mask_value(3), "baixo+pulo continua atravessando plataforma unidirecional")
	await reset(Vector2(300,490))
	Input.action_press("down")
	await frames(1)
	player.invulnerable = 0
	at = player.position
	player.take_damage(1,at+Vector2(60,0))
	await frames(2)
	check(player.hurt_lock>0 and player.velocity.x<0 and player.position.x<at.x-5, "agachar não bloqueia recuo por dano")
	await prayer_case(-40)
	await prayer_case(40)
	for direction in [-1.0,1.0]:
		await reset(LOTUS)
		player.facing = direction
		world.activate_lotus(LOTUS)
		await frames(1)
		check(player.facing == direction and player.position.is_equal_approx(LOTUS), "alinhado ao lótus preserva orientação%s sem direção zero" % direction)
	await reset(LOTUS+Vector2(-40,0))
	player.hp = 3
	world.activate_lotus(LOTUS)
	await frames(3)
	var before = completed
	var saved = FileAccess.get_file_as_string("user://progress.json")
	player.invulnerable = 0
	player.take_damage(1,player.position+Vector2(60,0))
	await frames(100)
	check(not world.praying and not player.praying and completed == before and player.hp == 2 and FileAccess.get_file_as_string("user://progress.json") == saved, "dano interrompe oração sem cura nem alteração de checkpoint salvo")
	game.persist_progress = false
	game.queue_free()
	await frames(2)
	print("RESULT: ",checks-failures,"/",checks," stationary prayer checks passed")
	quit(0 if failures == 0 else 1)
