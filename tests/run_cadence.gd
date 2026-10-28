extends SceneTree

# Input real numa cena mínima; não instancia Main nem acessa progresso.
var player
var checks = 0
var failures = 0

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

func block(at: Vector2, size: Vector2) -> void:
	var body = StaticBody2D.new()
	var shape = CollisionShape2D.new()
	var box = RectangleShape2D.new()
	box.size = size
	shape.shape = box
	body.position = at
	body.add_child(shape)
	root.add_child(body)

func _run() -> void:
	for action in ["left","right","jump","down","dash","attack"]:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
	block(Vector2(2500,610),Vector2(5000,40))
	player = load("res://scripts/player.gd").new()
	root.add_child(player)
	player.restore(Vector2(400,590))
	await frames(8)
	Input.action_press("right")
	await frames(12)
	var at = player.position.x
	var run_at = player.run_distance
	var previous = player.sprite.texture
	var transitions = 0
	for i in range(120):
		await frames(1)
		if player.sprite.texture != previous:
			transitions += 1
		previous = player.sprite.texture
	var distance = player.position.x-at
	var run_distance = player.run_distance-run_at
	var cycles = run_distance/player.RUN_CYCLE_DISTANCE
	print("METRIC: distance2s=",distance," run_distance=",run_distance," cycles=",cycles," transitions2s=",transitions," transitions/s=",transitions/2.0," speed=",player.velocity.x)
	check(player.run_frames.size() == 12, "corrida mantém as12 poses existentes")
	check(is_equal_approx(player.velocity.x,310) and absf(distance-620)<0.1, "dois segundos mantêm velocidade310 e deslocamento620px")
	check(absf(run_distance-distance)<0.1, "cadência acompanha a distância real percorrida")
	check(cycles>3.32 and cycles<3.42, "dois segundos completam cerca de3.37 ciclos em vez de5.54")
	check(transitions>=39 and transitions<=42, "corrida apresenta cerca de20 trocas de pose por segundo")
	Input.action_release("right")
	var stop_at = player.position.x
	await frames(1)
	check(player.motion_state == "brake", "soltar direção interrompe a corrida e mostra freio")
	var kept_running = false
	for i in range(8):
		await frames(1)
		kept_running = kept_running or player.motion_state == "run"
	check(not kept_running and player.motion_state == "idle" and absf(player.velocity.x)<1 and player.position.x-stop_at<22, "parada termina sem continuar o ciclo nem alterar a frenagem física")
	block(Vector2(570,500),Vector2(40,220))
	player.restore(Vector2(400,590))
	await frames(8)
	Input.action_press("right")
	await frames(60)
	var wall_at = player.position.x
	await frames(30)
	check(player.is_on_wall() and absf(player.position.x-wall_at)<0.01, "input contra parede não produz deslocamento fantasma")
	check(player.motion_state != "run" and player.run_distance == 0, "parede interrompe a passada sem avançar a distância de animação")
	Input.action_release("right")
	print("RESULT: ",checks-failures,"/",checks," run cadence checks passed")
	quit(0 if failures == 0 else 1)
