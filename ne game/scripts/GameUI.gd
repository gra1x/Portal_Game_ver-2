extends Control

@onready var health_bar: ProgressBar = $HUDPanel/VBoxContainer/HealthContainer/HealthBar
@onready var health_value: Label = $HUDPanel/VBoxContainer/HealthContainer/HealthValue
@onready var ammo_value: Label = $HUDPanel/VBoxContainer/AmmoContainer/AmmoValue
@onready var crosshair: Control = $Crosshair
@onready var score_value: Label = $HUDPanel/VBoxContainer/ScoreContainer/ScoreValue

var score: int = 0
var is_game_paused: bool = false
var escape_menu: Control = null
var death_menu: Control = null

func _ready():
	# Find the player and connect signals
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_health_changed)
		player.ammo_changed.connect(_on_ammo_changed)
		player.player_died.connect(_on_player_died)
	
	# Initialize UI
	update_score_display()
	
	# Connect to screen size changes
	get_viewport().size_changed.connect(_on_screen_size_changed)
	
	# Set initial layout
	_on_screen_size_changed()

func _on_health_changed(new_health: int):
	health_bar.value = new_health
	health_value.text = str(new_health)
	
	# Flash red if health is low
	if new_health <= 25:
		flash_low_health()

func _on_ammo_changed(new_ammo: int):
	ammo_value.text = str(new_ammo)
	
	# Flash red if ammo is low
	if new_ammo <= 5:
		flash_low_ammo()

func _on_player_died():
	# Show game over screen
	show_game_over()

func flash_low_health():
	var tween = create_tween()
	tween.tween_property(health_value, "modulate", Color.RED, 0.2)
	tween.tween_property(health_value, "modulate", Color.WHITE, 0.2)

func flash_low_ammo():
	var tween = create_tween()
	tween.tween_property(ammo_value, "modulate", Color.RED, 0.2)
	tween.tween_property(ammo_value, "modulate", Color.WHITE, 0.2)

func add_score(points: int):
	score += points
	update_score_display()

func update_score_display():
	score_value.text = str(score)

func show_game_over():
	if death_menu:
		return  # Already showing
	
	# Pause the game and show mouse
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Create enhanced death menu
	death_menu = Control.new()
	death_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	death_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Background with red tint for death
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.2, 0, 0, 0.9)  # Dark red tint
	death_menu.add_child(bg)
	
	# Get screen info for scaling
	var viewport_size = get_viewport().get_visible_rect().size
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var scale_factor = 1.0
	if is_fullscreen:
		scale_factor = min(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
		scale_factor = max(scale_factor * 1.5, 1.2)  # Make UI bigger in fullscreen
	
	# Menu container with proper centering
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(20 * scale_factor))
	
	# Death title with animation
	var title = Label.new()
	title.text = "YOU DIED"
	title.add_theme_font_size_override("font_size", int(64 * scale_factor))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.modulate = Color.RED
	vbox.add_child(title)
	
	# Cause of death
	var cause = Label.new()
	cause.text = "Eliminated by enemy forces"
	cause.add_theme_font_size_override("font_size", int(18 * scale_factor))
	cause.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cause.modulate = Color(0.8, 0.8, 0.8, 1)
	vbox.add_child(cause)
	
	# Score display
	var final_score = Label.new()
	final_score.text = "Final Score: " + str(score)
	final_score.add_theme_font_size_override("font_size", int(28 * scale_factor))
	final_score.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	final_score.modulate = Color.YELLOW
	vbox.add_child(final_score)
	
	# Performance rating
	var rating = Label.new()
	var rating_text = get_performance_rating(score)
	rating.text = rating_text
	rating.add_theme_font_size_override("font_size", int(16 * scale_factor))
	rating.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rating.modulate = Color(0.7, 0.9, 0.7, 1)
	vbox.add_child(rating)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, int(30 * scale_factor))
	vbox.add_child(spacer)
	
	# Respawn button (highlighted)
	var respawn_btn = Button.new()
	respawn_btn.text = "RESPAWN"
	respawn_btn.custom_minimum_size = Vector2(int(250 * scale_factor), int(60 * scale_factor))
	respawn_btn.add_theme_font_size_override("font_size", int(18 * scale_factor))
	respawn_btn.pressed.connect(_on_restart_pressed)
	vbox.add_child(respawn_btn)
	
	# Main menu button
	var menu_btn = Button.new()
	menu_btn.text = "MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(int(250 * scale_factor), int(50 * scale_factor))
	menu_btn.add_theme_font_size_override("font_size", int(16 * scale_factor))
	menu_btn.pressed.connect(_on_death_main_menu_pressed)
	vbox.add_child(menu_btn)
	
	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "QUIT GAME"
	quit_btn.custom_minimum_size = Vector2(int(250 * scale_factor), int(50 * scale_factor))
	quit_btn.add_theme_font_size_override("font_size", int(16 * scale_factor))
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)
	
	# Properly center the menu
	vbox.position = Vector2(
		(viewport_size.x - vbox.get_combined_minimum_size().x) / 2,
		(viewport_size.y - vbox.get_combined_minimum_size().y) / 2
	)
	
	death_menu.add_child(vbox)
	add_child(death_menu)
	
	# Ensure proper centering after the scene is ready
	await get_tree().process_frame
	vbox.position = Vector2(
		(viewport_size.x - vbox.size.x) / 2,
		(viewport_size.y - vbox.size.y) / 2
	)
	
	# Focus respawn button
	respawn_btn.grab_focus()
	
	# Animate title appearance
	title.modulate.a = 0
	var tween = create_tween()
	tween.tween_property(title, "modulate:a", 1.0, 0.5)
	tween.parallel().tween_property(title, "scale", Vector2(1.1, 1.1), 0.3)
	tween.parallel().tween_property(title, "scale", Vector2(1.0, 1.0), 0.2)

func get_performance_rating(final_score: int) -> String:
	if final_score >= 1000:
		return "★★★ LEGENDARY WARRIOR!"
	elif final_score >= 500:
		return "★★ SKILLED FIGHTER"
	elif final_score >= 200:
		return "★ DECENT EFFORT"
	else:
		return "NEEDS MORE PRACTICE"

func _on_death_main_menu_pressed():
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_restart_pressed():
	# Ensure game is unpaused before reloading
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	get_tree().reload_current_scene()

func _on_quit_pressed():
	get_tree().quit()

func _on_enemy_died():
	add_score(100)  # 100 points per enemy killed

func toggle_escape_menu():
	if is_game_paused:
		hide_escape_menu()
	else:
		show_escape_menu()

func show_escape_menu():
	if escape_menu:
		return  # Already showing
	
	is_game_paused = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	
	# Create escape menu
	escape_menu = Control.new()
	escape_menu.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	escape_menu.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	escape_menu.add_child(bg)
	
	# Get screen info for scaling
	var viewport_size = get_viewport().get_visible_rect().size
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	var scale_factor = 1.0
	if is_fullscreen:
		scale_factor = min(viewport_size.x / 1920.0, viewport_size.y / 1080.0)
		scale_factor = max(scale_factor * 1.4, 1.2)  # Make UI bigger in fullscreen
	
	# Menu container with proper centering
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", int(15 * scale_factor))
	
	# Title
	var title = Label.new()
	title.text = "GAME PAUSED"
	title.add_theme_font_size_override("font_size", int(36 * scale_factor))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, int(20 * scale_factor))
	vbox.add_child(spacer)
	
	# Resume button
	var resume_btn = Button.new()
	resume_btn.text = "RESUME GAME"
	resume_btn.custom_minimum_size = Vector2(int(200 * scale_factor), int(50 * scale_factor))
	resume_btn.add_theme_font_size_override("font_size", int(16 * scale_factor))
	resume_btn.pressed.connect(hide_escape_menu)
	vbox.add_child(resume_btn)
	
	# Options button
	var options_btn = Button.new()
	options_btn.text = "OPTIONS"
	options_btn.custom_minimum_size = Vector2(int(200 * scale_factor), int(50 * scale_factor))
	options_btn.add_theme_font_size_override("font_size", int(16 * scale_factor))
	options_btn.pressed.connect(show_pause_options)
	vbox.add_child(options_btn)
	
	# Main menu button
	var menu_btn = Button.new()
	menu_btn.text = "MAIN MENU"
	menu_btn.custom_minimum_size = Vector2(int(200 * scale_factor), int(50 * scale_factor))
	menu_btn.add_theme_font_size_override("font_size", int(16 * scale_factor))
	menu_btn.pressed.connect(_on_main_menu_pressed)
	vbox.add_child(menu_btn)
	
	# Quit button
	var quit_btn = Button.new()
	quit_btn.text = "QUIT GAME"
	quit_btn.custom_minimum_size = Vector2(int(200 * scale_factor), int(50 * scale_factor))
	quit_btn.add_theme_font_size_override("font_size", int(16 * scale_factor))
	quit_btn.pressed.connect(_on_quit_pressed)
	vbox.add_child(quit_btn)
	
	# Properly center the menu
	vbox.position = Vector2(
		(viewport_size.x - vbox.get_combined_minimum_size().x) / 2,
		(viewport_size.y - vbox.get_combined_minimum_size().y) / 2
	)
	
	escape_menu.add_child(vbox)
	add_child(escape_menu)
	
	# Ensure proper centering after the scene is ready
	await get_tree().process_frame
	vbox.position = Vector2(
		(viewport_size.x - vbox.size.x) / 2,
		(viewport_size.y - vbox.size.y) / 2
	)
	
	# Focus resume button
	resume_btn.grab_focus()

func hide_escape_menu():
	if not escape_menu:
		return
	
	is_game_paused = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	escape_menu.queue_free()
	escape_menu = null

func show_pause_options():
	# Simple options dialog for pause menu
	var dialog = AcceptDialog.new()
	dialog.title = "Game Options"
	dialog.dialog_text = "CONTROLS:\n\nW/A/S/D - Move\nMouse - Look around\nLeft Click - Shoot\nRight Click - Aim\nSpace - Jump\nR - Reload\nF11 - Toggle Fullscreen\nEscape - Pause Menu\n\nTip: Enemies spawn around the arena!\nScore: 100 points per kill"
	dialog.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	add_child(dialog)
	dialog.popup_centered()
	dialog.confirmed.connect(func(): dialog.queue_free())

func _on_main_menu_pressed():
	hide_escape_menu()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")

func _on_screen_size_changed():
	var viewport_size = get_viewport().get_visible_rect().size
	var is_fullscreen = DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN
	
	# Adjust HUD elements based on screen size and fullscreen state
	if is_fullscreen:
		# Fullscreen adjustments
		adjust_hud_for_fullscreen(viewport_size)
	else:
		# Windowed adjustments
		adjust_hud_for_windowed(viewport_size)

func adjust_hud_for_fullscreen(screen_size: Vector2):
	# Scale UI elements for fullscreen
	var scale_factor = min(screen_size.x / 1920.0, screen_size.y / 1080.0)
	scale_factor = max(scale_factor, 0.8)  # Minimum scale
	
	# Adjust HUD container position for wider screens
	var hud_container = $HUDPanel
	if hud_container:
		# Move HUD slightly more inward on ultrawide screens
		var margin_x = screen_size.x * 0.02  # 2% margin
		var margin_y = screen_size.y * 0.02  # 2% margin
		
		hud_container.position.x = margin_x
		hud_container.position.y = screen_size.y - hud_container.size.y - margin_y
		
		# Scale text for better visibility
		health_value.add_theme_font_size_override("font_size", int(16 * scale_factor))
		ammo_value.add_theme_font_size_override("font_size", int(16 * scale_factor))
		score_value.add_theme_font_size_override("font_size", int(16 * scale_factor))
	
	# Adjust crosshair for fullscreen
	if crosshair:
		var crosshair_scale = max(scale_factor, 1.0)
		crosshair.scale = Vector2(crosshair_scale, crosshair_scale)

func adjust_hud_for_windowed(screen_size: Vector2):
	# Reset to default windowed layout
	var hud_container = $HUDPanel
	if hud_container:
		# Standard windowed position
		hud_container.position.x = 20
		hud_container.position.y = screen_size.y - hud_container.size.y - 20
		
		# Default text sizes
		health_value.remove_theme_font_size_override("font_size")
		ammo_value.remove_theme_font_size_override("font_size")
		score_value.remove_theme_font_size_override("font_size")
	
	# Reset crosshair scale
	if crosshair:
		crosshair.scale = Vector2(1.0, 1.0)

func _input(event):
	# Handle fullscreen toggle with F11 key
	if event.is_action_pressed("fullscreen"):
		toggle_fullscreen()

func toggle_fullscreen():
	if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	
	# Force HUD update after fullscreen change
	call_deferred("_on_screen_size_changed")
