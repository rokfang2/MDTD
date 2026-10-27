extends RefCounted

const SHEET = preload("res://assets/style_a_atlas.png")
# Recortes reais da prancha; não presumir que a geração obedeceu células iguais.
const REGIONS = [
	Rect2i(79,40,232,184),Rect2i(416,40,236,184),Rect2i(769,40,237,184),Rect2i(1117,40,242,184),
	Rect2i(80,264,231,203),Rect2i(433,290,181,178),Rect2i(757,253,252,224),Rect2i(1164,280,115,178),
	Rect2i(85,499,196,172),Rect2i(441,499,184,172),Rect2i(790,499,189,172),Rect2i(1145,499,191,172),
	Rect2i(84,694,206,173),Rect2i(428,694,220,173),Rect2i(774,694,222,173),Rect2i(1129,694,206,173),
	Rect2i(42,872,281,236),Rect2i(374,884,338,218),Rect2i(729,950,375,149),Rect2i(1140,895,214,206)
]
static var textures: Dictionary = {}
static var palette: Array[Color] = []

static func simplify(image: Image) -> void:
	# Poucas faixas de sombra compartilhadas entre chão, personagens e chefe.
	if palette.is_empty():
		for hex in ["100f29","21124c","30126b","481c8e","5a1cba","7025df","8536f4","081d31","10273a","2b1424","462031","66302b","88402c","a9552f","c47640","e49a51","8a360b","c35a08","eb880a","ffb82b","ffe16a","173c25","1e5826","257e21","45a61c","79c91c","a9e326","d5f34d","093e58","087b99","02bbd7","31e5f3","befaff","996044","cb9663","f4c58a","ffe4b2","fff4d9","383b50","5a6172","7f879b","a8b4c8","d8e4e8","4e176a","8b238e","d630c9","ff78e7"]:
			palette.append(Color(hex))
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var source = image.get_pixel(x,y)
			if source.a < 0.5:
				image.set_pixel(x,y,Color.TRANSPARENT)
				continue
			var nearest = palette[0]
			var distance = INF
			for candidate in palette:
				var delta = Vector3(source.r-candidate.r,source.g-candidate.g,source.b-candidate.b).length_squared()
				if delta < distance:
					distance = delta
					nearest = candidate
			image.set_pixel(x,y,nearest)

static func pixels(index: int) -> Image:
	var image = SHEET.get_image().get_region(REGIONS[index])
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color = image.get_pixel(x,y)
			color.a = 1.0 if color.a >= 0.5 else 0.0
			image.set_pixel(x,y,color)
	return image

static func texture(index: int) -> Texture2D:
	if not textures.has(index):
		textures[index] = ImageTexture.create_from_image(pixels(index))
	return textures[index]
