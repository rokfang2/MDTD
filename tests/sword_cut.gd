extends SceneTree

# Verificar rigidez/silhueta no raster ativo; a leitura do gesto exige revisão visual.
var checks = 0
var failures = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func thickness(image: Image, x: int) -> int:
	var count = 0
	for y in range(18,25):
		if image.get_pixel(x,y).a > 0.5:
			count += 1
	return count

func wood_pixels(image: Image, area: Rect2i) -> int:
	var count = 0
	for y in range(area.position.y,area.end.y):
		for x in range(area.position.x,area.end.x):
			var c = image.get_pixel(x,y)
			if c.a > 0.5 and c.r < 0.75 and c.r > c.g*1.05 and c.g > c.b*1.05:
				count += 1
	return count

func _run() -> void:
	var art = load("res://scripts/pixel_art.gd")
	var early = art.motion("attack",2).get_image()
	var late = art.motion("attack",3).get_image()
	# Uma lâmina que gira muda de projeção. O retorno deve atravessar o
	# torso para a esquerda, em vez de só recuar a estocada à direita.
	check(wood_pixels(late,Rect2i(13,18,19,8)) >= 8,"follow-through leva a lâmina para a esquerda atravessando o torso")
	var broad = true
	for x in range(68,81):
		broad = broad and thickness(early,x) >= 4
	check(broad,"lâmina tem superfície larga contínua no meio em vez de cipó fino")
	check(thickness(early,87) >= 1 and thickness(early,87) < thickness(early,76),"lâmina termina em ponta mais fina que o corpo")
	check(early.get_used_rect().end.x == 88,"ponta completa alcança160px no instante ativo sem ultrapassar o canvas")
	check(early.get_region(Rect2i(43,17,19,12)).get_data() != late.get_region(Rect2i(43,17,19,12)).get_data(),"ombro e tronco mudam entre corte e follow-through")
	var bodies: Dictionary = {}
	for i in range(art.motion_count("attack")):
		bodies[hash(art.motion("attack",i).get_image().get_region(Rect2i(28,8,34,28)).get_data())] = true
	check(bodies.size() == 6,"seis fases possuem gestos corporais distintos além da arma")
	check(art.motion("attack",5).get_image().get_region(Rect2i(64,0,32,40)).get_used_rect().size == Vector2i.ZERO,"recuperação termina sem lâmina empunhada")
	print("RESULT: ",checks-failures,"/",checks," sword cut checks passed")
	quit(0 if failures == 0 else 1)
