extends SceneTree

var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1

func _run() -> void:
	var art = load("res://scripts/pixel_art.gd")
	if not art.has_method("motion_count"):
		check(false, "renderer oferece clips de vários quadros por estado")
		quit(1)
		return
	var minimum = {"run":12, "idle":4, "attack":6, "dash":3, "rise":3, "fall":2, "land":3, "hurt":2, "crouch":2, "pray":4}
	for state in minimum:
		var distinct: Dictionary = {}
		var anchored = true
		for frame in range(art.motion_count(state)):
			var texture = art.motion(state, frame)
			distinct[hash(texture.get_image().get_data())] = true
			anchored = anchored and texture.get_size() == Vector2(96,40) and art.foot(texture) == 36
		check(distinct.size() >= minimum[state], "%s possui pelo menos%d poses distintas" % [state, minimum[state]])
		check(anchored, "%s preserva canvas/pivô sem redimensionar por pose" % state)
	var prayer = art.prayer().get_image()
	var prayer_stable = true
	for frame in range(1,art.motion_count("pray")):
		var next = art.prayer(frame).get_image()
		for area in [Rect2i(48,18,48,22),Rect2i(0,32,96,8)]:
			prayer_stable = prayer_stable and prayer.get_region(area).get_data() == next.get_region(area).get_data()
	check(prayer_stable, "respiração da oração mantém mãos raiz joelho alto e pés imóveis")
	print("RESULT: ", checks - failures, "/", checks, " full motion clip checks passed")
	quit(0 if failures == 0 else 1)
