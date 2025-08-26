extends Node
class_name XPManager

signal xp_gained(amount)
signal level_up(new_level, skill_points_gained)
signal skill_unlocked(skill_name)

@export var current_xp: int = 0
@export var current_level: int = 1
@export var skill_points: int = 0

# XP required for each level (exponential growth)
var xp_requirements: Array[int] = []
var max_level: int = 50

# Player skills and abilities
var unlocked_skills: Dictionary = {}
var skill_tree: Dictionary = {
	"health_boost_1": {"cost": 1, "level_req": 2, "name": "Health Boost I", "description": "+20 Max Health"},
	"health_boost_2": {"cost": 2, "level_req": 5, "name": "Health Boost II", "description": "+40 Max Health", "requires": ["health_boost_1"]},
	"health_boost_3": {"cost": 3, "level_req": 10, "name": "Health Boost III", "description": "+60 Max Health", "requires": ["health_boost_2"]},
	
	"speed_boost_1": {"cost": 1, "level_req": 3, "name": "Speed Boost I", "description": "+15% Movement Speed"},
	"speed_boost_2": {"cost": 2, "level_req": 6, "name": "Speed Boost II", "description": "+30% Movement Speed", "requires": ["speed_boost_1"]},
	"speed_boost_3": {"cost": 3, "level_req": 12, "name": "Speed Boost III", "description": "+50% Movement Speed", "requires": ["speed_boost_2"]},
	
	"damage_boost_1": {"cost": 1, "level_req": 2, "name": "Damage Boost I", "description": "+25% Weapon Damage"},
	"damage_boost_2": {"cost": 2, "level_req": 7, "name": "Damage Boost II", "description": "+50% Weapon Damage", "requires": ["damage_boost_1"]},
	"damage_boost_3": {"cost": 3, "level_req": 15, "name": "Damage Boost III", "description": "+100% Weapon Damage", "requires": ["damage_boost_2"]},
	
	"ammo_boost_1": {"cost": 1, "level_req": 4, "name": "Ammo Capacity I", "description": "+15 Max Ammo"},
	"ammo_boost_2": {"cost": 2, "level_req": 8, "name": "Ammo Capacity II", "description": "+30 Max Ammo", "requires": ["ammo_boost_1"]},
	
	"regeneration_1": {"cost": 2, "level_req": 6, "name": "Health Regeneration I", "description": "Slowly regenerate health"},
	"regeneration_2": {"cost": 3, "level_req": 12, "name": "Health Regeneration II", "description": "Faster health regeneration", "requires": ["regeneration_1"]},
	
	"double_jump": {"cost": 2, "level_req": 5, "name": "Double Jump", "description": "Jump again while in air"},
	"triple_jump": {"cost": 3, "level_req": 10, "name": "Triple Jump", "description": "Jump a third time while in air", "requires": ["double_jump"]},
	
	"portal_mastery": {"cost": 2, "level_req": 8, "name": "Portal Mastery", "description": "Portals last longer and are more stable"},
	"portal_speed": {"cost": 3, "level_req": 14, "name": "Portal Speed", "description": "Faster portal creation and switching"},
	
	"armor_1": {"cost": 2, "level_req": 9, "name": "Armor Plating I", "description": "Reduce all damage by 2 points"},
	"armor_2": {"cost": 3, "level_req": 16, "name": "Armor Plating II", "description": "Reduce all damage by 5 points", "requires": ["armor_1"]},
	
	"quick_reload": {"cost": 1, "level_req": 3, "name": "Quick Reload", "description": "50% faster reload speed"},
	"instant_reload": {"cost": 3, "level_req": 11, "name": "Instant Reload", "description": "Reload instantly", "requires": ["quick_reload"]},
}

func _ready():
	# Generate XP requirements for each level
	generate_xp_requirements()
	
	# Add to group for easy access
	add_to_group("xp_manager")
	
	print("XP Manager initialized - Level ", current_level, " with ", current_xp, " XP")

func generate_xp_requirements():
	xp_requirements.resize(max_level + 1)
	xp_requirements[1] = 0  # Level 1 requires 0 XP
	
	# Exponential growth: each level requires more XP
	for i in range(2, max_level + 1):
		var base_xp = 100
		var multiplier = pow(1.3, i - 2)  # 30% increase per level
		xp_requirements[i] = int(base_xp * multiplier) + xp_requirements[i - 1]
	
	print("XP Requirements generated up to level ", max_level)

func award_xp(amount: int):
	current_xp += amount
	xp_gained.emit(amount)
	
	print("Gained ", amount, " XP! Total: ", current_xp)
	
	# Check for level up
	check_level_up()

func check_level_up():
	if current_level >= max_level:
		return
	
	var next_level = current_level + 1
	if current_xp >= xp_requirements[next_level]:
		level_up_player()

func level_up_player():
	current_level += 1
	var skill_points_gained = 1
	
	# Bonus skill points at certain levels
	if current_level % 5 == 0:  # Every 5 levels
		skill_points_gained += 1
	if current_level % 10 == 0:  # Every 10 levels
		skill_points_gained += 1
	
	skill_points += skill_points_gained
	
	level_up.emit(current_level, skill_points_gained)
	
	print("LEVEL UP! Now level ", current_level, " - Gained ", skill_points_gained, " skill points!")
	
	# Apply level-based improvements to player
	apply_level_benefits()

func apply_level_benefits():
	var player = get_tree().get_first_node_in_group("player")
	if not player:
		return
	
	# Apply unlocked skills
	for skill_id in unlocked_skills:
		apply_skill_effect(skill_id, player)

func unlock_skill(skill_id: String) -> bool:
	if not skill_tree.has(skill_id):
		print("Skill not found: ", skill_id)
		return false
	
	var skill = skill_tree[skill_id]
	
	# Check requirements
	if current_level < skill.level_req:
		print("Level too low for skill: ", skill.name)
		return false
	
	if skill_points < skill.cost:
		print("Not enough skill points for: ", skill.name)
		return false
	
	# Check prerequisites
	if skill.has("requires"):
		for prereq in skill.requires:
			if not unlocked_skills.has(prereq):
				print("Missing prerequisite for ", skill.name, ": ", prereq)
				return false
	
	# Unlock the skill
	skill_points -= skill.cost
	unlocked_skills[skill_id] = true
	
	skill_unlocked.emit(skill.name)
	print("Unlocked skill: ", skill.name)
	
	# Apply skill effect immediately
	var player = get_tree().get_first_node_in_group("player")
	if player:
		apply_skill_effect(skill_id, player)
	
	return true

func apply_skill_effect(skill_id: String, player):
	if not player.has_method("get_property") or not player.has_method("set_property"):
		# Fallback to direct property access if helper methods don't exist
		apply_skill_effect_direct(skill_id, player)
		return
	
	match skill_id:
		"health_boost_1":
			player.max_health += 20
			player.health = min(player.health + 20, player.max_health)
		"health_boost_2":
			player.max_health += 20  # Additional 20 (total +40)
			player.health = min(player.health + 20, player.max_health)
		"health_boost_3":
			player.max_health += 20  # Additional 20 (total +60)
			player.health = min(player.health + 20, player.max_health)
		
		"speed_boost_1":
			player.speed *= 1.15
		"speed_boost_2":
			player.speed *= 1.13  # Compounds to roughly 30% total
		"speed_boost_3":
			player.speed *= 1.15  # Compounds to roughly 50% total
		
		"damage_boost_1", "damage_boost_2", "damage_boost_3":
			# This would need to be handled in weapon damage calculation
			pass
		
		"ammo_boost_1":
			player.max_ammo += 15
			player.ammo += 15
		"ammo_boost_2":
			player.max_ammo += 15  # Additional 15 (total +30)
			player.ammo += 15
		
		"regeneration_1", "regeneration_2":
			# This would need a regeneration system
			setup_health_regeneration(player, skill_id)
		
		"double_jump", "triple_jump":
			# This would need to be handled in player jump logic
			setup_multi_jump(player, skill_id)

func apply_skill_effect_direct(skill_id: String, player):
	# Direct property access fallback
	match skill_id:
		"health_boost_1", "health_boost_2", "health_boost_3":
			if player.has_property("max_health"):
				player.max_health += 20
				if player.has_property("health"):
					player.health = min(player.health + 20, player.max_health)
		
		"speed_boost_1", "speed_boost_2", "speed_boost_3":
			if player.has_property("speed"):
				player.speed *= 1.15
		
		"ammo_boost_1", "ammo_boost_2":
			if player.has_property("max_ammo"):
				player.max_ammo += 15
				if player.has_property("ammo"):
					player.ammo += 15

func setup_health_regeneration(player, skill_id: String):
	# Create a regeneration timer
	var regen_timer = Timer.new()
	player.add_child(regen_timer)
	regen_timer.wait_time = 2.0 if skill_id == "regeneration_1" else 1.0
	regen_timer.timeout.connect(func(): regenerate_health(player, skill_id))
	regen_timer.start()

func regenerate_health(player, skill_id: String):
	if player.health < player.max_health:
		var regen_amount = 2 if skill_id == "regeneration_1" else 5
		player.health = min(player.health + regen_amount, player.max_health)
		
		# Update UI
		if player.has_signal("health_changed"):
			player.health_changed.emit(player.health)

func setup_multi_jump(player, skill_id: String):
	# This would require modifying the player's jump logic
	# For now, just set a property that the player can check
	if not player.has_property("max_jumps"):
		player.set("max_jumps", 1)
	
	if skill_id == "double_jump":
		player.max_jumps = 2
	elif skill_id == "triple_jump":
		player.max_jumps = 3

func get_damage_multiplier() -> float:
	var multiplier = 1.0
	
	if unlocked_skills.has("damage_boost_1"):
		multiplier *= 1.25
	if unlocked_skills.has("damage_boost_2"):
		multiplier *= 1.2  # Compounds to roughly 1.5x
	if unlocked_skills.has("damage_boost_3"):
		multiplier *= 1.33  # Compounds to roughly 2.0x
	
	return multiplier

func get_armor_reduction() -> int:
	var reduction = 0
	
	if unlocked_skills.has("armor_1"):
		reduction += 2
	if unlocked_skills.has("armor_2"):
		reduction += 3  # Additional 3 (total 5)
	
	return reduction

func has_skill(skill_id: String) -> bool:
	return unlocked_skills.has(skill_id)

func get_available_skills() -> Array:
	var available = []
	
	for skill_id in skill_tree:
		var skill = skill_tree[skill_id]
		
		# Skip if already unlocked
		if unlocked_skills.has(skill_id):
			continue
		
		# Check level requirement
		if current_level < skill.level_req:
			continue
		
		# Check skill point cost
		if skill_points < skill.cost:
			continue
		
		# Check prerequisites
		var can_unlock = true
		if skill.has("requires"):
			for prereq in skill.requires:
				if not unlocked_skills.has(prereq):
					can_unlock = false
					break
		
		if can_unlock:
			available.append(skill_id)
	
	return available

func get_xp_to_next_level() -> int:
	if current_level >= max_level:
		return 0
	
	return xp_requirements[current_level + 1] - current_xp

func get_level_progress() -> float:
	if current_level >= max_level:
		return 1.0
	
	var current_level_xp = xp_requirements[current_level]
	var next_level_xp = xp_requirements[current_level + 1]
	var progress_xp = current_xp - current_level_xp
	var total_level_xp = next_level_xp - current_level_xp
	
	return float(progress_xp) / float(total_level_xp)

# Save/Load functions
func get_save_data() -> Dictionary:
	return {
		"current_xp": current_xp,
		"current_level": current_level,
		"skill_points": skill_points,
		"unlocked_skills": unlocked_skills
	}

func load_save_data(data: Dictionary):
	current_xp = data.get("current_xp", 0)
	current_level = data.get("current_level", 1)
	skill_points = data.get("skill_points", 0)
	unlocked_skills = data.get("unlocked_skills", {})
	
	# Apply all unlocked skills
	apply_level_benefits()
	
	print("Loaded XP data - Level ", current_level, " with ", current_xp, " XP and ", skill_points, " skill points")
