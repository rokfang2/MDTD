extends Node2D

const Level = preload("res://scripts/level_data.gd")
const Atlas = preload("res://scripts/style_atlas.gd")
const EnvironmentArt = preload("res://scripts/style_environment.gd")
var mode = "trail"
var root_art: Texture2D
var branch_art: Texture2D
var branch_variants: Dictionary = {}
var branch_sources: Array[Image] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	var platforms = preload("res://assets/style_a_terrain_candidate_v4.png").get_image()
	var pixels = platforms.get_region(Rect2i(74,938,988,132))
	pixels.resize(128,16,Image.INTERPOLATE_NEAREST)
	Atlas.simplify(pixels)
	root_art = ImageTexture.create_from_image(pixels)
	# Each source is a finished silhouette, not a seamless tile. Preserve its
	# ends and root tips instead of cutting rectangular repeat regions from it.
	for region in [Rect2i(74,134,444,157), Rect2i(74,343,856,154), Rect2i(74,559,1084,125), Rect2i(34,755,1387,117)]:
		branch_sources.append(platforms.get_region(region))
	branch_art = _branch_texture(400)
	var soil = preload("res://scripts/soil_layer.gd").new()
	soil.mode = mode
	soil.z_index = -1
	add_child(soil)
	var background = Sprite2D.new()
	background.texture = EnvironmentArt.background_world()
	background.centered = false
	background.scale = Vector2.ONE*4
	background.region_enabled = true
	background.region_rect = Rect2(0,0,(Level.WIDTH if mode == "trail" else 1280)/4.0,240)
	background.texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	background.z_index = -2
	add_child(background)

func _draw() -> void:
	if root_art == null:
		return
	var ground: Array[Rect2] = []
	if mode == "trail":
		ground = Level.ground()
	else:
		ground.append(Rect2(-50,590,1380,260))
	var joined: Array[Rect2] = []
	for rect in ground:
		if not joined.is_empty() and is_equal_approx(joined.back().end.x,rect.position.x) and is_equal_approx(joined.back().position.y,rect.position.y):
			var previous: Rect2 = joined.pop_back()
			joined.append(Rect2(previous.position,Vector2(previous.size.x+rect.size.x,maxf(previous.size.y,rect.size.y))))
		else:
			joined.append(rect)
	for rect in joined:
		_draw_root(rect,16)
	if mode == "trail":
		for rect in _joined_branches():
			_draw_branch(rect)

func _joined_branches() -> Array[Rect2]:
	# Drawing only: Level remains the sole owner of collision geometry.
	# The gallery's overlapping supports form one continuous organic surface.
	var joined: Array[Rect2] = []
	for rect in Level.branches():
		var combined = rect
		var i = 0
		while i < joined.size():
			var previous = joined[i]
			if is_equal_approx(previous.position.y,combined.position.y) and previous.end.x >= combined.position.x and combined.end.x >= previous.position.x:
				var left = minf(previous.position.x,combined.position.x)
				var right = maxf(previous.end.x,combined.end.x)
				combined = Rect2(left,combined.position.y,right-left,maxf(previous.size.y,combined.size.y))
				joined.remove_at(i)
				i = 0
			else:
				i += 1
		joined.append(combined)
	return joined

func _branch_texture(width: float) -> Texture2D:
	var native_width = ceili(width/4.0)
	if not branch_variants.has(native_width):
		var source_index = 0 if width <= 260 else (1 if width <= 480 else 2)
		# The canopy's710px route uses the broader, less densely rooted piece;
		# compressing the long fringe here made its hanging roots look finer.
		if width > 720:
			source_index = 3
		var pixels = branch_sources[source_index].duplicate()
		pixels.resize(native_width,16,Image.INTERPOLATE_NEAREST)
		Atlas.simplify(pixels)
		# One transparent row protects the full tip even at the texture boundary.
		var padded = Image.create(native_width,17,false,Image.FORMAT_RGBA8)
		padded.blit_rect(pixels,Rect2i(0,0,native_width,16),Vector2i.ZERO)
		branch_variants[native_width] = ImageTexture.create_from_image(padded)
	return branch_variants[native_width]

func _draw_branch(rect: Rect2) -> void:
	# Wider routes have authored wider silhouettes with more root motifs.
	# Preserve the whole artwork, with no source slicing or overlapping ends.
	var texture = _branch_texture(rect.size.x)
	var x = rect.position.x + floorf((rect.size.x-texture.get_width()*4)/2)
	# Row1 is the solid moss surface; row0 contains decorative tufts. Align
	# that surface to the collider so its highlight no longer floats above it.
	draw_texture_rect(texture,Rect2(Vector2(x,rect.position.y-4),texture.get_size()*4),false)
	draw_rect(Rect2(rect.position+Vector2(4,0),Vector2(rect.size.x-8,4)),Color("79c91c"))

func _draw_root(rect: Rect2, native_depth: int) -> void:
	# Sem deformação UV ou escala fracionária: cada texel ocupa 4x4.
	# O topo desenhado começa exatamente na superfície de colisão.
	# Keep one world-aligned phase across steps, with mirrored authored ends.
	# Every source row remains visible; no horizontal cut through root tips.
	# At native15/35 the source's dangling roots have already ended; native8
	# would bisect the first root. Keep the entire end motif on each side.
	var cap_width = 60.0
	var center = Rect2(rect.position+Vector2(cap_width,-4),Vector2(rect.size.x-cap_width*2,native_depth*4))
	draw_texture_rect_region(root_art,center,Rect2((rect.position.x+cap_width)/4.0,0,center.size.x/4.0,native_depth),Color.WHITE,false,false)
	# The strip has no natural side endings. Borrow the complete outer ends
	# of the matching authored short platform, retaining every source row.
	var caps = _branch_texture(200)
	draw_texture_rect_region(caps,Rect2(rect.position+Vector2(0,-4),Vector2(cap_width,68)),Rect2(0,0,15,17))
	draw_texture_rect_region(caps,Rect2(Vector2(rect.end.x-cap_width,rect.position.y-4),Vector2(cap_width,68)),Rect2(35,0,15,17))
	draw_rect(Rect2(rect.position+Vector2(4,0),Vector2(rect.size.x-8,4)),Color("79c91c"))
