extends RigidBody3D
class_name EnemyProjectile

@export var damage: int = 15
@export var speed: float = 15.0
@export var lifetime: float = 5.0

var direction: Vector3
var has_hit: bool = false

# Visual components
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
@onready var collision_shape: CollisionShape3D = $CollisionShape3D
@onready var impact_particles: GPUParticles3D = $ImpactParticles

func _ready():
	# Set up collision detection
	contact_monitor = true
	max_contacts_reported = 10
	
	# Connect collision signal
	body_entered.connect(_on_body_entered)
	
	# Set up automatic cleanup
	get_tree().create_timer(lifetime).timeout.connect(cleanup)
	
	# Visual setup
	setup_visuals()

func setup(proj_direction: Vector3, proj_damage: int, proj_speed: float):
	direction = proj_direction.normalized()
	damage = proj_damage
	speed = proj_speed
	
	# Set initial velocity
	linear_velocity = direction * speed
	
	# Orient projectile to face movement direction
	if direction.length() > 0.1:
		look_at(global_position + direction, Vector3.UP)

func setup_visuals():
	# Create glowing sphere mesh
	if mesh_instance:
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = 0.2
		sphere_mesh.radial_segments = 8
		sphere_mesh.rings = 6
		mesh_instance.mesh = sphere_mesh
		
		# Create glowing material
		var material = StandardMaterial3D.new()
		material.emission_enabled = true
		material.emission = Color.RED
		material.emission_energy = 2.0
		material.albedo_color = Color(1.0, 0.3, 0.3)
		material.metallic = 0.8
		material.roughness = 0.2
		mesh_instance.material_override = material
	
	# Set up collision shape
	if collision_shape:
		var sphere_shape = SphereShape3D.new()
		sphere_shape.radius = 0.2
		collision_shape.shape = sphere_shape

func _physics_process(delta):
	if has_hit:
		return
	
	# Maintain velocity (in case of physics interference)
	if linear_velocity.length() < speed * 0.8:
		linear_velocity = direction * speed
	
	# Add trail effect
	add_trail_effect()

func add_trail_effect():
	# Simple trail by leaving temporary visual markers
	var trail_marker = MeshInstance3D.new()
	get_tree().current_scene.add_child(trail_marker)
	trail_marker.global_position = global_position
	
	# Small sphere for trail
	var small_sphere = SphereMesh.new()
	small_sphere.radius = 0.05
	trail_marker.mesh = small_sphere
	
	# Fading material
	var trail_material = StandardMaterial3D.new()
	trail_material.emission_enabled = true
	trail_material.emission = Color(1.0, 0.5, 0.5, 0.5)
	trail_material.emission_energy = 1.0
	trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_marker.material_override = trail_material
	
	# Fade out and remove trail marker
	var tween = create_tween()
	tween.tween_property(trail_material, "emission", Color(1.0, 0.5, 0.5, 0.0), 0.5)
	tween.tween_callback(trail_marker.queue_free)

func _on_body_entered(body):
	if has_hit:
		return
	
	# Don't hit other projectiles or enemies
	if body is EnemyProjectile or body is EnemyBase:
		return
	
	has_hit = true
	
	# Deal damage to player
	if body.has_method("take_damage"):
		body.take_damage(damage, global_position)
		print("Projectile hit ", body.name, " for ", damage, " damage")
	
	# Create impact effect
	create_impact_effect()
	
	# Remove projectile
	cleanup()

func create_impact_effect():
	# Impact particles
	if impact_particles:
		impact_particles.emitting = true
		impact_particles.reparent(get_tree().current_scene)
		
		# Clean up particles after emission
		get_tree().create_timer(2.0).timeout.connect(impact_particles.queue_free)
	
	# Impact flash
	var impact_flash = MeshInstance3D.new()
	get_tree().current_scene.add_child(impact_flash)
	impact_flash.global_position = global_position
	
	# Flash sphere
	var flash_mesh = SphereMesh.new()
	flash_mesh.radius = 1.0
	impact_flash.mesh = flash_mesh
	
	# Bright flash material
	var flash_material = StandardMaterial3D.new()
	flash_material.emission_enabled = true
	flash_material.emission = Color.YELLOW
	flash_material.emission_energy = 5.0
	flash_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	impact_flash.material_override = flash_material
	
	# Flash animation
	var tween = create_tween()
	tween.parallel().tween_property(impact_flash, "scale", Vector3(2.0, 2.0, 2.0), 0.2)
	tween.parallel().tween_property(flash_material, "emission_energy", 0.0, 0.2)
	tween.tween_callback(impact_flash.queue_free)
	
	print("Projectile impact effect created")

func cleanup():
	if not has_hit:
		print("Projectile lifetime expired")
	
	queue_free()
