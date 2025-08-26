extends CharacterBody3D
class_name EnemyBase

# Base stats that derived classes can override
@export var health: int = 80
@export var max_health: int = 80
@export var speed: float = 3.5
@export var chase_speed: float = 5.0
@export var detection_range: float = 12.0
@export var attack_range: float = 2.5
@export var attack_damage: int = 25
@export var patrol_radius: float = 8.0
@export var xp_reward: int = 10

# Enemy type identification
@export var enemy_type: String = "basic"
@export var enemy_name: String = "Enemy"

var player: CharacterBody3D
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var is_dead: bool = false
var spawn_position: Vector3
var patrol_target: Vector3
var last_known_player_pos: Vector3
var can_see_player: bool = false
var movement_timer: float = 0.0
var direction_change_timer: float = 0.0
var current_direction: Vector3 = Vector3.ZERO

# AI coordination variables
var ai_group_id: int = -1
var last_communication_time: float = 0.0
var shared_player_position: Vector3 = Vector3.ZERO
var is_coordinating: bool = false

@onready var model: Node3D = $Model if has_node("Model") else null
@onready var attack_timer: Timer = $AttackTimer if has_node("AttackTimer") else null

signal enemy_died(enemy)
signal enemy_spotted_player(enemy, player_position)
signal enemy_lost_player(enemy)

enum State {
	PATROL,
	CHASE,
	ATTACK,
	DEAD,
	SEARCH,
	FLANKING,
	TAKING_COVER
}

var current_state = State.PATROL
var state_timer: float = 0.0

func _ready():
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")
	spawn_position = global_position
	
	# Start patrol
	set_new_patrol_target()
	
	# Connect timer signals
	if attack_timer:
		attack_timer.timeout.connect(_on_attack_timer_timeout)
	
	# Setup AI coordination
	setup_ai_coordination()
	
	print(enemy_name + " spawned at: ", global_position)

func setup_ai_coordination():
	# Assign to nearest AI group or create new one
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and enemy.has_method("get_ai_group_id"):
			var distance = global_position.distance_to(enemy.global_position)
			if distance < 15.0:  # Within coordination range
				ai_group_id = enemy.get_ai_group_id()
				break
	
	if ai_group_id == -1:
		ai_group_id = randi() % 1000  # Create new group
	
	# Add to enemies group
	add_to_group("enemies")

func get_ai_group_id() -> int:
	return ai_group_id

func _physics_process(delta):
	if is_dead:
		return
	
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta
	else:
		velocity.y = 0
	
	# Update timers
	state_timer += delta
	movement_timer += delta
	direction_change_timer += delta
	last_communication_time += delta
	
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
				print(enemy_name + " spotted player, switching to chase")
			elif should_investigate_shared_knowledge():
				change_state(State.SEARCH)
		
		State.SEARCH:
			if can_see_player and distance_to_player <= detection_range:
				change_state(State.CHASE)
			elif state_timer > 8.0:  # Search timeout
				change_state(State.PATROL)
		
		State.CHASE:
			if distance_to_player <= attack_range:
				change_state(State.ATTACK)
			elif distance_to_player > detection_range * 2.0 or not can_see_player:
				if should_try_flanking():
					change_state(State.FLANKING)
				else:
					change_state(State.SEARCH)
					print(enemy_name + " lost player, searching")
		
		State.FLANKING:
			if can_see_player and distance_to_player <= attack_range:
				change_state(State.ATTACK)
			elif state_timer > 6.0:  # Flanking timeout
				change_state(State.CHASE)
		
		State.ATTACK:
			if distance_to_player > attack_range * 1.5:
				change_state(State.CHASE)
			elif attack_timer and attack_timer.is_stopped():
				perform_attack()

func should_investigate_shared_knowledge() -> bool:
	return shared_player_position != Vector3.ZERO and \
		   global_position.distance_to(shared_player_position) < 20.0 and \
		   last_communication_time < 5.0

func should_try_flanking() -> bool:
	# Try flanking if there are other enemies in group and we're close to player
	var allies_nearby = get_allies_in_range(15.0)
	return allies_nearby.size() > 0 and randf() < 0.4

func get_allies_in_range(range: float) -> Array:
	var allies = []
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if enemy != self and enemy.has_method("get_ai_group_id") and \
		   enemy.get_ai_group_id() == ai_group_id and \
		   global_position.distance_to(enemy.global_position) <= range:
			allies.append(enemy)
	return allies

func handle_ai_communication(delta):
	# Broadcast position every few seconds to allies
	if last_communication_time > 3.0:
		broadcast_knowledge_to_allies()
		last_communication_time = 0.0

func broadcast_knowledge_to_allies():
	if shared_player_position == Vector3.ZERO:
		return
	
	var allies = get_allies_in_range(20.0)
	for ally in allies:
		if ally.has_method("receive_player_intel"):
			ally.receive_player_intel(shared_player_position)

func receive_player_intel(player_pos: Vector3):
	shared_player_position = player_pos
	last_communication_time = 0.0

func handle_movement(delta):
	var target_speed = 0.0
	var move_direction = Vector3.ZERO
	
	match current_state:
		State.PATROL:
			target_speed = speed * 0.7
			move_direction = get_patrol_direction()
		
		State.SEARCH:
			target_speed = speed * 0.8
			move_direction = get_search_direction()
		
		State.CHASE:
			target_speed = chase_speed
			move_direction = get_chase_direction()
		
		State.FLANKING:
			target_speed = speed * 1.2
			move_direction = get_flanking_direction()
		
		State.ATTACK:
			target_speed = 0.0
			# Stay in place during attack
	
	# Apply movement
	apply_movement(move_direction, target_speed, delta)

func apply_movement(move_direction: Vector3, target_speed: float, delta: float):
	if target_speed > 0 and move_direction.length() > 0.1:
		# Check for obstacles ahead
		if not is_obstacle_ahead(move_direction):
			velocity.x = move_direction.x * target_speed
			velocity.z = move_direction.z * target_speed
			
			# Face movement direction
			var target_rotation = atan2(-move_direction.x, -move_direction.z)
			rotation.y = lerp_angle(rotation.y, target_rotation, delta * 8.0)
		else:
			# Try to avoid obstacle
			var avoid_direction = get_avoidance_direction(move_direction)
			if avoid_direction.length() > 0.1:
				velocity.x = avoid_direction.x * target_speed * 0.5
				velocity.z = avoid_direction.z * target_speed * 0.5
	else:
		# Stop moving
		velocity.x = move_toward(velocity.x, 0, target_speed * 2)
		velocity.z = move_toward(velocity.z, 0, target_speed * 2)

# Virtual functions for derived classes to override
func get_patrol_direction() -> Vector3:
	if global_position.distance_to(patrol_target) < 2.0:
		set_new_patrol_target()
	
	var direction = (patrol_target - global_position).normalized()
	direction.y = 0
	return direction

func get_search_direction() -> Vector3:
	if shared_player_position != Vector3.ZERO:
		var direction = (shared_player_position - global_position).normalized()
		direction.y = 0
		return direction
	return get_patrol_direction()

func get_chase_direction() -> Vector3:
	if not player:
		return Vector3.ZERO
	
	var direction = (player.global_position - global_position).normalized()
	direction.y = 0
	return direction

func get_flanking_direction() -> Vector3:
	if not player:
		return Vector3.ZERO
	
	# Try to circle around player
	var to_player = (player.global_position - global_position).normalized()
	var flanking_angle = PI / 3 * (1 if randf() > 0.5 else -1)
	var flanking_direction = to_player.rotated(Vector3.UP, flanking_angle)
	flanking_direction.y = 0
	return flanking_direction

func is_obstacle_ahead(direction: Vector3) -> bool:
	var space_state = get_world_3d().direct_space_state
	var from = global_position + Vector3(0, 1.0, 0)
	var to = from + direction * 2.0
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return not result.is_empty() and result.collider != player

func get_avoidance_direction(blocked_direction: Vector3) -> Vector3:
	# Try left and right alternatives
	var left_direction = blocked_direction.rotated(Vector3.UP, PI/2)
	var right_direction = blocked_direction.rotated(Vector3.UP, -PI/2)
	
	if not is_obstacle_ahead(right_direction):
		return right_direction
	elif not is_obstacle_ahead(left_direction):
		return left_direction
	else:
		# If both sides blocked, try backwards
		return -blocked_direction

# Virtual function for derived classes to override
func handle_animations(_delta):
	pass

func change_state(new_state: State):
	current_state = new_state
	state_timer = 0.0

# Virtual function for derived classes to override
func perform_attack():
	if not player or not player.has_method("take_damage"):
		return
	
	if attack_timer:
		attack_timer.start()
	
	# Look directly at player
	var look_direction = (player.global_position - global_position).normalized()
	rotation.y = atan2(-look_direction.x, -look_direction.z)
	
	# Deal damage
	player.take_damage(attack_damage)
	
	print(enemy_name + " attacked player!")

func check_line_of_sight_to_player() -> bool:
	if not player:
		return false
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(
		global_position + Vector3(0, 1.5, 0),
		player.global_position + Vector3(0, 1.0, 0)
	)
	query.exclude = [self]
	
	var result = space_state.intersect_ray(query)
	return result.is_empty() or result.collider == player

func set_new_patrol_target():
	var angle = randf() * TAU
	var distance = randf_range(3.0, patrol_radius)
	patrol_target = spawn_position + Vector3(sin(angle) * distance, 0, cos(angle) * distance)

func take_damage(damage: int, _hit_position: Vector3 = Vector3.ZERO):
	if is_dead:
		return
	
	health -= damage
	
	# Flash damage effect
	flash_damage()
	
	# Become aggressive toward player
	if current_state == State.PATROL:
		change_state(State.CHASE)
	
	if health <= 0:
		die()

# Virtual function for derived classes to override
func flash_damage():
	pass

func die():
	is_dead = true
	current_state = State.DEAD
	
	# Award XP to player
	award_xp_to_player()
	
	# Disable collision
	var collision = get_node_or_null("CollisionShape3D")
	if collision:
		collision.disabled = true
	
	# Death animation
	var tween = create_tween()
	if model:
		tween.parallel().tween_property(model, "rotation", Vector3(PI/2, 0, 0), 1.0)
		tween.parallel().tween_property(model, "position", model.position + Vector3(0, -0.5, 0), 1.0)
	
	# Emit signal for scoring
	enemy_died.emit(self)
	
	# Remove after delay
	tween.tween_interval(3.0)
	tween.tween_callback(queue_free)
	
	print(enemy_name + " died")

func award_xp_to_player():
	# Signal to XP system
	var xp_manager = get_tree().get_first_node_in_group("xp_manager")
	if xp_manager and xp_manager.has_method("award_xp"):
		xp_manager.award_xp(xp_reward)

func _on_attack_timer_timeout():
	# Attack cooldown finished - virtual function for derived classes
	pass

func handle_portal_teleportation():
	# Called when enemy is teleported through a portal
	# Reset some AI state to handle the sudden position change
	
	# If we were chasing, briefly lose track of player to make AI more realistic
	if current_state == State.CHASE:
		change_state(State.PATROL)
		# Set a new patrol target near the new position
		spawn_position = global_position
		set_new_patrol_target()
	
	# Reset movement timers
	movement_timer = 0.0
	direction_change_timer = 0.0
	current_direction = Vector3.ZERO
	
	print(enemy_name + " teleported and reset AI state")
