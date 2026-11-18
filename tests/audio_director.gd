extends SceneTree

# Áudio responsivo (ata 27/10/2026, 4.1): buses, trilha por zona e camadas, ambientes/eco por região,
# passos por superfície, avisos que preservam a leitura dos ataques, lótus (plantar/orar/salvar/revisitar),
# memórias como pistas sonoras com fala, chefe por fase, flor sagrada e bênção. Em headless não há
# reprodução real: as decisões do diretor ficam em `history`. Não grava progresso (persist_progress=false).
var game
var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func tap(action: String) -> void:
	Input.action_press(action)
	await frames(2)
	Input.action_release(action)
	await frames(2)

func heard_prefix(audio, prefix: String) -> bool:
	for entry in audio.history:
		if entry.begins_with(prefix):
			return true
	return false

func _run() -> void:
	var master_before = AudioServer.get_bus_volume_db(0)
	game = load("res://Scenes/main.tscn").instantiate()
	game.persist_progress = false
	root.add_child(game)
	await frames(3)
	var audio = game.audio
	check(audio != null, "Main cria o diretor de áudio")
	check(AudioServer.get_bus_name(0) == "Master" and is_equal_approx(AudioServer.get_bus_volume_db(0), master_before), "Master segue no índice 0 e o diretor não muda seu volume")
	for bus in ["Music", "Ambience", "Space", "SFX", "Telegraph", "Voice", "UI"]:
		check(AudioServer.get_bus_index(bus) > 0, "bus " + bus + " existe")
	var music_bus = AudioServer.get_bus_index("Music")
	check(String(AudioServer.get_bus_send(AudioServer.get_bus_index("SFX"))) == "Space", "efeitos passam pelo bus de eco Space")
	check(AudioServer.get_bus_effect(AudioServer.get_bus_index("Space"), 0) is AudioEffectReverb, "Space tem reverb")
	check(AudioServer.get_bus_effect(music_bus, 0) is AudioEffectLowPassFilter and AudioServer.get_bus_effect(music_bus, 1) is AudioEffectPhaser, "Music tem passa-baixa e phaser")
	check(audio.current_music == "menu", "menu toca a trilha do menu")
	check(game.ambience != null and game.sfx != null, "contrato antigo: Main.ambience e Main.sfx existem")

	# Catálogo: todo arquivo citado existe e carrega; camadas têm a mesma duração da base.
	var cues = load("res://scripts/audio_cues.gd")
	var missing: Array[String] = []
	var files: Array[String] = []
	for cue in cues.CUES:
		for file in cues.CUES[cue]["files"]:
			files.append(file)
	for table in [cues.MUSIC, cues.AMBIENCE, cues.LOOPS]:
		for key in table:
			for field in ["file", "layer"]:
				if table[key].has(field):
					files.append(table[key][field])
	for voice in cues.VOICES:
		for file in cues.VOICES[voice]["files"]:
			files.append(file)
	for file in files:
		if not ResourceLoader.exists(cues.ROOT + file) or load(cues.ROOT + file) == null:
			missing.append(file)
	check(missing.is_empty(), "todos os %d arquivos do catálogo existem e carregam %s" % [files.size(), str(missing)])
	for key in cues.MUSIC:
		if cues.MUSIC[key].has("layer"):
			var base = load(cues.ROOT + cues.MUSIC[key]["file"]) as AudioStream
			var layer = load(cues.ROOT + cues.MUSIC[key]["layer"]) as AudioStream
			check(base != null and layer != null and absf(base.get_length() - layer.get_length()) < 0.005, "camada de " + key + " tem a duração da base (sincronia)")
	var loop_stream = audio._stream(cues.LOOPS["memoria_seiva"]["file"], true)
	check(loop_stream is AudioStreamWAV and loop_stream.loop_mode == AudioStreamWAV.LOOP_FORWARD, "loops posicionais repetem sem emenda (WAV com loop)")
	check(cues.REGION_AUDIO.size() == load("res://scripts/level_data.gd").REGIONS.size(), "uma configuração de áudio por região do mapa")

	# Nova jornada: nasce do lótus, Reino Verdejante, sinais posicionais.
	game.new_game()
	await frames(4)
	var world = game.world
	var player = world.player
	player.invulnerable = 999.0
	check(audio.heard("cue:lotus_renascimento"), "nova jornada nasce do lótus (som)")
	check(audio.current_music == "verdejante" and audio.current_ambience == "floresta", "Reino Verdejante tem trilha e ambiente próprios")
	var memory_signals = 0
	var lotus_signals = 0
	var fly_signals = 0
	for node in world.find_children("*", "AudioStreamPlayer2D", true, false):
		var loop_name = str(node.get_meta("mdtd_loop", ""))
		if loop_name.begins_with("memoria_"):
			memory_signals += 1
		elif loop_name == "lotus_foco":
			lotus_signals += 1
		elif loop_name == "mosca_zumbido":
			fly_signals += 1
	check(memory_signals == world.Level.MEMORIES.size(), "cada memória não ouvida tem pista sonora posicional (%d)" % memory_signals)
	check(lotus_signals == world.Level.LOTUSES.size(), "cada lótus/foco de luz soa no mapa")
	check(fly_signals == 3, "moscas zumbem posicionalmente")

	# Passos pelos contatos reais da corrida + camada de perigo quando a formiga persegue.
	audio.clear_history()
	Input.action_press("right")
	await frames(45)
	Input.action_release("right")
	await frames(6)
	check(audio.count("cue:passo_musgo") + audio.count("cue:passo_madeira") >= 2, "passos tocam pelos contatos da corrida (%d)" % (audio.count("cue:passo_musgo") + audio.count("cue:passo_madeira")))
	check(audio.danger_target >= 1.0, "formiga em perseguição ativa a camada de perigo")
	await frames(30)
	check(audio.danger > 0.3, "camada de perigo entra gradualmente")

	# Galerias de Seiva: troca de zona com histerese, eco de caverna e passos úmidos.
	player.position = Vector2(7300, 650)
	player.velocity = Vector2.ZERO
	await frames(20)
	check(audio.current_music != "rede", "troca de trilha espera a histerese (sem oscilar na fronteira)")
	await frames(60)
	check(audio.current_music == "rede" and audio.current_ambience == "galerias", "Galerias trocam para trilha da Rede e ambiente de goteiras")
	check(audio.space_name == "caverna" and audio.surface == "umido", "bacia das galerias: eco de caverna e passos úmidos")
	audio.clear_history()
	Input.action_press("left")
	await frames(40)
	Input.action_release("left")
	await frames(4)
	check(audio.count("cue:passo_umido") >= 1, "passos úmidos nas galerias")
	var Director = load("res://scripts/audio_director.gd")
	var zone_high = Director.zone_at(Vector2(7300, 278))
	check(zone_high["space"] == "raizes" and zone_high["surface"] == "terra", "caminho alto das galerias é seco")
	var zone_tunnel = Director.zone_at(Vector2(11500, 610))
	check(zone_tunnel["ambience"] == "galerias" and zone_tunnel["surface"] == "umido", "pisos baixos do vestíbulo soam como túnel úmido")

	# Tato: dash bloqueado pela dormência e distorção enquanto os controles estão invertidos.
	audio.clear_history()
	player.numb = 1.7
	await tap("dash")
	check(audio.heard("cue:dash_bloqueado"), "dash recusado na dormência tem som próprio")
	player.numb = 0
	player.inverted = 1.0
	await frames(3)
	check(AudioServer.is_bus_effect_enabled(music_bus, 1), "inversão ativa a distorção (phaser) na trilha")
	player.inverted = 0
	await frames(3)
	check(not AudioServer.is_bus_effect_enabled(music_bus, 1), "distorção some ao fim da inversão")

	# Lótus: plantar, canto que acompanha a oração, salvamento, revisita e interrupção.
	player.position = Vector2(1450, 506)
	player.velocity = Vector2.ZERO
	await frames(70)
	audio.clear_history()
	world.activate_lotus(Vector2(1490, 506))
	await frames(2)
	check(audio.heard("cue:lotus_plantar") and audio.heard("prayer:start"), "orar planta a raiz e inicia o canto")
	await frames(45)
	check(audio.prayer_pitch > 1.05, "canto sobe com o progresso da oração (%.3f)" % audio.prayer_pitch)
	await frames(50)
	check(audio.heard("prayer:done") and audio.heard("cue:lotus_salvo"), "oração concluída toca o salvamento")
	audio.clear_history()
	world.activate_lotus(Vector2(1490, 506))
	await frames(95)
	check(audio.heard("cue:lotus_reafirmado") and not audio.heard("cue:lotus_salvo"), "revisitar o lótus ativo usa confirmação curta")
	audio.clear_history()
	world.activate_lotus(Vector2(1490, 506))
	await frames(10)
	player.invulnerable = 0
	player.take_damage(1, player.position + Vector2(30, 0))
	await frames(3)
	player.invulnerable = 999.0
	check(audio.heard("prayer:cancel") and audio.heard("cue:lotus_interrompida"), "dano interrompe a oração com som próprio")

	# Memória: a pista some, a seiva fala e a trilha recua enquanto o texto está aberto.
	await frames(30)
	var memory = world.Level.MEMORIES[0]
	player.position = memory.pos
	player.velocity = Vector2.ZERO
	await frames(6)
	audio.clear_history()
	await tap("interact")
	check(game.state == "memory" and audio.focus == "memory", "memória abre com foco de áudio")
	check(audio.heard("cue:memoria_revelada") and audio.heard("speech:seiva") and audio.speaking(), "memória é falada com a voz da seiva")
	check(not world.memory_emitters.has(memory.id), "pista sonora da memória ouvida é removida")
	await frames(20)
	check(AudioServer.is_bus_effect_enabled(music_bus, 0), "trilha fica abafada durante a memória")
	game.resume_game()
	await frames(2)
	check(audio.focus == "" and not audio.speaking(), "guardar a memória encerra a fala")

	# Pausa e mapa.
	audio.clear_history()
	game.show_pause()
	await frames(20)
	check(audio.focus == "pause" and audio.heard("cue:pausa_abrir") and AudioServer.is_bus_effect_enabled(music_bus, 0), "pausa abafa a trilha")
	game.resume_game()
	await frames(60)
	check(audio.focus == "" and not AudioServer.is_bus_effect_enabled(music_bus, 0), "retomar devolve a trilha limpa")
	await tap("map")
	check(audio.heard("cue:mapa_abrir"), "abrir o mapa tem som")
	await tap("map")
	check(audio.heard("cue:mapa_fechar"), "fechar o mapa tem som")

	# Morte e renascimento.
	audio.clear_history()
	player.invulnerable = 0
	player.take_damage(5, player.position)
	await frames(3)
	check(game.state == "dead" and audio.current_music == "" and audio.heard("cue:druida_morte"), "morte silencia a trilha")
	game._respawn()
	await frames(4)
	check(audio.heard("cue:lotus_renascimento") and audio.current_music != "", "renascer no lótus retoma a trilha da região")

	# Cordyceps: trilha de combate, avisos alinhados, fase II, colapso, flor e bênção.
	game.start_world("arena")
	await frames(3)
	world = game.world
	player = world.player
	player.invulnerable = 999.0
	check(audio.current_music == "cordyceps" and audio.current_ambience == "ninho" and audio.space_name == "ninho", "arena: trilha de combate, ninho e eco próprio")
	check(audio.heard("cue:cordyceps_rugido"), "Cordyceps anuncia o confronto")
	audio.clear_history()
	var told = false
	for i in range(220):
		await frames(1)
		if world.boss.state == "tell":
			told = true
			break
	await frames(6)
	check(told and heard_prefix(audio, "telegraph:tell_"), "aviso natural do chefe tem som próprio")
	check(audio.duck_db < -1.0 and AudioServer.get_bus_volume_db(music_bus) < -6.5, "aviso abaixa a trilha para preservar a leitura do ataque")
	await frames(75)
	check(heard_prefix(audio, "cue:esporos_lancados") or heard_prefix(audio, "cue:raizes_irrompem") or heard_prefix(audio, "cue:pulso_inversao") or heard_prefix(audio, "cue:investida_mandibulas"), "golpe do chefe tem som próprio")
	world.boss.receive_hit(95)
	await frames(3)
	check(world.boss.phase == 2 and audio.heard("cue:fase_dois"), "fase II tem sinal próprio")
	await frames(60)
	check(audio.danger_target >= 1.0 and audio.danger > 0.3, "fase II acrescenta a camada de combate")
	world.boss.receive_hit(200)
	await frames(3)
	check(audio.heard("cue:chefe_colapso") and audio.current_music == "", "colapso do chefe silencia a trilha de combate")
	await frames(175)
	check(audio.heard("cue:colapso_estalo"), "poses do colapso estalam")
	check(audio.current_music == "flor" and audio.heard("cue:chefe_silencia") and audio.heard("cue:flor_surge"), "flor sagrada surge com sua música")
	player.position = Vector2(world.reward_position.x, 590)
	player.velocity = Vector2.ZERO
	await frames(6)
	world.activate_lotus(world.reward_position)
	await frames(100)
	check(game.state == "victory" and audio.heard("cue:bencao_calendula") and audio.heard("speech:flor") and audio.focus == "blessing", "bênção da Calêndula com a voz da flor")

	game.show_menu()
	await frames(3)
	check(audio.current_music == "menu" and audio.current_ambience == "" and audio.focus == "", "voltar ao menu restaura a trilha do menu")
	check(is_equal_approx(AudioServer.get_bus_volume_db(0), master_before), "Master permanece intocado")
	game.queue_free()
	await frames(2)
	print("RESULT: ", checks - failures, "/", checks, " audio checks passed")
	quit(0 if failures == 0 else 1)
