extends SceneTree

var checks = 0
var failures = 0
var game
var original_volume = 0.0
var original_mute = false
var original_mode = DisplayServer.WINDOW_MODE_WINDOWED
var had_save = false
var save_before = ""

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

func button(node: Node, names: Array) -> BaseButton:
	for name in names:
		var found = node.find_child(name,true,false)
		if found is BaseButton:
			return found
	return null

func text_button(node: Node, text: String) -> BaseButton:
	for child in node.find_children("*","BaseButton",true,false):
		if child is Button and child.text == text:
			return child
	return null

func click(target: BaseButton, label: String) -> void:
	check(target != null,"button available: "+label)
	if target != null:
		target.pressed.emit()
	await frames(3)

func _run() -> void:
	if not OS.get_user_data_dir().ends_with("MushroomsStationaryPrayerQA"):
		print("FAIL: isolated namespace required for menu integration")
		quit(1)
		return
	original_volume = AudioServer.get_bus_volume_db(0)
	original_mute = AudioServer.is_bus_mute(0)
	original_mode = DisplayServer.window_get_mode()
	had_save = FileAccess.file_exists("user://progress.json")
	if had_save:
		save_before = FileAccess.get_file_as_string("user://progress.json")
	var configured = load("res://Scenes/main_menu.tscn").instantiate()
	configured.configure_save(true)
	root.add_child(configured)
	await frames(2)
	check(configured.continue_button.visible,"configure_save before entering the tree preserves a usable Continue button")
	configured.queue_free()
	await frames(2)
	game = load("res://Scenes/main.tscn").instantiate()
	game.persist_progress = false
	root.add_child(game)
	await frames(3)
	check(game.state == "menu" and game.get("menu_scene") != null,"Main opens the restored original menu scene")
	if game.get("menu_scene") == null:
		await finish()
		return
	game.save_data.clear()
	game.show_menu()
	await frames(3)
	var menu = game.menu_scene
	var continue_button = button(menu,["Continue"])
	check(continue_button != null and (continue_button.disabled or not continue_button.visible),"continue is unavailable without a checkpoint")
	check(menu.scene_file_path == "res://Scenes/main_menu.tscn","actual original scene is instantiated instead of a second generated menu")
	var start = button(menu,["Start"])
	check(start != null and start.get_theme_font("font").resource_path == "res://Fonts/MedievalSharp-Regular.ttf","original menu font is loaded through imported project resources")
	var parallax = menu.get_node_or_null("Parallax2D")
	var sprite = menu.get_node_or_null("Parallax2D/Sprite2D")
	check(parallax != null and sprite != null and sprite.texture.resource_path == "res://Textures/MainMenu_BG_Seamless.png","menu uses the original seamless artwork")
	if parallax != null and sprite != null:
		var rect = sprite.get_rect()
		var top = minf(sprite.position.y+rect.position.y*sprite.scale.y,sprite.position.y+rect.end.y*sprite.scale.y)
		var bottom = maxf(sprite.position.y+rect.position.y*sprite.scale.y,sprite.position.y+rect.end.y*sprite.scale.y)
		var span = absf(rect.size.x*sprite.scale.x)
		check(top <= 0.01 and bottom >= 719.99,"original backdrop covers full720px viewport without a lower cut")
		check(parallax.repeat_size.x >= 1280 and span+0.01 >= parallax.repeat_size.x,"horizontal repeat period and art span cover the viewport without a seam gap")
		var at = parallax.scroll_offset
		var clock_before = game.clock
		await frames(30)
		var delta = game.clock-clock_before
		var moved = parallax.scroll_offset-at
		check(absf(absf(moved.x)-absf(parallax.autoscroll.x*delta)) < 2 and absf(moved.x) > 1,"parallax movement follows elapsed delta instead of frame count")
	# Settings/Credits are exercised below after selecting their real buttons.
	await click(button(menu,["Settings"]),"Settings")
	var options = menu.get_node_or_null("UI/HBoxContainer/Menu_Options")
	check(options != null and options.visible,"settings button opens original options panel")
	var slider = menu.find_child("HSlider",true,false)
	check(slider is HSlider,"master volume slider is available")
	if slider is HSlider:
		slider.value = 37
		await frames(2)
		check(absf(db_to_linear(AudioServer.get_bus_volume_db(0))-0.37) < 0.015,"volume slider changes the actual Master audio bus")
		slider.value = 0
		await frames(2)
		check(AudioServer.is_bus_mute(0) or AudioServer.get_bus_volume_db(0) <= -60,"zero volume produces silence")
		slider.value = 63
		await frames(2)
		check(not AudioServer.is_bus_mute(0) and absf(db_to_linear(AudioServer.get_bus_volume_db(0))-0.63) < 0.015,"raising the slider restores audible Master gain")
	var fullscreen = button(options,["FullscreenButton"])
	check(fullscreen is CheckButton and not fullscreen.get_signal_connection_list("toggled").is_empty(),"fullscreen checkbox is connected to its setting handler")
	if fullscreen is CheckButton:
		var was_pressed = fullscreen.button_pressed
		fullscreen.button_pressed = not was_pressed
		await frames(2)
		check(fullscreen.button_pressed != was_pressed,"fullscreen setting responds to its toggle signal")
		if DisplayServer.get_name() == "headless":
			check(DisplayServer.window_get_mode() == original_mode,"headless settings safely avoid changing a desktop window")
		else:
			check(DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN] if fullscreen.button_pressed else DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_WINDOWED,"fullscreen setting changes the actual helper window mode")
		fullscreen.button_pressed = was_pressed
		await frames(2)
		check(DisplayServer.window_get_mode() == original_mode,"fullscreen test restores the original helper window mode")
	await click(button(options,["X"]),"close settings")
	check(not options.visible,"settings close button hides the panel")
	await click(button(menu,["Credits"]),"Credits")
	var credits = menu.find_child("CreditsPanel",true,false)
	check(credits != null and credits.visible,"credits button opens a real credits panel")
	if credits != null:
		var close = button(credits,["CloseCredits","Close","X","CreditsClose"])
		await click(close,"close credits")
		check(not credits.visible,"credits close button returns to the original menu")
	await click(button(menu,["Controls","Help","HowToPlay"]),"controls")
	check(game.state == "controls" and game.menu_scene == null and not is_instance_valid(menu),"help removes original menu and its CanvasLayer before controls screen")
	await click(text_button(game.ui,"Voltar"),"return from controls")
	check(game.state == "menu" and game.menu_scene != null,"return from help reconstructs original menu")
	menu = game.menu_scene
	await click(button(menu,["Start"]),"Start")
	check(game.state == "playing" and game.world != null and game.checkpoint == Vector2(130,490),"Start enters playable trail at the initial checkpoint")
	check(game.menu_scene == null and not is_instance_valid(menu),"starting gameplay removes original menu CanvasLayer and parallax")
	Input.action_press("pause")
	await frames(2)
	Input.action_release("pause")
	check(game.state == "paused" and game.world.process_mode == Node.PROCESS_MODE_DISABLED,"pause still freezes the playable world")
	await click(text_button(game.ui,"Menu"),"pause to menu")
	check(game.state == "menu" and game.world == null and game.menu_scene != null,"pause menu returns to the original menu without a lingering world")
	game.save_data = {"version":1,"checkpoint":[5310.0,506.0],"memories":["roots"],"flower":true}
	game.show_menu()
	await frames(3)
	menu = game.menu_scene
	continue_button = button(menu,["Continue"])
	check(continue_button != null and not continue_button.disabled and continue_button.visible,"continue is enabled for an existing checkpoint")
	await click(continue_button,"Continue")
	check(game.state == "playing" and absf(game.world.player.position.x-5310) < 2 and game.world.memories == ["roots"] and game.world.flower,"Continue restores checkpoint memories and earned flower")
	check(game.menu_scene == null and not is_instance_valid(menu),"Continue also disposes menu UI and scrolling background")
	var playing_world = game.world
	game.show_pause()
	await click(text_button(game.ui,"Retomar"),"Resume")
	check(game.state == "playing" and game.world == playing_world and game.world.process_mode == Node.PROCESS_MODE_INHERIT,"Resume preserves the same playable world")
	await finish()

func finish() -> void:
	AudioServer.set_bus_volume_db(0,original_volume)
	AudioServer.set_bus_mute(0,original_mute)
	if DisplayServer.get_name() != "headless":
		DisplayServer.window_set_mode(original_mode)
	check(FileAccess.file_exists("user://progress.json") == had_save and (not had_save or FileAccess.get_file_as_string("user://progress.json") == save_before),"menu tests preserve isolated progress file byte for byte")
	if is_instance_valid(game):
		game.ambience.stop()
		game.ambience.stream = null
		game.queue_free()
	await frames(3)
	print("RESULT: ",checks-failures,"/",checks," original menu integration checks passed")
	quit(0 if failures == 0 else 1)
