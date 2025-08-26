extends Area3D

var portal_type: String = "blue"  # "blue" or "orange"
var paired_portal: Node3D = null
var is_teleporting: bool = false

@onready var portal_mesh: MeshInstance3D = $PortalMesh
@onready var portal_ring: MeshInstance3D = $PortalRing
@onready var portal_light: OmniLight3D = $PortalLight

func _ready():
	# Connect signals for teleportation
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func set_portal_type(type: String):
	portal_type = type
	update_portal_appearance()

func set_paired_portal(portal: Node3D):
	paired_portal = portal

func update_portal_appearance():
	# Create new materials instead of trying to access null ones
	var portal_material = StandardMaterial3D.new()
	var ring_material = StandardMaterial3D.new()
	
	# Set common properties
	portal_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	portal_material.emission_enabled = true
	ring_material.emission_enabled = true
	
	if portal_type == "blue":
		# Blue portal
		portal_material.albedo_color = Color(0, 0.5, 1, 0.8)
		portal_material.emission = Color(0, 0.3, 0.8, 1)
		ring_material.albedo_color = Color(0, 0.5, 1, 1)
		ring_material.emission = Color(0, 0.3, 0.8, 1)
		portal_light.light_color = Color(0, 0.5, 1, 1)
	else:
		# Orange portal
		portal_material.albedo_color = Color(1, 0.5, 0, 0.8)
		portal_material.emission = Color(0.8, 0.3, 0, 1)
		ring_material.albedo_color = Color(1, 0.5, 0, 1)
		ring_material.emission = Color(0.8, 0.3, 0, 1)
		portal_light.light_color = Color(1, 0.5, 0, 1)
	
	# Apply materials
	portal_mesh.set_surface_override_material(0, portal_material)
	portal_ring.set_surface_override_material(0, ring_material)

func _on_body_entered(body):
	if paired_portal and not is_teleporting:
		if body.is_in_group("player"):
			teleport_player(body)
		elif body.is_in_group("enemies"):
			teleport_enemy(body)

func _on_body_exited(body):
	if body.is_in_group("player") or body.is_in_group("enemies"):
		is_teleporting = false

func teleport_player(player):
	if not paired_portal or is_teleporting:
		return
	
	# Prevent infinite teleportation loops
	is_teleporting = true
	paired_portal.is_teleporting = true
	
	# Calculate exit position and direction
	var exit_position = paired_portal.global_position
	var exit_direction = -paired_portal.global_transform.basis.z
	
	# Offset player slightly in front of exit portal
	var teleport_position = exit_position + exit_direction * 2.0
	
	# Calculate player's velocity relative to entrance portal
	var entrance_direction = -global_transform.basis.z
	var player_velocity = player.velocity
	
	# Transform velocity to exit portal's orientation
	var velocity_magnitude = player_velocity.length()
	var new_velocity = exit_direction * velocity_magnitude
	
	# Teleport the player
	player.global_position = teleport_position
	player.velocity = new_velocity
	
	# Reset teleportation flags after a short delay
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func(): 
		is_teleporting = false
		if paired_portal:
			paired_portal.is_teleporting = false
	)
	
	print("Player teleported from ", portal_type, " portal to ", paired_portal.portal_type, " portal")

func teleport_enemy(enemy):
	if not paired_portal or is_teleporting:
		return
	
	# Prevent infinite teleportation loops
	is_teleporting = true
	paired_portal.is_teleporting = true
	
	# Calculate exit position and direction
	var exit_position = paired_portal.global_position
	var exit_direction = -paired_portal.global_transform.basis.z
	
	# Offset enemy slightly in front of exit portal
	var teleport_position = exit_position + exit_direction * 2.0
	
	# Calculate enemy's velocity relative to entrance portal
	var enemy_velocity = enemy.velocity
	
	# Transform velocity to exit portal's orientation
	var velocity_magnitude = enemy_velocity.length()
	var new_velocity = exit_direction * velocity_magnitude
	
	# Teleport the enemy
	enemy.global_position = teleport_position
	enemy.velocity = new_velocity
	
	# If enemy has AI state, briefly interrupt it to handle teleportation
	if enemy.has_method("handle_portal_teleportation"):
		enemy.handle_portal_teleportation()
	
	# Reset teleportation flags after a short delay
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(func(): 
		is_teleporting = false
		if paired_portal:
			paired_portal.is_teleporting = false
	)
	
	print("Enemy teleported from ", portal_type, " portal to ", paired_portal.portal_type, " portal")

func _physics_process(_delta):
	# Add some portal animation
	portal_ring.rotation.z += 0.02
	
	# Pulse the light
	var pulse = sin(Time.get_ticks_msec() * 0.003) * 0.3 + 0.7
	portal_light.light_energy = pulse
