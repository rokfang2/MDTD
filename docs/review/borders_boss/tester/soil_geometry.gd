extends SceneTree

var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func polygon_area(points: PackedVector2Array) -> float:
	var twice = 0.0
	for i in range(points.size()):
		twice += points[i].cross(points[(i+1)%points.size()])
	return absf(twice)*0.5

func _run() -> void:
	var path = "res://scripts/soil_layer.gd"
	var source = FileAccess.get_file_as_string(path)
	var context = HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(source.to_utf8_buffer())
	print("SOURCE_SHA256: ",context.finish().hex_encode())
	# Instrument only an in-memory copy. Preserve the exact production chain
	# assembly/cleanup; replace rendering endpoints with geometry recording.
	var polygon_call = "draw_polygon(points,PackedColorArray([Color.WHITE]),uv,texture)"
	var outline_call = "draw_polyline(wall,Color(\"100f29\"),4,false)"
	if not source.contains(polygon_call) or not source.contains(outline_call):
		check(false,"known render endpoints available for exact geometry instrumentation")
		quit(1)
		return
	source = source.replace("var texture: Texture2D","var texture: Texture2D\nvar captured: Array = []")
	source = source.replace(polygon_call,"captured.append({\"points\":points,\"uv\":uv,\"walls\":walls})")
	source = source.replace(outline_call,"pass")
	var script = GDScript.new()
	script.source_code = source
	check(script.reload() == OK,"in-memory instrumented soil compiles")
	if failures:
		quit(1)
		return
	var soil = script.new()
	for mode in ["trail","arena"]:
		soil.mode = mode
		soil.captured.clear()
		soil._draw()
		check(not soil.captured.is_empty(),"actual draw pipeline emits chains for "+mode)
		for i in range(soil.captured.size()):
			var data = soil.captured[i]
			var points: PackedVector2Array = data.points
			var triangles = Geometry2D.triangulate_polygon(points)
			check(not triangles.is_empty(),"triangulation succeeds %s chain%d" % [mode,i])
			var orthogonal = true
			var uv_aligned = data.uv.size() == points.size()
			for j in range(points.size()):
				var delta = points[(j+1)%points.size()]-points[j]
				orthogonal = orthogonal and delta.length() > 0 and (is_zero_approx(delta.x) or is_zero_approx(delta.y))
				uv_aligned = uv_aligned and data.uv[j].is_equal_approx((points[j]-Vector2(0,400))/Vector2(1024,512))
			check(orthogonal and uv_aligned,"steps have nonzero orthogonal edges and continuous world UV %s chain%d" % [mode,i])
			var covered = 0.0
			for j in range(0,triangles.size(),3):
				covered += absf((points[triangles[j+1]]-points[triangles[j]]).cross(points[triangles[j+2]]-points[triangles[j]]))*0.5
			check(absf(covered-polygon_area(points)) < 0.5,"triangles exactly cover authored soil area %s chain%d" % [mode,i])
			var inset_valid = true
			for wall in data.walls:
				var edge = wall[0].x
				for point in wall:
					inset_valid = inset_valid and absf(point.x-edge) <= 12 and point.y >= minf(wall[0].y,wall[-1].y) and point.y <= maxf(wall[0].y,wall[-1].y)
			check(inset_valid,"cliff profile stays within12px and endpoint heights %s chain%d" % [mode,i])
	soil.free()
	print("RESULT: ",checks-failures,"/",checks," exact soil geometry checks passed")
	quit(0 if failures == 0 else 1)
