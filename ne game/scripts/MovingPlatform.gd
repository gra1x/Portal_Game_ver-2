extends AnimatableBody3D

@export var move_speed = 2.0
@export var pause_time = 1.0
@export var movement_type = "linear"  # "linear", "circular", "pendulum"
@export var waypoints: Array[Vector3] = []
@export var radius = 5.0  # For circular movement
@export var auto_start = true

var current_waypoint = 0
var start_position: Vector3
var is_moving = false
var pause_timer = 0.0
var move_timer = 0.0
var initial_position: Vector3

@onready var mesh_instance = $MeshInstance3D

func _ready():
	initial_position = global_position
	start_position = global_position
	
	# Set up default waypoints if none provided
	if waypoints.is_empty() and movement_type == "linear":
		waypoints = [
			start_position,
			start_position + Vector3(10, 0, 0),
			start_position + Vector3(10, 0, 10),
			start_position + Vector3(0, 0, 10)
		]
	
	if auto_start:
		is_moving = true
	
	# Make platform orange-ish color
	if mesh_instance:
		var material = StandardMaterial3D.new()
		material.albedo_color = Color.ORANGE
		material.emission = Color.ORANGE * 0.2
		mesh_instance.set_surface_override_material(0, material)

func _physics_process(delta):
	if not is_moving:
		return
	
	match movement_type:
		"linear":
			linear_movement(delta)
		"circular":
			circular_movement(delta)
		"pendulum":
			pendulum_movement(delta)

func linear_movement(delta):
	if pause_timer > 0:
		pause_timer -= delta
		return
	
	if waypoints.is_empty():
		return
	
	var target = waypoints[current_waypoint]
	var direction = (target - global_position).normalized()
	var distance_to_target = global_position.distance_to(target)
	
	if distance_to_target < 0.1:
		# Reached waypoint
		current_waypoint = (current_waypoint + 1) % waypoints.size()
		pause_timer = pause_time
		return
	
	# Move towards target
	var movement = direction * move_speed * delta
	if movement.length() > distance_to_target:
		movement = direction * distance_to_target
	
	global_position += movement

func circular_movement(delta):
	move_timer += delta
	var angle = move_timer * move_speed
	var x = start_position.x + cos(angle) * radius
	var z = start_position.z + sin(angle) * radius
	global_position = Vector3(x, start_position.y, z)

func pendulum_movement(delta):
	move_timer += delta
	var swing_factor = sin(move_timer * move_speed)
	
	if waypoints.size() >= 2:
		var start_pos = waypoints[0]
		var end_pos = waypoints[1]
		global_position = start_pos.lerp(end_pos, (swing_factor + 1.0) / 2.0)
	else:
		# Default pendulum movement
		global_position = start_position + Vector3(swing_factor * 5, 0, 0)

func start_moving():
	is_moving = true

func stop_moving():
	is_moving = false

func set_waypoints(new_waypoints: Array[Vector3]):
	waypoints = new_waypoints
	current_waypoint = 0
