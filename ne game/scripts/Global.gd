extends Node

# Game mode selection
var selected_game_mode: int = 0  # 0=Standard, 1=Target Practice, 2=Wave Survival

# Game settings
var master_volume: float = 1.0
var music_volume: float = 0.8
var sfx_volume: float = 1.0
var fullscreen: bool = false

# Player preferences
var mouse_sensitivity: float = 0.002
var invert_y_axis: bool = false

# Score tracking
var high_scores: Dictionary = {
	"target_practice": 0,
	"wave_survival": 0,
	"standard": 0
}

func _ready():
	# Load saved settings
	load_settings()

func save_settings():
	var config = ConfigFile.new()
	
	# Game settings
	config.set_value("settings", "master_volume", master_volume)
	config.set_value("settings", "music_volume", music_volume)
	config.set_value("settings", "sfx_volume", sfx_volume)
	config.set_value("settings", "fullscreen", fullscreen)
	config.set_value("settings", "mouse_sensitivity", mouse_sensitivity)
	config.set_value("settings", "invert_y_axis", invert_y_axis)
	
	# High scores
	for mode in high_scores:
		config.set_value("scores", mode, high_scores[mode])
	
	config.save("user://settings.cfg")

func load_settings():
	var config = ConfigFile.new()
	var err = config.load("user://settings.cfg")
	
	if err != OK:
		# File doesn't exist, use defaults
		return
	
	# Load game settings
	master_volume = config.get_value("settings", "master_volume", 1.0)
	music_volume = config.get_value("settings", "music_volume", 0.8)
	sfx_volume = config.get_value("settings", "sfx_volume", 1.0)
	fullscreen = config.get_value("settings", "fullscreen", false)
	mouse_sensitivity = config.get_value("settings", "mouse_sensitivity", 0.002)
	invert_y_axis = config.get_value("settings", "invert_y_axis", false)
	
	# Load high scores
	for mode in high_scores:
		high_scores[mode] = config.get_value("scores", mode, 0)

func set_high_score(mode: String, score: int):
	if score > high_scores.get(mode, 0):
		high_scores[mode] = score
		save_settings()
		return true
	return false

func get_high_score(mode: String) -> int:
	return high_scores.get(mode, 0)

func reset_high_scores():
	for mode in high_scores:
		high_scores[mode] = 0
	save_settings()
