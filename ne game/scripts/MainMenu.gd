extends Control

# Main menu buttons
@onready var start_button: Button = $MainContainer/MenuPanel/VBoxContainer/StartButton
@onready var big_map_button: Button = $MainContainer/MenuPanel/VBoxContainer/BigMapButton
@onready var target_practice_button: Button = $MainContainer/MenuPanel/VBoxContainer/TargetPracticeButton
@onready var wave_survival_button: Button = $MainContainer/MenuPanel/VBoxContainer/WaveSurvivalButton
@onready var options_button: Button = $MainContainer/MenuPanel/VBoxContainer/OptionsButton
@onready var credits_button: Button = $MainContainer/MenuPanel/VBoxContainer/CreditsButton
@onready var quit_button: Button = $MainContainer/MenuPanel/VBoxContainer/QuitButton

# UI elements
@onready var title_label: Label = $MainContainer/TitleContainer/TitleLabel
@onready var main_container: VBoxContainer = $MainContainer
@onready var particle_system: CPUParticles2D = $ParticleSystem

# Settings menu
@onready var settings_menu: Control = $SettingsMenu
@onready var settings_panel: Panel = $SettingsMenu/SettingsPanel
@onready var credits_menu: Control = $CreditsMenu
@onready var credits_panel: Panel = $CreditsMenu/CreditsPanel

# Game settings
var master_volume: float = 1.0
var sfx_volume: float = 1.0
var mouse_sensitivity: float = 0.5
var fullscreen: bool = false
var vsync: bool = true

func _ready():
	# Load saved settings
	load_settings()
	
	# Connect button signals
	start_button.pressed.connect(_on_start_pressed)
	big_map_button.pressed.connect(_on_big_map_pressed)
	target_practice_button.pressed.connect(_on_target_practice_pressed)
	wave_survival_button.pressed.connect(_on_wave_survival_pressed)
	options_button.pressed.connect(_on_options_pressed)
	credits_button.pressed.connect(_on_credits_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	
	# Focus the start button
	start_button.grab_focus()
	
	# Start animations
	animate_title()
	animate_menu_entrance()
	
	# Start particle effects
	particle_system.emitting = true
	
	# Create settings menu content
	create_settings_menu()
	create_credits_menu()

func animate_title():
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(title_label, "modulate", Color(1, 1, 0.9), 3.0)
	tween.tween_property(title_label, "modulate", Color(0.9, 0.9, 1), 3.0)

func animate_menu_entrance():
	# Start with panels invisible and scaled down
	main_container.modulate.a = 0.0
	main_container.scale = Vector2(0.8, 0.8)
	
	# Animate entrance
	var tween = create_tween()
	tween.parallel().tween_property(main_container, "modulate:a", 1.0, 1.0)
	tween.parallel().tween_property(main_container, "scale", Vector2(1.0, 1.0), 1.0)
	tween.tween_property(main_container, "position", main_container.position, 0.5)

func _on_start_pressed():
	animate_button_press(start_button)
	await get_tree().create_timer(0.3).timeout
	
	Global.selected_game_mode = 0  # Standard
	transition_to_scene("res://scenes/Main.tscn")

func _on_big_map_pressed():
	animate_button_press(big_map_button)
	await get_tree().create_timer(0.3).timeout
	
	Global.selected_game_mode = 0  # Standard
	transition_to_scene("res://scenes/BigMap.tscn")

func _on_target_practice_pressed():
	animate_button_press(target_practice_button)
	await get_tree().create_timer(0.3).timeout
	
	Global.selected_game_mode = 1  # Target Practice
	transition_to_scene("res://scenes/Main.tscn")

func _on_wave_survival_pressed():
	animate_button_press(wave_survival_button)
	await get_tree().create_timer(0.3).timeout
	
	Global.selected_game_mode = 2  # Wave Survival
	transition_to_scene("res://scenes/Main.tscn")

func _on_options_pressed():
	animate_button_press(options_button)
	await get_tree().create_timer(0.2).timeout
	show_settings_menu()

func _on_credits_pressed():
	animate_button_press(credits_button)
	await get_tree().create_timer(0.2).timeout
	show_credits_menu()

func _on_quit_pressed():
	animate_button_press(quit_button)
	await get_tree().create_timer(0.3).timeout
	
	# Fade out effect
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(get_tree().quit)

func animate_button_press(button: Button):
	var original_scale = button.scale
	var tween = create_tween()
	tween.tween_property(button, "scale", original_scale * 0.95, 0.1)
	tween.tween_property(button, "scale", original_scale, 0.1)

func transition_to_scene(scene_path: String):
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): get_tree().change_scene_to_file(scene_path))

func show_settings_menu():
	settings_menu.visible = true
	settings_menu.modulate.a = 0.0
	settings_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(settings_menu, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(settings_panel, "scale", Vector2(1.0, 1.0), 0.3)

func hide_settings_menu():
	var tween = create_tween()
	tween.parallel().tween_property(settings_menu, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(settings_panel, "scale", Vector2(0.8, 0.8), 0.3)
	tween.tween_callback(func(): settings_menu.visible = false)

func show_credits_menu():
	credits_menu.visible = true
	credits_menu.modulate.a = 0.0
	credits_panel.scale = Vector2(0.8, 0.8)
	
	var tween = create_tween()
	tween.parallel().tween_property(credits_menu, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(credits_panel, "scale", Vector2(1.0, 1.0), 0.3)

func hide_credits_menu():
	var tween = create_tween()
	tween.parallel().tween_property(credits_menu, "modulate:a", 0.0, 0.3)
	tween.parallel().tween_property(credits_panel, "scale", Vector2(0.8, 0.8), 0.3)
	tween.tween_callback(func(): credits_menu.visible = false)

func create_settings_menu():
	var vbox = VBoxContainer.new()
	settings_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "GAME SETTINGS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Add spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Graphics section
	var graphics_label = Label.new()
	graphics_label.text = "GRAPHICS"
	graphics_label.add_theme_font_size_override("font_size", 20)
	graphics_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
	vbox.add_child(graphics_label)
	
	# Fullscreen toggle
	var fullscreen_check = CheckBox.new()
	fullscreen_check.text = "Fullscreen"
	fullscreen_check.button_pressed = fullscreen
	fullscreen_check.toggled.connect(_on_fullscreen_toggled)
	vbox.add_child(fullscreen_check)
	
	# VSync toggle
	var vsync_check = CheckBox.new()
	vsync_check.text = "VSync"
	vsync_check.button_pressed = vsync
	vsync_check.toggled.connect(_on_vsync_toggled)
	vbox.add_child(vsync_check)
	
	# Add spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	# Audio section
	var audio_label = Label.new()
	audio_label.text = "AUDIO"
	audio_label.add_theme_font_size_override("font_size", 20)
	audio_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
	vbox.add_child(audio_label)
	
	# Master volume
	var master_hbox = HBoxContainer.new()
	vbox.add_child(master_hbox)
	
	var master_label = Label.new()
	master_label.text = "Master Volume:"
	master_label.custom_minimum_size = Vector2(150, 0)
	master_hbox.add_child(master_label)
	
	var master_slider = HSlider.new()
	master_slider.min_value = 0.0
	master_slider.max_value = 1.0
	master_slider.value = master_volume
	master_slider.custom_minimum_size = Vector2(200, 0)
	master_slider.value_changed.connect(_on_master_volume_changed)
	master_hbox.add_child(master_slider)
	
	# SFX volume
	var sfx_hbox = HBoxContainer.new()
	vbox.add_child(sfx_hbox)
	
	var sfx_label = Label.new()
	sfx_label.text = "SFX Volume:"
	sfx_label.custom_minimum_size = Vector2(150, 0)
	sfx_hbox.add_child(sfx_label)
	
	var sfx_slider = HSlider.new()
	sfx_slider.min_value = 0.0
	sfx_slider.max_value = 1.0
	sfx_slider.value = sfx_volume
	sfx_slider.custom_minimum_size = Vector2(200, 0)
	sfx_slider.value_changed.connect(_on_sfx_volume_changed)
	sfx_hbox.add_child(sfx_slider)
	
	# Add spacer
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer3)
	
	# Controls section
	var controls_label = Label.new()
	controls_label.text = "CONTROLS"
	controls_label.add_theme_font_size_override("font_size", 20)
	controls_label.add_theme_color_override("font_color", Color(0.8, 0.8, 1))
	vbox.add_child(controls_label)
	
	# Mouse sensitivity
	var mouse_hbox = HBoxContainer.new()
	vbox.add_child(mouse_hbox)
	
	var mouse_label = Label.new()
	mouse_label.text = "Mouse Sensitivity:"
	mouse_label.custom_minimum_size = Vector2(150, 0)
	mouse_hbox.add_child(mouse_label)
	
	var mouse_slider = HSlider.new()
	mouse_slider.min_value = 0.1
	mouse_slider.max_value = 2.0
	mouse_slider.value = mouse_sensitivity
	mouse_slider.custom_minimum_size = Vector2(200, 0)
	mouse_slider.value_changed.connect(_on_mouse_sensitivity_changed)
	mouse_hbox.add_child(mouse_slider)
	
	# Add spacer
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer4)
	
	# Buttons container
	var button_hbox = HBoxContainer.new()
	button_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(button_hbox)
	
	# Apply button
	var apply_button = Button.new()
	apply_button.text = "Apply"
	apply_button.custom_minimum_size = Vector2(100, 40)
	apply_button.pressed.connect(_on_apply_settings)
	button_hbox.add_child(apply_button)
	
	# Back button
	var back_button = Button.new()
	back_button.text = "Back"
	back_button.custom_minimum_size = Vector2(100, 40)
	back_button.pressed.connect(hide_settings_menu)
	button_hbox.add_child(back_button)

func create_credits_menu():
	var vbox = VBoxContainer.new()
	credits_panel.add_child(vbox)
	
	# Title
	var title = Label.new()
	title.text = "CREDITS"
	title.add_theme_font_size_override("font_size", 28)
	title.add_theme_color_override("font_color", Color.WHITE)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Add spacer
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer1)
	
	# Credits text
	var credits_text = RichTextLabel.new()
	credits_text.custom_minimum_size = Vector2(650, 350)
	credits_text.add_theme_font_size_override("normal_font_size", 16)
	credits_text.add_theme_color_override("default_color", Color(0.9, 0.9, 1))
	credits_text.bbcode_enabled = true
	credits_text.fit_content = true
	
	credits_text.text = """[center][color=lightblue][font_size=24]PORTAL WARFARE[/font_size][/color]
[color=lightgray]Advanced 3D FPS Experience[/color][/center]

[color=yellow]Game Development:[/color]
• Advanced Enemy AI System with coordinated behaviors
• Multi-enemy types: Scout, Tank, Drone, and Boss
• Portal-based teleportation mechanics
• Dynamic lighting and atmospheric effects
• XP/Leveling system with skill progression
• Multiple game modes and difficulty settings

[color=yellow]Technical Features:[/color]
• Godot 4.4.1 Engine
• Advanced 3D Physics
• Real-time lighting and shadows
• Particle effects system
• Audio mixing and effects
• Save/Load system

[color=yellow]Game Modes:[/color]
• Campaign Mode - Story-driven experience
• Exploration Mode - Large open world
• Target Practice - Skill improvement
• Wave Survival - Endless challenge

[color=yellow]Special Thanks:[/color]
• Godot Engine Community
• Open Source Contributors
• Beta Testing Team

[center][color=lightgray]Built with passion for immersive gaming
Version 1.0.0 - 2025[/color][/center]"""
	
	vbox.add_child(credits_text)
	
	# Add spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(spacer2)
	
	# Back button
	var back_button = Button.new()
	back_button.text = "Back to Menu"
	back_button.custom_minimum_size = Vector2(150, 40)
	back_button.pressed.connect(hide_credits_menu)
	
	var button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_child(back_button)
	vbox.add_child(button_container)

# Settings callbacks
func _on_fullscreen_toggled(pressed: bool):
	fullscreen = pressed

func _on_vsync_toggled(pressed: bool):
	vsync = pressed

func _on_master_volume_changed(value: float):
	master_volume = value

func _on_sfx_volume_changed(value: float):
	sfx_volume = value

func _on_mouse_sensitivity_changed(value: float):
	mouse_sensitivity = value

func _on_apply_settings():
	# Apply display settings
	if fullscreen:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	
	# Apply VSync
	if vsync:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED)
	else:
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	
	# Save settings
	save_settings()
	
	# Show confirmation
	show_confirmation("Settings applied successfully!")

func show_confirmation(message: String):
	var dialog = AcceptDialog.new()
	dialog.title = "Settings"
	dialog.dialog_text = message
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func save_settings():
	var config = ConfigFile.new()
	config.set_value("graphics", "fullscreen", fullscreen)
	config.set_value("graphics", "vsync", vsync)
	config.set_value("audio", "master_volume", master_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)
	config.set_value("controls", "mouse_sensitivity", mouse_sensitivity)
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		fullscreen = config.get_value("graphics", "fullscreen", false)
		vsync = config.get_value("graphics", "vsync", true)
		master_volume = config.get_value("audio", "master_volume", 1.0)
		sfx_volume = config.get_value("audio", "sfx_volume", 1.0)
		mouse_sensitivity = config.get_value("controls", "mouse_sensitivity", 0.5)

func _input(event):
	# Handle escape key to close menus
	if event.is_action_pressed("ui_cancel"):
		if settings_menu.visible:
			hide_settings_menu()
		elif credits_menu.visible:
			hide_credits_menu()
	
	# Allow Enter to start game from main menu
	elif event.is_action_pressed("ui_accept") and not settings_menu.visible and not credits_menu.visible:
		_on_start_pressed()
