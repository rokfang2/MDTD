extends Node2D

const Level = preload("res://scripts/level_data.gd")
const Druid = preload("res://scripts/player.gd")
const Guardian = preload("res://scripts/boss.gd")
const Art = preload("res://scripts/art.gd")
const PixelArt = preload("res://scripts/pixel_art.gd")
signal entered_arena
signal checkpoint_activated(at: Vector2)
signal memory_found(id: String, text: String)
signal reward_claimed
signal toast(text: String)
signal sound(name: String)

var mode = "trail"
var player
var boss
var camera: Camera2D
var clock = 0.0
var shake = 0.0
var enemies: Array = []
var shots: Array = []
var hazards: Array = []
var particles: Array = []
var platforms: Array[Rect2] = []
var memories: Array[String] = []
var checkpoint = Vector2(130, 490)
var checkpoint_lit = false
var reward_ready = false
var reward_position = Vector2(990,590)
var pulse_time = 0.0
var flower = false
var flower_cooldown = 0.0
var prompt = ""
var rng = RandomNumberGenerator.new()
var camera_target = 640.0
var camera_target_y = 360.0
var enemy_art = PixelArt.actor(6)
var branches: Array[Rect2] = []
var prayer_at = Vector2.ZERO
var prayer_elapsed = 0.0
var praying = false
var map_open = false
var lotus_art = PixelArt.actor(7)
var gem_art = preload("res://scripts/style_atlas.gd").texture(7)

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rng.seed = 8261
	if mode == "trail":
		var terrain = preload("res://scripts/terrain.gd").new()
		terrain.mode = mode
		terrain.z_index = -5
		add_child(terrain)
		platforms = Level.ground()
		branches = Level.branches()
		for data in Level.ENEMIES:
			enemies.append({"x":float(data[0]),"y":float(data[1]),"home":float(data[0]),"base_y":float(data[1]),"hp":24,"t":0.0,"kind":data[2],"state":"patrol","timer":1.0,"direction":-1.0,"flash":0.0,"aim":Vector2.ZERO,"moving":false})
	else:
		var terrain = preload("res://scripts/terrain.gd").new()
		terrain.mode = mode
		terrain.z_index = -5
		add_child(terrain)
		platforms = [Rect2(-50, 590, 1380, 200), Rect2(-60, -500, 60, 1200), Rect2(1280, -500, 60, 1200)]
	for rect in platforms + branches:
		var ground = StaticBody2D.new()
		ground.collision_layer = 4 if rect in branches else 1
		var shape = CollisionShape2D.new()
		var box = RectangleShape2D.new()
		box.size = rect.size
		shape.shape = box
		shape.one_way_collision = rect in branches
		shape.one_way_collision_margin = 5
		ground.position = rect.get_center()
		ground.add_child(shape)
		add_child(ground)
	player = Druid.new()
	player.z_index = 10
	player.has_fragment = flower
	player.position = checkpoint if mode == "trail" else Vector2(220, 590)
	player.slash.connect(_on_slash)
	player.hurt.connect(func(): shake = 9; sound.emit("hurt"))
	player.dashed.connect(func(): sound.emit("dash"))
	add_child(player)
	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera_target = clampf(player.position.x, 640, Level.WIDTH - 640) if mode == "trail" else 640.0
	camera.position.x = camera_target
	if mode == "arena":
		boss = Guardian.new()
		boss.position = Vector2(990, 590)
		boss.player = player
		boss.active = true
		boss.cue.connect(func(message): toast.emit(message))
		boss.attack.connect(_boss_attack)
		boss.defeated.connect(_boss_defeated)
		boss.death_started.connect(_boss_death_started)
		boss.phase_changed.connect(_boss_phase_changed)
		boss.collapse_step.connect(_boss_collapse_step)
		add_child(boss)
		toast.emit("CORDYCEPS  ·  o hospedeiro da Rede")

func _physics_process(dt: float) -> void:
	clock += dt
	if Input.is_action_just_pressed("map"):
		map_open = not map_open
	player.visible = not map_open
	player.set_physics_process(not map_open)
	if map_open:
		queue_redraw()
		return
	flower_cooldown = maxf(0, flower_cooldown - dt)
	pulse_time = maxf(0,pulse_time-dt)
	shake = maxf(0, shake - dt * 25)
	var desired_x = clampf(player.position.x + player.facing * 65, 640, Level.WIDTH - 640) if mode == "trail" else 640.0
	camera_target = lerpf(camera_target, desired_x, 1.0 - exp(-7.0 * dt))
	if mode == "trail":
		# Zona neutra: a câmera acompanha a descida para as galerias sem
		# subir e descer a cada passada ou salto dentro da mesma plataforma.
		var desired_y = clampf(camera_target_y, player.position.y - 210, player.position.y + 180)
		desired_y = clampf(desired_y,360,480)
		camera_target_y = lerpf(camera_target_y,desired_y,1.0-exp(-5.0*dt))
	camera.position = Vector2(roundf(camera_target / 2) * 2, roundf(camera_target_y / 2) * 2)
	camera.offset = (Vector2(sin(clock * 101), cos(clock * 87)) * minf(shake, 5)).snapped(Vector2(2, 2))
	prompt = ""
	if player.position.y > 850 and player.enabled:
		player.invulnerable = 0
		player.take_damage(5, player.position)
	if mode == "trail":
		_tick_trail(dt)
	else:
		_tick_arena(dt)
	_tick_shots(dt)
	_tick_hazards(dt)
	for p in particles:
		p.pos += p.vel * dt
		p.vel.y += 100 * dt
		p.life -= dt
	particles = particles.filter(func(p): return p.life > 0)
	if Input.is_action_just_pressed("flower") and player.enabled:
		use_flower()
	queue_redraw()

func _tick_trail(dt: float) -> void:
	player.position.x = clampf(player.position.x, 25, Level.WIDTH - 25)
	_tick_enemies(dt)
	if _tick_prayer(dt):
		return
	for at in Level.LOTUSES:
		if player.position.distance_to(at) < 90:
			prompt = "E  ·  ajoelhar, orar e salvar no lótus"
			if Input.is_action_just_pressed("interact") and player.enabled and player.is_on_floor():
				activate_lotus(at)
	for item in Level.MEMORIES:
		if item.id not in memories and player.position.distance_to(item.pos) < 70:
			prompt = "E  ·  escutar a memória na seiva"
			if Input.is_action_just_pressed("interact") and player.enabled:
				memories.append(item.id)
				memory_found.emit(item.id, item.text)
				sound.emit("lotus")
	if absf(player.position.x - Level.PORTAL_X) < 90:
		prompt = "E  ·  entrar no ninho do Cordyceps"
		if Input.is_action_just_pressed("interact") and player.enabled:
			entered_arena.emit()

func _tick_prayer(dt: float) -> bool:
	if not praying:
		return false
	if player.hurt_lock > 0 or not player.enabled or player.position.distance_to(prayer_at) > 105:
		_cancel_prayer()
	else:
		prayer_elapsed += dt
		prompt = "ORANDO  ·  %d%%" % mini(100,int(prayer_elapsed/1.4*100))
		if prayer_elapsed >= 1.4:
			_cancel_prayer()
			if mode == "arena":
				reward_ready = false
				reward_claimed.emit()
			else:
				_complete_lotus(prayer_at)
	return true

func activate_lotus(at: Vector2 = Vector2(1490,506)) -> void:
	if praying or not player.enabled or not player.is_on_floor():
		return
	prayer_at = at
	prayer_elapsed = 0
	praying = true
	# Ajoelhar no apoio atual; o checkpoint continua sendo a posição do lótus.
	var toward_lotus = signf(at.x - player.position.x)
	if toward_lotus != 0:
		player.facing = toward_lotus
	player.praying = true
	player.velocity = Vector2.ZERO
	player.attack_pending = false
	player.attack_time = 0
	player.dash_time = 0

func _cancel_prayer() -> void:
	praying = false
	player.praying = false
	player.jump_buffer = 0
	player.attack_buffer = 0
	player.dash_buffer = 0

func _complete_lotus(at: Vector2) -> void:
	checkpoint_lit = true
	checkpoint = at
	player.hp = 5
	checkpoint_activated.emit(checkpoint)
	toast.emit("ORAÇÃO CONCLUÍDA  ·  progresso salvo")
	sound.emit("lotus")
	burst(at + Vector2(0,-31), Color("ffdfa0"), 30)

func _enemy_floor(enemy: Dictionary) -> Rect2:
	for floor_rect in platforms:
		if enemy.home >= floor_rect.position.x and enemy.home < floor_rect.end.x and absf(floor_rect.position.y-enemy.base_y) < 5:
			return floor_rect
	return Rect2(0,enemy.base_y,Level.WIDTH,20)

func _tick_enemies(dt: float) -> void:
	for enemy in enemies:
		if enemy.hp <= 0:
			continue
		enemy.t += dt
		enemy.flash = maxf(0,enemy.flash-dt)
		enemy.timer -= dt
		var before = Vector2(enemy.x,enemy.y)
		var diff = player.position-before
		var flying = enemy.kind == "fly"
		var surface = _enemy_floor(enemy)
		var reachable = flying or (player.position.x >= surface.position.x and player.position.x <= surface.end.x and absf(player.position.y-enemy.base_y) < 85)
		var detected = reachable and absf(diff.x) < 420 and absf(diff.y) < 190 and player.enabled
		var attack_range = 145.0 if flying else (340.0 if enemy.kind == "spitter" else 175.0)
		if enemy.state in ["patrol","chase"]:
			if detected:
				enemy.direction = signf(diff.x) if diff.x != 0 else enemy.direction
				if absf(diff.x) <= attack_range and absf(diff.y) < 100:
					if enemy.timer <= 0:
						enemy.state = "tell"
						enemy.timer = 0.65
						enemy.aim = player.position+Vector2(0,-10 if flying else 0)
				else:
					enemy.state = "chase"
					if flying:
						var next = before.move_toward(player.position+Vector2(0,-18),dt*150)
						enemy.x = next.x
						enemy.y = next.y
					else:
						enemy.x = move_toward(enemy.x,player.position.x,dt*115)
			else:
				enemy.state = "patrol"
				var destination = enemy.home+sin(enemy.t*1.2)*48
				enemy.direction = signf(destination-enemy.x) if absf(destination-enemy.x)>1 else enemy.direction
				enemy.x = move_toward(enemy.x,destination,dt*50)
				if flying:
					enemy.y = move_toward(enemy.y,enemy.base_y-18+sin(enemy.t*3)*9,dt*70)
		elif enemy.state == "tell" and enemy.timer <= 0:
			enemy.state = "strike"
			enemy.timer = 0.3
			if enemy.kind == "spitter":
				shots.append({"pos":Vector2(enemy.x+enemy.direction*50,enemy.y-40),"vel":Vector2(enemy.direction*240,0),"life":2.4,"radius":10.0})
		elif enemy.state == "strike":
			if flying:
				var next = before.move_toward(enemy.aim,dt*390)
				enemy.x = next.x
				enemy.y = next.y
			elif enemy.kind != "spitter":
				enemy.x += enemy.direction*340*dt
			if enemy.timer <= 0:
				enemy.state = "recover"
				enemy.timer = 1.1
		elif enemy.state == "recover":
			if flying:
				enemy.y = move_toward(enemy.y,enemy.base_y-42,dt*45)
			if enemy.timer <= 0:
				enemy.state = "patrol"
				enemy.timer = 0.65
		if not flying:
			enemy.x = clampf(enemy.x,surface.position.x+40,surface.end.x-40)
			enemy.y = surface.position.y
		enemy.moving = before.distance_to(Vector2(enemy.x,enemy.y)) > 0.2
		var body = Vector2(enemy.x,enemy.y-40)
		var player_body = player.position+Vector2(0,-38)
		if absf(player_body.x-body.x)<64 and absf(player_body.y-body.y)<46:
			player.take_damage(1,body)

func _tick_arena(dt: float) -> void:
	if _tick_prayer(dt):
		return
	if boss.active and boss.state != "phase_shift" and player.position.distance_to(boss.position + Vector2(0, -50)) < 80:
		player.take_damage(1, boss.position)
	if boss.state == "dying":
		prompt = "O MICÉLIO SE DESFAZ"
	if reward_ready and player.position.distance_to(reward_position) < 140:
		prompt = "E  ·  orar, acolher o fragmento e salvar"
		if Input.is_action_just_pressed("interact") and player.enabled:
			activate_lotus(reward_position)

func _on_slash(origin: Vector2, direction: float) -> void:
	sound.emit("slash")
	for enemy in enemies:
		var diff = Vector2(enemy.x, enemy.y - 28) - origin
		# Ponta160px mais6px de tolerância ao centro dos inimigos pequenos.
		if enemy.hp > 0 and absf(diff.y) < 65 and diff.x * direction > 0 and diff.x * direction < Druid.SLASH_REACH + 6:
			enemy.hp -= 12
			enemy.flash = 0.14
			enemy.state = "recover"
			enemy.timer = 0.65
			burst(Vector2(enemy.x, enemy.y - 30), Color("b6c4f9"), 10)
			sound.emit("hit")
	if boss != null and boss.active:
		var diff = boss.position + Vector2(0, -70) - origin
		# A silhueta larga do guardião projeta76px além do centro do alvo.
		if absf(diff.y) < 110 and diff.x * direction > 0 and diff.x * direction < Druid.SLASH_REACH + 76:
			boss.receive_hit(12)
			burst(origin + Vector2(direction * 70, 0), Color("e0ffc0"), 12)
			sound.emit("hit")
			shake = 3

func _boss_attack(kind: String, target: Vector2, phase: int) -> void:
	if not player.enabled:
		return
	match kind:
		"roots":
			hazards.append({"x": clampf(target.x, 80, 1170), "delay": 0.08, "life": 0.5, "width": 85.0, "hit": false})
			if phase == 2:
				hazards.append({"x": clampf(target.x - 180, 80, 1170), "delay": 0.55, "life": 0.5, "width": 65.0, "hit": false})
		"spores":
			var count = 3 if phase == 1 else 5
			var side = signf(target.x-boss.position.x)
			if side == 0:
				side = 1 if boss.sprite.flip_h else -1
			var start = boss.position + Vector2(side*95,-110)
			for i in range(count):
				var direction = (target + Vector2(0,-35)-start).normalized().rotated((i-(count-1)*0.5)*0.13)
				shots.append({"pos": start, "vel": direction * (235 + phase * 25), "life": 5.5, "radius": 12.0})
		"invert":
			pulse_time = 0.65
			if player.is_on_floor() and player.invulnerable <= 0:
				player.inverted = 1.2 if phase == 1 else 1.6
				toast.emit("CONTROLES INVERTIDOS  ·  esquerda ↔ direita")
			else:
				toast.emit("PULSO EVITADO  ·  aproxime-se durante a recuperação")
			hazards.append({"x": clampf(target.x, 80, 1170), "delay": 0.7, "life": 0.38, "width": 100.0, "hit": false})
	sound.emit("warning")

func _tick_shots(dt: float) -> void:
	for shot in shots:
		shot.pos += shot.vel * dt
		shot.life -= dt
		if player.enabled and shot.pos.distance_to(player.position + Vector2(0, -40)) < 31 and player.invulnerable <= 0:
			player.take_damage(1, shot.pos)
			player.numb = 1.7
			shot.life = 0
			toast.emit("DORMÊNCIA  ·  dash bloqueado por 1,7 s" + ("  ·  F para usar Calêndula" if flower else ""))
	shots = shots.filter(func(s): return s.life > 0 and s.pos.x > -60 and s.pos.x < (Level.WIDTH + 60 if mode == "trail" else 1340))

func _tick_hazards(dt: float) -> void:
	for hazard in hazards:
		if hazard.delay > 0:
			hazard.delay -= dt
			continue
		hazard.life -= dt
		if player.enabled and not hazard.hit and absf(player.position.x - hazard.x) < hazard.width and player.position.y > 520 and player.invulnerable <= 0:
			player.take_damage(1, Vector2(hazard.x, 590))
			hazard.hit = true
	hazards = hazards.filter(func(h): return h.life > 0)

func use_flower() -> bool:
	if not flower or flower_cooldown > 0:
		return false
	player.numb = 0
	flower_cooldown = 6.0
	burst(player.position + Vector2(0, -40), Color("ffc875"), 24)
	sound.emit("lotus")
	toast.emit("CALÊNDULA  ·  o tato desperta")
	return true

func _boss_death_started() -> void:
	shots.clear()
	hazards.clear()
	pulse_time = 0
	player.numb = 0
	player.inverted = 0
	# Let the lotus grow beside the remains, keeping the authored collapse
	# visible rather than covering it with the reward artwork.
	var side = signf(player.position.x-boss.position.x)
	if side == 0:
		side = -1
	var reward_x = clampf(boss.position.x+side*260,140,1140)
	if absf(reward_x-boss.position.x) < 220:
		reward_x = clampf(boss.position.x-side*260,140,1140)
	reward_position = Vector2(reward_x,590)
	shake = 5
	toast.emit("O HOSPEDEIRO CEDE  ·  a Rede perde sua voz")
	sound.emit("hit")

func _boss_phase_changed() -> void:
	shots.clear()
	hazards.clear()
	pulse_time = 0
	shake = 4
	burst(boss.position+Vector2(0,-120),Color("ffb82b"),16)
	sound.emit("warning")

func _boss_collapse_step(frame: int) -> void:
	if frame in [2,3,4]:
		burst(boss.position+Vector2(0,-12),Color("996044"),12 if frame == 3 else 6)
		shake = 4 if frame == 3 else 2
	if frame == 5:
		burst(boss.position+Vector2(0,-65),Color("31e5f3"),12)

func _boss_defeated() -> void:
	player.hp = 5
	reward_ready = true
	burst(reward_position+Vector2(0,-65),Color("ffc677"),24)
	toast.emit("O GUARDIÃO SILENCIA  ·  aproxime-se da luz")
	sound.emit("lotus")

func burst(at: Vector2, color: Color, amount: int) -> void:
	for i in range(amount):
		particles.append({"pos": at, "vel": Vector2(rng.randf_range(-150, 150), rng.randf_range(-210, 20)), "life": rng.randf_range(0.3, 1), "color": color})

func _draw() -> void:
	if mode == "trail":
		for at in Level.LOTUSES:
			_draw_lotus(at, checkpoint == at and checkpoint_lit)
		for memory in Level.MEMORIES:
			if memory.id not in memories:
				var p = memory.pos + Vector2(0, -30 + sin(clock * 3) * 5)
				_draw_pixel_gem(p, Color("ffe4a4"))
		for enemy in enemies:
			if enemy.hp > 0:
				_draw_enemy(enemy)
		# A passagem se abre dentro do território, sem ataque fora da arena.
		for i in range(8):
			var p = Vector2(Level.PORTAL_X, Level.PORTAL_Y-42) + Vector2(cos(i * PI / 7 + PI), sin(i * PI / 7 + PI)) * 52
			draw_rect(Rect2(p.snapped(Vector2(4, 4)), Vector2(8, 12)), Color("58d7dd"))
	else:
		if pulse_time > 0:
			var reach = (1.0-pulse_time/0.65)*1350
			for side in [-1,1]:
				var x = clampf(boss.position.x+side*reach,0,1280)
				draw_rect(Rect2(Vector2(x,574).snapped(Vector2(4,4)),Vector2(12,16)),Color("d630c9"))
		if boss != null and boss.state == "tell" and boss.pattern == 2:
			for x in range(20,1260,40):
				draw_rect(Rect2(x,582,16,4),Color("d630c9"))
		if boss != null and boss.state == "tell" and boss.pattern == 0:
			_draw_warning(boss.target.x, 85, 0.4)
		for hazard in hazards:
			if hazard.delay > 0:
				_draw_warning(hazard.x, hazard.width, 0.6)
			else:
				for i in range(9):
					var x = roundf((hazard.x - hazard.width + i * hazard.width / 4) / 4) * 4
					var height = 60 + (i % 3) * 12
					for step in range(5):
						draw_rect(Rect2(x - 8 + step * 2, 590 - height + step * height / 5, 8 + step * 4, height / 5 + 4), Color("e9a263").darkened(step * 0.09))
		if reward_ready:
			_draw_lotus(reward_position,true)
			var gem = reward_position + Vector2(0,-100+sin(clock*3)*8)
			draw_texture_rect(gem_art, Rect2(gem + Vector2(-12, -18), Vector2(24, 34)), false)
	for shot in shots:
		var at = shot.pos.snapped(Vector2(4, 4))
		draw_rect(Rect2(at + Vector2(-12, -8), Vector2(24, 16)), Color("1c255f"))
		draw_rect(Rect2(at + Vector2(-8, -12), Vector2(16, 24)), Color("1c255f"))
		draw_rect(Rect2(at + Vector2(-8, -8), Vector2(16, 16)), Color("39d8ee"))
		draw_rect(Rect2(at + Vector2(-4, -4), Vector2(8, 8)), Color("d6fff5"))
	for p in particles:
		var color = p.color
		color.a = clampf(p.life, 0, 1)
		draw_rect(Rect2(p.pos.snapped(Vector2(4, 4)), Vector2(4, 4)), color)
	for i in range(ceili(Level.WIDTH/144.0) if mode == "trail" else 45):
		var w = int(Level.WIDTH) if mode == "trail" else 1280
		var pos = Vector2(fposmod(i * 137.0 + sin(clock * 0.3 + i) * 30, w), fposmod(i * 71.0 - clock * (5 + i % 4), 590))
		draw_rect(Rect2(pos.snapped(Vector2(4, 4)), Vector2(4, 4)), Color(0.7, 1, 0.8, 0.18 + sin(clock + i) * 0.15))

	if mode == "trail" and map_open:
		_draw_map()

func _draw_enemy(enemy: Dictionary) -> void:
	var frame = int(enemy.t*(12 if enemy.kind == "fly" else 9))%4 if enemy.moving or enemy.kind == "fly" else 0
	var texture = PixelArt.insect(enemy.kind == "fly",frame,enemy.kind == "spitter")
	var at = Vector2(enemy.x,enemy.y).snapped(Vector2(2,2))
	draw_set_transform(at,0,Vector2(-1 if enemy.direction > 0 else 1,1))
	draw_texture_rect(texture,PixelArt.floor_rect(texture,Vector2.ZERO),false,Color("fff4cd") if enemy.flash > 0 else Color.WHITE)
	draw_set_transform(Vector2.ZERO)
	if enemy.state == "tell":
		_draw_pixel_gem(at+Vector2(0,-144),Color("ffbd72"))

func _draw_map() -> void:
	var left = camera.position.x - 580
	var top = camera.position.y - 260
	draw_rect(Rect2(left,top,1160,420),Color("120a28"))
	draw_string(ThemeDB.fallback_font,Vector2(left+20,top+27),"RAÍZES DO REINO  ·  Tab para voltar",HORIZONTAL_ALIGNMENT_LEFT,-1,20,Color("f4e8ca"))
	var sx = 1120.0/Level.WIDTH
	for region in Level.REGIONS:
		var x = left+20+region.start*sx
		draw_line(Vector2(x,top+60),Vector2(x,top+350),Color("35234f"),2)
		draw_string(ThemeDB.fallback_font,Vector2(x+3,top+51),region.name,HORIZONTAL_ALIGNMENT_LEFT,maxf(30,(region.end-region.start)*sx-8),12,Color("bac5bd"))
	for rect in platforms + branches:
		var start = Vector2(clampf(rect.position.x,0,Level.WIDTH),rect.position.y)
		var end = clampf(rect.end.x,0,Level.WIDTH)
		draw_rect(Rect2(map_point(start),Vector2(maxf(2,(end-start.x)*sx),4)),Color("6aab22") if rect in platforms else Color("a9e326"))
	for memory in Level.MEMORIES:
		if memory.id not in memories:
			_draw_map_marker(map_point(memory.pos),Color("ff78e7"),4)
	for at in Level.LOTUSES:
		_draw_map_marker(map_point(at),Color("ffeab0"),5)
	_draw_map_marker(map_point(Vector2(Level.PORTAL_X,Level.PORTAL_Y)),Color("f4e8ca"),6)
	_draw_map_marker(map_point(player.position),Color("24d9e2"),6)
	draw_string(ThemeDB.fallback_font,Vector2(left+20,top+389),"CIANO  você     DOURADO  lótus     ROSA  memória     BRANCO  ninho",HORIZONTAL_ALIGNMENT_LEFT,-1,16,Color("bac5bd"))

func map_point(at: Vector2) -> Vector2:
	return Vector2(camera.position.x-560+clampf(at.x,0,Level.WIDTH)*1120.0/Level.WIDTH,camera.position.y-186+clampf(at.y,0,720)*0.36)

func _draw_map_marker(at: Vector2, color: Color, radius: int) -> void:
	draw_rect(Rect2(at-Vector2.ONE*(radius+2),Vector2.ONE*(radius+2)*2),Color("120a28"))
	draw_rect(Rect2(at-Vector2.ONE*radius,Vector2.ONE*radius*2),color)

func _draw_pixel_gem(at: Vector2, color: Color) -> void:
	var center = at.snapped(Vector2(4, 4))
	for row in range(-3, 4):
		var half = (3 - absi(row)) * 4 + 4
		draw_rect(Rect2(center + Vector2(-half, row * 4), Vector2(half * 2, 4)), color.darkened(maxf(0, row) * 0.12))
	draw_rect(Rect2(center + Vector2(-4, -8), Vector2(4, 8)), Color("fff4cd"))

func _draw_warning(x: float, width: float, alpha: float) -> void:
	draw_rect(Rect2(x - width, 581, width * 2, 9), Color(1, 0.6, 0.3, alpha + sin(clock * 18) * 0.15))
	for i in range(5):
		draw_line(Vector2(x - width + i * width / 2, 572), Vector2(x - width + i * width / 2 + 8, 560), Color("ffbd72"), 2)

func _draw_lotus(at: Vector2, lit: bool) -> void:
	draw_texture_rect(lotus_art, PixelArt.floor_rect(lotus_art, at), false, Color.WHITE if lit else Color("d7d6c4"))
	if lit:
		for i in range(5):
			var p = at + Vector2(sin(clock + i * 2) * 38, -32 - fposmod(clock * 14 + i * 19, 58))
			draw_rect(Rect2(p.snapped(Vector2(4, 4)), Vector2(4, 4)), Color("ffe8a6"))

func _draw_mushroom(at: Vector2, time: float) -> void:
	# Os pés ficam ancorados; não flutuar o corpo inteiro sobre a superfície.
	draw_texture_rect(enemy_art, PixelArt.floor_rect(enemy_art, at.snapped(Vector2(4, 4))), false)
