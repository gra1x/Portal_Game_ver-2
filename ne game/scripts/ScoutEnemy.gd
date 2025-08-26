extends EnemyBase
class_name ScoutEnemy

func _ready():
	# Scout-specific stats
	enemy_type = "scout"
	enemy_name = "Scout"
	health = 40
	max_health = 40
	speed = 6.0
	chase_speed = 8.0
	detection_range = 15.0
	attack_range = 1.8
	attack_damage = 15
	patrol_radius = 12.0
	xp_reward = 15
	
	# Call parent ready
	super._ready()

func setup_scout_model():
	# Create a more agile-looking model
	if model and model.has_node("Body"):
		var body = model.get_node("Body")
		body.scale = Vector3(0.8, 1.1, 0.8)  # Thinner, taller
		
		if model.has_node("Head"):
			var head = model.get_node("Head")
			head.scale = Vector3(0.9, 0.9, 0.9)  # Smaller head
		
		# Make legs longer for speed appearance
		if model.has_node("LeftLeg") and model.has_node("RightLeg"):
			var left_leg = model.get_node("LeftLeg")
			var right_leg = model.get_node("RightLeg")
			left_leg.scale = Vector3(0.8, 1.2, 0.8)
			right_leg.scale = Vector3(0.8, 1.2, 0.8)

func handle_animations(delta):
	if not model:
		return
	
	# Fast, jittery movements
	if velocity.length() > 0.1:
		animate_scout_movement(delta)
	
	# Nervous head movements when not chasing
	if current_state == State.PATROL or current_state == State.SEARCH:
		animate_alert_scanning()
	elif current_state == State.CHASE:
		animate_aggressive_pursuit()

func animate_scout_movement(_delta):
	var time = Time.get_ticks_msec() * 0.015  # Faster animation
	var walk_cycle = sin(time)
	
	if model.has_node("LeftArm") and model.has_node("RightArm"):
		var left_arm = model.get_node("LeftArm")
		var right_arm = model.get_node("RightArm")
		
		# Exaggerated arm swing
		left_arm.rotation.x = walk_cycle * 0.5
		right_arm.rotation.x = -walk_cycle * 0.5
	
	if model.has_node("LeftLeg") and model.has_node("RightLeg"):
		var left_leg = model.get_node("LeftLeg")
		var right_leg = model.get_node("RightLeg")
		
		# Quick, light steps
		left_leg.rotation.x = walk_cycle * 0.4
		right_leg.rotation.x = -walk_cycle * 0.4
	
	# Fast body bob
	if model.has_node("Body"):
		var body = model.get_node("Body")
		body.position.y = 0.7 + sin(time * 2) * 0.08

func animate_alert_scanning():
	var time = Time.get_ticks_msec() * 0.002
	
	if model.has_node("Head"):
		var head = model.get_node("Head")
		# Quick head movements scanning for threats
		head.rotation.y = sin(time * 4) * 0.7
		head.rotation.x = sin(time * 3) * 0.2

func animate_aggressive_pursuit():
	if model.has_node("Head"):
		var head = model.get_node("Head")
		# Lock onto target with slight bob
		if player:
			var look_direction = (player.global_position - global_position).normalized()
			var target_y_rotation = atan2(-look_direction.x, -look_direction.z) - rotation.y
			head.rotation.y = lerp_angle(head.rotation.y, target_y_rotation, 0.1)

func get_chase_direction() -> Vector3:
	if not player:
		return Vector3.ZERO
	
	# Scouts use more erratic movement when chasing
	var base_direction = (player.global_position - global_position).normalized()
	base_direction.y = 0
	
	# Add some randomness to make movement unpredictable
	var random_offset = Vector3(
		randf_range(-0.3, 0.3),
		0,
		randf_range(-0.3, 0.3)
	)
	
	return (base_direction + random_offset).normalized()

func get_flanking_direction() -> Vector3:
	if not player:
		return Vector3.ZERO
	
	# Scouts are more aggressive with flanking
	var to_player = (player.global_position - global_position).normalized()
	var flanking_angle = PI / 2 * (1 if randf() > 0.5 else -1)  # More extreme flanking
	var flanking_direction = to_player.rotated(Vector3.UP, flanking_angle)
	flanking_direction.y = 0
	return flanking_direction

func perform_attack():
	if not player or not player.has_method("take_damage"):
		return
	
	# Scouts perform quick, multiple hits
	if attack_timer:
		attack_timer.wait_time = 0.8  # Faster attacks
		attack_timer.start()
	
	# Look directly at player
	var look_direction = (player.global_position - global_position).normalized()
	rotation.y = atan2(-look_direction.x, -look_direction.z)
	
	# Deal damage
	player.take_damage(attack_damage)
	
	# Quick attack animation
	animate_scout_attack()
	
	print(enemy_name + " performed quick strike!")

func animate_scout_attack():
	if not model:
		return
	
	var tween = create_tween()
	
	# Quick double-strike animation
	if model.has_node("RightArm") and model.has_node("LeftArm"):
		var right_arm = model.get_node("RightArm")
		var left_arm = model.get_node("LeftArm")
		
		# First strike
		tween.parallel().tween_property(right_arm, "rotation", Vector3(-1.5, 0, 0), 0.1)
		tween.tween_property(right_arm, "rotation", Vector3(0, 0, 0), 0.15)
		
		# Second strike with other arm
		tween.parallel().tween_property(left_arm, "rotation", Vector3(-1.5, 0, 0), 0.1)
		tween.tween_property(left_arm, "rotation", Vector3(0, 0, 0), 0.15)
	
	# Body lean into attack
	if model.has_node("Body"):
		var body = model.get_node("Body")
		tween.parallel().tween_property(body, "rotation", Vector3(0.3, 0, 0), 0.1)
		tween.parallel().tween_property(body, "rotation", Vector3(-0.2, 0, 0), 0.1)
		tween.tween_property(body, "rotation", Vector3(0, 0, 0), 0.2)

func flash_damage():
	if not model or not model.has_node("Body"):
		return
	
	var body = model.get_node("Body")
	var material = body.get_surface_override_material(0)
	if not material:
		material = StandardMaterial3D.new()
		body.set_surface_override_material(0, material)
	
	var tween = create_tween()
	# Fast red flash for scout
	tween.tween_property(material, "emission", Color(1, 0.2, 0.2), 0.05)
	tween.tween_property(material, "emission", Color(0.2, 0.05, 0.05), 0.1)

func should_try_flanking() -> bool:
	# Scouts are more likely to try flanking
	var allies_nearby = get_allies_in_range(15.0)
	return allies_nearby.size() >= 0 and randf() < 0.7  # Higher chance than base class

# Override AI behavior for more aggressive scouting
func update_ai_state(_delta):
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
				print(enemy_name + " spotted player, switching to chase")
			elif should_investigate_shared_knowledge():
				change_state(State.SEARCH)
		
		State.SEARCH:
			if can_see_player and distance_to_player <= detection_range:
				change_state(State.CHASE)
			elif state_timer > 6.0:  # Shorter search time for scouts
				change_state(State.PATROL)
		
		State.CHASE:
			if distance_to_player <= attack_range:
				change_state(State.ATTACK)
			elif distance_to_player > detection_range * 1.5:  # Scouts give up chase sooner
				if should_try_flanking():
					change_state(State.FLANKING)
				else:
					change_state(State.SEARCH)
					print(enemy_name + " lost player, searching")
		
		State.FLANKING:
			if can_see_player and distance_to_player <= attack_range:
				change_state(State.ATTACK)
			elif state_timer > 4.0:  # Faster flanking for scouts
				change_state(State.CHASE)
		
		State.ATTACK:
			if distance_to_player > attack_range * 1.3:  # Scouts stick closer
				change_state(State.CHASE)
			elif attack_timer and attack_timer.is_stopped():
				perform_attack()
