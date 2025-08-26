extends EnemyBase
class_name TankEnemy

func _ready():
	# Tank-specific stats
	enemy_type = "tank"
	enemy_name = "Tank"
	health = 200
	max_health = 200
	speed = 2.0
	chase_speed = 3.0
	detection_range = 10.0
	attack_range = 3.0
	attack_damage = 40
	patrol_radius = 6.0
	xp_reward = 30
	
	# Call parent ready
	super._ready()

func setup_tank_model():
	# Create a bulky, armored-looking model
	if model and model.has_node("Body"):
		var body = model.get_node("Body")
		body.scale = Vector3(1.4, 1.2, 1.4)  # Bigger, wider
		
		if model.has_node("Head"):
			var head = model.get_node("Head")
			head.scale = Vector3(1.2, 1.0, 1.2)  # Wider head
		
		# Make arms thicker
		if model.has_node("LeftArm") and model.has_node("RightArm"):
			var left_arm = model.get_node("LeftArm")
			var right_arm = model.get_node("RightArm")
			left_arm.scale = Vector3(1.3, 1.1, 1.3)
			right_arm.scale = Vector3(1.3, 1.1, 1.3)
		
		# Shorter, thicker legs
		if model.has_node("LeftLeg") and model.has_node("RightLeg"):
			var left_leg = model.get_node("LeftLeg")
			var right_leg = model.get_node("RightLeg")
			left_leg.scale = Vector3(1.2, 0.9, 1.2)
			right_leg.scale = Vector3(1.2, 0.9, 1.2)

func handle_animations(delta):
	if not model:
		return
	
	# Heavy, slow movements
	if velocity.length() > 0.1:
		animate_tank_movement(delta)
	
	# Steady, intimidating presence
	if current_state == State.PATROL:
		animate_tank_patrol()
	elif current_state == State.CHASE:
		animate_tank_charge()
	elif current_state == State.ATTACK:
		animate_tank_attack_stance()

func animate_tank_movement(_delta):
	var time = Time.get_ticks_msec() * 0.008  # Slower animation
	var walk_cycle = sin(time)
	
	if model.has_node("LeftArm") and model.has_node("RightArm"):
		var left_arm = model.get_node("LeftArm")
		var right_arm = model.get_node("RightArm")
		
		# Minimal arm swing - tanks are focused
		left_arm.rotation.x = walk_cycle * 0.2
		right_arm.rotation.x = -walk_cycle * 0.2
	
	if model.has_node("LeftLeg") and model.has_node("RightLeg"):
		var left_leg = model.get_node("LeftLeg")
		var right_leg = model.get_node("RightLeg")
		
		# Heavy, deliberate steps
		left_leg.rotation.x = walk_cycle * 0.25
		right_leg.rotation.x = -walk_cycle * 0.25
	
	# Heavy body sway
	if model.has_node("Body"):
		var body = model.get_node("Body")
		body.position.y = 1.2 + sin(time) * 0.03
		body.rotation.z = sin(time * 0.5) * 0.05  # Slight sway

func animate_tank_patrol():
	var time = Time.get_ticks_msec() * 0.001
	
	if model.has_node("Head"):
		var head = model.get_node("Head")
		# Slow, methodical head scanning
		head.rotation.y = sin(time) * 0.3

func animate_tank_charge():
	if model.has_node("Body"):
		var body = model.get_node("Body")
		# Lean forward when charging
		body.rotation.x = -0.1
	
	if model.has_node("Head"):
		var head = model.get_node("Head")
		# Fixed forward gaze when charging
		if player:
			var look_direction = (player.global_position - global_position).normalized()
			var target_y_rotation = atan2(-look_direction.x, -look_direction.z) - rotation.y
			head.rotation.y = lerp_angle(head.rotation.y, target_y_rotation, 0.05)

func animate_tank_attack_stance():
	var time = Time.get_ticks_msec() * 0.003
	
	if model.has_node("Body"):
		var body = model.get_node("Body")
		# Aggressive stance
		body.rotation.x = -0.2
		body.scale = Vector3(1.4, 1.2, 1.4) + Vector3(0.1, 0, 0.1) * sin(time * 2)

func get_chase_direction() -> Vector3:
	if not player:
		return Vector3.ZERO
	
	# Tanks charge directly - no fancy movement
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0
	return direction

func get_flanking_direction() -> Vector3:
	# Tanks don't really flank - they just advance
	return get_chase_direction()

func perform_attack():
	if not player or not player.has_method("take_damage"):
		return
	
	# Tanks have slower but devastating attacks
	if attack_timer:
		attack_timer.wait_time = 2.0  # Much slower attacks
		attack_timer.start()
	
	# Look directly at player
	var look_direction = (player.global_position - global_position).normalized()
	rotation.y = atan2(-look_direction.x, -look_direction.z)
	
	# Deal heavy damage
	player.take_damage(attack_damage)
	
	# Heavy attack animation
	animate_tank_attack()
	
	# Screen shake effect for heavy hit
	create_screen_shake()
	
	print(enemy_name + " dealt devastating blow!")

func animate_tank_attack():
	if not model:
		return
	
	var tween = create_tween()
	
	# Heavy slam attack
	if model.has_node("RightArm"):
		var right_arm = model.get_node("RightArm")
		
		# Wind up
		tween.tween_property(right_arm, "rotation", Vector3(-2.0, 0, 0), 0.5)
		# Slam down
		tween.tween_property(right_arm, "rotation", Vector3(1.0, 0, 0), 0.3)
		# Return to normal
		tween.tween_property(right_arm, "rotation", Vector3(0, 0, 0), 0.7)
	
	# Body movement during attack
	if model.has_node("Body"):
		var body = model.get_node("Body")
		tween.parallel().tween_property(body, "rotation", Vector3(-0.5, 0, 0), 0.5)
		tween.parallel().tween_property(body, "rotation", Vector3(0.3, 0, 0), 0.3)
		tween.parallel().tween_property(body, "rotation", Vector3(0, 0, 0), 0.7)
		
		# Scale up during attack for impact
		tween.parallel().tween_property(body, "scale", Vector3(1.5, 1.3, 1.5), 0.3)
		tween.parallel().tween_property(body, "scale", Vector3(1.4, 1.2, 1.4), 0.5)

func create_screen_shake():
	# Signal to camera or game manager for screen shake
	var game_manager = get_tree().get_first_node_in_group("game_manager")
	if game_manager and game_manager.has_method("create_screen_shake"):
		game_manager.create_screen_shake(0.5, 0.3)

func flash_damage():
	if not model or not model.has_node("Body"):
		return
	
	var body = model.get_node("Body")
	var material = body.get_surface_override_material(0)
	if not material:
		material = StandardMaterial3D.new()
		body.set_surface_override_material(0, material)
	
	var tween = create_tween()
	# Orange flash for tank (armored)
	tween.tween_property(material, "emission", Color(1, 0.5, 0), 0.1)
	tween.tween_property(material, "emission", Color(0.3, 0.15, 0), 0.3)

func should_try_flanking() -> bool:
	# Tanks rarely flank - they prefer direct assault
	return randf() < 0.1

func take_damage(damage: int, _hit_position: Vector3 = Vector3.ZERO):
	# Tanks have damage resistance
	var reduced_damage = max(1, damage - 5)  # 5 point armor
	super.take_damage(reduced_damage, _hit_position)
	
	print(enemy_name + " absorbed some damage! (" + str(reduced_damage) + " taken)")

# Override AI behavior for tank mentality
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
				print(enemy_name + " spotted player, beginning relentless pursuit")
			elif should_investigate_shared_knowledge():
				change_state(State.SEARCH)
		
		State.SEARCH:
			if can_see_player and distance_to_player <= detection_range:
				change_state(State.CHASE)
			elif state_timer > 12.0:  # Tanks search longer
				change_state(State.PATROL)
		
		State.CHASE:
			if distance_to_player <= attack_range:
				change_state(State.ATTACK)
			elif distance_to_player > detection_range * 3.0:  # Tanks pursue longer
				change_state(State.SEARCH)
				print(enemy_name + " lost player, searching area")
		
		State.FLANKING:
			# Tanks don't really flank, just treat as chase
			change_state(State.CHASE)
		
		State.ATTACK:
			if distance_to_player > attack_range * 1.8:
				change_state(State.CHASE)
			elif attack_timer and attack_timer.is_stopped():
				perform_attack()

func get_patrol_direction() -> Vector3:
	if global_position.distance_to(patrol_target) < 1.5:  # Closer tolerance for tanks
		set_new_patrol_target()
	
	var direction = (patrol_target - global_position).normalized()
	direction.y = 0
	return direction

func apply_movement(move_direction: Vector3, target_speed: float, delta: float):
	# Tanks are harder to stop and change direction
	if target_speed > 0 and move_direction.length() > 0.1:
		# Check for obstacles ahead
		if not is_obstacle_ahead(move_direction):
			# Tanks build momentum
			velocity.x = lerp(velocity.x, move_direction.x * target_speed, delta * 2.0)
			velocity.z = lerp(velocity.z, move_direction.z * target_speed, delta * 2.0)
			
			# Face movement direction slowly
			var target_rotation = atan2(-move_direction.x, -move_direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * 3.0)
		else:
			# Tanks try to break through obstacles more aggressively
			var avoid_direction = get_avoidance_direction(move_direction)
			if avoid_direction.length() > 0.1:
				velocity.x = avoid_direction.x * target_speed * 0.7
				velocity.z = avoid_direction.z * target_speed * 0.7
			else:
				# If no way around, just push forward slowly
				velocity.x = move_direction.x * target_speed * 0.3
				velocity.z = move_direction.z * target_speed * 0.3
	else:
		# Tanks take longer to stop
		velocity.x = move_toward(velocity.x, 0, target_speed * 1.5)
		velocity.z = move_toward(velocity.z, 0, target_speed * 1.5)
