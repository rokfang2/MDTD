extends SceneTree

var world
var checks = 0
var failures = 0
var seen: Array[String] = []

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func check(value: bool, label: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",label)
	if not value:
		failures += 1

func arena(index: int, at_x: float = 400, phase: int = 1) -> void:
	for action in ["left","right","jump","dash","interact"]:
		Input.action_release(action)
	if is_instance_valid(world):
		world.queue_free()
		await frames(2)
	world = load("res://scripts/world.gd").new()
	world.mode = "arena"
	root.add_child(world)
	world.boss.active = false
	world.player.restore(Vector2(at_x,590))
	await frames(8)
	world.player.invulnerable = 0
	seen.clear()
	world.boss.attack.connect(func(kind,_target,_phase): seen.append(kind))
	world.boss.phase = phase
	world.boss.state = "recover"
	world.boss.pattern = posmod(index-1,4)
	world.boss.timer = 0.001
	world.boss.active = true
	await frames(2)
	check(world.boss.state == "tell" and world.boss.pattern == index,"natural AI announces pattern%d phase%d" % [index,phase])

func wait_for_attack() -> void:
	for i in range(100):
		if not seen.is_empty():
			return
		await frames(1)

func _run() -> void:
	var controller = load("res://scripts/main.gd").new()
	controller._setup_inputs()
	controller.free()
	await arena(0)
	Input.action_press("right")
	await frames(35)
	Input.action_release("right")
	await wait_for_attack()
	check(seen == ["roots"],"natural roots attack is emitted from its tell")
	# Disable only later boss patterns; leave the emitted hazards processing.
	world.boss.active = false
	await frames(60)
	check(world.player.hp == 5 and world.player.invulnerable <= 0,"walking away from announced roots avoids real damage without invulnerability")
	await arena(2)
	while world.boss.timer > 0.12:
		await frames(1)
	Input.action_press("jump")
	Input.action_press("right")
	await wait_for_attack()
	check(seen == ["invert"] and world.player.inverted == 0,"jump input avoids the naturally emitted inversion pulse")
	world.boss.active = false
	await frames(35)
	Input.action_release("jump")
	Input.action_release("right")
	await frames(45)
	check(world.player.hp == 5 and world.player.invulnerable <= 0,"airborne counterplay and lateral movement also avoid delayed pulse roots")
	await arena(3,800)
	await wait_for_attack()
	Input.action_press("right")
	Input.action_press("dash")
	await frames(1)
	Input.action_release("right")
	Input.action_release("dash")
	check(seen == ["charge"] and world.player.dash_time > 0,"natural mandibular charge is crossed with a real dash input")
	await frames(60)
	check(world.player.hp == 5 and world.player.invulnerable <= 0,"dash crosses charge without lingering artificial invulnerability")
	for start in [400.0,1250.0]:
		await arena(1,start,2)
		await wait_for_attack()
		check(seen == ["spores"] and world.shots.size() == 5,"natural phaseII spore fan emits five projectiles from side%.0f" % start)
		world.boss.active = false
		var direction = "right" if start < world.boss.position.x else "left"
		var dashed = false
		for i in range(220):
			var closest = INF
			for shot in world.shots:
				closest = minf(closest,shot.pos.distance_to(world.player.position+Vector2(0,-40)))
			if closest < 115:
				Input.action_press(direction)
				Input.action_press("dash")
				await frames(1)
				Input.action_release(direction)
				Input.action_release("dash")
				dashed = world.player.dash_time > 0
				break
			await frames(1)
		await frames(50)
		check(dashed and world.player.hp == 5 and world.player.numb == 0 and world.player.invulnerable <= 0,"dash counters natural phaseII spores on side%.0f without damage or numbness" % start)
	# Vulnerable player beside the collapse: no active-body contact damage.
	await arena(0,990)
	world.boss.receive_hit(180)
	world.player.hp = 2
	world.player.invulnerable = 0
	await frames(150)
	check(world.player.hp == 2 and not world.reward_ready and world.boss.state == "dying","vulnerable player beside collapse takes no contact damage and reward waits beyond2.5s")
	await frames(12)
	check(world.reward_ready and world.boss.state == "defeated" and world.boss.sprite.visible,"reward releases after2.6s with visible grounded corpse")
	var completed = [0]
	world.reward_claimed.connect(func(): completed[0] += 1)
	for side in [-1,1]:
		world.reward_ready = true
		world.player.restore(world.reward_position+Vector2(side*40,0))
		await frames(8)
		world.player.invulnerable = 0
		var at = world.player.position
		Input.action_press("interact")
		await frames(2)
		Input.action_release("interact")
		check(world.praying and world.player.position == at and world.player.facing == -side,"reward prayer starts in place facing altar from side%d" % side)
		await frames(90)
		check(completed[0] == (1 if side == -1 else 2) and not world.praying and world.boss.sprite.visible,"reward prayer completes from side%d while corpse remains visible" % side)
	world.queue_free()
	await frames(2)
	print("RESULT: ",checks-failures,"/",checks," natural boss counterplay and corpse safety checks passed")
	quit(0 if failures == 0 else 1)
