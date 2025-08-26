extends EnemyBase
class_name DroneEnemy

var flight_height: float = 3.0
var hover_amplitude: float = 0.5
var projectile_scene: PackedScene = null
var shoot_cooldown: float = 1.5
var last_shot_time: float = 0.0

func _ready():
	# Drone-specific stats
	enemy_type = "drone"
	enemy_name = "Drone"
	health = 60
	max_health = 60
	speed = 4.0
	chase_speed = 6.0
	detection_range = 18.0
	attack_range = 12.0  # Ranged attacks
	attack_damage = 20
	patrol_radius = 15.0
	xp_reward = 20
	
	# Setup flight position
	global_position.y += flight_height
	
	# Call parent ready
	super._ready()

func setup_drone_model():
	# Create a sleeker, technological-looking model
	if model and model.has_node("Body"):
		var body = model.get_node("Body")
		body.scale = Vector3(1.0, 0.6, 1.2)  # Flatter, longer
		
		if model.has_node("Head"):
			var head = model.get_node("Head")
			head.scale = Vector3(0.8, 0.8, 0.8)  # Smaller head (sensor pod)
		
		# Remove legs for drones
		if model.has_node("LeftLeg"):
			model.get_node("LeftLeg").visible = false
		if model.has_node("RightLeg"):
			model.get_node("RightLeg").visible = false
		
		# Modify arms to look like weapon pods
		if model.has_node("LeftArm") and model.has_node("RightArm"):
			var left_arm = model.get_node("LeftArm")
			var right_arm = model.get_node("RightArm")
			left_arm.scale = Vector3(0.8, 0.8, 1.4)  # Elongated weapon pods
			right_arm.scale = Vector3(0.8, 0.8, 1.4)

func _physics_process(delta):
	if is_dead:
		return
	
	# Override gravity for flying
	# Add slight downward drift instead of full gravity
	velocity.y -= gravity * delta * 0.1
	
	# Maintain flight height
	maintain_flight_height()
	
	# Update timers
	state_timer += delta
	movement_timer += delta
	direction_change_timer += delta
	last_communication_time += delta
	last_shot_time += delta
	
	# Update AI state machine
	update_ai_state(delta)
	
	# Handle movement
	handle_movement(delta)
	
	# Apply movement
	move_and_slide()
	
	# Handle animations
	handle_animations(delta)
	
	# AI coordination communication
	handle_ai_communication(delta)

func maintain_flight_height():
	var target_y = spawn_position.y + flight_height
	var current_y = global_position.y
	
	# Smoothly adjust to maintain flight height
	if abs(current_y - target_y) > 0.5:
		var y_adjustment = (target_y - current_y) * 2.0
		velocity.y += y_adjustment

func handle_animations(delta):
	if not model:
		return
	
	# Floating/hovering animation
	animate_hovering(delta)
	
	# State-specific animations
	if current_state == State.PATROL:
		animate_drone_patrol()
	elif current_state == State.CHASE:
		animate_drone_pursuit()
	elif current_state == State.ATTACK:
		animate_drone_combat()

func animate_hovering(_delta):
	var time = Time.get_ticks_msec() * 0.003
	
	if model.has_node("Body"):
		var body = model.get_node("Body")
		# Gentle hovering bob
		body.position.y = sin(time * 2) * hover_amplitude
		# Slight rotation for technological feel
		body.rotation.y = sin(time * 0.5) * 0.1

func animate_drone_patrol():
	var time = Time.get_ticks_msec() * 0.002
	
	if model.has_node("Head"):
		var head = model.get_node("Head")
		# Scanning motion
		head.rotation.y = sin(time * 2) * 0.8
		head.rotation.x = sin(time * 1.5) * 0.2

func animate_drone_pursuit():
	if model.has_node("Head"):
		var head = model.get_node("Head")
		# Lock onto target
		if player:
			var look_direction = (player.global_position - global_position).normalized()
			var target_y_rotation = atan2(-look_direction.x, -look_direction.z) - rotation.y
			head.rotation.y = lerp_angle(head.rotation.y, target_y_rotation, 0.1)

func animate_drone_combat():
	var time = Time.get_ticks_msec() * 0.005
	
	if model.has_node("LeftArm") and model.has_node("RightArm"):
		var left_arm = model.get_node("LeftArm")
		var right_arm = model.get_node("RightArm")
		
		# Weapon charging animation
		left_arm.rotation.z = sin(time * 4) * 0.2
		right_arm.rotation.z = -sin(time * 4) * 0.2

func get_chase_direction() -> Vector3:
	if not player:
		return Vector3.ZERO
	
	# Drones try to maintain distance while following
	var to_player = player.global_position - global_position
	var distance = to_player.length()
	
	if distance < attack_range * 0.8:
		# Too close, back away while maintaining sight
		var direction = -to_player.normalized()
		direction.y = 0  # Don't change altitude while backing away
		return direction
	elif distance > attack_range * 1.2:
		# Too far, get closer
		var direction = to_player.normalized()
		direction.y = 0
		return direction
	else:
		# Good distance, circle around player
		var circle_direction = to_player.normalized().rotated(Vector3.UP, PI/2)
		circle_direction.y = 0
		return circle_direction

func get_flanking_direction() -> Vector3:
	if not player:
		return Vector3.ZERO
	
	# Drones use vertical flanking - rise or lower while circling
	var to_player = (player.global_position - global_position).normalized()
	var flanking_angle = PI / 4 * (1 if randf() > 0.5 else -1)
	var flanking_direction = to_player.rotated(Vector3.UP, flanking_angle)
	
	# Add vertical component for 3D flanking
	flanking_direction.y = randf_range(-0.3, 0.3)
	return flanking_direction.normalized()

func perform_attack():
	if not player or last_shot_time < shoot_cooldown:
		return
	
	# Drones shoot projectiles instead of melee
	shoot_projectile()
	last_shot_time = 0.0
	
	# Look directly at player
	var look_direction = (player.global_position - global_position).normalized()
	rotation.y = atan2(-look_direction.x, -look_direction.z)
	
	# Attack animation
	animate_drone_shooting()
	
	print(enemy_name + " fired projectile!")

func shoot_projectile():
	# Create a simple projectile
	var projectile = create_projectile()
	if projectile:
		get_tree().current_scene.add_child(projectile)
		
		# Position at drone
		projectile.global_position = global_position + Vector3(0, -0.5, 0)
		
		# Aim at player
		var direction = (player.global_position - global_position).normalized()
		projectile.set_direction(direction, attack_damage)

func create_projectile():
	# Create a simple energy bolt projectile
	var projectile = RigidBody3D.new()
	
	# Add mesh
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.1
	sphere_mesh.height = 0.2
	mesh_instance.mesh = sphere_mesh
	projectile.add_child(mesh_instance)
	
	# Add collision
	var collision = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.1
	collision.shape = sphere_shape
	projectile.add_child(collision)
	
	# Add material - glowing effect
	var material = StandardMaterial3D.new()
	material.emission = Color.CYAN
	material.emission_energy = 2.0
	mesh_instance.material_override = material
	
	# Add script for projectile behavior
	var script_code = """
extends RigidBody3D

var damage: int = 20
var speed: float = 15.0
var lifetime: float = 3.0
var direction: Vector3 = Vector3.ZERO

func set_direction(dir: Vector3, dmg: int):
	direction = dir
	damage = dmg
	linear_velocity = direction * speed

func _ready():
	# Remove after lifetime
	var timer = get_tree().create_timer(lifetime)
	timer.timeout.connect(queue_free)
	
	# Connect collision
	body_entered.connect(_on_body_entered)

func _on_body_entered(body):
	if body.has_method('take_damage') and body.is_in_group('player'):
		body.take_damage(damage)
		queue_free()
	elif not body.is_in_group('enemies'):
		queue_free()
"""
	
	var projectile_script = GDScript.new()
	projectile_script.source_code = script_code
	projectile.set_script(projectile_script)
	
	return projectile

func animate_drone_shooting():
	if not model:
		return
	
	var tween = create_tween()
	
	# Weapon flash animation
	if model.has_node("LeftArm") and model.has_node("RightArm"):
		var left_arm = model.get_node("LeftArm")
		var right_arm = model.get_node("RightArm")
		
		# Recoil effect
		tween.parallel().tween_property(left_arm, "position", Vector3(-0.1, 0, -0.2), 0.1)
		tween.parallel().tween_property(right_arm, "position", Vector3(0.1, 0, -0.2), 0.1)
		tween.parallel().tween_property(left_arm, "position", Vector3(0, 0, 0), 0.2)
		tween.parallel().tween_property(right_arm, "position", Vector3(0, 0, 0), 0.2)
	
	# Body recoil
	if model.has_node("Body"):
		var body = model.get_node("Body")
		tween.parallel().tween_property(body, "position", body.position + Vector3(0, 0, 0.1), 0.1)
		tween.parallel().tween_property(body, "position", body.position, 0.2)

func flash_damage():
	if not model or not model.has_node("Body"):
		return
	
	var body = model.get_node("Body")
	var material = body.get_surface_override_material(0)
	if not material:
		material = StandardMaterial3D.new()
		body.set_surface_override_material(0, material)
	
	var tween = create_tween()
	# Blue flash for drone (technological)
	tween.tween_property(material, "emission", Color(0.2, 0.5, 1), 0.1)
	tween.tween_property(material, "emission", Color(0.05, 0.1, 0.3), 0.2)

func should_try_flanking() -> bool:
	# Drones frequently use flanking maneuvers
	return randf() < 0.6

# Override AI behavior for aerial combat
func update_ai_state(delta):
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	can_see_player = check_line_of_sight_to_player()
	
	# Update shared knowledge if player spotted
	if can_see_player:
		shared_player_position = player.global_position
		enemy_spotted_player.emit(self, player.global_position)
	
	match current_state:
		State.PATROL:
			if can_see_player and distance_to_player <= detection_range:
				change_state(State.CHASE)
				print(enemy_name + " spotted player, engaging")
			elif should_investigate_shared_knowledge():
				change_state(State.SEARCH)
		
		State.SEARCH:
			if can_see_player and distance_to_player <= detection_range:
				change_state(State.CHASE)
			elif state_timer > 10.0:  # Search timeout for drones
				change_state(State.PATROL)
		
		State.CHASE:
			if distance_to_player <= attack_range and can_see_player:
				change_state(State.ATTACK)
			elif distance_to_player > detection_range * 2.5:
				if should_try_flanking():
					change_state(State.FLANKING)
				else:
					change_state(State.SEARCH)
					print(enemy_name + " lost target, searching")
		
		State.FLANKING:
			if can_see_player and distance_to_player <= attack_range:
				change_state(State.ATTACK)
			elif state_timer > 5.0:  # Flanking timeout
				change_state(State.CHASE)
		
		State.ATTACK:
			if distance_to_player > attack_range * 1.5 or not can_see_player:
				change_state(State.CHASE)
			elif last_shot_time >= shoot_cooldown:
				perform_attack()

func die():
	# Drones crash when destroyed
	is_dead = true
	current_state = State.DEAD
	
	# Award XP to player
	award_xp_to_player()
	
	# Disable collision
	var collision = get_node_or_null("CollisionShape3D")
	if collision:
		collision.disabled = true
	
	# Crash animation - fall and explode
	var tween = create_tween()
	if model:
		# Spinning crash
		tween.parallel().tween_property(model, "rotation", Vector3(PI*2, PI*2, PI*2), 2.0)
		tween.parallel().tween_property(self, "global_position", global_position + Vector3(0, -10, 0), 2.0)
		tween.parallel().tween_property(model, "scale", Vector3(0.1, 0.1, 0.1), 2.0)
	
	# Create explosion effect
	tween.tween_callback(create_explosion_effect)
	
	# Emit signal for scoring
	enemy_died.emit(self)
	
	# Remove after explosion
	tween.tween_interval(1.0)
	tween.tween_callback(queue_free)
	
	print(enemy_name + " crashed!")

func create_explosion_effect():
	# Simple explosion effect
	var explosion = Node3D.new()
	get_tree().current_scene.add_child(explosion)
	explosion.global_position = global_position
	
	# Create several small particles
	for i in range(5):
		var particle = MeshInstance3D.new()
		var cube_mesh = BoxMesh.new()
		cube_mesh.size = Vector3(0.2, 0.2, 0.2)
		particle.mesh = cube_mesh
		
		var material = StandardMaterial3D.new()
		material.emission = Color.ORANGE
		material.emission_energy = 3.0
		particle.material_override = material
		
		explosion.add_child(particle)
		
		# Random directions
		var direction = Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var tween = create_tween()
		tween.parallel().tween_property(particle, "position", direction * 2.0, 0.5)
		tween.parallel().tween_property(particle, "scale", Vector3.ZERO, 0.5)
	
	# Remove explosion after animation
	var cleanup_timer = get_tree().create_timer(1.0)
	cleanup_timer.timeout.connect(func(): if is_instance_valid(explosion): explosion.queue_free())

# Override movement for flying behavior
func apply_movement(move_direction: Vector3, target_speed: float, delta: float):
	if target_speed > 0 and move_direction.length() > 0.1:
		# Smooth flying movement in all 3 dimensions
		velocity.x = lerp(velocity.x, move_direction.x * target_speed, delta * 4.0)
		velocity.z = lerp(velocity.z, move_direction.z * target_speed, delta * 4.0)
		
		# Allow Y movement for drones
		if abs(move_direction.y) > 0.1:
			velocity.y = lerp(velocity.y, move_direction.y * target_speed * 0.5, delta * 3.0)
		
		# Face movement direction quickly (flying units are more agile)
		var target_rotation = atan2(-move_direction.x, -move_direction.z)
		rotation.y = lerp_angle(rotation.y, target_rotation, delta * 6.0)
	else:
		# Smooth deceleration
		velocity.x = move_toward(velocity.x, 0, target_speed * 3)
		velocity.z = move_toward(velocity.z, 0, target_speed * 3)
