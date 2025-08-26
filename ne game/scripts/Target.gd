extends Area3D

@export var target_health: int = 1
@export var points_value: int = 10
@export var auto_destroy_time: float = 15.0

var is_destroyed: bool = false

@onready var model: Node3D = $Model
@onready var destruction_timer: Timer = $DestructionTimer

signal target_hit(target: Node3D)
signal target_destroyed(target: Node3D)

func _ready():
	# Connect signals
	body_entered.connect(_on_body_entered)
	destruction_timer.timeout.connect(_on_destruction_timer_timeout)
	destruction_timer.wait_time = auto_destroy_time
	destruction_timer.start()
	
	# Setup target appearance
	setup_target_appearance()
	
	# Start floating animation
	start_floating_animation()

func setup_target_appearance():
	# Create target visual - classic bullseye design
	var mesh_instance = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.8
	sphere_mesh.height = 1.6
	mesh_instance.mesh = sphere_mesh
	
	# Create bullseye material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.WHITE
	material.emission_enabled = true
	material.emission = Color(1, 0.8, 0.8, 1)
	mesh_instance.set_surface_override_material(0, material)
	model.add_child(mesh_instance)
	
	# Add inner ring
	var inner_ring = MeshInstance3D.new()
	var inner_sphere = SphereMesh.new()
	inner_sphere.radius = 0.5
	inner_sphere.height = 1.0
	inner_ring.mesh = inner_sphere
	
	var inner_material = StandardMaterial3D.new()
	inner_material.albedo_color = Color.RED
	inner_material.emission_enabled = true
	inner_material.emission = Color.RED
	inner_ring.set_surface_override_material(0, inner_material)
	model.add_child(inner_ring)
	
	# Add center bullseye
	var center = MeshInstance3D.new()
	var center_sphere = SphereMesh.new()
	center_sphere.radius = 0.2
	center_sphere.height = 0.4
	center.mesh = center_sphere
	
	var center_material = StandardMaterial3D.new()
	center_material.albedo_color = Color.YELLOW
	center_material.emission_enabled = true
	center_material.emission = Color.YELLOW
	center.set_surface_override_material(0, center_material)
	model.add_child(center)
	
	# Add glow light
	var light = OmniLight3D.new()
	light.light_energy = 2.0
	light.omni_range = 3.0
	light.light_color = Color(1, 0.8, 0.8, 1)
	model.add_child(light)

func start_floating_animation():
	# Create floating and rotating animation
	var float_tween = create_tween()
	float_tween.set_loops()
	float_tween.tween_property(model, "position:y", 0.5, 2.0)
	float_tween.tween_property(model, "position:y", -0.5, 2.0)
	
	var rotate_tween = create_tween()
	rotate_tween.set_loops()
	rotate_tween.tween_property(model, "rotation:y", TAU, 4.0)

func _on_body_entered(body):
	if is_destroyed:
		return
	
	# Check if hit by player projectile (regular gun)
	if body.is_in_group("bullets") or body.is_in_group("player"):
		hit_target()

func hit_target():
	if is_destroyed:
		return
	
	target_health -= 1
	
	if target_health <= 0:
		destroy_target()
	else:
		# Flash effect for partial damage
		flash_hit_effect()

func flash_hit_effect():
	var tween = create_tween()
	tween.tween_property(model, "scale", Vector3(1.2, 1.2, 1.2), 0.1)
	tween.tween_property(model, "scale", Vector3(1.0, 1.0, 1.0), 0.1)

func destroy_target():
	if is_destroyed:
		return
	
	is_destroyed = true
	
	# Play destruction effect
	play_destruction_effect()
	
	# Emit signals
	target_hit.emit(self)
	target_destroyed.emit(self)
	
	print("Target destroyed! Points: ", points_value)
	
	# Remove after effect
	await get_tree().create_timer(1.0).timeout
	queue_free()

func play_destruction_effect():
	# Explosion-like effect
	var explosion_light = OmniLight3D.new()
	explosion_light.light_energy = 8.0
	explosion_light.omni_range = 6.0
	explosion_light.light_color = Color.YELLOW
	add_child(explosion_light)
	
	# Scale up and fade out
	var effect_tween = create_tween()
	effect_tween.parallel().tween_property(model, "scale", Vector3(1.5, 1.5, 1.5), 0.3)
	effect_tween.parallel().tween_property(model, "modulate:a", 0.0, 0.3)
	effect_tween.parallel().tween_property(explosion_light, "light_energy", 0.0, 0.5)
	
	# Hide collision
	$CollisionShape3D.disabled = true

func _on_destruction_timer_timeout():
	# Auto-destroy if not hit in time
	if not is_destroyed:
		print("Target timed out")
		queue_free()

func take_damage(damage: int, _hit_position: Vector3 = Vector3.ZERO):
	# Called by player bullets
	hit_target()
