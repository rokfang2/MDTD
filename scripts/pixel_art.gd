extends RefCounted

# Estilo A: desenhos novos em grade baixa, ampliados por fator inteiro.
const SCALE = 4.0
const Atlas = preload("res://scripts/style_atlas.gd")
static var cache: Dictionary = {}
static var baselines: Dictionary = {}
static var hero_palette: Array[Color] = []

# Atlas de movimento tem canvas e origem comuns; nunca recortar cada pose
# pelo alpha, pois pés suspensos e espada mudam o retângulo usado.
const MOTION_NAMES = ["attack", "dash", "rise", "fall", "land", "idle", "hurt", "crouch", "pray"]
# arquivo, colunas, primeiro quadro, quantidade. Nenhum clip recorta pelo alpha.
const MOTION_CLIPS = {
	"run": ["res://assets/run_native_v4.png",4,0,12],
	"attack": ["res://assets/attack_native_v5.png",3,0,6],
	"dash": ["res://assets/actions_native_v3.png",4,0,3],
	"rise": ["res://assets/actions_native_v3.png",4,3,3],
	"fall": ["res://assets/actions_native_v3.png",4,6,2],
	"land": ["res://assets/actions_native_v3.png",4,8,3],
	"idle": ["res://assets/idle_native_v3.png",4,0,4],
	"hurt": ["res://assets/actions_native_v3.png",4,11,2],
	"crouch": ["res://assets/actions_native_v3.png",4,13,2],
	"pray": ["res://assets/prayer_native_v3.png",4,0,4]
}

static func motion_count(name: String) -> int:
	assert(MOTION_CLIPS.has(name), "Clip desconhecido: " + name)
	return MOTION_CLIPS[name][3]

static func motion(name: String, frame: int = 0) -> Texture2D:
	# Compatibilidade com ferramentas de captura das fases anteriores.
	if name == "attack_windup":
		name = "attack"
		frame = 0
	elif name == "attack_active":
		name = "attack"
		frame = 1 if motion_count(name) == 3 else 2
	elif name == "attack_recover":
		name = "attack"
		frame = motion_count(name) - 1
	var clip = MOTION_CLIPS[name]
	frame = posmod(frame, motion_count(name))
	var index: int = clip[2] + frame
	var columns: int = clip[1]
	var key = "motion_%s_%d" % [name,frame]
	if cache.has(key):
		return cache[key]
	var sheet = load(clip[0]) as Texture2D
	# Canvas96x40, pivô(48,36): a margem extra acomoda a raiz sem
	# redimensionar o corpo e mantém o espelhamento centrado no mesmo apoio.
	var pixels = sheet.get_image().get_region(Rect2i((index % columns) * 96, (index / columns) * 40, 96, 40))
	_clean_alpha(pixels)
	var texture = _remember(key, pixels, true)
	baselines[texture.get_instance_id()] = 36
	return texture

static func actor(index: int) -> Texture2D:
	if cache.has(index):
		return cache[index]
	var mapping = [0,1,2,3,4,2,8,6]
	var pixels = Atlas.pixels(mapping[index])
	if index < 6:
		# A mesma escala do desenho mantém cabeça/membros entre as poses.
		pixels.resize(roundi(pixels.get_width()*0.14),roundi(pixels.get_height()*0.14),Image.INTERPOLATE_NEAREST)
	else:
		var width = 32 if index == 7 else 36
		pixels.resize(width,roundi(pixels.get_height()*float(width)/pixels.get_width()),Image.INTERPOLATE_NEAREST)
	_clean_alpha(pixels)
	return _remember(index,pixels)

static func guardian(striking: bool = false) -> Texture2D:
	var key = "boss_strike" if striking else "boss_idle"
	if cache.has(key):
		return cache[key]
	var pixels = Atlas.pixels(17 if striking else 16)
	# Mesma escala entre poses: a investida abre a silhueta sem encolher o corpo.
	pixels.resize(roundi(pixels.get_width()*80.0/281.0),roundi(pixels.get_height()*80.0/281.0),Image.INTERPOLATE_NEAREST)
	_clean_alpha(pixels)
	return _remember(key,pixels)

static func guardian_death(frame: int) -> Texture2D:
	frame = clampi(frame,0,5)
	var key = "boss_death_%d" % frame
	if cache.has(key):
		return cache[key]
	var sheet = preload("res://assets/cordyceps_death_sheet_v1.png").get_image()
	# One fifth scale for every pose, never fit the changing silhouette.
	var upper = frame < 3
	var region = Rect2i(32+(frame%3)*512,133 if upper else 620,480,450 if upper else 400)
	var pixels = sheet.get_region(region)
	pixels.resize(96,90 if upper else 80,Image.INTERPOLATE_NEAREST)
	_clean_alpha(pixels)
	var canvas = Image.create(112,96,false,Image.FORMAT_RGBA8)
	canvas.blit_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),Vector2i(8,0 if upper else 23))
	var texture = _remember(key,canvas)
	baselines[texture.get_instance_id()] = 88
	return texture

static func insect(flying: bool = false, frame: int = 0, spitter: bool = false) -> Texture2D:
	frame = posmod(frame,4)
	var key = "insect_%s_%d_%s" % [flying,frame,spitter]
	if cache.has(key):
		return cache[key]
	var pixels = Atlas.pixels((12 if flying else 8)+frame)
	var ratio = minf(36.0/pixels.get_width(),32.0/pixels.get_height())
	pixels.resize(roundi(pixels.get_width()*ratio),roundi(pixels.get_height()*ratio),Image.INTERPOLATE_NEAREST)
	_clean_alpha(pixels)
	if spitter:
		for y in range(mini(12,pixels.get_height())):
			for x in range(pixels.get_width()):
				var color = pixels.get_pixel(x,y)
				if color.a > 0.5 and color.r > 0.5 and color.g > 0.18 and color.b < 0.4:
					pixels.set_pixel(x,y,Color("ff78e7") if color.g > 0.65 else Color("d630c9"))
	var canvas = Image.create(36,32,false,Image.FORMAT_RGBA8)
	canvas.blit_rect(pixels,Rect2i(Vector2i.ZERO,pixels.get_size()),Vector2i((36-pixels.get_width())/2,32-pixels.get_height()))
	return _remember(key,canvas)

static func prayer(frame: int = 0) -> Texture2D:
	return motion("pray",frame)

static func _remember(key, pixels: Image, hero: bool = false) -> Texture2D:
	if hero:
		_simplify_hero(pixels)
	else:
		Atlas.simplify(pixels)
	var texture = ImageTexture.create_from_image(pixels)
	cache[key] = texture
	baselines[texture.get_instance_id()] = pixels.get_used_rect().end.y
	return texture

static func _simplify_hero(pixels: Image) -> void:
	if hero_palette.is_empty():
		# Inicializar a paleta compartilhada sem quantizar antes a casca original.
		Atlas.simplify(Image.create(1,1,false,Image.FORMAT_RGBA8))
		hero_palette.assign(Atlas.palette)
		for hex in ["35271f","594334","79604a","a18b69","c4b08a"]:
			hero_palette.append(Color(hex))
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			var source = pixels.get_pixel(x,y)
			if source.a < 0.5:
				pixels.set_pixel(x,y,Color.TRANSPARENT)
				continue
			var nearest = hero_palette[0]
			var distance = INF
			for candidate in hero_palette:
				var delta = Vector3(source.r-candidate.r,source.g-candidate.g,source.b-candidate.b).length_squared()
				if delta < distance:
					distance = delta
					nearest = candidate
			pixels.set_pixel(x,y,nearest)

static func _clean_alpha(pixels: Image) -> void:
	for y in range(pixels.get_height()):
		for x in range(pixels.get_width()):
			var color = pixels.get_pixel(x,y)
			color.a = 1.0 if color.a >= 0.5 else 0.0
			pixels.set_pixel(x,y,color)

static func foot(texture: Texture2D) -> float:
	return float(baselines.get(texture.get_instance_id(),texture.get_height()))

static func offset_y(texture: Texture2D) -> float:
	return (texture.get_height()*0.5-foot(texture))*SCALE

static func floor_rect(texture: Texture2D, at: Vector2) -> Rect2:
	return Rect2(at+Vector2(-texture.get_width()*SCALE*0.5,-foot(texture)*SCALE),texture.get_size()*SCALE)
