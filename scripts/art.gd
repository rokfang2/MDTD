extends RefCounted

const SHEET = preload("res://assets/actors_v2.png")

static func slice(rect: Rect2) -> AtlasTexture:
	var texture = AtlasTexture.new()
	texture.atlas = SHEET
	texture.region = rect
	texture.filter_clip = true
	return texture
