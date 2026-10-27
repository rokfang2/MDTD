extends SceneTree

# Medir membros no raster exibido: punhos isolados e pernas na banda inferior.
var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func limb(image: Image, area: Rect2i, near: bool) -> Vector3:
	var total = Vector2.ZERO
	var count = 0
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var c = image.get_pixel(x,y)
			var selected = c.a > 0.5 and c.g > c.r*1.15 and c.g > c.b*1.5
			selected = selected and (c.g > 0.68 and c.r > 0.35 and c.b < 0.2 if near else c.g > 0.22 and c.g < 0.65 and c.r < 0.35)
			if selected:
				total += Vector2(x,y)
				count += 1
	return Vector3(total.x/maxi(count,1),total.y/maxi(count,1),count)

func _run() -> void:
	var art = load("res://scripts/pixel_art.gd")
	var a = art.motion("run",0).get_image()
	var b = art.motion("run",6).get_image()
	var leg_area = Rect2i(30,29,34,7)
	var an = limb(a,leg_area,true)
	var af = limb(a,leg_area,false)
	var bn = limb(b,leg_area,true)
	var bf = limb(b,leg_area,false)
	check(an.z >= 4 and af.z >= 4 and bn.z >= 4 and bf.z >= 4,"dois apoios têm duas pernas com tons distintos")
	check(an.x > af.x + 6,"apoio0: perna próxima clara lidera")
	check(bf.x > bn.x + 6,"apoio6: perna distante escura lidera")
	# Contato0 foi deslocado um pixel para assentar a sola na linha36.
	var ah = limb(a,Rect2i(40,26,7,4),true)
	var bh = limb(b,Rect2i(53,23,6,3),true)
	var ad = limb(a,Rect2i(56,23,6,5),false)
	var bd = limb(b,Rect2i(42,25,6,3),false)
	check(ah.z >= 3 and bh.z >= 3 and ad.z >= 3 and bd.z >= 3,"punhos dos dois braços são visíveis nos apoios")
	check(ah.x < ad.x - 8 and bh.x > bd.x + 6,"braços invertem a ordem entre apoios0/6")
	check(ah.x < an.x and bh.x > bn.x,"braço próximo alterna em oposição à perna próxima")
	check(art.motion_count("run") == 12,"corrida usa doze fases na engine")
	check(limb(a,Rect2i(34,31,10,5),true).z == 0 and limb(a,Rect2i(52,32,8,4),true).z >= 5,"apoio0 assenta pé claro à frente e pé escuro atrás")
	check(limb(b,Rect2i(34,31,10,5),true).z >= 5 and limb(b,Rect2i(52,31,8,5),true).z == 0,"apoio6 troca o pé claro para trás e pé escuro para frente")
	var passing_dark = art.motion("run",3).get_image()
	var passing_light = art.motion("run",9).get_image()
	check(limb(passing_dark,Rect2i(51,25,7,6),false).z >= 3 and limb(passing_dark,Rect2i(51,25,7,6),true).z == 0 and limb(passing_light,Rect2i(48,25,7,6),true).z >= 5,"passagens3/9 alternam também o joelho levantado")
	print("RESULT: ",checks-failures,"/",checks," gait checks passed")
	quit(0 if failures == 0 else 1)
