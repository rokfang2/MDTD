extends SceneTree

# Geometria usada pelo desenho real; não cria Main, mundo nem progresso.
var failures = 0
var checks = 0

func _initialize() -> void:
	_run.call_deferred()

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ", label)
	if not value:
		failures += 1

func bounds(cells: Array) -> Rect2:
	var result: Rect2 = cells[0]
	for cell in cells:
		result = result.merge(cell)
	return result

func bark_color(image: Image, roi: Rect2i) -> Vector3:
	var sum = Vector3.ZERO
	var count = 0
	for y in range(roi.position.y,roi.end.y):
		for x in range(roi.position.x,roi.end.x):
			var color = image.get_pixel(x,y)
			if color.a > 0.5:
				sum += Vector3(color.r,color.g,color.b)
				count += 1
	return sum / count if count > 0 else Vector3.ONE

func reach_checks() -> void:
	# Chamar o receptor real do dano em objetos fora da árvore. Não iniciar
	# Main/_ready do mundo: nenhum save, inimigo ou IA pode interferir.
	var world = load("res://scripts/world.gd").new()
	var guardian = load("res://scripts/boss.gd").new()
	world.boss = guardian
	var origin = Vector2(400, 550)
	for direction in [1.0, -1.0]:
		for distance in [80.0, 165.9, 166.0, 166.1, 0.0, -80.0]:
			var enemy = {"x": origin.x + distance * direction, "y": origin.y + 28, "hp": 24, "flash": 0.0, "state": "patrol", "timer": 1.0}
			world.enemies = [enemy]
			guardian.active = false
			world._on_slash(origin, direction)
			var expected = 12 if distance > 0 and distance < 166 else 24
			check(enemy.hp == expected, "dano comum12 respeita frente/limite166: distância%s direção%s" % [distance, direction])
		world.enemies.clear()
		for distance in [80.0, 235.9, 236.0, 236.1, 0.0, -80.0]:
			guardian.position = origin + Vector2(distance * direction, 70)
			guardian.hp = 180
			guardian.active = true
			world._on_slash(origin, direction)
			var expected = 168 if distance > 0 and distance < 236 else 180
			check(guardian.hp == expected, "dano chefe12 respeita frente/limite236: distância%s direção%s" % [distance, direction])
	guardian.free()
	world.free()

func _run() -> void:
	var player = load("res://scripts/player.gd").new()
	if not player.has_method("attack_trail_cells"):
		check(false, "golpe oferece a geometria horizontal usada pelo desenho")
		player.free()
		quit(1)
		return
	player.attack_time = 0.18
	player.attack_pending = false
	player.attack_facing = 1
	var right = player.attack_trail_cells()
	check(not right.is_empty(), "trilha aparece durante a fase ativa")
	if not right.is_empty():
		var area = bounds(right)
		check(area.size.x >= area.size.y * 3 and area.position.y >= -72 and area.end.y <= -48, "golpe horizontal acompanha a banda real da lâmina de madeira")
		check(area.position.x >= 0 and area.end.x == 160 and area.size.y <= 32, "trilha acompanha a ponta160 sem atingir atrás nem crescer na vertical")
		var aligned = true
		for cell in right:
			aligned = aligned and cell.size == Vector2(4, 4) and cell.position == cell.position.snapped(Vector2(4, 4))
		check(aligned, "trilha usa somente células na grade de pixels A")
		player.attack_facing = -1
		var left = player.attack_trail_cells()
		var mirrored = left.size() == right.size()
		for i in range(mini(left.size(), right.size())):
			mirrored = mirrored and left[i] == Rect2(Vector2(-right[i].end.x, right[i].position.y), right[i].size)
		check(mirrored and bounds(left).end.x <= 0, "virar à esquerda espelha cada célula sem mudar altura ou atacar atrás")
	player.attack_pending = true
	check(player.attack_trail_cells().is_empty(), "preparo não exibe golpe antes da emissão de dano")
	player.attack_pending = false
	player.attack_time = 0.07
	check(player.attack_trail_cells().is_empty(), "retração não mantém trilha ativa")
	player.attack_time = 0
	check(player.attack_trail_cells().is_empty(), "repouso não mantém efeito do ataque")
	player.free()
	var art = load("res://scripts/pixel_art.gd")
	art.Atlas.simplify(Image.create(1,1,false,Image.FORMAT_RGBA8))
	var palette_before = art.Atlas.palette.duplicate()
	var wood_roi = Rect2i(65,18,23,7)
	var color = bark_color(art.motion("attack",2).get_image(),wood_roi)
	# Medir só a casca, sem confundir cinza neutro legítimo com metal.
	check(color.x < 0.65 and color.x-color.z < 0.25, "cor média da casca ativa permanece escura e neutra sem dominante dourada")
	# Comparar a fonte do clip ativo, e não um arquivo histórico aprovado.
	var clip = art.MOTION_CLIPS["attack"]
	var index: int = clip[2] + 2
	var source = load(clip[0]).get_image().get_region(Rect2i((index % clip[1])*96,(index / clip[1])*40,96,40))
	check(color.distance_to(bark_color(source,wood_roi)) < 0.12, "paleta hero preserva a cor da casca gerada em vez de convertê-la para bronze")
	check(art.Atlas.palette == palette_before, "paleta local de madeira não modifica a paleta de cenário e inimigos")
	reach_checks()
	print("RESULT: ", checks - failures, "/", checks, " motion wood checks passed")
	quit(0 if failures == 0 else 1)
