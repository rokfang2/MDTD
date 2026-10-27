extends Node2D

const PixelArt = preload("res://scripts/pixel_art.gd")

signal defeated
signal death_started
signal phase_changed
signal collapse_step(frame: int)
signal cue(text: String)
signal attack(kind: String, target: Vector2, phase: int)

var hp = 180
var max_hp = 180
var active = false
var phase = 1
var state = "intro"
var timer = 1.8
var pattern = 0
var clock = 0.0
var flash = 0.0
var target = Vector2.ZERO
var player: CharacterBody2D
var sprite: Sprite2D
const STRIKE_DURATION = 0.48
var charge_goal = 990.0
var tell_duration = 1.05
const DEATH_DURATION = 2.6
const DEATH_FRAME_ENDS = [0.18,0.46,0.88,1.38,2.0,2.6]
var death_elapsed = 0.0
var death_frame = 0

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite = Sprite2D.new()
	sprite.texture = PixelArt.guardian()
	sprite.scale = Vector2.ONE * PixelArt.SCALE
	sprite.position = Vector2(0, PixelArt.offset_y(sprite.texture))
	var material = ShaderMaterial.new()
	material.shader = preload("res://scripts/hit_flash.gdshader")
	sprite.material = material
	add_child(sprite)
	for frame in range(6):
		PixelArt.guardian_death(frame)

func _physics_process(dt: float) -> void:
	clock += dt
	flash = maxf(0, flash - dt)
	sprite.material.set_shader_parameter("flash", minf(1, flash * 7))
	if state in ["dying","defeated"]:
		_tick_death(dt)
		queue_redraw()
		return
	sprite.modulate = Color("d3b8ff") if phase == 2 else Color.WHITE
	sprite.texture = PixelArt.guardian(state == "strike")
	var anticipation = 0.0
	if state == "tell":
		var progress = clampf(1.0-timer/tell_duration,0,1)
		anticipation = (8 if sprite.flip_h else -8)*progress
	sprite.position = Vector2(roundf(anticipation/4)*4,PixelArt.offset_y(sprite.texture))
	if not active:
		queue_redraw()
		return
	timer -= dt
	if timer <= 0:
		match state:
			"phase_shift":
				state = "recover"
				timer = 0.45
			"intro", "recover":
				state = "tell"
				pattern = (pattern + 1) % 4
				target = player.position
				if pattern == 3:
					charge_goal = move_toward(position.x,clampf(target.x,140,1140),(680 if phase == 1 else 800)*STRIKE_DURATION)
				sprite.flip_h = target.x > position.x
				if pattern == 0:
					# A marca precisa anunciar o centro já limitado, antes do golpe.
					target.x = clampf(target.x, 80, 1170)
				# Each move has its own readable preparation; phase II retains
				# enough warning to jump the sensory pulse or cross a charge.
				tell_duration = ([1.05,0.95,1.2,0.9] if phase == 1 else [0.8,0.8,1.05,0.72])[pattern]
				timer = tell_duration
				match pattern:
					0: cue.emit("RAÍZES EMERGINDO  ·  pule sobre a marca laranja")
					1: cue.emit("ESPOROS DORMENTES  ·  desvie das esferas azuis")
					2: cue.emit("PULSO DA REDE  ·  salte ou use dash para evitar a inversão")
					3: cue.emit("MANDÍBULAS  ·  pule ou use dash para atravessar a investida")
			"tell":
				state = "strike"
				timer = STRIKE_DURATION
				attack.emit(["roots", "spores", "invert", "charge"][pattern], target, phase)
			"strike":
				state = "recover"
				timer = 1.25 if phase == 1 else 1.0
				cue.emit("A guarda está aberta. Aproxime-se e ataque.")
	if state == "strike" and pattern == 3:
		position.x = move_toward(position.x,charge_goal,dt*(680 if phase == 1 else 800))
	queue_redraw()

func receive_hit(amount: int) -> void:
	if not active or hp <= 0:
		return
	hp = maxi(0, hp - amount)
	flash = 0.13
	if hp == 0:
		active = false
		state = "dying"
		death_elapsed = 0.0
		death_frame = 0
		death_started.emit()
		collapse_step.emit(0)
	elif hp <= max_hp / 2 and phase == 1:
		phase = 2
		state = "phase_shift"
		timer = 0.9
		phase_changed.emit()
		cue.emit("FASE II  ·  o micélio se rompe. Prepare-se.")
	queue_redraw()

func _tick_death(dt: float) -> void:
	sprite.visible = true
	sprite.modulate = Color.WHITE
	if state == "defeated":
		sprite.texture = PixelArt.guardian_death(5)
		sprite.position = Vector2(0,PixelArt.offset_y(sprite.texture))
		return
	death_elapsed = minf(DEATH_DURATION,death_elapsed+dt)
	var next_frame = 0
	while next_frame < DEATH_FRAME_ENDS.size()-1 and death_elapsed >= DEATH_FRAME_ENDS[next_frame]:
		next_frame += 1
	if next_frame != death_frame:
		death_frame = next_frame
		collapse_step.emit(death_frame)
	# A common grounded pivot keeps falling limbs and the corpse in place.
	sprite.texture = PixelArt.guardian_death(death_frame)
	sprite.position = Vector2(0,PixelArt.offset_y(sprite.texture))
	if death_elapsed >= DEATH_DURATION:
		state = "defeated"
		defeated.emit()

func _draw() -> void:
	if state in ["dying","defeated"]:
		return
	if state == "phase_shift":
		for i in range(12):
			var at = Vector2((i-6)*20,-110-absf(i-6)*8).snapped(Vector2(4,4))
			draw_rect(Rect2(at,Vector2(8,8)),Color("ffb82b"))
	if state == "tell":
		if pattern == 3:
			var end_x = charge_goal
			for x in range(int(minf(position.x,end_x)),int(maxf(position.x,end_x)),16):
				draw_rect(Rect2(x-position.x,-12,8,4),Color("f5a32b"))
		var color = Color("ffb768") if pattern != 1 else Color("82e7ff")
		var fill = clampf(1.0 - timer / tell_duration, 0, 1)
		for i in range(20):
			if float(i) / 20 > fill:
				continue
			var angle = -PI + i * PI / 19
			var at = (Vector2(0, -100) + Vector2(cos(angle) * 172, sin(angle) * 180)).snapped(Vector2(4, 4))
			draw_rect(Rect2(at, Vector2(8, 8)), color)
