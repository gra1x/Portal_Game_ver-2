extends Node

enum GameMode {
	STANDARD,
	TARGET_PRACTICE,
	WAVE_SURVIVAL
}

var current_mode: GameMode = GameMode.STANDARD
var game_manager: Node3D
var ui: Control
var player: CharacterBody3D

# Target Practice Variables
var targets_hit: int = 0
var targets_spawned: int = 0
var max_targets: int = 20
var target_spawn_timer: Timer
var practice_time_limit: float = 120.0  # 2 minutes
var practice_timer: Timer

# Wave Survival Variables
var current_wave: int = 0
var enemies_in_wave: int = 0
var enemies_killed_this_wave: int = 0
var wave_active: bool = false
var wave_prep_time: float = 10.0
var wave_timer: Timer
var base_enemies_per_wave: int = 3

# Target Practice Scene
var target_scene: PackedScene = preload("res://scenes/Target.tscn")
var active_targets: Array = []

signal mode_started(mode: GameMode)
signal mode_ended(mode: GameMode)
signal wave_completed(wave_number: int)
signal target_hit(targets_remaining: int)

func _ready():
	# Create timers
	target_spawn_timer = Timer.new()
	target_spawn_timer.wait_time = 3.0
	target_spawn_timer.timeout.connect(_spawn_target)
	add_child(target_spawn_timer)
	
	practice_timer = Timer.new()
	practice_timer.wait_time = practice_time_limit
	practice_timer.timeout.connect(_end_target_practice)
	practice_timer.one_shot = true
	add_child(practice_timer)
	
	wave_timer = Timer.new()
	wave_timer.wait_time = wave_prep_time
	wave_timer.timeout.connect(_start_next_wave)
	wave_timer.one_shot = true
	add_child(wave_timer)

func initialize(gm: Node3D, ui_node: Control, player_node: CharacterBody3D):
	game_manager = gm
	ui = ui_node
	player = player_node

func start_game_mode(mode: GameMode):
	current_mode = mode
	mode_started.emit(mode)
	
	match mode:
		GameMode.STANDARD:
			start_standard_mode()
		GameMode.TARGET_PRACTICE:
			start_target_practice()
		GameMode.WAVE_SURVIVAL:
			start_wave_survival()

func start_standard_mode():
	print("Started Standard Mode")
	# Standard mode uses existing GameManager behavior

func start_target_practice():
	print("Started Target Practice Mode")
	
	# Disable enemy spawning
	if game_manager and game_manager.has_method("clear_all_enemies"):
		game_manager.clear_all_enemies()
	
	# Reset variables
	targets_hit = 0
	targets_spawned = 0
	active_targets.clear()
	
	# Start spawning targets
	target_spawn_timer.start()
	practice_timer.start()
	
	# Update UI
	if ui and ui.has_method("show_target_practice_ui"):
		ui.show_target_practice_ui(max_targets, practice_time_limit)

func start_wave_survival():
	print("Started Wave Survival Mode")
	
	# Reset variables
	current_wave = 0
	enemies_in_wave = 0
	enemies_killed_this_wave = 0
	wave_active = false
	
	# Start first wave preparation
	_prepare_next_wave()

func _spawn_target():
	if targets_spawned >= max_targets:
		target_spawn_timer.stop()
		return
	
	if not target_scene:
		print("Target scene not found!")
		return
	
	# Spawn target at random elevated position
	var target = target_scene.instantiate()
	var spawn_positions = [
		Vector3(randf_range(-20, 20), randf_range(3, 12), randf_range(-20, 20)),
		Vector3(randf_range(-25, 25), randf_range(5, 15), randf_range(-25, 25)),
		Vector3(randf_range(-15, 15), randf_range(8, 18), randf_range(-15, 15))
	]
	
	target.global_position = spawn_positions[randi() % spawn_positions.size()]
	
	# Connect target hit signal
	target.target_hit.connect(_on_target_hit)
	
	get_tree().current_scene.add_child(target)
	active_targets.append(target)
	targets_spawned += 1
	
	print("Target spawned: ", targets_spawned, "/", max_targets)

func _on_target_hit(target):
	targets_hit += 1
	
	# Remove from active targets
	if target in active_targets:
		active_targets.erase(target)
	
	# Update UI
	target_hit.emit(max_targets - targets_hit)
	
	print("Target hit! Score: ", targets_hit, "/", max_targets)
	
	# Check if all targets hit
	if targets_hit >= max_targets:
		_end_target_practice()

func _end_target_practice():
	target_spawn_timer.stop()
	practice_timer.stop()
	
	# Clean up remaining targets
	for target in active_targets:
		if is_instance_valid(target):
			target.queue_free()
	active_targets.clear()
	
	# Calculate performance
	var accuracy = float(targets_hit) / float(max_targets) * 100.0
	var time_taken = practice_time_limit - practice_timer.time_left
	
	print("Target Practice Complete! Targets Hit: ", targets_hit, "/", max_targets)
	print("Accuracy: ", accuracy, "%")
	print("Time: ", time_taken, " seconds")
	
	# Show results
	if ui and ui.has_method("show_target_practice_results"):
		ui.show_target_practice_results(targets_hit, max_targets, accuracy, time_taken)
	
	mode_ended.emit(GameMode.TARGET_PRACTICE)

func _prepare_next_wave():
	current_wave += 1
	enemies_in_wave = base_enemies_per_wave + (current_wave - 1) * 2  # Increase enemies each wave
	enemies_killed_this_wave = 0
	wave_active = false
	
	print("Preparing Wave ", current_wave, " - ", enemies_in_wave, " enemies")
	
	# Update UI
	if ui and ui.has_method("show_wave_preparation"):
		ui.show_wave_preparation(current_wave, enemies_in_wave, wave_prep_time)
	
	# Start preparation timer
	wave_timer.wait_time = wave_prep_time
	wave_timer.start()

func _start_next_wave():
	wave_active = true
	
	print("Wave ", current_wave, " started!")
	
	# Update UI
	if ui and ui.has_method("show_wave_active"):
		ui.show_wave_active(current_wave, enemies_in_wave)
	
	# Spawn enemies for this wave
	if game_manager and game_manager.has_method("spawn_wave_enemies"):
		game_manager.spawn_wave_enemies(enemies_in_wave)

func on_enemy_killed():
	if current_mode != GameMode.WAVE_SURVIVAL or not wave_active:
		return
	
	enemies_killed_this_wave += 1
	
	print("Enemy killed in wave: ", enemies_killed_this_wave, "/", enemies_in_wave)
	
	# Check if wave complete
	if enemies_killed_this_wave >= enemies_in_wave:
		_complete_wave()

func _complete_wave():
	wave_active = false
	
	print("Wave ", current_wave, " completed!")
	
	wave_completed.emit(current_wave)
	
	# Give rewards or bonuses
	if player:
		player.heal(25)  # Heal player between waves
		player.add_ammo(10)  # Give some ammo
	
	# Update UI
	if ui and ui.has_method("show_wave_completed"):
		ui.show_wave_completed(current_wave)
	
	# Start next wave after delay
	await get_tree().create_timer(3.0).timeout
	_prepare_next_wave()

func get_current_mode() -> GameMode:
	return current_mode

func is_mode_active(mode: GameMode) -> bool:
	return current_mode == mode
