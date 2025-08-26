extends EnemyBase
class_name BasicEnemy

func _ready():
	# Basic enemy stats (uses default EnemyBase values)
	enemy_type = "basic"
	enemy_name = "Basic Enemy"
	# Keep default stats from EnemyBase
	
	# Call parent ready
	super._ready()

# BasicEnemy uses all default behavior from EnemyBase
# No additional customization needed - this is the standard enemy type
