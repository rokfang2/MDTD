extends SceneTree

var checks = 0
var failures = 0
var entered = 0

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func _run() -> void:
	var setup = load("res://scripts/main.gd").new()
	setup._setup_inputs()
	setup.free()
	var world = load("res://scripts/world.gd").new()
	root.add_child(world)
	world.enemies.clear()
	world.entered_arena.connect(func(): entered += 1)
	var level = world.Level
	check(level.WIDTH == 13032 and level.REGIONS.size() == 6,"fase dobra a extensão com seis setores nomeados")
	for center in [Vector2(640,360),Vector2(11700,440)]:
		world.camera.position = center
		var panel = Rect2(center+Vector2(-580,-260),Vector2(1160,420)).grow(-8)
		var points: Array = [Vector2.ZERO,Vector2(level.WIDTH,650),Vector2(level.PORTAL_X,506)]
		points.append_array(level.LOTUSES)
		for memory in level.MEMORIES:
			points.append(memory.pos)
		var inside = true
		for at in points:
			inside = inside and panel.has_point(world.map_point(at)-Vector2(6,6)) and panel.has_point(world.map_point(at)+Vector2(6,6))
		check(inside,"mapa inteiro e todos os marcadores cabem no painel na câmera%s" % center)
	world.player.restore(Vector2(6450,506))
	await frames(8)
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	check(entered == 0 and world.player.position.x < level.PORTAL_X-5000,"antigo portal agora permite continuar a exploração")
	world.player.restore(Vector2(7300,650))
	await frames(60)
	check(world.player.is_on_floor() and world.camera.position.y >= 430 and world.camera.position.y <= 480,"câmera acompanha o piso baixo sem ocultar o personagem")
	var camera_y = world.camera.position.y
	Input.action_press("jump")
	await frames(16)
	Input.action_release("jump")
	await frames(5)
	check(absf(world.camera.position.y-camera_y) <= 4,"zona neutra não sobe junto de cada salto na galeria")
	world.queue_free()
	await frames(2)
	print("RESULT: ",checks-failures,"/",checks," enlarged map projection checks passed")
	quit(0 if failures == 0 else 1)
