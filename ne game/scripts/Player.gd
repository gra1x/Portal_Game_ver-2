extends CharacterBody3D

@export var speed: float = 5.0
@export var jump_velocity: float = 11.0
@export var mouse_sensitivity: float = 0.002
@export var max_health: int = 100
@export var max_ammo: int = 30

var health: int = 100
var ammo: int = 30
var is_aiming: bool = false

# Weapon system
enum WeaponType { GUN, PORTAL_GUN }
var current_weapon: WeaponType = WeaponType.GUN

# Portal system
var blue_portal: Node3D = null
var orange_portal: Node3D = null
var portal_scene: PackedScene = preload("res://scenes/Portal.tscn")

@onready var camera: Camera3D = $Head/Camera3D
@onready var head: Node3D = $Head
@onready var gun: Node3D = $Head/Camera3D/Gun
@onready var portal_gun: Node3D = $Head/Camera3D/PortalGun
@onready var muzzle: Marker3D = $Head/Camera3D/Gun/Muzzle
@onready var portal_muzzle: Marker3D = $Head/Camera3D/PortalGun/PortalMuzzle
@onready var raycast: RayCast3D = $Head/Camera3D/Raycast3D

# Bullet scene to instantiate
@export var bullet_scene: PackedScene

# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")

signal health_changed(new_health)
signal ammo_changed(new_ammo)
signal player_died

func _ready():
	# Capture the mouse cursor
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Set initial weapon visibility
	gun.visible = true
	portal_gun.visible = false
	
	# Add player to group for enemy AI targeting
	add_to_group("player")
	
	# Connect signals
	health_changed.emit(health)
	ammo_changed.emit(ammo)

func _input(event):
	# Handle mouse look
	if event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		# Rotate the head (yaw)
		head.rotate_y(-event.relative.x * mouse_sensitivity)
		
		# Rotate the camera (pitch)
		camera.rotate_x(-event.relative.y * mouse_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, -1.5, 1.5)
	
	# Toggle escape menu with Escape
	if event.is_action_pressed("ui_cancel"):
		var ui = get_tree().get_first_node_in_group("ui")
		if ui and ui.has_method("toggle_escape_menu"):
			ui.toggle_escape_menu()

func _physics_process(delta):
	# Add gravity
	if not is_on_floor():
		velocity.y -= gravity * delta

	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Handle movement
	var input_dir = Vector2.ZERO
	if Input.is_action_pressed("move_forward"):
		input_dir.y += 1
	if Input.is_action_pressed("move_backward"):
		input_dir.y -= 1
	if Input.is_action_pressed("move_left"):
		input_dir.x -= 1
	if Input.is_action_pressed("move_right"):
		input_dir.x += 1
	
	if input_dir != Vector2.ZERO:
		input_dir = input_dir.normalized()
		var direction = (head.transform.basis * Vector3(input_dir.x, 0, -input_dir.y)).normalized()
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
	else:
		velocity.x = move_toward(velocity.x, 0, speed)
		velocity.z = move_toward(velocity.z, 0, speed)

	# Handle shooting
	if Input.is_action_just_pressed("shoot"):
		shoot()
	
	# Handle aiming based on weapon type
	if current_weapon == WeaponType.GUN:
		if Input.is_action_pressed("aim"):
			if not is_aiming:
				is_aiming = true
				# Zoom in camera
				camera.fov = 45
		else:
			if is_aiming:
				is_aiming = false
				# Zoom out camera
				camera.fov = 75
	elif current_weapon == WeaponType.PORTAL_GUN:
		# Portal gun - right click for orange portal
		if Input.is_action_just_pressed("aim"):
			shoot_orange_portal()
	
	# Handle reload
	if Input.is_action_just_pressed("reload"):
		reload()
	
	# Handle weapon switching
	if Input.is_action_just_pressed("switch_weapon"): # Key 2
		switch_weapon()

	move_and_slide()

func shoot():
	match current_weapon:
		WeaponType.GUN:
			shoot_regular_gun()
		WeaponType.PORTAL_GUN:
			shoot_portal_gun()

func shoot_regular_gun():
	if ammo <= 0:
		# Play empty gun sound here
		return
	
	ammo -= 1
	ammo_changed.emit(ammo)
	
	# Create muzzle flash effect
	create_muzzle_flash()
	
	# Raycast for hit detection
	if raycast.is_colliding():
		var collider = raycast.get_collider()
		var hit_point = raycast.get_collision_point()
		
		# Handle different types of objects
		if collider.has_method("take_damage"):
			collider.take_damage(20, hit_point)
		
		# Create bullet hole effect
		create_bullet_hole(hit_point, raycast.get_collision_normal())
	
	# Create bullet trail effect
	create_bullet_trail()

func create_muzzle_flash():
	# Simple muzzle flash - enhanced with light
	var light = OmniLight3D.new()
	light.light_energy = 2.0
	light.omni_range = 3.0
	light.light_color = Color.ORANGE
	muzzle.add_child(light)
	
	# Remove the light after a short time
	var timer = get_tree().create_timer(0.1)
	timer.timeout.connect(func(): if is_instance_valid(light): light.queue_free())

func create_bullet_hole(_position: Vector3, _normal: Vector3):
	# Create bullet hole decal at hit position
	pass

func create_bullet_trail():
	# Create bullet trail effect
	pass

func reload():
	ammo = max_ammo
	ammo_changed.emit(ammo)
	# Play reload animation/sound here

func take_damage(damage: int):
	health -= damage
	health_changed.emit(health)
	
	if health <= 0:
		die()

func die():
	player_died.emit()
	# Handle player death - respawn, game over, etc.

func heal(amount: int):
	health = min(health + amount, max_health)
	health_changed.emit(health)

func add_ammo(amount: int):
	ammo = min(ammo + amount, max_ammo)
	ammo_changed.emit(ammo)

func switch_weapon():
	match current_weapon:
		WeaponType.GUN:
			current_weapon = WeaponType.PORTAL_GUN
			gun.visible = false
			portal_gun.visible = true
			print("Switched to Portal Gun")
		WeaponType.PORTAL_GUN:
			current_weapon = WeaponType.GUN
			portal_gun.visible = false
			gun.visible = true
			print("Switched to Regular Gun")

func shoot_portal_gun():
	# Left click creates blue portal
	if not raycast.is_colliding():
		return
	
	var hit_point = raycast.get_collision_point()
	var hit_normal = raycast.get_collision_normal()
	var collider = raycast.get_collider()
	
	# Check if the surface is suitable for portals (not moving objects)
	if collider is RigidBody3D or collider is CharacterBody3D:
		print("Cannot place portal on moving object")
		return
	
	# Create muzzle flash for portal gun
	create_portal_muzzle_flash(Color.CYAN)
	
	create_portal(hit_point, hit_normal, "blue")

func shoot_orange_portal():
	# Right click creates orange portal
	if not raycast.is_colliding():
		return
	
	var hit_point = raycast.get_collision_point()
	var hit_normal = raycast.get_collision_normal()
	var collider = raycast.get_collider()
	
	# Check if the surface is suitable for portals (not moving objects)
	if collider is RigidBody3D or collider is CharacterBody3D:
		print("Cannot place portal on moving object")
		return
	
	# Create muzzle flash for portal gun
	create_portal_muzzle_flash(Color.ORANGE)
	
	create_portal(hit_point, hit_normal, "orange")

func create_portal_muzzle_flash(color: Color):
	# Portal gun muzzle flash
	var light = OmniLight3D.new()
	light.light_energy = 3.0
	light.omni_range = 4.0
	light.light_color = color
	portal_muzzle.add_child(light)
	
	# Remove the light after a short time
	var timer = get_tree().create_timer(0.15)
	timer.timeout.connect(func(): if is_instance_valid(light): light.queue_free())

func create_portal(portal_position: Vector3, normal: Vector3, portal_type: String):
	# Remove existing portal of this type
	if portal_type == "blue" and blue_portal:
		blue_portal.queue_free()
		blue_portal = null
	elif portal_type == "orange" and orange_portal:
		orange_portal.queue_free()
		orange_portal = null
	
	# Create new portal
	var portal = portal_scene.instantiate()
	
	# Add to scene first
	get_tree().current_scene.add_child(portal)
	
	# Set position after adding to scene
	portal.global_position = portal_position + normal * 0.1  # Slightly offset from surface
	
	# Orient portal to face outward from the surface
	portal.look_at(portal_position + normal, Vector3.UP)
	
	# Set portal properties
	portal.set_portal_type(portal_type)
	portal.set_paired_portal(blue_portal if portal_type == "orange" else orange_portal)
	
	# Store reference
	if portal_type == "blue":
		blue_portal = portal
		if orange_portal:
			orange_portal.set_paired_portal(blue_portal)
	else:
		orange_portal = portal
		if blue_portal:
			blue_portal.set_paired_portal(orange_portal)
	
	print("Created ", portal_type, " portal at ", portal_position)

func handle_portal_teleportation(from_portal: Node3D, to_portal: Node3D):
	if not to_portal:
		return
	
	# Calculate player's relative position and velocity to entrance portal
	var relative_pos = global_position - from_portal.global_position
	var relative_vel = velocity
	
	# Transform to exit portal's coordinate system
	var new_position = to_portal.global_position + to_portal.global_transform.basis * relative_pos
	var new_velocity = to_portal.global_transform.basis * relative_vel
	
	# Teleport player
	global_position = new_position
	velocity = new_velocity
	
	print("Player teleported through portal")
