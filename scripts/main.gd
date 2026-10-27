extends Node2D

const World = preload("res://scripts/world.gd")
const SAVE_PATH = "user://progress.json"
const CREAM = Color("f4e8ca")
const MINT = Color("a5d9bc")
var state = "menu"
var world
var layer: CanvasLayer
var ui: Control
var hud: Control
var health_label: Label
var status_label: Label
var prompt_label: Label
var notice_label: Label
var boss_bar: ProgressBar
var boss_name: Label
var notice_time = 0.0
var clock = 0.0
var save_data: Dictionary = {}
var checkpoint = Vector2(130, 490)
var memories: Array[String] = []
var flower = false
var title_font: SystemFont
var sfx: AudioStreamPlayer
var ambience: AudioStreamPlayer
var muted = false
var captures: Array[String] = []
var shutting_down = false
var persist_progress = true
var region_label: Label

func _ready() -> void:
	get_tree().auto_accept_quit = false
	_setup_inputs()
	title_font = SystemFont.new()
	title_font.font_names = PackedStringArray(["Georgia", "Liberation Serif", "DejaVu Serif"])
	title_font.font_weight = 700
	layer = CanvasLayer.new()
	add_child(layer)
	hud = Control.new()
	layer.add_child(hud)
	ui = Control.new()
	layer.add_child(ui)
	sfx = AudioStreamPlayer.new()
	sfx.volume_db = -15
	add_child(sfx)
	ambience = AudioStreamPlayer.new()
	ambience.stream = preload("res://assets/ambience.wav")
	ambience.volume_db = -24
	add_child(ambience)
	if DisplayServer.get_name() != "headless":
		ambience.play()
	_read_save()
	show_menu()
	var args = OS.get_cmdline_user_args()
	if "--arena" in args:
		start_world("arena")
	elif "--trail" in args:
		start_world("trail")
	for arg in args:
		if arg.begins_with("--capture="):
			captures.append(arg.trim_prefix("--capture="))
	if not captures.is_empty():
		_capture.call_deferred()

func _setup_inputs() -> void:
	var bindings = {"left": [KEY_A, KEY_LEFT], "right": [KEY_D, KEY_RIGHT], "jump": [KEY_SPACE, KEY_W, KEY_UP], "dash": [KEY_SHIFT, KEY_K], "attack": [KEY_J, KEY_X], "down": [KEY_S, KEY_DOWN], "map": [KEY_TAB], "interact": [KEY_E], "flower": [KEY_F], "pause": [KEY_ESCAPE], "mute": [KEY_M]}
	for action in bindings:
		if not InputMap.has_action(action):
			InputMap.add_action(action)
		for key in bindings[action]:
			var event = InputEventKey.new()
			event.physical_keycode = key
			InputMap.action_add_event(action, event)
	var mouse = InputEventMouseButton.new()
	mouse.button_index = MOUSE_BUTTON_LEFT
	InputMap.action_add_event("attack", mouse)

func _process(dt: float) -> void:
	if shutting_down:
		return
	clock += dt
	if DisplayServer.get_name() != "headless" and not ambience.playing:
		ambience.play()
	if Input.is_action_just_pressed("mute"):
		muted = not muted
		AudioServer.set_bus_mute(0, muted)
	if Input.is_action_just_pressed("pause"):
		if state == "playing":
			show_pause()
		elif state in ["paused", "memory"]:
			resume_game()
		elif state == "controls":
			show_menu()
	if world != null and is_instance_valid(world) and state == "playing":
		_update_hud(dt)
	queue_redraw()

func _clear(container: Control) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _label(parent: Node, text: String, at: Vector2, size: int = 20, color: Color = CREAM, width: float = 650, serif: bool = false) -> Label:
	var label = Label.new()
	label.text = text
	label.position = at
	label.size.x = width
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	if parent == hud:
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 2)
	if serif:
		label.add_theme_font_override("font", title_font)
	parent.add_child(label)
	return label

func _panel(parent: Node, rect: Rect2, color: Color = Color("101e25")) -> Panel:
	var panel = Panel.new()
	panel.position = rect.position
	panel.size = rect.size
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("49635c")
	style.set_border_width_all(1)
	style.set_corner_radius_all(0)
	panel.add_theme_stylebox_override("panel", style)
	parent.add_child(panel)
	return panel

func _button(parent: Node, text: String, at: Vector2, callback: Callable, primary: bool = false, width: float = 310) -> Button:
	var button = Button.new()
	button.text = text
	button.position = at
	button.size = Vector2(width, 48)
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_font_size_override("font_size", 18)
	for style_name in ["normal", "hover", "pressed", "focus"]:
		var style = StyleBoxFlat.new()
		style.bg_color = Color("dce5bf") if primary else Color(0.04, 0.1, 0.12, 0.9)
		if style_name in ["hover", "focus"]:
			style.bg_color = Color("f2e8cc") if primary else Color("29453e")
		style.border_color = Color("c8d9ad") if primary else Color("698675")
		style.set_border_width_all(1)
		style.set_corner_radius_all(0)
		button.add_theme_stylebox_override(style_name, style)
	for color_name in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color"]:
		button.add_theme_color_override(color_name, Color("172a28") if primary else CREAM)
	button.pressed.connect(callback)
	parent.add_child(button)
	return button

func show_menu() -> void:
	state = "menu"
	if world != null and is_instance_valid(world):
		remove_child(world)
		world.queue_free()
		world = null
	_clear(ui)
	_clear(hud)
	_label(ui, "UM REINO EM GUERRA. UMA VERDADE ENTERRADA.", Vector2(82, 77), 14, MINT)
	_label(ui, "Mushrooms\nDeserve to Die", Vector2(76, 121), 68, CREAM, 850, true)
	_label(ui, "O ódio do jogador é a mentira do mundo.", Vector2(83, 310), 21, Color("c5d1bd"))
	var y = 390.0
	if save_data.has("checkpoint"):
		_button(ui, "Continuar jornada   →", Vector2(84, y), continue_game, true)
		y += 60
	_button(ui, "Nascer do lótus   →", Vector2(84, y), new_game, not save_data.has("checkpoint"))
	_button(ui, "Como jogar", Vector2(84, y + 60), show_controls)
	_button(ui, "Sair", Vector2(84, y + 120), shutdown)
	var card = _panel(ui, Rect2(900, 405, 300, 194), Color(0.03, 0.09, 0.12, 0.87))
	_label(card, "01 / RAÍZES PROFUNDAS", Vector2(22, 20), 13, MINT, 260)
	_label(card, "A Pele Dormente", Vector2(22, 54), 23, CREAM, 260, true)
	_label(card, "Encontre o Cordyceps.\nDesconfie dos seus sentidos.", Vector2(22, 98), 16, Color("bac5bd"), 260)
	_label(ui, "FATIA JOGÁVEL  /  GDD v2.0", Vector2(84, 671), 12, Color("9ab2a7"))
	_label(ui, "M  som ligado/desligado", Vector2(1010, 671), 12, Color("9ab2a7"), 230)

func show_controls() -> void:
	state = "controls"
	_clear(ui)
	_panel(ui, Rect2(230, 75, 820, 575), Color(0.035, 0.075, 0.1, 0.97))
	_label(ui, "A memória do corpo", Vector2(280, 105), 38, CREAM, 720, true)
	_label(ui, "Cada movimento é uma escolha. Cada luz, um retorno.", Vector2(282, 165), 18, MINT)
	var rows = [["A / D   ou   ← / →", "Mover"], ["Espaço / W / ↑", "Pular · solte antes para um salto curto"], ["Shift / K", "Dash · invulnerabilidade breve"], ["J / X / clique esquerdo", "Lâmina de espinho"], ["E", "Lótus, memórias e passagem"], ["F", "Calêndula · após derrotar o guardião"], ["Esc   /   M", "Pausa   /   ativar ou silenciar som"]]
	for i in range(rows.size()):
		_label(ui, rows[i][0], Vector2(285, 222 + i * 41), 17, CREAM, 280)
		_label(ui, rows[i][1], Vector2(565, 222 + i * 41), 17, Color("b5c7be"), 460)
	_button(ui, "Voltar", Vector2(282, 557), show_menu, true, 230).grab_focus()

func new_game() -> void:
	checkpoint = Vector2(130, 490)
	memories.clear()
	flower = false
	start_world("trail")
	show_notice("ENCONTRE O LÓTUS  ·  siga à direita e escute as memórias", 5)

func continue_game() -> void:
	var saved = save_data.get("checkpoint", [130, 490])
	checkpoint = Vector2(float(saved[0]), float(saved[1]))
	memories.assign(save_data.get("memories", []))
	flower = bool(save_data.get("flower", false))
	start_world("trail")

func start_world(mode: String) -> void:
	if world != null and is_instance_valid(world):
		remove_child(world)
		world.queue_free()
	world = World.new()
	world.mode = mode
	world.checkpoint = checkpoint
	world.checkpoint_lit = checkpoint.x > 1000
	world.memories.assign(memories)
	world.flower = flower
	world.entered_arena.connect(func(): start_world.call_deferred("arena"))
	world.checkpoint_activated.connect(func(at): checkpoint = at; _write_save())
	world.memory_found.connect(_memory_found)
	world.reward_claimed.connect(_victory)
	world.toast.connect(show_notice)
	world.sound.connect(play_sound)
	state = "playing"
	_clear(ui)
	_build_hud(mode)
	add_child(world)
	world.player.died.connect(_death)
	if mode == "arena":
		show_notice("CORDYCEPS  ·  o hospedeiro da Rede", 3)

func _build_hud(mode: String) -> void:
	_clear(hud)
	var card = _panel(hud, Rect2(28, 24, 335, 90), Color(0.03, 0.08, 0.1, 0.88))
	_label(card, "O INVOCADO", Vector2(17, 10), 12, MINT, 300)
	health_label = _label(card, "", Vector2(17, 30), 26, CREAM, 300)
	status_label = _label(hud, "", Vector2(32, 125), 16, CREAM, 800)
	var region = "REINO VERDEJANTE" if mode == "trail" else "RAÍZES PROFUNDAS"
	var label = _label(hud, region, Vector2(850, 30), 16, CREAM, 400)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	region_label = label
	label = _label(hud, "TRILHA DO LÓTUS" if mode == "trail" else "TATO / PRIMEIRO GUARDIÃO", Vector2(830, 57), 12, MINT, 420)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	notice_label = _label(hud, "", Vector2(230, 147), 17, CREAM, 820)
	notice_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notice_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	notice_label.add_theme_constant_override("shadow_offset_x", 2)
	notice_label.add_theme_constant_override("shadow_offset_y", 2)
	prompt_label = _label(hud, "", Vector2(200, 623), 18, CREAM, 880)
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	prompt_label.add_theme_constant_override("shadow_offset_y", 2)
	_label(hud, "A D  mover     Espaço  pular     Shift  dash     J / clique  atacar     E  interagir     Esc  pausa", Vector2(280, 687), 13, Color("bbd1c6"), 990)
	if mode == "arena":
		boss_name = _label(hud, "Cordyceps, o Hospedeiro", Vector2(320, 624), 19, CREAM, 640, true)
		boss_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boss_bar = ProgressBar.new()
		boss_bar.position = Vector2(320, 659)
		boss_bar.size = Vector2(640, 10)
		boss_bar.max_value = 180
		boss_bar.show_percentage = false
		var fill = StyleBoxFlat.new()
		fill.bg_color = Color("b5a7dc")
		fill.set_corner_radius_all(0)
		boss_bar.add_theme_stylebox_override("fill", fill)
		var back = StyleBoxFlat.new()
		back.bg_color = Color("263340")
		back.set_corner_radius_all(0)
		boss_bar.add_theme_stylebox_override("background", back)
		hud.add_child(boss_bar)

func _update_hud(dt: float) -> void:
	health_label.text = _health_text()
	if world.mode == "trail":
		for region in world.Level.REGIONS:
			if world.player.position.x >= region.start:
				region_label.text = region.name.to_upper()
	var status = ""
	if world.player.numb > 0:
		status += "DORMÊNCIA %.1fs   " % world.player.numb
	elif world.player.dash_cooldown > 0:
		status += "Dash %.1fs   " % world.player.dash_cooldown
	else:
		status += "Dash pronto   "
	if world.player.inverted > 0:
		status += "← CONTROLES INVERTIDOS →   "
	if flower:
		status += "F · Calêndula " + ("pronta" if world.flower_cooldown <= 0 else "%.0fs" % world.flower_cooldown)
	if world.mode == "trail":
		status += "   Tab · mapa   S + Espaço · descer raiz"
	if world.map_open:
		status = "" # A legenda fica no painel do mapa, sem cobrir os setores.
	status_label.text = status
	prompt_label.text = world.prompt
	if world.mode == "arena" and world.boss != null:
		boss_bar.value = world.boss.hp
		boss_bar.visible = world.boss.hp > 0
		boss_name.visible = world.boss.hp > 0
		prompt_label.position.y = 600 if world.reward_ready else 194
	notice_time = maxf(0, notice_time - dt)
	notice_label.modulate.a = minf(1, notice_time)

func _health_text() -> String:
	var text = ""
	for i in range(5):
		text += "◆  " if i < world.player.hp else "◇  "
	return text

func show_notice(message: String, duration: float = 3.0) -> void:
	if is_instance_valid(notice_label):
		notice_label.text = message
		notice_time = duration

func _overlay(title: String, subtitle: String) -> void:
	_clear(ui)
	var shade = ColorRect.new()
	shade.color = Color(0.015, 0.035, 0.05, 0.83)
	shade.size = Vector2(1280, 720)
	ui.add_child(shade)
	_panel(ui, Rect2(300, 160, 680, 410), Color("10222a"))
	_label(ui, title, Vector2(344, 198), 36, CREAM, 600, true)
	var description = _label(ui, subtitle, Vector2(347, 266), 19, Color("c0d1c3"), 580)
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.size.y = 160

func show_pause() -> void:
	state = "paused"
	world.process_mode = Node.PROCESS_MODE_DISABLED
	_overlay("Entre uma respiração e outra", "O mundo espera. A luz permanece acesa.\n\nJ / clique: ataque · Shift: dash · E: interagir")
	_button(ui, "Retomar", Vector2(347, 432), resume_game, true, 270).grab_focus()
	_button(ui, "Menu", Vector2(637, 432), show_menu, false, 270)

func resume_game() -> void:
	_clear(ui)
	state = "playing"
	world.process_mode = Node.PROCESS_MODE_INHERIT

func _memory_found(id: String, text: String) -> void:
	if id not in memories:
		memories.append(id)
	state = "memory"
	world.process_mode = Node.PROCESS_MODE_DISABLED
	var parts = text.split("\n", true, 1)
	_overlay(parts[0].capitalize(), parts[1])
	_label(ui, "PERCEPÇÃO  ·  %d / %d memórias escutadas" % [memories.size(),world.Level.MEMORIES.size()], Vector2(347, 381), 14, MINT, 590)
	_button(ui, "Guardar a memória", Vector2(347, 470), resume_game, true, 330).grab_focus()

func _death() -> void:
	state = "dead"
	world.process_mode = Node.PROCESS_MODE_DISABLED
	_overlay("A luz ainda se lembra", "O corpo se desfaz. O lótus acolhe o que resta.\n\nRenasça no último lótus ativado. As memórias permanecem.")
	_button(ui, "Renascer no lótus", Vector2(347, 445), func(): start_world("trail"), true, 330).grab_focus()
	_button(ui, "Menu", Vector2(697, 445), show_menu, false, 205)

func _victory() -> void:
	flower = true
	world.flower = true
	_write_save()
	state = "victory"
	world.process_mode = Node.PROCESS_MODE_DISABLED
	_overlay("O primeiro fragmento", "Calêndula adquirida. Use F para curar a dormência do dash.\n\nA gema laranja encontra seu lugar no amuleto. A luz dos olhos vacila. O que ele estava protegendo?")
	_label(ui, "FIM DA PRIMEIRA FATIA JOGÁVEL  ·  1 de 5 confrontos", Vector2(347, 398), 13, MINT, 590)
	_button(ui, "Testar a Calêndula · repetir luta", Vector2(347, 460), func(): start_world("arena"), true, 390).grab_focus()
	_button(ui, "Menu", Vector2(753, 460), show_menu, false, 150)

func _read_save() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	if parsed is Dictionary and parsed.get("version") == 1:
		var point = parsed.get("checkpoint", [])
		if point is Array and point.size() == 2 and point[0] is float and point[1] is float:
			save_data = parsed

func _write_save() -> void:
	if not persist_progress:
		return
	save_data = {"version": 1, "checkpoint": [checkpoint.x, checkpoint.y], "memories": memories, "flower": flower}
	var file = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(save_data))

func play_sound(name: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	var path = "res://assets/" + name + ".wav"
	if ResourceLoader.exists(path):
		sfx.stream = load(path)
		sfx.play()

func _draw() -> void:
	if state in ["menu", "controls"]:
		draw_texture_rect(preload("res://scripts/style_environment.gd").background(), Rect2(0, 0, 1280, 720), false)
		for i in range(128):
			var alpha = 0.91 - float(i) / 128 * 0.79
			draw_rect(Rect2(i * 10, 0, 10, 720), Color(0.015, 0.055, 0.065, alpha))
		draw_rect(Rect2(0, 640, 1280, 80), Color(0.02, 0.05, 0.06, 0.4))
		for i in range(36):
			var at = Vector2(fposmod(i * 79 + sin(clock * 0.3 + i) * 20, 1280), fposmod(i * 83 - clock * 7, 720))
			draw_rect(Rect2(at.snapped(Vector2(4, 4)), Vector2(4, 4)), Color(0.7, 1, 0.8, 0.2 + sin(clock + i) * 0.15))

func _capture() -> void:
	await get_tree().create_timer(0.7).timeout
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(captures[0])
	await shutdown()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		shutdown()

func shutdown() -> void:
	if shutting_down:
		return
	shutting_down = true
	sfx.stop()
	ambience.stop()
	sfx.stream = null
	ambience.stream = null
	await get_tree().create_timer(0.15).timeout
	get_tree().quit()
