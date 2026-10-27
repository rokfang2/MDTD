extends SceneTree

# Source-project deployment check. Run after import, independently of save/Main.
var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func _run() -> void:
	var art = load("res://scripts/pixel_art.gd")
	var paths: Dictionary = {}
	for clip in art.MOTION_CLIPS.values():
		paths[clip[0]] = true
	var ready: Dictionary = {}
	for path in paths:
		var sidecar = ConfigFile.new()
		var has_sidecar = sidecar.load(path+".import") == OK
		check(has_sidecar,"import metadata exists: "+path)
		var destination = str(sidecar.get_value("remap","path","")) if has_sidecar else ""
		check(not destination.is_empty() and FileAccess.file_exists(destination),"imported texture file exists: "+path)
		var texture = load(path) as Texture2D if ResourceLoader.exists(path) else null
		ready[path] = texture != null and texture.get_image() != null
		check(ready[path],"engine loads texture/image: "+path)
	for state in art.MOTION_CLIPS:
		for index in range(art.motion_count(state)):
			if not ready[art.MOTION_CLIPS[state][0]]:
				check(false,"visible nonempty frame: %s/%d" % [state,index])
				continue
			var texture = art.motion(state,index)
			var image = texture.get_image() if texture != null else null
			var opaque = 0
			if image != null:
				for y in range(image.get_height()):
					for x in range(image.get_width()):
						if image.get_pixel(x,y).a > 0.5:
							opaque += 1
			check(image != null and image.get_size() == Vector2i(96,40) and opaque >= 40,"visible nonempty frame: %s/%d (opaque=%d)" % [state,index,opaque])
	print("RESULT: ",checks-failures,"/",checks," imported resource visibility checks passed")
	quit(0 if failures == 0 else 1)
