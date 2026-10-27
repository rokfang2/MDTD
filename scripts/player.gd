extends CharacterBody2D

const PixelArt = preload("res://scripts/pixel_art.gd")

signal hurt
signal died
signal slash(origin: Vector2, direction: float)
signal dashed

const SPEED = 310.0
const GRAVITY = 1800.0
const JUMP = -620.0
const GROUND_ACCEL = 2800.0
const AIR_ACCEL = 1850.0
const BRAKE = 3400.0
const DASH_SPEED = 840.0
const DASH_DURATION = 0.16
# Tempos só da apresentação; o dano continua no término de attack_windup.
const ATTACK_DURATION = 0.23
const ATTACK_RECOVERY = 0.085
const ATTACK_WINDUP_DURATION = 0.045
# Doze poses em184px: ~1.68ciclos/s a310px/s, sem alterar a física.
const RUN_CYCLE_DISTANCE = 184.0
# Ponta da raiz medida a partir do pivô; margens dos alvos ficam no mundo.
const SLASH_REACH = 160.0
const SLASH_CENTER_Y = -60
var praying = false
var crouching = false
var dropping = 0.0
var hp = 5
var facing = 1.0
var invulnerable = 0.0
var dash_time = 0.0
var dash_cooldown = 0.0
var attack_time = 0.0
var attack_cooldown = 0.0
var numb = 0.0
var inverted = 0.0
var coyote = 0.0
var jump_buffer = 0.0
var clock = 0.0
var enabled = true
var has_fragment = false
var dash_direction = 1.0
var attack_facing = 1.0
var dash_buffer = 0.0
var attack_buffer = 0.0
var hurt_lock = 0.0
var attack_pending = false
var attack_windup = 0.0
var run_distance = 0.0
var ghost_timer = 0.0
var motion_state = "idle"
var motion_elapsed = 0.0
var land_pulse = 0.0
var run_frames: Array[Texture2D] = []
var idle_frame: Texture2D
var jump_frame: Texture2D
var sprite: Sprite2D
var ghosts: Array = []

func _ready() -> void:
	collision_layer = 2
	collision_mask = 5
	var shape = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 15
	capsule.height = 76
	shape.shape = capsule
	shape.position.y = -38
	add_child(shape)
	for i in range(PixelArt.motion_count("run")):
		run_frames.append(PixelArt.motion("run", i))
	# Preparar a paleta de todas as poses antes do primeiro comando em jogo.
	for pose in PixelArt.MOTION_NAMES:
		for frame in range(PixelArt.motion_count(pose)):
			PixelArt.motion(pose,frame)
	PixelArt.prayer()
	idle_frame = PixelArt.motion("idle")
	jump_frame = PixelArt.motion("rise")
	sprite = Sprite2D.new()
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.texture = idle_frame
	var material = ShaderMaterial.new()
	material.shader = preload("res://scripts/eyes.gdshader")
	material.set_shader_parameter("faith", 0.55 if has_fragment else 1.0)
	sprite.material = material
	sprite.scale = Vector2.ONE * PixelArt.SCALE
	sprite.position.y = PixelArt.offset_y(sprite.texture)
	add_child(sprite)
	floor_snap_length = 7.0
	floor_stop_on_slope = true

func _physics_process(dt: float) -> void:
	clock += dt
	invulnerable = maxf(0, invulnerable - dt)
	dash_cooldown = maxf(0, dash_cooldown - dt)
	attack_cooldown = maxf(0, attack_cooldown - dt)
	attack_time = maxf(0, attack_time - dt)
	hurt_lock = maxf(0, hurt_lock - dt)
	land_pulse = maxf(0, land_pulse - dt)
	numb = maxf(0, numb - dt)
	inverted = maxf(0, inverted - dt)
	for ghost in ghosts:
		ghost.life -= dt
	ghosts = ghosts.filter(func(g): return g.life > 0)
	if not enabled:
		queue_redraw()
		return
	dropping = maxf(0,dropping-dt)
	set_collision_mask_value(3, dropping <= 0)
	if praying:
		sprite.modulate = Color.WHITE
		motion_elapsed = motion_elapsed + dt if motion_state == "pray" else 0.0
		motion_state = "pray"
		velocity = Vector2.ZERO
		sprite.texture = PixelArt.prayer(int(motion_elapsed/0.35) % PixelArt.motion_count("pray"))
		sprite.position.y = PixelArt.offset_y(sprite.texture)
		sprite.flip_h = facing < 0
		queue_redraw()
		return
	crouching = Input.is_action_pressed("down") and is_on_floor()
	if crouching and hurt_lock <= 0:
		# Agachar planta os pés imediatamente; recuo de dano mantém prioridade.
		velocity.x = 0
		dash_time = 0
	if crouching and Input.is_action_just_pressed("jump"):
		dropping = 0.3
		velocity.y = 120
		set_collision_mask_value(3,false)
		position.y += 8
		coyote = 0
		jump_buffer = 0
	if attack_pending:
		attack_windup -= dt
		if attack_windup <= 0:
			attack_pending = false
			slash.emit(position + Vector2(0, -40), attack_facing)
	var axis = Input.get_axis("left", "right")
	if inverted > 0:
		axis *= -1
	if axis != 0 and dash_time <= 0 and attack_time <= 0 and hurt_lock <= 0:
		facing = signf(axis)
	coyote = 0.0 if dropping > 0 else (0.12 if is_on_floor() else maxf(0, coyote - dt))
	jump_buffer = 0.0 if dropping > 0 else (0.13 if Input.is_action_just_pressed("jump") else maxf(0, jump_buffer - dt))
	dash_buffer = 0.12 if Input.is_action_just_pressed("dash") else maxf(0, dash_buffer - dt)
	if crouching:
		dash_buffer = 0
	attack_buffer = 0.12 if Input.is_action_just_pressed("attack") else maxf(0, attack_buffer - dt)
	if jump_buffer > 0 and not crouching and coyote > 0 and dash_time <= 0 and hurt_lock <= 0:
		velocity.y = JUMP
		coyote = 0
		jump_buffer = 0
	if Input.is_action_just_released("jump") and velocity.y < -230:
		velocity.y = -230
	if dash_buffer > 0 and try_dash():
		dash_buffer = 0
	if attack_buffer > 0 and try_attack():
		attack_buffer = 0
	var was_on_floor = is_on_floor()
	var was_dashing = dash_time > 0
	if dash_time > 0:
		dash_time = maxf(0, dash_time - dt)
		velocity = Vector2(dash_direction * DASH_SPEED, 0)
		ghost_timer -= dt
		if ghost_timer <= 0:
			ghosts.append({"pos": position, "life": 0.16, "texture": PixelArt.motion("dash", timed_frame("dash",DASH_DURATION-dash_time,DASH_DURATION)), "flip": dash_direction < 0})
			ghost_timer = 0.035
	else:
		if hurt_lock <= 0:
			var acceleration = GROUND_ACCEL if was_on_floor else AIR_ACCEL
			if axis == 0 and was_on_floor:
				acceleration = BRAKE
			velocity.x = 0 if crouching else move_toward(velocity.x, axis * SPEED, dt * acceleration)
		var gravity_scale = 1.35 if velocity.y > 0 else 1.0
		if absf(velocity.y) < 110 and Input.is_action_pressed("jump"):
			gravity_scale = 0.62
		velocity.y = minf(velocity.y + GRAVITY * gravity_scale * dt, 1000)
	var before_move = position
	move_and_slide()
	if was_dashing and (dash_time <= 0 or is_on_wall()):
		dash_time = 0
		velocity.x = dash_direction * SPEED if not is_on_wall() else 0.0
	if not was_on_floor and is_on_floor():
		land_pulse = 0.1
	sprite.flip_h = facing < 0
	var previous_motion = motion_state
	motion_state = "idle"
	if hurt_lock > 0:
		motion_state = "hurt"
	elif dash_time > 0:
		motion_state = "dash"
	elif attack_time > 0:
		motion_state = "attack"
	elif not is_on_floor():
		motion_state = "rise" if velocity.y < 0 else "fall"
	elif axis == 0 and absf(velocity.x) > 20:
		motion_state = "brake"
	elif land_pulse > 0.02:
		motion_state = "land"
	elif axis != 0 and absf(velocity.x) > 20:
		motion_state = "run"
	if crouching and hurt_lock <= 0 and dash_time <= 0 and attack_time <= 0:
		motion_state = "crouch"
	motion_elapsed = motion_elapsed + dt if motion_state == previous_motion else 0.0
	if motion_state == "brake":
		sprite.texture = PixelArt.motion("land",0)
	elif motion_state == "land":
		sprite.texture = PixelArt.motion("land",timed_frame("land",0.1-land_pulse,0.08))
	elif motion_state == "crouch":
		sprite.texture = PixelArt.motion("crouch",timed_frame("crouch",motion_elapsed,0.1))
	elif motion_state == "run":
		# Deslocamento real não avança o ciclo ao pressionar contra uma parede.
		run_distance += absf(position.x - before_move.x)
		sprite.texture = run_frames[int(run_distance / RUN_CYCLE_DISTANCE * run_frames.size()) % run_frames.size()]
	elif motion_state == "rise":
		sprite.texture = PixelArt.motion("rise",timed_frame("rise",motion_elapsed,0.15))
	elif motion_state == "dash":
		sprite.texture = PixelArt.motion("dash",timed_frame("dash",DASH_DURATION-dash_time,DASH_DURATION))
		sprite.flip_h = dash_direction < 0
	elif motion_state == "attack":
		sprite.texture = PixelArt.motion("attack",attack_frame())
		sprite.flip_h = attack_facing < 0
	elif motion_state == "fall":
		sprite.texture = PixelArt.motion("fall",timed_frame("fall",motion_elapsed,0.14))
	elif motion_state == "hurt":
		sprite.texture = PixelArt.motion("hurt",timed_frame("hurt",0.18-hurt_lock,0.18))
	else:
		sprite.texture = PixelArt.motion("idle",int(motion_elapsed/0.22) % PixelArt.motion_count("idle"))
		run_distance = 0.0
	sprite.position.y = PixelArt.offset_y(sprite.texture)
	sprite.rotation = 0
	sprite.modulate = Color(0.6, 0.9, 1) if numb > 0 else Color.WHITE
	if invulnerable > 0 and dash_time <= 0:
		sprite.modulate.a = 0.35 if int(clock * 18) % 2 == 0 else 1.0
	queue_redraw()

func try_dash() -> bool:
	if praying or not enabled or numb > 0 or dash_cooldown > 0 or hurt_lock > 0 or dash_time > 0 or (is_on_floor() and Input.is_action_pressed("down")):
		return false
	dash_direction = facing
	attack_pending = false
	attack_time = 0
	dash_time = DASH_DURATION
	dash_cooldown = 0.65
	ghost_timer = 0
	velocity.y = 0
	invulnerable = maxf(invulnerable, DASH_DURATION + 0.03)
	dashed.emit()
	return true

func try_attack() -> bool:
	if praying or not enabled or attack_cooldown > 0 or dash_time > 0 or hurt_lock > 0:
		return false
	attack_time = ATTACK_DURATION
	attack_cooldown = 0.29
	attack_facing = facing
	attack_pending = true
	attack_windup = ATTACK_WINDUP_DURATION
	return true

func take_damage(amount: int, source: Vector2) -> void:
	if not enabled or invulnerable > 0:
		return
	praying = false
	hp = maxi(0, hp - amount)
	invulnerable = 1.15
	hurt_lock = 0.18
	dash_time = 0
	attack_pending = false
	attack_time = 0
	var away = signf(position.x - source.x)
	if away == 0:
		away = -facing
	velocity = Vector2(away * 285, -230)
	hurt.emit()
	if hp == 0:
		enabled = false
		died.emit()

func restore(at: Vector2) -> void:
	praying = false
	crouching = false
	dropping = 0
	set_collision_mask_value(3,true)
	position = at
	velocity = Vector2.ZERO
	hp = 5
	numb = 0
	inverted = 0
	dash_time = 0
	dash_cooldown = 0
	attack_time = 0
	attack_cooldown = 0
	attack_pending = false
	attack_windup = 0
	attack_buffer = 0
	dash_buffer = 0
	jump_buffer = 0
	coyote = 0
	hurt_lock = 0
	run_distance = 0
	motion_elapsed = 0
	land_pulse = 0
	ghosts.clear()
	invulnerable = 1.0
	enabled = true

func timed_frame(clip: String, elapsed: float, duration: float) -> int:
	return clampi(int(elapsed / duration * PixelArt.motion_count(clip)),0,PixelArt.motion_count(clip)-1)

func attack_frame() -> int:
	if attack_pending:
		return mini(1,int((ATTACK_DURATION-attack_time)/ATTACK_WINDUP_DURATION*2))
	if attack_time > ATTACK_RECOVERY:
		# O corte à frente coincide com a janela ativa. O braço atravessa o
		# torso nas poses seguintes, já sem dano nem trilha à frente.
		return 2
	return 3 + clampi(int((ATTACK_RECOVERY-attack_time)/ATTACK_RECOVERY*3),0,2)

func attack_trail_cells() -> Array[Rect2]:
	var cells: Array[Rect2] = []
	if attack_pending or attack_time <= ATTACK_RECOVERY:
		return cells
	# Rastro de deslocamento, atrás da madeira desenhada no sprite. A largura
	# domina a altura; extremidades afiladas evitam o antigo crescente vertical.
	for x in range(12, int(SLASH_REACH), 4):
		var half_height = 12
		if x < 28:
			half_height = 4 + int((x - 12) / 8) * 4
		elif x >= int(SLASH_REACH) - 24:
			half_height = maxi(4, 12 - int((x - (int(SLASH_REACH) - 24)) / 8) * 4)
		for y in range(SLASH_CENTER_Y - half_height, SLASH_CENTER_Y + half_height, 4):
			cells.append(Rect2(Vector2(x if attack_facing > 0 else -x - 4, y), Vector2(4, 4)))
	return cells

func _draw() -> void:
	for ghost in ghosts:
		var rect = PixelArt.floor_rect(ghost.texture, ghost.pos - position)
		if ghost.flip:
			rect.position.x += rect.size.x
			rect.size.x *= -1
		draw_texture_rect(ghost.texture, rect, false, Color(0.45, 1, 0.8, ghost.life * 2.8))
	for cell in attack_trail_cells():
		var color = Color("594334")
		if cell.position.y in [float(SLASH_CENTER_Y - 4), float(SLASH_CENTER_Y)]:
			color = Color("66806d")
		elif cell.position.y in [float(SLASH_CENTER_Y - 8), float(SLASH_CENTER_Y + 4)]:
			color = Color("79604a")
		color.a = clampf((attack_time - ATTACK_RECOVERY) * 4, 0, 0.32)
		draw_rect(cell, color)
	if land_pulse > 0:
		for i in [-1, 1]:
			draw_rect(Rect2(Vector2(i * (18 + (0.1 - land_pulse) * 160), -4), Vector2(8, 4)), Color(0.65, 0.85, 0.56, land_pulse * 8))
	if inverted > 0:
		for i in range(8):
			var p = (Vector2(0, -104) + Vector2(cos(i * TAU / 8), sin(i * TAU / 8)) * 14).snapped(Vector2(4, 4))
			draw_rect(Rect2(p, Vector2(4, 4)), Color("ffb665"))
	if numb > 0:
		for i in range(3):
			for j in range(5):
				draw_rect(Rect2(-16 + i * 16 + (j % 2) * 4, -80 + j * 12, 4, 8), Color(0.5, 0.8, 1, 0.6))
