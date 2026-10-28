extends Node2D

signal start_requested
signal continue_requested
signal controls_requested
signal exit_requested

@onready var menu_buttons: VBoxContainer = $UI/HBoxContainer/MarginContainer/Menu/VBoxContainer
@onready var continue_button: Button = $UI/HBoxContainer/MarginContainer/Menu/VBoxContainer/Continue
@onready var settings_panel: PanelContainer = $UI/HBoxContainer/Menu_Options
@onready var credits_panel: PanelContainer = $UI/HBoxContainer/CreditsPanel
@onready var volume_slider: HSlider = $UI/HBoxContainer/Menu_Options/VBoxContainer/Volume_Row/HSlider
@onready var fullscreen_button: CheckButton = $UI/HBoxContainer/Menu_Options/VBoxContainer/Screen_Row/FullscreenButton
@onready var background: Sprite2D = $Parallax2D/Sprite2D
@onready var parallax: Parallax2D = $Parallax2D
var has_save = false

func _ready() -> void:
	menu_buttons.get_node("Start").pressed.connect(func(): start_requested.emit())
	continue_button.pressed.connect(func(): continue_requested.emit())
	menu_buttons.get_node("Credits").pressed.connect(show_credits)
	menu_buttons.get_node("Footer/Help").pressed.connect(func(): controls_requested.emit())
	menu_buttons.get_node("Footer/Exit").pressed.connect(func(): exit_requested.emit())
	credits_panel.get_node("CloseCredits").pressed.connect(close_panels)
	volume_slider.set_value_no_signal(db_to_linear(AudioServer.get_bus_volume_db(0))*100.0)
	volume_slider.value_changed.connect(_set_master_volume)
	if DisplayServer.get_name() != "headless":
		fullscreen_button.set_pressed_no_signal(DisplayServer.window_get_mode() in [DisplayServer.WINDOW_MODE_FULLSCREEN,DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN])
	fullscreen_button.toggled.connect(_set_fullscreen)
	get_viewport().size_changed.connect(_fit_background)
	_fit_background()
	configure_save(has_save)

func configure_save(available: bool) -> void:
	has_save = available
	if not is_instance_valid(continue_button):
		return
	continue_button.visible = has_save
	menu_buttons.add_theme_constant_override("separation",36 if has_save else 58)
	if has_save:
		continue_button.grab_focus()
	else:
		menu_buttons.get_node("Start").grab_focus()

func _fit_background() -> void:
	var view = get_viewport_rect().size
	var source = background.texture.get_size()
	var factor = maxf(view.x/source.x,view.y/source.y)
	var tile = source*factor
	# Preserve the original horizontally mirrored artwork. Repetition uses
	# its exact rendered width; uniform cover avoids the old bottom gap.
	background.scale = Vector2(-factor,factor)
	background.position = Vector2(tile.x,(view.y-tile.y)*0.5)
	parallax.repeat_size = Vector2(tile.x,0)
	parallax.repeat_times = 2
	parallax.autoscroll = Vector2(-20,0)

func show_settings() -> void:
	var opening = not settings_panel.visible
	close_panels()
	settings_panel.visible = opening
	if opening:
		volume_slider.grab_focus()

func show_credits() -> void:
	var opening = not credits_panel.visible
	close_panels()
	credits_panel.visible = opening
	if opening:
		credits_panel.get_node("CloseCredits").grab_focus()

func close_panels() -> void:
	settings_panel.hide()
	credits_panel.hide()

func _set_master_volume(value: float) -> void:
	AudioServer.set_bus_volume_db(0,-80.0 if value<=0 else linear_to_db(value/100.0))

func _set_fullscreen(enabled: bool) -> void:
	# Headless QA can exercise the control without a desktop/window backend.
	if DisplayServer.get_name() == "headless":
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if enabled else DisplayServer.WINDOW_MODE_WINDOWED)

func _on_settings_pressed() -> void:
	show_settings()

func _on_x_pressed() -> void:
	close_panels()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and (settings_panel.visible or credits_panel.visible):
		close_panels()
		menu_buttons.get_node("Settings").grab_focus()
		get_viewport().set_input_as_handled()
