extends Node
## Diretor de áudio responsivo (ata 27/10/2026, seção 4.1; lista completa em docs/AUDIO_MAP.md).
##
## - Buses próprios abaixo do Master. O Master continua no índice 0, controlado pelo volume do menu e pela tecla M.
## - Música por zona com crossfade e camada sincronizada: perigo na trilha (inimigos em perseguição) e fase II no chefe.
## - Ambiente e eco por região (bus Space com reverb): goteiras e eco nas galerias/caverna.
## - Avisos de ataque no bus Telegraph: abaixam trilha/ambiente e têm o clímax alinhado ao golpe (leitura dos ataques).
## - Sinais posicionais de memórias, lótus e moscas; oração com canto que acompanha o progresso; falas silábicas.
## Em modo headless não há reprodução real, mas todas as decisões ficam registradas em `history` para os testes.

const Cues = preload("res://scripts/audio_cues.gd")
const Level = preload("res://scripts/level_data.gd")

const BUSES = [
	# nome, volume_db, envia para (precisa estar à esquerda)
	["Music", -6.0, "Master"],
	["Ambience", -7.0, "Master"],
	["Space", 0.0, "Master"],
	["SFX", -2.0, "Space"],
	["Telegraph", -1.0, "Master"],
	["Voice", -4.0, "Master"],
	["UI", -6.0, "Master"],
]
const SILENT_DB = -80.0
const ZONE_HOLD = 0.8
const OPEN_CUTOFF = 20500.0
const FOCUS_MIX = {
	"": {"music": 0.0, "ambience": 0.0, "cutoff": OPEN_CUTOFF},
	"pause": {"music": -4.0, "ambience": -6.0, "cutoff": 900.0},
	"memory": {"music": -9.0, "ambience": -7.0, "cutoff": 1600.0},
	"blessing": {"music": -2.0, "ambience": -8.0, "cutoff": OPEN_CUTOFF},
	"dead": {"music": -6.0, "ambience": -10.0, "cutoff": 1200.0},
}

var playback_enabled = DisplayServer.get_name() != "headless"
var clock = 0.0
var history: PackedStringArray = PackedStringArray()
var current_music = ""
var current_ambience = ""
var space_name = "floresta"
var surface = "musgo"
var focus = ""
var danger = 0.0
var danger_target = 0.0
var duck_db = 0.0
var prayer_pitch = 1.0
var inverted = false
var numb = false

var _decks: Array[AudioStreamPlayer] = []
var _layers: Array[AudioStreamPlayer] = []
var _deck_db = [SILENT_DB, SILENT_DB]
var _layer_db = [SILENT_DB, SILENT_DB]
var _deck = 0
var _amb: Array[AudioStreamPlayer] = []
var _amb_index = 0
var _pools = {}
var _pool_next = {}
var _pos_pool: Array[AudioStreamPlayer2D] = []
var _pos_next = 0
var _voice: Array[AudioStreamPlayer] = []
var _voice_next = 0
var _prayer: AudioStreamPlayer
var _praying = false
var _fades = {}
var _cache = {}
var _variants = {}
var _last_variant = {}
var _last_played = {}
var _missing = {}
var _rng = RandomNumberGenerator.new()
var _base_db = {}
var _danger_request = 0.0
var _danger_hold = 0.0
var _duck_until = -1.0
var _duck_amount = 0.0
var _cutoff = OPEN_CUTOFF
var _pending_zone = ""
var _pending_since = 0.0
var _force_zone = false
var _speech: Array = []
var _speech_voice = ""
var _ui_quiet_until = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_rng.seed = 2710
	_setup_buses()
	for i in range(2):
		_decks.append(_player("Music"))
		_layers.append(_player("Music"))
		_amb.append(_player("Ambience"))
		_voice.append(_player("Voice"))
	for bus in ["SFX", "Telegraph", "UI", "Music"]:
		var pool: Array = []
		for i in range(10 if bus == "SFX" else 3):
			pool.append(_player(bus))
		_pools[bus] = pool
		_pool_next[bus] = 0
	for i in range(8):
		var emitter = AudioStreamPlayer2D.new()
		emitter.bus = "SFX"
		emitter.max_distance = 1500.0
		emitter.attenuation = 1.4
		add_child(emitter)
		_pos_pool.append(emitter)
	_prayer = _player("SFX")

func _player(bus: String) -> AudioStreamPlayer:
	var p = AudioStreamPlayer.new()
	p.bus = bus
	p.volume_db = SILENT_DB
	add_child(p)
	return p

func _setup_buses() -> void:
	for spec in BUSES:
		var index = AudioServer.get_bus_index(spec[0])
		if index < 0:
			AudioServer.add_bus()
			index = AudioServer.bus_count - 1
			AudioServer.set_bus_name(index, spec[0])
		AudioServer.set_bus_volume_db(index, spec[1])
		AudioServer.set_bus_send(index, spec[2])
		_base_db[spec[0]] = spec[1]
	for bus_name in ["Music", "Ambience"]:
		var index = AudioServer.get_bus_index(bus_name)
		if AudioServer.get_bus_effect_count(index) == 0:
			var lowpass = AudioEffectLowPassFilter.new()
			lowpass.cutoff_hz = OPEN_CUTOFF
			AudioServer.add_bus_effect(index, lowpass)
			AudioServer.set_bus_effect_enabled(index, 0, false)
	var music = AudioServer.get_bus_index("Music")
	if AudioServer.get_bus_effect_count(music) == 1:
		# Distorção sensorial enquanto os controles estão invertidos (GDD: tato).
		var phaser = AudioEffectPhaser.new()
		phaser.rate_hz = 0.9
		phaser.depth = 0.8
		phaser.feedback = 0.5
		AudioServer.add_bus_effect(music, phaser)
		AudioServer.set_bus_effect_enabled(music, 1, false)
	var space = AudioServer.get_bus_index("Space")
	if AudioServer.get_bus_effect_count(space) == 0:
		var reverb = AudioEffectReverb.new()
		reverb.dry = 1.0
		reverb.wet = 0.06
		reverb.room_size = 0.35
		reverb.damping = 0.7
		reverb.predelay_msec = 10.0
		reverb.hipass = 0.1
		AudioServer.add_bus_effect(space, reverb)

func _bus(bus_name: String) -> int:
	return AudioServer.get_bus_index(bus_name)

func sfx_player() -> AudioStreamPlayer:
	return _pools["SFX"][0]

func ambience_player() -> AudioStreamPlayer:
	return _amb[0]

func _process(dt: float) -> void:
	clock += dt
	_step_fades(dt)
	_update_layers(dt)
	_update_mix(dt)
	_update_space(dt)
	_update_speech()

# ------------------------------------------------------------------ registro (testes headless)
func _log(entry: String) -> void:
	history.append(entry)
	if history.size() > 400:
		history = history.slice(history.size() - 300)

func heard(entry: String) -> bool:
	return history.has(entry)

func count(entry: String) -> int:
	return history.count(entry)

func clear_history() -> void:
	history.clear()

# ------------------------------------------------------------------ recursos
func _stream(file: String, loop: bool) -> AudioStream:
	if file.is_empty():
		return null
	var path = Cues.ROOT + file
	if _cache.has(path):
		return _cache[path]
	var stream: AudioStream = null
	if ResourceLoader.exists(path):
		stream = load(path) as AudioStream
	if stream == null:
		if not _missing.has(path):
			_missing[path] = true
			print("AUDIO: recurso ausente ", path)
	elif loop:
		var ogg = stream as AudioStreamOggVorbis
		if ogg != null:
			ogg.loop = true
		var wav = stream as AudioStreamWAV
		if wav != null:
			wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
			wav.loop_begin = 0
			wav.loop_end = int(round(wav.get_length() * wav.mix_rate))
	_cache[path] = stream
	return stream

func _variant(cue: String, data: Dictionary) -> AudioStream:
	if not _variants.has(cue):
		var options: Array = []
		for file in data["files"]:
			var stream = _stream(file, false)
			if stream != null:
				options.append(stream)
		_variants[cue] = options
	var list: Array = _variants[cue]
	if list.is_empty():
		return null
	var index = _rng.randi_range(0, list.size() - 1)
	if list.size() > 1 and index == int(_last_variant.get(cue, -1)):
		index = (index + 1) % list.size()
	_last_variant[cue] = index
	return list[index]

func _from_pool(bus: String) -> AudioStreamPlayer:
	var key = bus if _pools.has(bus) else "SFX"
	var pool: Array = _pools[key]
	for i in range(pool.size()):
		var index = (int(_pool_next[key]) + i) % pool.size()
		if not pool[index].playing:
			_pool_next[key] = (index + 1) % pool.size()
			return pool[index]
	var chosen = pool[int(_pool_next[key])]
	_pool_next[key] = (int(_pool_next[key]) + 1) % pool.size()
	return chosen

# ------------------------------------------------------------------ efeitos
func play(cue: String, at: Variant = null, volume_offset: float = 0.0, from_position: float = 0.0) -> void:
	if not Cues.CUES.has(cue):
		_log("missing:" + cue)
		return
	var data: Dictionary = Cues.CUES[cue]
	var gap = float(data.get("gap", 0.0))
	if gap > 0.0 and clock - float(_last_played.get(cue, -100.0)) < gap:
		return
	_last_played[cue] = clock
	_log("cue:" + cue)
	if not playback_enabled:
		return
	var stream = _variant(cue, data)
	if stream == null:
		return
	var bus = str(data.get("bus", "SFX"))
	var player
	if at is Vector2:
		player = _pos_pool[_pos_next]
		_pos_next = (_pos_next + 1) % _pos_pool.size()
		player.global_position = at
	else:
		player = _from_pool(bus)
	player.stop()
	player.bus = bus
	player.stream = stream
	player.volume_db = float(data.get("db", -8.0)) + volume_offset
	var spread = float(data.get("pitch", 0.0))
	player.pitch_scale = 1.0 + _rng.randf_range(-spread, spread)
	player.play(from_position)

## Aviso de ataque: o clímax do som coincide com o fim do aviso (golpe) e a trilha abaixa enquanto dura.
func telegraph(cue: String, duration: float, at: Variant = null, duck: float = -6.0) -> void:
	var data: Dictionary = Cues.CUES.get(cue, {})
	var climax = float(data.get("climax", 0.0))
	var start = maxf(0.0, climax - duration)
	_duck_amount = minf(_duck_amount if clock < _duck_until else 0.0, duck)
	_duck_until = maxf(_duck_until, clock + duration + 0.3)
	_log("telegraph:" + cue)
	play(cue, at, 0.0, start)

func footstep() -> void:
	play("passo_" + surface)

func land(impact: float) -> void:
	if impact < 380.0:
		return
	var loud = lerpf(-7.0, 0.0, clampf((impact - 380.0) / 600.0, 0.0, 1.0))
	play("aterrissagem_umida" if surface == "umido" else "aterrissagem", null, loud)

# ------------------------------------------------------------------ música e ambiente
func set_music(music_name: String, fade: float = 2.5) -> void:
	if music_name == current_music:
		return
	current_music = music_name
	_log("music:" + music_name)
	_fade(_decks[_deck], SILENT_DB, fade, true)
	_deck = 1 - _deck
	var deck = _decks[_deck]
	var layer = _layers[_deck]
	_fades.erase(deck)
	deck.stop()
	layer.stop()
	deck.stream = null
	layer.stream = null
	deck.volume_db = SILENT_DB
	layer.volume_db = SILENT_DB
	_deck_db[_deck] = SILENT_DB
	if not Cues.MUSIC.has(music_name):
		return
	var data: Dictionary = Cues.MUSIC[music_name]
	deck.stream = _stream(str(data["file"]), true)
	layer.stream = _stream(str(data.get("layer", "")), true)
	_deck_db[_deck] = float(data.get("db", -4.0))
	_layer_db[_deck] = float(data.get("layer_db", -3.0))
	if playback_enabled and deck.stream != null:
		deck.play()
		if layer.stream != null:
			layer.play()
	_fade(deck, _deck_db[_deck], fade)

func set_ambience(ambience_name: String, fade: float = 3.0) -> void:
	if ambience_name == current_ambience:
		return
	current_ambience = ambience_name
	_log("ambience:" + ambience_name)
	_fade(_amb[_amb_index], SILENT_DB, fade, true)
	_amb_index = 1 - _amb_index
	var p = _amb[_amb_index]
	_fades.erase(p)
	p.stop()
	p.stream = null
	p.volume_db = SILENT_DB
	if not Cues.AMBIENCE.has(ambience_name):
		return
	var data: Dictionary = Cues.AMBIENCE[ambience_name]
	p.stream = _stream(str(data["file"]), true)
	if playback_enabled and p.stream != null:
		p.play(_rng.randf() * p.stream.get_length())
	_fade(p, float(data.get("db", -3.0)), fade)

## Pedido de perigo (0..1). Sobe rápido; só desce depois de 3 s sem ameaça, para não oscilar.
func set_danger(level: float) -> void:
	_danger_request = clampf(level, 0.0, 1.0)
	if _danger_request >= danger_target:
		danger_target = _danger_request
		_danger_hold = 3.0

func set_focus(focus_name: String) -> void:
	if focus_name == focus:
		return
	focus = focus_name
	# O canto da oração não segue tocando com o jogo pausado.
	_prayer.stream_paused = focus_name == "pause"
	_log("focus:" + focus_name)

func set_sensory(is_inverted: bool, is_numb: bool) -> void:
	inverted = is_inverted
	numb = is_numb

static func zone_at(pos: Vector2) -> Dictionary:
	var index = 0
	for i in range(Level.REGIONS.size()):
		if pos.x >= float(Level.REGIONS[i]["start"]):
			index = i
	var base: Dictionary = Cues.REGION_AUDIO[index]
	var zone = {"music": base["music"], "ambience": base["ambience"], "surface": base["surface"], "space": base["space"], "region": index}
	if index == 3 and pos.y < 400.0:
		# Caminho alto das galerias: raízes secas acima da bacia úmida.
		zone["space"] = "raizes"
		zone["surface"] = "terra"
	elif index == 5 and pos.y >= 600.0:
		# Pisos baixos do vestíbulo: túnel úmido com goteiras.
		zone["space"] = "caverna"
		zone["surface"] = "umido"
		zone["ambience"] = "galerias"
	return zone

func update_position(pos: Vector2, on_branch: bool) -> void:
	var zone = zone_at(pos)
	surface = "madeira" if on_branch else str(zone["surface"])
	space_name = str(zone["space"])
	var music_name = str(zone["music"])
	var ambience_name = str(zone["ambience"])
	if _force_zone:
		_force_zone = false
		_pending_zone = ""
		set_music(music_name, 1.5)
		set_ambience(ambience_name, 1.5)
		return
	if music_name == current_music and ambience_name == current_ambience:
		_pending_zone = ""
		return
	var key = music_name + "|" + ambience_name
	if key != _pending_zone:
		_pending_zone = key
		_pending_since = clock
	elif clock - _pending_since >= ZONE_HOLD:
		_pending_zone = ""
		set_music(music_name, 3.5)
		set_ambience(ambience_name, 3.0)

func _reset_combat() -> void:
	danger = 0.0
	danger_target = 0.0
	_danger_request = 0.0
	_danger_hold = 0.0
	_duck_until = -1.0
	duck_db = 0.0
	inverted = false
	numb = false

func enter_menu() -> void:
	set_focus("")
	stop_speech()
	stop_prayer()
	_reset_combat()
	space_name = "floresta"
	set_music("menu", 2.0)
	set_ambience("", 1.5)

func enter_trail() -> void:
	set_focus("")
	stop_speech()
	stop_prayer()
	_reset_combat()
	_force_zone = true

func enter_arena() -> void:
	set_focus("")
	stop_speech()
	stop_prayer()
	_reset_combat()
	space_name = "ninho"
	surface = "terra"
	set_music("cordyceps", 1.2)
	set_ambience("ninho", 1.5)
	play("cordyceps_rugido")

func on_player_death() -> void:
	stop_prayer()
	set_focus("dead")
	play("druida_morte")
	set_music("", 2.0)

func boss_dying() -> void:
	set_music("", 1.4)
	play("chefe_colapso")

func boss_defeated() -> void:
	play("chefe_silencia")
	play("flor_surge")
	set_music("flor", 4.0)

# ------------------------------------------------------------------ oração no lótus
func prayer_start() -> void:
	play("lotus_plantar")
	_fades.erase(_prayer)
	_prayer.stop()
	_prayer.stream = _stream(str(Cues.LOOPS["lotus_oracao"]["file"]), true)
	_prayer.pitch_scale = 1.0
	_prayer.volume_db = -22.0
	prayer_pitch = 1.0
	_praying = true
	_log("prayer:start")
	if playback_enabled and _prayer.stream != null:
		_prayer.play()

func prayer_progress(progress: float) -> void:
	if not _praying:
		return
	var p = clampf(progress, 0.0, 1.0)
	prayer_pitch = 1.0 + 0.14 * p
	_prayer.pitch_scale = prayer_pitch
	_prayer.volume_db = lerpf(-22.0, -8.0, p)

func prayer_end(completed: bool) -> void:
	if not _praying:
		return
	_praying = false
	_fade(_prayer, SILENT_DB, 0.4 if completed else 0.12, true)
	_log("prayer:" + ("done" if completed else "cancel"))
	if not completed:
		play("lotus_interrompida")

func stop_prayer() -> void:
	_praying = false
	_fades.erase(_prayer)
	_prayer.stop()

# ------------------------------------------------------------------ sinais posicionais (memórias, lótus, moscas)
func make_emitter(parent: Node, loop_name: String, at: Vector2) -> AudioStreamPlayer2D:
	var data: Dictionary = Cues.LOOPS.get(loop_name, {})
	var emitter = AudioStreamPlayer2D.new()
	emitter.set_meta("mdtd_loop", loop_name)
	emitter.position = at
	emitter.bus = str(data.get("bus", "SFX"))
	emitter.volume_db = float(data.get("db", -12.0))
	emitter.max_distance = float(data.get("range", 700.0))
	emitter.attenuation = float(data.get("attenuation", 1.6))
	emitter.stream = _stream(str(data.get("file", "")), true)
	parent.add_child(emitter)
	_log("emitter:" + loop_name)
	if playback_enabled and emitter.stream != null and emitter.is_inside_tree():
		emitter.play(_rng.randf() * emitter.stream.get_length())
	return emitter

func remove_emitter(emitter) -> void:
	if is_instance_valid(emitter):
		emitter.stop()
		emitter.queue_free()

# ------------------------------------------------------------------ falas (voz da seiva / da flor)
func speak(voice_name: String, text: String, speech_seed: int) -> void:
	stop_speech()
	if not Cues.VOICES.has(voice_name):
		return
	var files: Array = Cues.VOICES[voice_name]["files"]
	var rng = RandomNumberGenerator.new()
	rng.seed = speech_seed
	var syllables = clampi(int(text.length() / 9.0), 6, 24)
	var at = clock + 0.3
	for i in range(syllables):
		var contour = 1.0 + 0.05 * sin(i * 0.9) - (0.07 if i >= syllables - 2 else 0.0)
		_speech.append({"t": at, "file": files[rng.randi_range(0, files.size() - 1)], "pitch": contour * rng.randf_range(0.95, 1.05)})
		at += rng.randf_range(0.095, 0.15) + (0.2 if rng.randf() < 0.12 else 0.0)
	_speech_voice = voice_name
	_log("speech:" + voice_name)

func stop_speech() -> void:
	_speech.clear()

func speaking() -> bool:
	return not _speech.is_empty()

func _update_speech() -> void:
	while not _speech.is_empty() and float(_speech[0]["t"]) <= clock:
		var syllable: Dictionary = _speech.pop_front()
		if not playback_enabled:
			continue
		var stream = _stream(str(syllable["file"]), false)
		if stream == null:
			continue
		var p = _voice[_voice_next]
		_voice_next = (_voice_next + 1) % _voice.size()
		p.stream = stream
		p.volume_db = float(Cues.VOICES[_speech_voice].get("db", -5.0))
		p.pitch_scale = float(syllable["pitch"])
		p.play()

# ------------------------------------------------------------------ interface
func connect_ui(root: Node) -> void:
	_ui_quiet_until = clock + 0.3
	for node in root.find_children("*", "BaseButton", true, false):
		var button = node as BaseButton
		if button != null:
			bind_button(button)

func bind_button(button: BaseButton) -> void:
	if button.has_meta("mdtd_audio"):
		return
	button.set_meta("mdtd_audio", true)
	# O foco inicial que a própria tela dá ao abrir não deve soar como navegação.
	_ui_quiet_until = clock + 0.15
	button.focus_entered.connect(_on_ui_focus)
	button.pressed.connect(_on_ui_pressed)

func _on_ui_focus() -> void:
	if clock >= _ui_quiet_until:
		play("ui_mover")

func _on_ui_pressed() -> void:
	play("ui_confirmar")

# ------------------------------------------------------------------ mixagem contínua
func _fade(p, target_db: float, seconds: float, stop_when_silent: bool = false) -> void:
	var target = db_to_linear(target_db) if target_db > SILENT_DB + 1.0 else 0.0
	_fades[p] = {"target": target, "rate": 1.0 / maxf(seconds, 0.01), "stop": stop_when_silent}

func _step_fades(dt: float) -> void:
	for p in _fades.keys():
		if not is_instance_valid(p):
			_fades.erase(p)
			continue
		var f: Dictionary = _fades[p]
		var target = float(f["target"])
		var value = move_toward(db_to_linear(p.volume_db), target, float(f["rate"]) * dt)
		p.volume_db = linear_to_db(value) if value > 0.0001 else SILENT_DB
		if absf(value - target) < 0.0001:
			if bool(f["stop"]) and target == 0.0:
				p.stop()
			_fades.erase(p)

func _update_layers(dt: float) -> void:
	_danger_hold = maxf(0.0, _danger_hold - dt)
	if _danger_hold <= 0.0:
		danger_target = _danger_request
	danger = move_toward(danger, danger_target, dt * (1.4 if danger_target > danger else 0.25))
	for i in range(2):
		var layer = _layers[i]
		if layer.stream == null:
			continue
		var deck = _decks[i]
		var base = db_to_linear(_deck_db[i]) if _deck_db[i] > SILENT_DB else 0.0
		var ratio = clampf(db_to_linear(deck.volume_db) / base, 0.0, 1.0) if base > 0.0 else 0.0
		var level = danger * ratio * db_to_linear(_layer_db[i])
		layer.volume_db = linear_to_db(level) if level > 0.0001 else SILENT_DB
		if layer.playing and not deck.playing:
			layer.stop()

func _update_mix(dt: float) -> void:
	var mix: Dictionary = FOCUS_MIX.get(focus, FOCUS_MIX[""])
	var goal = _duck_amount if clock < _duck_until else 0.0
	duck_db = move_toward(duck_db, goal, dt * (45.0 if goal < duck_db else 8.0))
	AudioServer.set_bus_volume_db(_bus("Music"), float(_base_db["Music"]) + float(mix["music"]) + duck_db)
	AudioServer.set_bus_volume_db(_bus("Ambience"), float(_base_db["Ambience"]) + float(mix["ambience"]) + duck_db * 0.6)
	_cutoff = lerpf(_cutoff, float(mix["cutoff"]), 1.0 - exp(-7.0 * dt))
	for bus_name in ["Music", "Ambience"]:
		var index = _bus(bus_name)
		var lowpass = AudioServer.get_bus_effect(index, 0) as AudioEffectLowPassFilter
		if lowpass != null:
			lowpass.cutoff_hz = _cutoff
		AudioServer.set_bus_effect_enabled(index, 0, _cutoff < 18000.0)
	AudioServer.set_bus_effect_enabled(_bus("Music"), 1, inverted)

func _update_space(dt: float) -> void:
	var target: Dictionary = Cues.SPACES.get(space_name, Cues.SPACES["floresta"])
	var reverb = AudioServer.get_bus_effect(_bus("Space"), 0) as AudioEffectReverb
	if reverb == null:
		return
	var k = 1.0 - exp(-1.6 * dt)
	reverb.room_size = lerpf(reverb.room_size, float(target["room"]), k)
	reverb.wet = lerpf(reverb.wet, float(target["wet"]), k)
	reverb.damping = lerpf(reverb.damping, float(target["damping"]), k)
	reverb.predelay_msec = lerpf(reverb.predelay_msec, float(target["predelay"]), k)

func stop_all() -> void:
	stop_speech()
	stop_prayer()
	for child in get_children():
		if child is AudioStreamPlayer or child is AudioStreamPlayer2D:
			child.stop()
			child.stream = null
