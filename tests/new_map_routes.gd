extends SceneTree

const Level = preload("res://scripts/level_data.gd")
var world
var player
var checks = 0
var failures = 0
var entered = 0
var visited_basins: Dictionary = {}

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

func setup_at(at: Vector2) -> void:
	for action in ["left","right","jump","down","dash","attack","interact"]:
		Input.action_release(action)
	world._cancel_prayer()
	player.restore(at)
	player.invulnerable = 1000
	await frames(8)

func interact() -> void:
	Input.action_press("interact")
	await frames(2)
	Input.action_release("interact")
	await frames(2)

func travel_main(target: float) -> bool:
	var direction = 1.0 if target>player.position.x else -1.0
	var action = "right" if direction>0 else "left"
	var jumps: Array = []
	for point in Level.MAIN_JUMPS[action]:
		if direction*(point-player.position.x)>0 and direction*(target-point)>0:
			jumps.append(point)
	var next_jump = 0
	var held = 0
	Input.action_press(action)
	for tick in range(5000):
		if next_jump<jumps.size() and direction*(player.position.x-jumps[next_jump])>=0 and player.is_on_floor():
			Input.action_press("jump")
			held = 25
			next_jump += 1
		if held>0:
			held -= 1
			if held == 0:
				Input.action_release("jump")
		await frames(1)
		if player.is_on_floor():
			if player.position.x>7020 and player.position.x<7880 and absf(player.position.y-650)<2:
				visited_basins["sap"] = true
			if player.position.x>11400 and player.position.x<11800 and absf(player.position.y-610)<2:
				visited_basins["vestibule"] = true
		if direction*(target-player.position.x)<10 or not player.enabled:
			break
	Input.action_release(action)
	Input.action_release("jump")
	await frames(12)
	var success = player.enabled and player.is_on_floor() and absf(player.position.x-target)<25
	if not success:
		print("ROUTE_FAILURE: target=",target," actual=",player.position," jump_index=",next_jump," triggers=",jumps)
	return success

func walk_point(target: Vector2) -> bool:
	var action = "right" if target.x>player.position.x else "left"
	var jumped = target.y<player.position.y-10
	Input.action_press(action)
	if jumped:
		Input.action_press("jump")
	for tick in range(180):
		await frames(1)
		if tick == 25:
			Input.action_release("jump")
		if absf(player.position.x-target.x)<10:
			Input.action_release(action)
		if player.is_on_floor() and absf(player.position.x-target.x)<25 and absf(player.position.y-target.y)<5:
			break
	Input.action_release(action)
	Input.action_release("jump")
	await frames(12)
	var success = player.enabled and player.is_on_floor() and player.position.distance_to(target)<30
	if not success:
		print("LOOP_FAILURE: target=",target," actual=",player.position)
	return success

func metadata_checks() -> void:
	var old_ground = [Rect2(-100,490,800,250),Rect2(700,444,340,300),Rect2(1140,466,250,300),Rect2(1390,506,1322,300),Rect2(2712,450,380,350),Rect2(3212,420,430,380),Rect2(3642,490,702,310),Rect2(4344,506,2172,300)]
	var old_branches = [Rect2(420,414,160,20),Rect2(560,338,160,20),Rect2(690,262,550,20),Rect2(1210,338,170,20),Rect2(1350,414,180,20),Rect2(2412,430,180,20),Rect2(2632,360,180,20),Rect2(2780,282,750,20),Rect2(3430,360,190,20),Rect2(3650,430,180,20),Rect2(4500,430,190,20),Rect2(4710,354,190,20),Rect2(4900,278,840,20),Rect2(5600,354,190,20),Rect2(5810,430,190,20)]
	var old_enemies = [[570,490,"scout"],[880,444,"scout"],[1770,506,"scout"],[2500,506,"scout"],[2910,450,"spitter"],[3410,420,"scout"],[4000,490,"spitter"],[4700,506,"scout"],[5900,506,"spitter"],[3100,282,"fly"],[5200,278,"fly"]]
	var ground = Level.ground()
	var branches = Level.branches()
	check(Level.WIDTH==13032 and Level.PORTAL_X==12966 and Level.PORTAL_Y==506,"fase dobra para13032 e portal permanece em piso506")
	check(ground.slice(0,8)==old_ground and branches.slice(0,15)==old_branches,"geometria histórica até6516 preservada integralmente")
	var old_memories = [["roots",Vector2(820,444)],["border",Vector2(1900,506)],["canopy",Vector2(960,262)],["bridge",Vector2(2700,360)],["echo",Vector2(5500,278)]]
	var old_progress = Level.LOTUSES.slice(0,2)==[Vector2(1490,506),Vector2(5310,506)]
	for i in range(old_memories.size()):
		old_progress = old_progress and Level.MEMORIES[i].id==old_memories[i][0] and Level.MEMORIES[i].pos==old_memories[i][1]
	check(old_progress,"lótus e IDs/posições de memórias antigas preservam progresso existente")
	check(Level.ENEMIES.slice(0,11)==old_enemies,"onze spawns históricos mantêm ordem e coordenadas")
	var safe_steps = true
	for i in range(1,ground.size()):
		safe_steps = safe_steps and absf(ground[i].position.y-ground[i-1].position.y)<=90 and ground[i].position.x-ground[i-1].end.x<=130
	for surface in ground:
		safe_steps = safe_steps and surface.position.y<=650
	check(safe_steps,"caminho principal mantém degraus<=90 vãos<=130 e fundo<=650")
	var branch_sizes = true
	for surface in branches:
		branch_sizes = branch_sizes and surface.size.x<=840
	check(branch_sizes,"raízes completas cabem no limite840px da arte disponível")
	var valid_spawns = true
	for enemy in Level.ENEMIES:
		var supported = false
		for surface in ground+branches:
			if enemy[0]>surface.position.x and enemy[0]<surface.end.x and enemy[1]==surface.position.y:
				supported = true
		for lotus in Level.LOTUSES:
			valid_spawns = valid_spawns and Vector2(enemy[0],enemy[1]).distance_to(lotus)>=140
		valid_spawns = valid_spawns and supported
	check(Level.ENEMIES.size()>=21 and valid_spawns,"novos inimigos têm apoio válido e ficam a140px dos lótus")
	check(Level.LOTUSES.size()==4 and Level.MEMORIES.size()==8 and Level.NEW_ROUTE_LOOPS.size()>=3,"fase oferece quatro lótus oito memórias e três laços de retorno")
	var regions_valid = Level.REGIONS.size()==6
	for i in range(Level.REGIONS.size()):
		regions_valid = regions_valid and Level.REGIONS[i].start==i*2172 and Level.REGIONS[i].end==(i+1)*2172
	check(regions_valid,"seis regiões cobrem a fase inteira sem lacunas")

func _run() -> void:
	print("ISOLATED_USER_DIR: ",OS.get_user_data_dir())
	if not OS.get_user_data_dir().ends_with("MushroomsNewMapRoutesQA"):
		check(false,"ensaio exige namespace MushroomsNewMapRoutesQA")
		quit(1)
		return
	metadata_checks()
	var controller = load("res://scripts/main.gd").new()
	controller._setup_inputs()
	controller.free()
	world = load("res://scripts/world.gd").new()
	root.add_child(world)
	world.enemies.clear() # Isolar a geometria sem invulnerabilidade afetar IA.
	world.entered_arena.connect(func(): entered += 1)
	player = world.player
	await setup_at(Vector2(130,490))
	check(await travel_main(8470),"percurso principal por input liga início antigo ao terceiro lótus")
	player.hp = 2
	await interact()
	await frames(90)
	check(world.checkpoint==Level.LOTUSES[2] and player.hp==5,"terceiro lótus conclui oração e checkpoint no piso seguro")
	check(await travel_main(10580),"percurso principal alcança quarto lótus atravessando novos terraços")
	player.hp = 2
	await interact()
	await frames(90)
	check(world.checkpoint==Level.LOTUSES[3] and player.hp==5,"quarto lótus conclui oração no terraço450")
	check(entered==0,"antigo limite6516 não entrega mais o altar final")
	check(await travel_main(Level.PORTAL_X+22),"percurso principal termina no novo portal após atravessar a bacia610")
	check(visited_basins.has("sap") and visited_basins.has("vestibule"),"rota baixa realmente percorre os fundos650/610 sem ser bloqueada pelas raízes superiores")
	await interact()
	check(entered==1,"interação no novo portal entrega acesso ao altar do ninho")
	check(await travel_main(130),"fase inteira permite retorno por input incluindo degraus e vãos antigos")
	for loop in Level.NEW_ROUTE_LOOPS:
		await setup_at(loop.points[0])
		var outward = true
		for i in range(1,loop.points.size()):
			outward = await walk_point(loop.points[i]) and outward
			for memory in Level.MEMORIES:
				if memory.id==loop.memory and player.position.distance_to(memory.pos)<35:
					await interact()
		check(outward,"laço%s alcança memória e entrada leste sem teleporte" % loop.id)
		check(loop.memory in world.memories,"memória opcional%s é coletável com interação real" % loop.memory)
		var returning = true
		for i in range(loop.points.size()-2,-1,-1):
			returning = await walk_point(loop.points[i]) and returning
		check(returning,"segunda entrada do laço%s permite retorno completo" % loop.id)
	for lotus in Level.LOTUSES.slice(2):
		world.queue_free()
		await frames(2)
		world = load("res://scripts/world.gd").new()
		world.checkpoint = lotus
		root.add_child(world)
		world.enemies.clear()
		player = world.player
		await frames(8)
		check(player.is_on_floor() and player.position.distance_to(lotus)<2,"checkpoint novo%s renasce sobre chão válido" % lotus)
	world.queue_free()
	await frames(2)
	print("RESULT: ",checks-failures,"/",checks," new map route checks passed")
	quit(0 if failures == 0 else 1)
