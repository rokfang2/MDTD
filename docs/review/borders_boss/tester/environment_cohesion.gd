extends SceneTree

# Properties of actual runtime raster textures; aesthetic review is separate.
const Level = preload("res://scripts/level_data.gd")
const Atlas = preload("res://scripts/style_atlas.gd")
const EnvironmentArt = preload("res://scripts/style_environment.gd")
var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func palette_valid(image: Image) -> bool:
	var allowed: Dictionary = {}
	for color in Atlas.palette:
		allowed[color.to_rgba32()] = true
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			var color = image.get_pixel(x,y)
			if color.a > 0.0 and not allowed.has(color.to_rgba32()):
				return false
	return true

func fully_opaque(image: Image) -> bool:
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a < 1.0:
				return false
	return true

func main_component_fraction(image: Image) -> float:
	var opaque: Dictionary = {}
	for y in range(image.get_height()):
		for x in range(image.get_width()):
			if image.get_pixel(x,y).a >= 0.5:
				opaque[Vector2i(x,y)] = true
	var total = opaque.size()
	var largest = 0
	while not opaque.is_empty():
		var queue: Array[Vector2i] = [opaque.keys()[0]]
		opaque.erase(queue[0])
		var cursor = 0
		while cursor < queue.size():
			var point = queue[cursor]
			cursor += 1
			for delta in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
				var neighbor = point+delta
				if opaque.has(neighbor):
					opaque.erase(neighbor)
					queue.append(neighbor)
		largest = maxi(largest,queue.size())
	return float(largest)/total if total else 0.0

func _run() -> void:
	var terrain = load("res://scripts/terrain.gd").new()
	root.add_child(terrain)
	await process_frame
	var widths: Dictionary = {161.0:true,170.0:true,190.0:true,400.0:true,1000.0:true}
	for branch in Level.branches():
		widths[branch.size.x] = true
	var ids: Dictionary = {}
	for width in widths:
		var texture = terrain._branch_texture(width)
		var image = texture.get_image()
		ids[width] = texture.get_instance_id()
		check(image.get_size() == Vector2i(ceili(width/4.0),17),"platform%d retains nearest4x canvas and padding" % width)
		var top_columns = 0
		for x in range(image.get_width()):
			for y in range(5):
				if image.get_pixel(x,y).a >= 0.5:
					top_columns += 1
					break
		check(top_columns >= image.get_width()*0.8 and main_component_fraction(image) >= 0.9,"platform%d has broad supported top and connected body" % width)
		var padding = true
		for x in range(image.get_width()):
			padding = padding and image.get_pixel(x,16).a == 0
		check(padding and image.get_pixel(0,15).a == 0 and image.get_pixel(image.get_width()-1,15).a == 0,"platform%d retains transparent tip/bottom margins" % width)
		check(palette_valid(image),"platform%d uses the shared opaque47-color palette" % width)
	var stable = true
	for repeat in range(60):
		for width in widths:
			stable = stable and terrain._branch_texture(width).get_instance_id() == ids[width]
	check(stable,"all platform widths reuse stable texture instances")
	var environment = load("res://scripts/style_environment.gd")
	var menu = environment.background()
	check(menu.get_size() == Vector2(320,180) and menu == environment.background(),"menu texture retains320x180 and caching")
	check(environment.has_method("background_world"),"environment offers lower-camera world background")
	if environment.has_method("background_world"):
		var world_background = environment.background_world()
		check(world_background.get_size() == Vector2(320,240) and world_background == environment.background_world(),"world texture covers240native rows and is cached")
		check(fully_opaque(world_background.get_image()),"world background is fully opaque without a lower-alpha cut")
		var covers = false
		var below_soil = false
		var soil
		for child in terrain.get_children():
			if child.get_script() == load("res://scripts/soil_layer.gd"):
				soil = child
		for child in terrain.get_children():
			if child is Sprite2D and child.texture == world_background:
				var height = child.region_rect.size.y*child.scale.y
				covers = child.position.y <= 0 and child.position.y+height >= 840 and child.texture_repeat == CanvasItem.TEXTURE_REPEAT_MIRROR
				below_soil = soil != null and child.z_index < soil.z_index
		check(covers and below_soil,"background covers lower viewport through840world and stays behind soil")
		check(soil != null and soil.texture.get_size() == Vector2(256,128) and fully_opaque(soil.texture.get_image()) and palette_valid(soil.texture.get_image()),"soil uses opaque256x128 shared-palette texture")
	check(terrain.root_art.get_size() == Vector2(128,16) and palette_valid(terrain.root_art.get_image()),"ground moss strip retains128x16 native palette")
	terrain.queue_free()
	await process_frame
	print("RESULT: ",checks-failures,"/",checks," environment cohesion structural checks passed")
	quit(0 if failures == 0 else 1)
