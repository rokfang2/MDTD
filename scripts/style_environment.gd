extends RefCounted

const Atlas = preload("res://scripts/style_atlas.gd")
static var forest: Texture2D
static var world_forest: Texture2D

static func background() -> Texture2D:
	if forest == null:
		# The menu remains a 320x180 crop at integer4x, not a compressed
		# version of the deeper world background.
		var crop = AtlasTexture.new()
		crop.atlas = background_world()
		crop.region = Rect2(0,0,320,180)
		forest = crop
	return forest

static func background_world() -> Texture2D:
	if world_forest == null:
		var pixels = preload("res://assets/style_a_forest_candidate_v5.png").get_image()
		pixels.resize(320,240,Image.INTERPOLATE_NEAREST)
		Atlas.simplify(pixels)
		world_forest = ImageTexture.create_from_image(pixels)
	return world_forest
