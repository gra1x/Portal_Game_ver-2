extends Area3D

enum PickupType {
	HEALTH,
	AMMO
}

@export var pickup_type: PickupType = PickupType.HEALTH
@export var health_amount: int = 25
@export var ammo_amount: int = 15
@export var respawn_time: float = 10.0

var is_collected: bool = false
var original_position: Vector3

@onready var model: Node3D = $Model
@onready var collect_sound: AudioStreamPlayer3D = $CollectSound
@onready var respawn_timer: Timer = $RespawnTimer

func _ready():
	# Store original position for respawning
	original_position = global_position
	
	# Connect signals
	body_entered.connect(_on_body_entered)
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	respawn_timer.wait_time = respawn_time
	
	# Setup appearance based on type
	setup_pickup_appearance()
	
	# Add floating animation
	start_floating_animation()

func setup_pickup_appearance():
	# Create different models for health and ammo
	var mesh_instance = MeshInstance3D.new()
	var material = StandardMaterial3D.new()
	
	match pickup_type:
		PickupType.HEALTH:
			# Health pickup - red cross
			var box_mesh = BoxMesh.new()
			box_mesh.size = Vector3(0.8, 0.8, 0.2)
			mesh_instance.mesh = box_mesh
			material.albedo_color = Color.RED
			material.emission_enabled = true
			material.emission = Color(1, 0.3, 0.3)
		
		PickupType.AMMO:
			# Ammo pickup - yellow cylinder
			var cylinder_mesh = CylinderMesh.new()
			cylinder_mesh.height = 0.6
			cylinder_mesh.top_radius = 0.3
			cylinder_mesh.bottom_radius = 0.3
			mesh_instance.mesh = cylinder_mesh
			material.albedo_color = Color.YELLOW
			material.emission_enabled = true
			material.emission = Color(1, 1, 0.3)
	
	mesh_instance.set_surface_override_material(0, material)
	model.add_child(mesh_instance)
	
	# Add a light for glow effect
	var light = OmniLight3D.new()
	light.light_energy = 1.5
	light.omni_range = 3.0
	match pickup_type:
		PickupType.HEALTH:
			light.light_color = Color(1, 0.3, 0.3)
		PickupType.AMMO:
			light.light_color = Color(1, 1, 0.3)
	model.add_child(light)

func start_floating_animation():
	# Create floating up and down animation
	var tween = create_tween()
	tween.set_loops()
	tween.tween_property(model, "position:y", 0.3, 1.0)
	tween.tween_property(model, "position:y", -0.3, 1.0)

func _physics_process(delta):
	# Rotate the pickup
	if not is_collected:
		model.rotation.y += delta * 2.0

func _on_body_entered(body):
	if is_collected:
		return
	
	if body.is_in_group("player"):
		collect_pickup(body)

func collect_pickup(player):
	if is_collected:
		return
	
	var pickup_successful = false
	
	match pickup_type:
		PickupType.HEALTH:
			if player.health < player.max_health:
				player.heal(health_amount)
				pickup_successful = true
				print("Player collected health pickup: +", health_amount, " health")
		
		PickupType.AMMO:
			if player.ammo < player.max_ammo:
				player.add_ammo(ammo_amount)
				pickup_successful = true
				print("Player collected ammo pickup: +", ammo_amount, " ammo")
	
	if pickup_successful:
		is_collected = true
		
		# Hide the pickup
		model.visible = false
		
		# Disable collision
		$CollisionShape3D.disabled = true
		
		# Play collect effect
		play_collect_effect()
		
		# Start respawn timer
		respawn_timer.start()

func play_collect_effect():
	# Create pickup effect
	var effect_light = OmniLight3D.new()
	effect_light.light_energy = 5.0
	effect_light.omni_range = 5.0
	
	match pickup_type:
		PickupType.HEALTH:
			effect_light.light_color = Color(1, 0.3, 0.3)
		PickupType.AMMO:
			effect_light.light_color = Color(1, 1, 0.3)
	
	add_child(effect_light)
	
	# Animate the effect
	var tween = create_tween()
	tween.tween_property(effect_light, "light_energy", 0.0, 0.5)
	tween.tween_callback(func(): effect_light.queue_free())

func _on_respawn_timer_timeout():
	# Respawn the pickup
	is_collected = false
	model.visible = true
	$CollisionShape3D.disabled = false
	
	# Reset position
	global_position = original_position
	
	# Restart floating animation
	start_floating_animation()
	
	print("Pickup respawned at: ", global_position)
