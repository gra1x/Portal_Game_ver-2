extends Node3D
class_name DynamicLightingManager

# Dynamic lighting effects for atmosphere and gameplay
signal lighting_changed(new_intensity: float)

@export var flicker_lights_enabled: bool = true
@export var darkness_zones_enabled: bool = true
@export var player_flashlight_enabled: bool = true

# Light groups for different effects
var flicker_lights: Array[Light3D] = []
var emergency_lights: Array[Light3D] = []
var darkness_zones: Array[Area3D] = []

# Flicker settings
@export var flicker_intensity_min: float = 0.1
@export var flicker_intensity_max: float = 1.0
@export var flicker_speed_min: float = 0.05
@export var flicker_speed_max: float = 0.3

# Global lighting state
var global_light_modifier: float = 1.0
var in_darkness_zone: bool = false

# Player reference for flashlight
var player: Node3D

func _ready():
	# Find player
	player = get_tree().get_first_node_in_group("player")
	
	# Set up initial lighting
	setup_dynamic_lighting()
	
	print("Dynamic Lighting Manager initialized")

func setup_dynamic_lighting():
	# Find all existing lights and categorize them
	categorize_existing_lights()
	
	# Create some default atmospheric lighting
	create_atmospheric_lighting()
	
	# Set up darkness zones
	if darkness_zones_enabled:
		create_darkness_zones()
	
	# Start lighting effects
	if flicker_lights_enabled:
		start_flicker_effects()

func categorize_existing_lights():
	# Find all lights in the scene
	var all_lights = find_all_lights(get_tree().current_scene)
	
	for light in all_lights:
		if light.name.contains("Flicker") or light.name.contains("flicker"):
			flicker_lights.append(light)
		elif light.name.contains("Emergency") or light.name.contains("emergency"):
			emergency_lights.append(light)
	
	print("Categorized ", flicker_lights.size(), " flicker lights and ", emergency_lights.size(), " emergency lights")

func find_all_lights(node: Node) -> Array[Light3D]:
	var lights: Array[Light3D] = []
	
	if node is Light3D:
		lights.append(node)
	
	for child in node.get_children():
		lights.append_array(find_all_lights(child))
	
	return lights

func create_atmospheric_lighting():
	# Create main ambient lighting
	var env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.1, 0.1, 0.15)  # Dark blue ambient
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.2, 0.2, 0.3)
	env.ambient_light_energy = 0.3
	
	# Add fog for atmosphere
	env.fog_enabled = true
	env.fog_light_color = Color(0.5, 0.5, 0.7)
	env.fog_light_energy = 0.5
	env.fog_sun_scatter = 0.1
	env.fog_density = 0.01
	env.fog_height = 2.0
	env.fog_height_density = 0.1
	
	# Apply environment
	if get_viewport().world_3d.environment:
		# Modify existing environment
		var current_env = get_viewport().world_3d.environment
		current_env.ambient_light_energy *= 0.7  # Dim ambient light
	else:
		get_viewport().world_3d.environment = env
	
	# Create some strategic spot lights
	create_spot_lights()

func create_spot_lights():
	# Create flickering ceiling lights
	for i in range(3):
		var spot_light = SpotLight3D.new()
		add_child(spot_light)
		
		spot_light.position = Vector3(randf_range(-10, 10), 8, randf_range(-10, 10))
		spot_light.light_energy = randf_range(0.8, 1.2)
		spot_light.light_color = Color(1.0, 0.9, 0.7)  # Warm white
		spot_light.spot_range = 15.0
		spot_light.spot_angle = 45.0
		spot_light.shadow_enabled = true
		
		flicker_lights.append(spot_light)
	
	# Create emergency lights
	for i in range(2):
		var emergency_light = SpotLight3D.new()
		add_child(emergency_light)
		
		emergency_light.position = Vector3(randf_range(-15, 15), 6, randf_range(-15, 15))
		emergency_light.light_energy = 0.5
		emergency_light.light_color = Color(1.0, 0.3, 0.3)  # Red emergency light
		emergency_light.spot_range = 8.0
		emergency_light.spot_angle = 60.0
		
		emergency_lights.append(emergency_light)

func create_darkness_zones():
	# Create areas where lighting is dramatically reduced
	for i in range(2):
		var darkness_area = Area3D.new()
		add_child(darkness_area)
		
		# Position darkness zones
		darkness_area.position = Vector3(randf_range(-20, 20), 0, randf_range(-20, 20))
		
		# Create collision shape
		var collision_shape = CollisionShape3D.new()
		darkness_area.add_child(collision_shape)
		
		var box_shape = BoxShape3D.new()
		box_shape.size = Vector3(8, 6, 8)
		collision_shape.shape = box_shape
		
		# Connect signals
		darkness_area.body_entered.connect(_on_darkness_zone_entered)
		darkness_area.body_exited.connect(_on_darkness_zone_exited)
		
		darkness_zones.append(darkness_area)
		
		print("Created darkness zone at: ", darkness_area.position)

func start_flicker_effects():
	for light in flicker_lights:
		start_light_flicker(light)

func start_light_flicker(light: Light3D):
	# Create a unique flicker pattern for each light
	var flicker_timer = Timer.new()
	add_child(flicker_timer)
	
	flicker_timer.wait_time = randf_range(flicker_speed_min, flicker_speed_max)
	flicker_timer.timeout.connect(_on_flicker_timer_timeout.bind(light, flicker_timer))
	flicker_timer.start()

func _on_flicker_timer_timeout(light: Light3D, timer: Timer):
	if not is_instance_valid(light):
		timer.queue_free()
		return
	
	# Create flicker effect
	var original_energy = light.light_energy
	var target_energy = randf_range(flicker_intensity_min, flicker_intensity_max)
	
	# Apply darkness zone modifier
	if in_darkness_zone:
		target_energy *= 0.3
	
	target_energy *= global_light_modifier
	
	# Animate the flicker
	var tween = create_tween()
	tween.tween_property(light, "light_energy", target_energy, 0.1)
	tween.tween_property(light, "light_energy", original_energy * global_light_modifier, 0.1)
	
	# Set random next flicker time
	timer.wait_time = randf_range(flicker_speed_min, flicker_speed_max)
	timer.start()

func _on_darkness_zone_entered(body):
	if body == player:
		enter_darkness_zone()

func _on_darkness_zone_exited(body):
	if body == player:
		exit_darkness_zone()

func enter_darkness_zone():
	if in_darkness_zone:
		return
	
	in_darkness_zone = true
	print("Player entered darkness zone")
	
	# Dramatically reduce all lighting
	set_global_light_modifier(0.2)
	
	# Enable player flashlight if available
	if player_flashlight_enabled and player and player.has_method("enable_flashlight"):
		player.enable_flashlight(true)
	
	# Create spooky atmosphere
	create_darkness_effects()

func exit_darkness_zone():
	if not in_darkness_zone:
		return
	
	in_darkness_zone = false
	print("Player exited darkness zone")
	
	# Restore normal lighting
	set_global_light_modifier(1.0)
	
	# Disable player flashlight
	if player and player.has_method("enable_flashlight"):
		player.enable_flashlight(false)

func set_global_light_modifier(modifier: float):
	global_light_modifier = modifier
	
	# Apply to all lights immediately
	for light in flicker_lights:
		if is_instance_valid(light):
			light.light_energy *= modifier / (light.light_energy / light.light_energy)  # Maintain relative brightness
	
	for light in emergency_lights:
		if is_instance_valid(light):
			light.light_energy *= modifier
	
	lighting_changed.emit(modifier)

func create_darkness_effects():
	# Add some eerie effects in darkness zones
	
	# Occasional light pulses
	var pulse_timer = Timer.new()
	add_child(pulse_timer)
	pulse_timer.wait_time = randf_range(3.0, 8.0)
	pulse_timer.timeout.connect(_on_darkness_pulse_timeout.bind(pulse_timer))
	pulse_timer.start()

func _on_darkness_pulse_timeout(timer: Timer):
	if not in_darkness_zone:
		timer.queue_free()
		return
	
	# Create a brief light pulse
	var pulse_light = SpotLight3D.new()
	add_child(pulse_light)
	
	if player:
		pulse_light.position = player.global_position + Vector3(randf_range(-5, 5), 3, randf_range(-5, 5))
	else:
		pulse_light.position = Vector3(0, 3, 0)
	
	pulse_light.light_energy = 2.0
	pulse_light.light_color = Color(0.8, 0.8, 1.0)  # Cold blue-white
	pulse_light.spot_range = 10.0
	pulse_light.spot_angle = 90.0
	
	# Animate pulse
	var tween = create_tween()
	tween.tween_property(pulse_light, "light_energy", 0.0, 1.5)
	tween.tween_callback(pulse_light.queue_free)
	
	# Schedule next pulse
	timer.wait_time = randf_range(5.0, 12.0)
	timer.start()

# Power outage system
func trigger_power_outage(duration: float = 10.0):
	print("Power outage triggered for ", duration, " seconds")
	
	# Turn off all non-emergency lights
	for light in flicker_lights:
		if is_instance_valid(light):
			light.visible = false
	
	# Emergency lights go to half power
	for light in emergency_lights:
		if is_instance_valid(light):
			light.light_energy *= 0.5
	
	# Enable emergency lighting mode
	enable_emergency_mode()
	
	# Restore power after duration
	await get_tree().create_timer(duration).timeout
	restore_power()

func enable_emergency_mode():
	# Flash emergency lights
	for light in emergency_lights:
		if is_instance_valid(light):
			var flash_tween = create_tween()
			flash_tween.set_loops()
			flash_tween.tween_property(light, "light_energy", 0.1, 0.5)
			flash_tween.tween_property(light, "light_energy", 0.8, 0.5)

func restore_power():
	print("Power restored")
	
	# Turn lights back on gradually
	for i in range(flicker_lights.size()):
		var light = flicker_lights[i]
		if is_instance_valid(light):
			# Stagger the restoration
			await get_tree().create_timer(randf_range(0.1, 1.0)).timeout
			light.visible = true
			
			# Brief surge effect
			var surge_tween = create_tween()
			surge_tween.tween_property(light, "light_energy", 2.0, 0.1)
			surge_tween.tween_property(light, "light_energy", 1.0, 0.3)
	
	# Restore emergency lights to normal
	for light in emergency_lights:
		if is_instance_valid(light):
			var restore_tween = create_tween()
			restore_tween.tween_property(light, "light_energy", 0.5, 1.0)

# Dynamic time of day system
func set_time_of_day(hour: int):
	var time_factor: float
	
	if hour >= 6 and hour <= 18:  # Day time
		time_factor = 1.0
	elif hour >= 19 and hour <= 21:  # Evening
		time_factor = 0.7
	elif hour >= 22 or hour <= 5:  # Night
		time_factor = 0.3
	else:  # Dawn
		time_factor = 0.5
	
	set_global_light_modifier(time_factor)
	print("Time of day set to hour ", hour, " with light factor ", time_factor)

# Public interface for external systems
func add_flicker_light(light: Light3D):
	flicker_lights.append(light)
	start_light_flicker(light)

func add_emergency_light(light: Light3D):
	emergency_lights.append(light)

func get_current_light_level() -> float:
	return global_light_modifier

func is_in_darkness() -> bool:
	return in_darkness_zone or global_light_modifier < 0.4
