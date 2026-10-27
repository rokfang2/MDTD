extends SceneTree

var checks = 0
var failures = 0
var world

func _initialize() -> void:
	_run.call_deferred()

func frames(count: int) -> void:
	for i in range(count):
		await physics_frame
		await process_frame

func check(value: bool, message: String) -> void:
	checks += 1
	print("PASS: " if value else "FAIL: ",message)
	if not value:
		failures += 1

func arena() -> void:
	if is_instance_valid(world):
		world.queue_free()
		await frames(2)
	world = load("res://scripts/world.gd").new()
	world.mode = "arena"
	root.add_child(world)
	await frames(5)
	world.player.invulnerable = 100

func _run() -> void:
	var controller = load("res://scripts/main.gd").new()
	controller._setup_inputs()
	controller.free()
	var art = load("res://scripts/pixel_art.gd")
	var pose_ids: Dictionary = {}
	for frame in range(6):
		var texture = art.guardian_death(frame)
		pose_ids[texture.get_instance_id()] = true
		check(texture.get_size() == Vector2(112,96) and art.foot(texture) == 88 and texture.get_image().get_used_rect().size.x > 60,"death pose has visible body and shared grounded canvas "+str(frame))
	check(pose_ids.size() == 6,"all six authored collapse poses are retained in the renderer")
	await arena()
	var boss = world.boss
	var completed = [0]
	boss.defeated.connect(func(): completed[0] += 1)
	world.shots.append({"pos":Vector2(400,550),"vel":Vector2.ZERO,"life":10.0,"radius":12.0})
	world.hazards.append({"x":400.0,"delay":2.0,"life":1.0,"width":85.0,"hit":false})
	boss.receive_hit(180)
	await frames(2)
	check(boss.state == "dying" and not boss.active,"lethal hit begins a non-attacking collapse state")
	check(boss.sprite.visible,"boss remains visible after lethal damage")
	check(not world.reward_ready and completed[0] == 0,"reward waits for the collapse instead of appearing on lethal hit")
	check(world.shots.is_empty() and world.hazards.is_empty(),"lethal hit clears existing hazards immediately")
	var at = boss.position
	await frames(25)
	world.process_mode = Node.PROCESS_MODE_DISABLED
	var paused_texture = boss.sprite.texture
	await frames(25)
	check(boss.sprite.texture == paused_texture and not world.reward_ready,"pause freezes the collapse and reward timing")
	world.process_mode = Node.PROCESS_MODE_INHERIT
	await frames(155)
	check(boss.state == "defeated" and world.reward_ready,"collapse completion releases the reward")
	check(absf(world.reward_position.x-boss.position.x) >= 220,"lotus reward appears beside the corpse without hiding it")
	check(boss.sprite.visible and boss.sprite.texture != null,"a visible corpse remains after reward release")
	check(boss.position == at,"collapse and corpse stay anchored to the death location")
	boss.receive_hit(180)
	await frames(15)
	check(completed[0] == 1,"death completion is emitted exactly once")
	# Aimed volley must originate on the face toward the player, on both sides.
	for side in [-1,1]:
		await arena()
		boss = world.boss
		boss.active = false
		boss.target = Vector2(boss.position.x+side*250,590)
		world._boss_attack("spores",boss.target,2)
		check(world.shots.size() == 5,"phase II volley retains five spores")
		var front = true
		for shot in world.shots:
			front = front and (shot.pos.x-boss.position.x)*side > 0 and shot.vel.x*side > 0
		check(front,"spore fan originates and travels toward announced side "+str(side))
	# Inversion has counterplay: airborne and invulnerable dash cross the pulse.
	await arena()
	boss = world.boss
	boss.active = false
	world.player.invulnerable = 0
	world.player.restore(Vector2(400,590))
	await frames(5)
	world.player.invulnerable = 0
	world._boss_attack("invert",world.player.position,1)
	check(world.player.inverted > 0,"grounded player receives the inversion pulse")
	world.player.inverted = 0
	world.hazards.clear()
	Input.action_press("jump")
	await frames(8)
	Input.action_release("jump")
	world._boss_attack("invert",world.player.position,1)
	check(world.player.inverted == 0,"jumping over the pulse avoids inversion")
	world.hazards.clear()
	world.player.restore(Vector2(400,590))
	await frames(5)
	world.player.dash_cooldown = 0
	world.player.try_dash()
	world._boss_attack("invert",world.player.position,1)
	check(world.player.inverted == 0,"invulnerable dash avoids inversion pulse")
	# Phase shift announces escalation and cancels the old attack timeline.
	await arena()
	boss = world.boss
	boss.state = "tell"
	boss.timer = 0.15
	world.hazards.append({"x":400.0,"delay":0.1,"life":1.0,"width":85.0,"hit":false})
	boss.receive_hit(96)
	check(boss.phase == 2 and boss.state == "phase_shift","half health enters a dedicated readable phase shift")
	check(world.hazards.is_empty(),"phase shift cancels hazards from the previous timeline")
	await frames(35)
	check(boss.state == "phase_shift","phase transition gives a visible breathing window")
	await frames(45)
	check(boss.state in ["recover","tell"],"boss resumes announced attacks after phase transition")
	boss.position.x = 550
	boss.state = "recover"
	boss.timer = 1.0
	await frames(20)
	check(is_equal_approx(boss.position.x,550),"recovery stays exposed instead of sliding backwards to spawn")
	world.queue_free()
	await frames(2)
	print("RESULT: ",checks-failures,"/",checks," boss encounter checks passed")
	quit(0 if failures == 0 else 1)
