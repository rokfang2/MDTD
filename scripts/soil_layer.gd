extends Node2D
const Level = preload("res://scripts/level_data.gd")
const Atlas = preload("res://scripts/style_atlas.gd")
var mode = "trail"
var texture: Texture2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Reflection joins the authored roots without cutting them at tile edges.
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	var image = preload("res://assets/style_a_soil_candidate_v4.png").get_image()
	image.resize(256,128,Image.INTERPOLATE_NEAREST)
	Atlas.simplify(image)
	texture = ImageTexture.create_from_image(image)

func _draw() -> void:
	var ground: Array[Rect2] = []
	if mode == "trail":
		ground = Level.ground()
	else:
		ground.append(Rect2(-50,590,1380,260))
	var chain: Array[Rect2] = []
	for rect in ground:
		if not chain.is_empty() and not is_equal_approx(chain.back().end.x,rect.position.x):
			_draw_chain(chain)
			chain.clear()
		chain.append(rect)
	if not chain.is_empty():
		_draw_chain(chain)

func _draw_chain(chain: Array[Rect2]) -> void:
	var points = PackedVector2Array()
	var walls: Array[PackedVector2Array] = []
	points.append(chain.front().position)
	for i in range(chain.size()):
		var rect = chain[i]
		var corner = Vector2(rect.end.x,rect.position.y)
		points.append(corner)
		if i+1 < chain.size() and not is_equal_approx(rect.position.y,chain[i+1].position.y):
			var next = Vector2(rect.end.x,chain[i+1].position.y)
			var inward = -1 if next.y > corner.y else 1
			var wall = _cliff_profile(corner,next,inward)
			points.append_array(wall.slice(1))
			walls.append(wall)
	var right_wall = _cliff_profile(Vector2(chain.back().end.x,chain.back().position.y),Vector2(chain.back().end.x,850),-1)
	points.append_array(right_wall.slice(1))
	walls.append(right_wall)
	points.append(Vector2(chain.front().position.x,850))
	var left_wall = _cliff_profile(Vector2(chain.front().position.x,850),chain.front().position,1)
	points.append_array(left_wall.slice(1))
	walls.append(left_wall)
	var cleaned = PackedVector2Array()
	for point in points:
		if cleaned.is_empty() or not cleaned[-1].is_equal_approx(point):
			cleaned.append(point)
	if cleaned[0].is_equal_approx(cleaned[-1]):
		cleaned.resize(cleaned.size()-1)
	points = cleaned
	var uv = PackedVector2Array()
	for point in points:
		# Keep the visible depth420..850 inside one vertical tile. A repeat
		# boundary immediately under the grass would resemble a pasted strip.
		uv.append((point-Vector2(0,400))/Vector2(1024,512))
	draw_polygon(points,PackedColorArray([Color.WHITE]),uv,texture)
	for wall in walls:
		# A dark, stepped rim finishes roots against the air instead of letting
		# the interior texture stop on an unoutlined rectangular crop.
		draw_polyline(wall,Color("100f29"),4,false)

func _cliff_profile(from: Vector2, to: Vector2, inward: int) -> PackedVector2Array:
	var points = PackedVector2Array([from])
	var distance = absf(to.y-from.y)
	if distance <= 16:
		return PackedVector2Array([from,to])
	var direction = signf(to.y-from.y)
	var previous_y = from.y+direction*8
	points.append(Vector2(from.x,previous_y))
	var pattern = [1,2,1,3,2,1,2,3]
	var count = floori((distance-8)/16.0)
	for i in range(1,count+1):
		var y = from.y+direction*i*16
		var inset = pattern[posmod(i+floori(from.x/16),pattern.size())]*4
		var x = from.x+inset*inward
		points.append(Vector2(x,previous_y))
		points.append(Vector2(x,y))
		previous_y = y
	points.append(Vector2(points[-1].x,to.y-direction*8))
	points.append(Vector2(to.x,to.y-direction*8))
	points.append(to)
	return points
