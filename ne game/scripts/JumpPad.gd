extends Area3D

@export var jump_force: float = 15.0
@export var jump_direction: Vector3 = Vector3(0, 1, 0)

var is_cooling_down: bool = false
var cooldown_time: float = 0.5

@onready var model: Node3D = $Model
@onready var effect_particles: GPUParticles3D = $EffectParticles
@onready var jump_sound: AudioStreamPlayer3D = $JumpSound
@onready var cooldown_timer: Timer = $CooldownTimer

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	cooldown_timer.timeout.connect(_on_cooldown_timeout)
	cooldown_timer.wait_time = cooldown_time
	
	# Setup appearance
	setup_jump_pad_appearance()
	
	# Start pulsing animation
	start_pulse_animation()

func setup_jump_pad_appearance():
	# Create jump pad visual
	var mesh_instance = MeshInstance3D.new()
	var cylinder_mesh = CylinderMesh.new()
	cylinder_mesh.height = 0.3
	cylinder_mesh.top_radius = 1.2
	cylinder_mesh.bottom_radius = 1.2
	mesh_instance.mesh = cylinder_mesh
	
	# Create glowing material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(0, 1, 1, 0.8)  # Cyan
	material.emission_enabled = true
	material.emission = Color(0, 0.8, 0.8, 1)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.set_surface_override_material(0, material)
	model.add_child(mesh_instance)
	
	# Add glow light
	var light = OmniLight3D.new()
	light.light_energy = 2.0
	light.omni_range = 4.0
	light.light_color = Color(0, 1, 1, 1)
	model.add_child(light)
	
	# Add directional indicator if not straight up
	if jump_direction != Vector3(0, 1, 0):
		var arrow = MeshInstance3D.new()
		var arrow_mesh = BoxMesh.new()
		arrow_mesh.size = Vector3(0.2, 0.5, 0.2)
		arrow.mesh = arrow_mesh
		arrow.position = jump_direction.normalized() * 0.8
		arrow.look_at(global_position + jump_direction * 2, Vector3.UP)
		
		var arrow_material = StandardMaterial3D.new()
		arrow_material.albedo_color = Color.YELLOW
		arrow_material.emission_enabled = true
		arrow_material.emission = Color.YELLOW
		arrow.set_surface_override_material(0, arrow_material)
		model.add_child(arrow)

func start_pulse_animation():
	# Create pulsing scale animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(model, "scale", Vector3(1.1, 1.0, 1.1), 0.8)
	tween.tween_property(model, "scale", Vector3(1.0, 1.0, 1.0), 0.8)

func _on_body_entered(body):
	if is_cooling_down:
		return
	
	if body.is_in_group("player") or body.is_in_group("enemies"):
		launch_body(body)

func launch_body(body):
	if is_cooling_down:
		return
	
	is_cooling_down = true
	cooldown_timer.start()
	
	# Calculate launch velocity
	var launch_velocity = jump_direction.normalized() * jump_force
	
	# Apply force to the body
	if body.has_method("set_velocity") or "velocity" in body:
		# For CharacterBody3D (player and enemies)
		body.velocity = launch_velocity
		
		# Add some horizontal velocity preservation if jumping mostly up
		if jump_direction.y > 0.7:
			body.velocity.x += body.velocity.x * 0.3
			body.velocity.z += body.velocity.z * 0.3
	elif body is RigidBody3D:
		# For physics objects
		body.linear_velocity = launch_velocity
	
	# Play effects
	play_launch_effects()
	
	# Special handling for player
	if body.is_in_group("player"):
		print("Player launched by jump pad with force: ", launch_velocity)
	elif body.is_in_group("enemies"):
		print("Enemy launched by jump pad")

func play_launch_effects():
	# Flash effect
	var flash_light = OmniLight3D.new()
	flash_light.light_energy = 5.0
	flash_light.omni_range = 6.0
	flash_light.light_color = Color(0, 1, 1, 1)
	add_child(flash_light)
	
	# Animate flash
	var tween = create_tween()
	tween.tween_property(flash_light, "light_energy", 0.0, 0.3)
	tween.tween_callback(func(): flash_light.queue_free())
	
	# Scale bounce effect
	var bounce_tween = create_tween()
	bounce_tween.tween_property(model, "scale", Vector3(1.3, 0.8, 1.3), 0.1)
	bounce_tween.tween_property(model, "scale", Vector3(1.0, 1.0, 1.0), 0.2)
	
	# Play sound effect (placeholder)
	if jump_sound:
		jump_sound.play()

func _on_cooldown_timeout():
	is_cooling_down = false

func set_jump_properties(force: float, direction: Vector3):
	jump_force = force
	jump_direction = direction.normalized()
	
	# Update visual if needed
	if is_inside_tree():
		setup_jump_pad_appearance()
