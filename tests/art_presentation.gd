extends SceneTree

var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, message: String) -> void:
	print("PASS: " if value else "FAIL: ", message)
	if not value:
		failures += 1

func _run() -> void:
	# This scene never creates main.gd or writes player progress.
	var terrain = load("res://scripts/terrain.gd").new()
	root.add_child(terrain)
	await process_frame
	var texture = terrain.get("branch_art") as Texture2D
	check(texture != null, "suspended platforms have their own complete silhouette asset")
	if texture != null:
		var pixels = texture.get_image()
		var transparent = 0
		var opaque = 0
		for x in range(pixels.get_width()):
			if pixels.get_pixel(x,pixels.get_height()-1).a < 0.5:
				transparent += 1
			for y in range(pixels.get_height()):
				if pixels.get_pixel(x,y).a >= 0.5:
					opaque += 1
		check(transparent == pixels.get_width(), "root tips finish before the asset boundary with transparent padding")
		check(opaque > pixels.get_width()*3, "complete platform artwork retains a connected visible body")
	terrain.queue_free()
	await process_frame
	quit(0 if failures == 0 else 1)
