extends Node
class_name SaveSystem

# Save system for persistent game progress
signal save_completed(success: bool)
signal load_completed(success: bool, data: Dictionary)

const SAVE_FILE_PATH = "user://savegame.dat"
const SETTINGS_FILE_PATH = "user://settings.cfg"
const AUTO_SAVE_INTERVAL = 30.0  # Auto-save every 30 seconds

var auto_save_timer: Timer
var is_saving: bool = false
var current_save_data: Dictionary = {}

# Game state tracking
var game_manager: Node
var xp_manager: XPManager
var player: Node3D

func _ready():
	# Set up auto-save timer
	auto_save_timer = Timer.new()
	add_child(auto_save_timer)
	auto_save_timer.wait_time = AUTO_SAVE_INTERVAL
	auto_save_timer.timeout.connect(_on_auto_save_timer_timeout)
	auto_save_timer.start()
	
	# Find key game components
	await get_tree().process_frame  # Wait for scene to be ready
	find_game_components()
	
	print("Save System initialized")

func find_game_components():
	# Find game manager
	game_manager = get_tree().get_first_node_in_group("game_manager")
	if not game_manager:
		game_manager = get_node_or_null("/root/GameManager")
	
	# Find XP manager
	xp_manager = get_tree().get_first_node_in_group("xp_manager")
	if not xp_manager:
		var xp_nodes = get_tree().get_nodes_in_group("xp")
		if xp_nodes.size() > 0:
			xp_manager = xp_nodes[0]
	
	# Find player
	player = get_tree().get_first_node_in_group("player")

func _on_auto_save_timer_timeout():
	if not is_saving:
		auto_save()

func auto_save():
	print("Auto-saving game...")
	save_game(true)  # true indicates auto-save

func save_game(is_auto_save: bool = false) -> bool:
	if is_saving:
		print("Save already in progress")
		return false
	
	is_saving = true
	var save_data = collect_save_data()
	
	if is_auto_save:
		save_data["is_auto_save"] = true
		save_data["auto_save_timestamp"] = Time.get_unix_time_from_system()
	
	var success = write_save_file(save_data)
	
	if success:
		current_save_data = save_data
		if not is_auto_save:
			print("Game saved successfully")
	else:
		print("Failed to save game")
	
	is_saving = false
	save_completed.emit(success)
	return success

func collect_save_data() -> Dictionary:
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"playtime": 0.0,
		"level_name": "",
		"player_data": {},
		"xp_data": {},
		"game_state": {},
		"settings": {},
		"achievements": [],
		"statistics": {}
	}
	
	# Collect player data
	if player:
		save_data["player_data"] = collect_player_data()
	
	# Collect XP and leveling data
	if xp_manager:
		save_data["xp_data"] = collect_xp_data()
	
	# Collect game state
	if game_manager:
		save_data["game_state"] = collect_game_state()
	
	# Collect current level info
	save_data["level_name"] = get_current_level_name()
	
	# Collect playtime
	save_data["playtime"] = get_total_playtime()
	
	# Collect statistics
	save_data["statistics"] = collect_statistics()
	
	return save_data

func collect_player_data() -> Dictionary:
	var player_data = {
		"position": Vector3.ZERO,
		"rotation": Vector3.ZERO,
		"health": 100,
		"max_health": 100,
		"armor": 0,
		"weapons": [],
		"ammunition": {},
		"inventory": [],
		"abilities": []
	}
	
	if player:
		player_data["position"] = player.global_position
		player_data["rotation"] = player.global_rotation
		
		# Get health if available
		if player.has_method("get_health"):
			player_data["health"] = player.get_health()
		elif player.has_property("health"):
			player_data["health"] = player.health
		
		if player.has_method("get_max_health"):
			player_data["max_health"] = player.get_max_health()
		elif player.has_property("max_health"):
			player_data["max_health"] = player.max_health
		
		# Get weapons and inventory if available
		if player.has_method("get_weapons"):
			player_data["weapons"] = player.get_weapons()
		
		if player.has_method("get_inventory"):
			player_data["inventory"] = player.get_inventory()
		
		if player.has_method("get_abilities"):
			player_data["abilities"] = player.get_abilities()
	
	return player_data

func collect_xp_data() -> Dictionary:
	var xp_data = {
		"current_xp": 0,
		"current_level": 1,
		"total_xp_earned": 0,
		"skill_points": 0,
		"unlocked_skills": [],
		"skill_levels": {}
	}
	
	if xp_manager:
		if xp_manager.has_method("get_current_xp"):
			xp_data["current_xp"] = xp_manager.get_current_xp()
		elif xp_manager.has_property("current_xp"):
			xp_data["current_xp"] = xp_manager.current_xp
		
		if xp_manager.has_method("get_current_level"):
			xp_data["current_level"] = xp_manager.get_current_level()
		elif xp_manager.has_property("current_level"):
			xp_data["current_level"] = xp_manager.current_level
		
		if xp_manager.has_method("get_total_xp_earned"):
			xp_data["total_xp_earned"] = xp_manager.get_total_xp_earned()
		elif xp_manager.has_property("total_xp_earned"):
			xp_data["total_xp_earned"] = xp_manager.total_xp_earned
		
		if xp_manager.has_method("get_skill_points"):
			xp_data["skill_points"] = xp_manager.get_skill_points()
		elif xp_manager.has_property("skill_points"):
			xp_data["skill_points"] = xp_manager.skill_points
		
		if xp_manager.has_method("get_unlocked_skills"):
			xp_data["unlocked_skills"] = xp_manager.get_unlocked_skills()
		elif xp_manager.has_property("unlocked_skills"):
			xp_data["unlocked_skills"] = xp_manager.unlocked_skills
	
	return xp_data

func collect_game_state() -> Dictionary:
	var game_state = {
		"enemies_defeated": 0,
		"current_wave": 1,
		"score": 0,
		"difficulty_level": 1,
		"game_mode": "survival",
		"unlocked_areas": [],
		"completed_objectives": [],
		"active_power_ups": []
	}
	
	if game_manager:
		# Collect various game state variables if they exist
		var properties = ["enemies_defeated", "current_wave", "score", "difficulty_level", 
						 "game_mode", "unlocked_areas", "completed_objectives"]
		
		for prop in properties:
			if game_manager.has_method("get_" + prop):
				game_state[prop] = game_manager.call("get_" + prop)
			elif game_manager.has_property(prop):
				game_state[prop] = game_manager.get(prop)
	
	return game_state

func collect_statistics() -> Dictionary:
	var stats = {
		"total_playtime": 0.0,
		"enemies_killed": 0,
		"shots_fired": 0,
		"accuracy": 0.0,
		"deaths": 0,
		"levels_completed": 0,
		"xp_earned": 0,
		"distance_traveled": 0.0,
		"power_ups_collected": 0,
		"secrets_found": 0
	}
	
	# Try to get statistics from Global node or game manager
	var global_node = get_node_or_null("/root/Global")
	if global_node and global_node.has_method("get_statistics"):
		var global_stats = global_node.get_statistics()
		for key in global_stats:
			stats[key] = global_stats[key]
	
	return stats

func get_current_level_name() -> String:
	var current_scene = get_tree().current_scene
	if current_scene:
		return current_scene.name
	return "Unknown"

func get_total_playtime() -> float:
	# Try to get playtime from game manager or calculate from session start
	if game_manager and game_manager.has_method("get_playtime"):
		return game_manager.get_playtime()
	
	# Fallback: use engine time (not accurate for total playtime)
	return Time.get_ticks_msec() / 1000.0

func write_save_file(save_data: Dictionary) -> bool:
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.WRITE)
	if not file:
		print("Failed to open save file for writing")
		return false
	
	# Convert to JSON and encrypt/encode if desired
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	return true

func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_FILE_PATH):
		print("No save file found")
		load_completed.emit(false, {})
		return false
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		print("Failed to open save file for reading")
		load_completed.emit(false, {})
		return false
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		print("Failed to parse save file JSON")
		load_completed.emit(false, {})
		return false
	
	var save_data = json.data
	if not save_data is Dictionary:
		print("Invalid save data format")
		load_completed.emit(false, {})
		return false
	
	# Apply loaded data
	var success = apply_save_data(save_data)
	current_save_data = save_data
	
	load_completed.emit(success, save_data)
	return success

func apply_save_data(save_data: Dictionary) -> bool:
	print("Loading game from save data...")
	
	# Apply player data
	if save_data.has("player_data"):
		apply_player_data(save_data["player_data"])
	
	# Apply XP data
	if save_data.has("xp_data"):
		apply_xp_data(save_data["xp_data"])
	
	# Apply game state
	if save_data.has("game_state"):
		apply_game_state(save_data["game_state"])
	
	print("Game loaded successfully")
	return true

func apply_player_data(player_data: Dictionary):
	if not player:
		return
	
	# Set position and rotation
	if player_data.has("position"):
		player.global_position = str_to_var("Vector3" + str(player_data["position"]))
	
	if player_data.has("rotation"):
		player.global_rotation = str_to_var("Vector3" + str(player_data["rotation"]))
	
	# Set health
	if player_data.has("health") and player.has_method("set_health"):
		player.set_health(player_data["health"])
	elif player_data.has("health") and player.has_property("health"):
		player.health = player_data["health"]
	
	# Set max health
	if player_data.has("max_health") and player.has_method("set_max_health"):
		player.set_max_health(player_data["max_health"])
	elif player_data.has("max_health") and player.has_property("max_health"):
		player.max_health = player_data["max_health"]
	
	# Restore weapons and inventory
	if player_data.has("weapons") and player.has_method("set_weapons"):
		player.set_weapons(player_data["weapons"])
	
	if player_data.has("inventory") and player.has_method("set_inventory"):
		player.set_inventory(player_data["inventory"])

func apply_xp_data(xp_data: Dictionary):
	if not xp_manager:
		return
	
	# Restore XP and level
	if xp_data.has("current_xp") and xp_manager.has_method("set_xp"):
		xp_manager.set_xp(xp_data["current_xp"])
	elif xp_data.has("current_xp") and xp_manager.has_property("current_xp"):
		xp_manager.current_xp = xp_data["current_xp"]
	
	if xp_data.has("current_level") and xp_manager.has_method("set_level"):
		xp_manager.set_level(xp_data["current_level"])
	elif xp_data.has("current_level") and xp_manager.has_property("current_level"):
		xp_manager.current_level = xp_data["current_level"]
	
	# Restore skill points
	if xp_data.has("skill_points") and xp_manager.has_method("set_skill_points"):
		xp_manager.set_skill_points(xp_data["skill_points"])
	elif xp_data.has("skill_points") and xp_manager.has_property("skill_points"):
		xp_manager.skill_points = xp_data["skill_points"]
	
	# Restore unlocked skills
	if xp_data.has("unlocked_skills") and xp_manager.has_method("set_unlocked_skills"):
		xp_manager.set_unlocked_skills(xp_data["unlocked_skills"])
	elif xp_data.has("unlocked_skills") and xp_manager.has_property("unlocked_skills"):
		xp_manager.unlocked_skills = xp_data["unlocked_skills"]

func apply_game_state(game_state: Dictionary):
	if not game_manager:
		return
	
	# Restore game state variables
	for key in game_state:
		if game_manager.has_method("set_" + key):
			game_manager.call("set_" + key, game_state[key])
		elif game_manager.has_property(key):
			game_manager.set(key, game_state[key])

# Quick save/load functions
func quick_save() -> bool:
	print("Quick saving...")
	return save_game()

func quick_load() -> bool:
	print("Quick loading...")
	return load_game()

# Save file management
func delete_save_file() -> bool:
	if FileAccess.file_exists(SAVE_FILE_PATH):
		DirAccess.remove_absolute(SAVE_FILE_PATH)
		print("Save file deleted")
		return true
	return false

func has_save_file() -> bool:
	return FileAccess.file_exists(SAVE_FILE_PATH)

func get_save_file_info() -> Dictionary:
	if not has_save_file():
		return {}
	
	var file = FileAccess.open(SAVE_FILE_PATH, FileAccess.READ)
	if not file:
		return {}
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return {}
	
	var save_data = json.data
	if not save_data is Dictionary:
		return {}
	
	return {
		"timestamp": save_data.get("timestamp", 0),
		"playtime": save_data.get("playtime", 0.0),
		"level_name": save_data.get("level_name", "Unknown"),
		"player_level": save_data.get("xp_data", {}).get("current_level", 1),
		"is_auto_save": save_data.get("is_auto_save", false)
	}

# Settings save/load
func save_settings(settings: Dictionary) -> bool:
	var config = ConfigFile.new()
	
	for section in settings:
		for key in settings[section]:
			config.set_value(section, key, settings[section][key])
	
	var error = config.save(SETTINGS_FILE_PATH)
	return error == OK

func load_settings() -> Dictionary:
	var config = ConfigFile.new()
	var error = config.load(SETTINGS_FILE_PATH)
	
	if error != OK:
		return {}
	
	var settings = {}
	for section in config.get_sections():
		settings[section] = {}
		for key in config.get_section_keys(section):
			settings[section][key] = config.get_value(section, key)
	
	return settings

# Public interface for external systems
func request_save():
	save_game()

func request_load():
	load_game()

func get_current_save_data() -> Dictionary:
	return current_save_data

func set_auto_save_enabled(enabled: bool):
	if enabled:
		auto_save_timer.start()
	else:
		auto_save_timer.stop()

func set_auto_save_interval(interval: float):
	auto_save_timer.wait_time = interval
