extends EnemyBase
class_name BossEnemy

# Boss-specific properties
@export var phase_2_health_threshold: float = 0.6  # 60% health remaining
@export var phase_3_health_threshold: float = 0.3  # 30% health remaining
@export var enrage_health_threshold: float = 0.15  # 15% health remaining

enum BossPhase { PHASE_1, PHASE_2, PHASE_3, ENRAGED }
var current_phase: BossPhase = BossPhase.PHASE_1

# Attack patterns
var slam_attack_cooldown: float = 0.0
var projectile_attack_cooldown: float = 0.0
var charge_attack_cooldown: float = 0.0
var summon_cooldown: float = 0.0

# Attack timings
@export var slam_attack_interval: float = 4.0
@export var projectile_attack_interval: float = 2.5
@export var charge_attack_interval: float = 8.0
@export var summon_interval: float = 15.0

# Boss movement
var charge_target: Vector3
var is_charging: bool = false
var charge_speed: float = 15.0
var charge_duration: float = 0.0

# Projectile system
var projectile_scene = preload("res://scenes/EnemyProjectile.tscn")
var projectile_count: int = 3

# Summon system
var scout_scene = preload("res://scenes/ScoutEnemy.tscn")
var summon_count: int = 2

# Visual effects
var screen_shake_intensity: float = 10.0

func _ready():
	# Boss stats
	enemy_type = "boss"
	enemy_name = "Titan Boss"
	
	# High health and damage
	health = 500
	max_health = health
	attack_damage = 35
	speed = 3.0
	chase_speed = 4.0
	detection_range = 20.0
	attack_range = 4.0
	xp_reward = 200
	
	# Larger patrol area
	patrol_radius = 15.0
	
	super._ready()
	
	# Connect to health changes to trigger phase transitions
	print("Boss spawned with ", health, " health")

func _physics_process(delta):
	super._physics_process(delta)
	
	# Update boss-specific timers
	update_boss_timers(delta)
	
	# Handle charging behavior
	if is_charging:
		handle_charge_attack(delta)
	
	# Check for phase transitions
	check_phase_transitions()

func update_boss_timers(delta):
	slam_attack_cooldown = max(0.0, slam_attack_cooldown - delta)
	projectile_attack_cooldown = max(0.0, projectile_attack_cooldown - delta)
	charge_attack_cooldown = max(0.0, charge_attack_cooldown - delta)
	summon_cooldown = max(0.0, summon_cooldown - delta)
	
	if is_charging:
		charge_duration += delta

func check_phase_transitions():
	var health_percentage = health / max_health
	var previous_phase = current_phase
	
	if health_percentage <= enrage_health_threshold and current_phase != BossPhase.ENRAGED:
		current_phase = BossPhase.ENRAGED
	elif health_percentage <= phase_3_health_threshold and current_phase == BossPhase.PHASE_2:
		current_phase = BossPhase.PHASE_3
	elif health_percentage <= phase_2_health_threshold and current_phase == BossPhase.PHASE_1:
		current_phase = BossPhase.PHASE_2
	
	if previous_phase != current_phase:
		trigger_phase_transition()

func trigger_phase_transition():
	print("Boss entering phase: ", current_phase)
	
	# Phase transition effects
	screen_shake()
	phase_transition_animation()
	
	# Adjust stats per phase
	match current_phase:
		BossPhase.PHASE_2:
			speed *= 1.2
			chase_speed *= 1.2
			attack_damage = int(attack_damage * 1.1)
			slam_attack_interval *= 0.8
			projectile_count = 5
			
		BossPhase.PHASE_3:
			speed *= 1.3
			chase_speed *= 1.3
			attack_damage = int(attack_damage * 1.2)
			slam_attack_interval *= 0.7
			projectile_count = 7
			summon_count = 3
			
		BossPhase.ENRAGED:
			speed *= 1.5
			chase_speed *= 1.5
			attack_damage = int(attack_damage * 1.4)
			slam_attack_interval *= 0.5
			projectile_count = 10
			summon_count = 4
			charge_attack_interval *= 0.6

func update_ai_state(delta):
	if not player or is_dead:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	can_see_player = check_line_of_sight_to_player()
	
	# Boss is always aggressive - no patrol state
	if current_state == State.PATROL:
		change_state(State.CHASE)
	
	match current_state:
		State.CHASE:
			if distance_to_player <= attack_range:
				change_state(State.ATTACK)
			# Boss specific attack patterns at range
			if distance_to_player > attack_range:
				handle_ranged_attacks()
		
		State.ATTACK:
			if distance_to_player > attack_range * 1.5:
				change_state(State.CHASE)
			else:
				handle_melee_attacks()

func handle_ranged_attacks():
	if not player:
		return
	
	var distance = global_position.distance_to(player.global_position)
	
	# Projectile attack (all phases)
	if projectile_attack_cooldown <= 0.0 and distance > 5.0:
		perform_projectile_attack()
	
	# Charge attack (phase 2+)
	if current_phase >= BossPhase.PHASE_2 and charge_attack_cooldown <= 0.0 and distance > 8.0:
		perform_charge_attack()
	
	# Summon minions (phase 3+)
	if current_phase >= BossPhase.PHASE_3 and summon_cooldown <= 0.0:
		perform_summon_attack()

func handle_melee_attacks():
	# Slam attack
	if slam_attack_cooldown <= 0.0 and attack_timer.is_stopped():
		perform_slam_attack()

func perform_slam_attack():
	if not player:
		return
	
	slam_attack_cooldown = slam_attack_interval
	attack_timer.start()
	
	# Look at player
	var look_direction = (player.global_position - global_position).normalized()
	rotation.y = atan2(-look_direction.x, -look_direction.z)
	
	# Enhanced damage based on phase
	var slam_damage = attack_damage
	if current_phase >= BossPhase.PHASE_2:
		slam_damage = int(slam_damage * 1.3)
	
	# Area damage
	deal_area_damage(slam_damage, 5.0)
	
	# Visual effects
	screen_shake()
	slam_animation()
	
	print("Boss performed slam attack! Damage: ", slam_damage)

func perform_projectile_attack():
	if not player:
		return
	
	projectile_attack_cooldown = projectile_attack_interval
	
	# Look at player
	var look_direction = (player.global_position - global_position).normalized()
	rotation.y = atan2(-look_direction.x, -look_direction.z)
	
	# Fire multiple projectiles in a spread pattern
	for i in range(projectile_count):
		create_projectile(i)
	
	projectile_animation()
	print("Boss fired ", projectile_count, " projectiles!")

func create_projectile(index: int):
	if not projectile_scene:
		return
	
	var projectile = projectile_scene.instantiate()
	get_tree().current_scene.add_child(projectile)
	
	# Position projectile
	var spawn_position = global_position + Vector3(0, 2.0, 0)
	projectile.global_position = spawn_position
	
	# Calculate direction with spread
	var base_direction = (player.global_position - global_position).normalized()
	var spread_angle = (index - projectile_count / 2.0) * 0.3  # Spread projectiles
	var direction = base_direction.rotated(Vector3.UP, spread_angle)
	
	# Set projectile properties
	if projectile.has_method("setup"):
		projectile.setup(direction, attack_damage * 0.7, 20.0)  # 70% of melee damage

func perform_charge_attack():
	if not player:
		return
	
	charge_attack_cooldown = charge_attack_interval
	
	# Set charge target to player's current position
	charge_target = player.global_position
	is_charging = true
	charge_duration = 0.0
	
	# Change state and increase speed temporarily
	current_state = State.CHASE
	
	charge_animation()
	print("Boss started charge attack!")

func handle_charge_attack(delta):
	if not is_charging:
		return
	
	# Move toward charge target at high speed
	var direction = (charge_target - global_position).normalized()
	velocity.x = direction.x * charge_speed
	velocity.z = direction.z * charge_speed
	
	# Look in charge direction
	rotation.y = atan2(-direction.x, -direction.z)
	
	# Check if we hit something or reached target
	var distance_to_target = global_position.distance_to(charge_target)
	
	if distance_to_target < 2.0 or charge_duration > 3.0:
		end_charge_attack()
	
	# Deal damage to player if we hit them
	if player and global_position.distance_to(player.global_position) < 3.0:
		player.take_damage(attack_damage * 2)  # Double damage for charge
		end_charge_attack()
		screen_shake()

func end_charge_attack():
	is_charging = false
	charge_duration = 0.0
	
	# Brief stun after charge
	await get_tree().create_timer(1.0).timeout
	
	print("Boss charge attack ended")

func perform_summon_attack():
	if not scout_scene:
		return
	
	summon_cooldown = summon_interval
	
	# Summon minions around the boss
	for i in range(summon_count):
		var minion = scout_scene.instantiate()
		get_tree().current_scene.add_child(minion)
		
		# Position around boss
		var angle = (i / float(summon_count)) * TAU
		var spawn_pos = global_position + Vector3(sin(angle) * 4.0, 1.0, cos(angle) * 4.0)
		minion.global_position = spawn_pos
		
		print("Boss summoned minion at: ", spawn_pos)
	
	summon_animation()
	print("Boss summoned ", summon_count, " minions!")

func deal_area_damage(damage: int, radius: float):
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	if distance_to_player <= radius:
		player.take_damage(damage)

func screen_shake():
	# Send screen shake signal to camera
	var camera = get_viewport().get_camera_3d()
	if camera and camera.has_method("shake"):
		camera.shake(screen_shake_intensity, 0.5)

func slam_animation():
	var tween = create_tween()
	tween.parallel().tween_property(model, "scale", Vector3(1.2, 0.8, 1.2), 0.2)
	tween.parallel().tween_property(model, "position", model.position + Vector3(0, -0.3, 0), 0.2)
	tween.tween_property(model, "scale", Vector3(1.0, 1.0, 1.0), 0.3)
	tween.parallel().tween_property(model, "position", model.position, 0.3)

func projectile_animation():
	var tween = create_tween()
	# Animate the whole model instead of specific arms
	tween.parallel().tween_property(model, "rotation", Vector3(0, 0, 0.2), 0.3)
	tween.tween_property(model, "rotation", Vector3(0, 0, 0), 0.4)

func charge_animation():
	var tween = create_tween()
	tween.parallel().tween_property(model, "rotation", Vector3(0.3, 0, 0), 0.2)
	tween.tween_property(model, "rotation", Vector3(0, 0, 0), 1.0)

func summon_animation():
	var tween = create_tween()
	# Animate the whole model instead of specific arms
	tween.parallel().tween_property(model, "scale", Vector3(1.2, 1.2, 1.2), 0.5)
	tween.parallel().tween_property(model, "rotation", Vector3(0, PI, 0), 0.5)
	tween.tween_property(model, "scale", Vector3(1.0, 1.0, 1.0), 0.5)
	tween.parallel().tween_property(model, "rotation", Vector3(0, 0, 0), 0.5)

func phase_transition_animation():
	var tween = create_tween()
	tween.parallel().tween_property(model, "scale", Vector3(1.3, 1.3, 1.3), 0.3)
	tween.parallel().tween_property(model, "rotation", Vector3(0, TAU, 0), 0.3)
	tween.tween_property(model, "scale", Vector3(1.0, 1.0, 1.0), 0.4)
	tween.parallel().tween_property(model, "rotation", Vector3(0, 0, 0), 0.4)

func take_damage(damage: int, _hit_position: Vector3 = Vector3.ZERO):
	if is_dead:
		return
	
	# Boss takes reduced damage in later phases
	var actual_damage = damage
	match current_phase:
		BossPhase.PHASE_2:
			actual_damage = int(damage * 0.9)
		BossPhase.PHASE_3:
			actual_damage = int(damage * 0.8)
		BossPhase.ENRAGED:
			actual_damage = int(damage * 0.7)
	
	health -= actual_damage
	
	# Enhanced damage flash for boss
	flash_damage()
	
	# Interrupt charge if taking damage
	if is_charging:
		end_charge_attack()
	
	# Become more aggressive
	if current_state == State.PATROL:
		change_state(State.CHASE)
	
	print("Boss took ", actual_damage, " damage. Health: ", health, "/", max_health)
	
	if health <= 0:
		die()

func die():
	is_dead = true
	current_state = State.DEAD
	
	# Stop all attacks
	is_charging = false
	
	# Disable collision
	$CollisionShape3D.disabled = true
	
	# Epic death animation
	var tween = create_tween()
	tween.parallel().tween_property(model, "rotation", Vector3(PI/2, 0, 0), 2.0)
	tween.parallel().tween_property(model, "position", model.position + Vector3(0, -1.0, 0), 2.0)
	tween.parallel().tween_property(model, "scale", Vector3(1.5, 1.5, 1.5), 2.0)
	
	# Screen shake for dramatic effect
	screen_shake()
	
	# Emit signal for scoring (huge XP reward)
	enemy_died.emit(self)
	
	# Remove after longer delay
	tween.tween_interval(5.0)
	tween.tween_callback(queue_free)
	
	print("BOSS DEFEATED! Massive XP reward: ", xp_reward)
