extends Node3D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 3.0
@export var max_enemies: int = 5
@export var spawn_radius: float = 12.0

var current_enemies: Array[CharacterBody3D] = []
var spawn_timer: float = 0.0
var player: CharacterBody3D
var ui: Control
var spawn_points: Array[Vector3] = []
var game_mode_manager: Node

@onready var navigation_region: NavigationRegion3D = $NavigationRegion3D

func _ready():
	# Find player and UI
	player = get_tree().get_first_node_in_group("player")
	ui = get_tree().get_first_node_in_group("ui")
	
	# Set up spawn points around the level
	setup_spawn_points()
	
	# Load enemy scene if not assigned
	if not enemy_scene:
		enemy_scene = preload("res://scenes/Enemy.tscn")
	
	# Initialize game mode manager
	game_mode_manager = preload("res://scripts/GameModeManager.gd").new()
	add_child(game_mode_manager)
	game_mode_manager.initialize(self, ui, player)

func setup_spawn_points():
	# Create spawn points in a circle around the center
	var center = Vector3.ZERO
	var num_points = 8
	
	for i in range(num_points):
		var angle = (i * 2 * PI) / num_points
		var x = center.x + spawn_radius * cos(angle)
		var z = center.z + spawn_radius * sin(angle)
		
		# Use raycast to find proper ground level
		var ground_y = find_ground_level(Vector3(x, 10, z))
		# Enemy model is positioned so legs touch ground when enemy root is at ground level
		spawn_points.append(Vector3(x, ground_y, z))

func _process(delta):
	# Update spawn timer
	spawn_timer += delta
	
	# Spawn enemies if needed
	if spawn_timer >= spawn_interval and current_enemies.size() < max_enemies:
		spawn_enemy()
		spawn_timer = 0.0
	
	# Clean up dead enemies from the array
	current_enemies = current_enemies.filter(func(enemy): return is_instance_valid(enemy))

func spawn_enemy():
	if not enemy_scene or spawn_points.is_empty():
		return
	
	# Choose a random spawn point
	var spawn_point = spawn_points[randi() % spawn_points.size()]
	
	# Make sure spawn point is not too close to player
	if player and spawn_point.distance_to(player.global_position) < 5.0:
		return
	
	# Instantiate enemy
	var enemy = enemy_scene.instantiate()
	enemy.global_position = spawn_point
	
	# Connect enemy signals
	enemy.enemy_died.connect(_on_enemy_died)
	
	# Add to scene and track
	add_child(enemy)
	current_enemies.append(enemy)
	
	# Add enemy to player group for AI targeting
	enemy.add_to_group("enemies")

func _on_enemy_died(enemy):
	# Remove from tracking array
	if enemy in current_enemies:
		current_enemies.erase(enemy)
	
	# Notify UI for scoring
	if ui and ui.has_method("_on_enemy_died"):
		ui._on_enemy_died()

func get_enemy_count() -> int:
	return current_enemies.size()

func clear_all_enemies():
	for enemy in current_enemies:
		if is_instance_valid(enemy):
			enemy.queue_free()
	current_enemies.clear()

func find_ground_level(from_position: Vector3) -> float:
	# Raycast downward to find ground level
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		from_position,
		from_position + Vector3(0, -20, 0)
	)
	
	var result = space_state.intersect_ray(query)
	if result:
		return result.position.y
	else:
		# Default ground level if no hit
		return 0.0

func set_difficulty(difficulty_level: int):
	# Adjust spawn rate and max enemies based on difficulty
	match difficulty_level:
		1: # Easy
			spawn_interval = 4.0
			max_enemies = 3
		2: # Medium
			spawn_interval = 3.0
			max_enemies = 5
		3: # Hard
			spawn_interval = 2.0
			max_enemies = 8
		_: # Default
			spawn_interval = 3.0
			max_enemies = 5
