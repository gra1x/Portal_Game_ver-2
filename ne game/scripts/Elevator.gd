extends StaticBody3D
class_name Elevator

signal floor_changed(new_floor: int)
signal player_entered_elevator
signal player_exited_elevator

@export var floors: Array[float] = [0.0, 5.0, 10.0]  # Y positions of each floor
@export var elevator_speed: float = 3.0
@export var door_open_time: float = 3.0
@export var auto_close_doors: bool = true

var current_floor: int = 0
var target_floor: int = 0
var is_moving: bool = false
var doors_open: bool = false
var players_inside: Array[CharacterBody3D] = []

# Components
@onready var platform: MeshInstance3D = $Platform
@onready var left_door: MeshInstance3D = $LeftDoor
@onready var right_door: MeshInstance3D = $RightDoor
@onready var call_area: Area3D = $CallArea
@onready var elevator_area: Area3D = $ElevatorArea
@onready var movement_sound: AudioStreamPlayer3D = $MovementSound
@onready var door_sound: AudioStreamPlayer3D = $DoorSound
@onready var arrival_sound: AudioStreamPlayer3D = $ArrivalSound

# UI elements
@onready var floor_display: Label3D = $FloorDisplay
@onready var button_panel: Node3D = $ButtonPanel

# Door positions
var left_door_open_pos: Vector3
var left_door_closed_pos: Vector3
var right_door_open_pos: Vector3
var right_door_closed_pos: Vector3

func _ready():
	# Set up initial positions
	setup_elevator()
	
	# Connect area signals
	call_area.body_entered.connect(_on_call_area_entered)
	call_area.body_exited.connect(_on_call_area_exited)
	elevator_area.body_entered.connect(_on_elevator_area_entered)
	elevator_area.body_exited.connect(_on_elevator_area_exited)
	
	# Set up button panel
	setup_button_panel()
	
	print("Elevator initialized with ", floors.size(), " floors")

func setup_elevator():
	# Store door positions
	if left_door:
		left_door_closed_pos = left_door.position
		left_door_open_pos = left_door_closed_pos + Vector3(-2.0, 0, 0)
	
	if right_door:
		right_door_closed_pos = right_door.position
		right_door_open_pos = right_door_closed_pos + Vector3(2.0, 0, 0)
	
	# Set initial floor
	if floors.size() > 0:
		global_position.y = floors[current_floor]
	
	# Update floor display
	update_floor_display()

func setup_button_panel():
	if not button_panel:
		return
	
	# Create buttons for each floor
	for i in range(floors.size()):
		var button = create_floor_button(i)
		button_panel.add_child(button)

func create_floor_button(floor_index: int) -> Area3D:
	var button = Area3D.new()
	button.name = "FloorButton" + str(floor_index)
	
	# Button mesh
	var mesh_instance = MeshInstance3D.new()
	button.add_child(mesh_instance)
	
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.3, 0.3, 0.1)
	mesh_instance.mesh = box_mesh
	
	# Button material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color.GRAY
	material.emission_enabled = true
	material.emission = Color(0.2, 0.2, 0.2)
	mesh_instance.material_override = material
	
	# Button collision
	var collision_shape = CollisionShape3D.new()
	button.add_child(collision_shape)
	
	var box_shape = BoxShape3D.new()
	box_shape.size = Vector3(0.3, 0.3, 0.1)
	collision_shape.shape = box_shape
	
	# Position button
	button.position = Vector3(0, (floors.size() - 1 - floor_index) * 0.4, 0)
	
	# Add floor number label
	var label = Label3D.new()
	button.add_child(label)
	label.text = str(floor_index + 1)
	label.position = Vector3(0, 0, 0.06)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	# Connect button signal
	button.input_event.connect(_on_floor_button_pressed.bind(floor_index))
	
	return button

func _on_call_area_entered(body):
	if body.is_in_group("player"):
		show_elevator_ui()

func _on_call_area_exited(body):
	if body.is_in_group("player"):
		hide_elevator_ui()

func _on_elevator_area_entered(body):
	if body is CharacterBody3D and body.is_in_group("player"):
		players_inside.append(body)
		player_entered_elevator.emit()
		print("Player entered elevator")

func _on_elevator_area_exited(body):
	if body is CharacterBody3D and body.is_in_group("player"):
		players_inside.erase(body)
		player_exited_elevator.emit()
		print("Player exited elevator")

func _on_floor_button_pressed(floor_index: int, camera, event, click_position, normal):
	if event is InputEventMouseButton and event.pressed:
		call_elevator_to_floor(floor_index)

func show_elevator_ui():
	# Highlight button panel
	if button_panel:
		var tween = create_tween()
		tween.tween_property(button_panel, "scale", Vector3(1.1, 1.1, 1.1), 0.2)

func hide_elevator_ui():
	# Return button panel to normal
	if button_panel:
		var tween = create_tween()
		tween.tween_property(button_panel, "scale", Vector3(1.0, 1.0, 1.0), 0.2)

func call_elevator_to_floor(floor_index: int):
	if floor_index < 0 or floor_index >= floors.size():
		print("Invalid floor index: ", floor_index)
		return
	
	if is_moving:
		print("Elevator is already moving")
		return
	
	if floor_index == current_floor:
		# Just open doors if on same floor
		if not doors_open:
			open_doors()
		return
	
	target_floor = floor_index
	print("Elevator called to floor ", target_floor + 1)
	
	# Close doors before moving
	if doors_open:
		close_doors()
		await get_tree().create_timer(2.0).timeout  # Wait for doors to close
	
	# Move elevator
	move_to_floor(target_floor)

func move_to_floor(floor_index: int):
	if is_moving or floor_index < 0 or floor_index >= floors.size():
		return
	
	is_moving = true
	var target_y = floors[floor_index]
	var start_y = global_position.y
	var distance = abs(target_y - start_y)
	var move_time = distance / elevator_speed
	
	print("Moving elevator from floor ", current_floor + 1, " to floor ", floor_index + 1)
	
	# Play movement sound
	if movement_sound:
		movement_sound.play()
	
	# Animate elevator movement
	var tween = create_tween()
	tween.tween_property(self, "global_position:y", target_y, move_time)
	
	# Move players with elevator
	for player in players_inside:
		if is_instance_valid(player):
			var player_start_y = player.global_position.y
			var player_target_y = player_start_y + (target_y - start_y)
			tween.parallel().tween_property(player, "global_position:y", player_target_y, move_time)
	
	await tween.finished
	
	# Update current floor
	current_floor = floor_index
	is_moving = false
	
	# Play arrival sound
	if arrival_sound:
		arrival_sound.play()
	
	# Update display and open doors
	update_floor_display()
	floor_changed.emit(current_floor)
	
	# Open doors
	open_doors()
	
	print("Elevator arrived at floor ", current_floor + 1)

func open_doors():
	if doors_open or is_moving:
		return
	
	doors_open = true
	print("Opening elevator doors")
	
	# Play door sound
	if door_sound:
		door_sound.play()
	
	# Animate doors opening
	var tween = create_tween()
	if left_door:
		tween.parallel().tween_property(left_door, "position", left_door_open_pos, 1.0)
	if right_door:
		tween.parallel().tween_property(right_door, "position", right_door_open_pos, 1.0)
	
	# Auto-close doors after delay
	if auto_close_doors:
		await get_tree().create_timer(door_open_time).timeout
		close_doors()

func close_doors():
	if not doors_open:
		return
	
	doors_open = false
	print("Closing elevator doors")
	
	# Play door sound
	if door_sound:
		door_sound.play()
	
	# Animate doors closing
	var tween = create_tween()
	if left_door:
		tween.parallel().tween_property(left_door, "position", left_door_closed_pos, 1.0)
	if right_door:
		tween.parallel().tween_property(right_door, "position", right_door_closed_pos, 1.0)

func update_floor_display():
	if floor_display:
		floor_display.text = "Floor " + str(current_floor + 1)

# Emergency functions
func emergency_stop():
	if not is_moving:
		return
	
	print("EMERGENCY STOP activated")
	
	# Stop all tweens
	var tween = get_tree().get_tween()
	if tween:
		tween.kill()
	
	is_moving = false
	
	# Play alarm sound
	if movement_sound:
		movement_sound.stop()

func maintenance_mode(enabled: bool):
	if enabled:
		print("Elevator entering maintenance mode")
		emergency_stop()
		# Disable all interactions
		call_area.monitoring = false
	else:
		print("Elevator exiting maintenance mode")
		call_area.monitoring = true

# Public interface
func get_current_floor() -> int:
	return current_floor

func get_floor_count() -> int:
	return floors.size()

func is_elevator_moving() -> bool:
	return is_moving

func are_doors_open() -> bool:
	return doors_open

func get_floor_height(floor_index: int) -> float:
	if floor_index >= 0 and floor_index < floors.size():
		return floors[floor_index]
	return 0.0

# Express elevator function (skip floors)
func express_to_floor(floor_index: int):
	if floor_index < 0 or floor_index >= floors.size() or is_moving:
		return
	
	print("Express elevator to floor ", floor_index + 1)
	
	# Close doors immediately
	doors_open = false
	
	# Instant movement for express
	is_moving = true
	global_position.y = floors[floor_index]
	
	# Move players instantly
	for player in players_inside:
		if is_instance_valid(player):
			var height_diff = floors[floor_index] - floors[current_floor]
			player.global_position.y += height_diff
	
	current_floor = floor_index
	is_moving = false
	
	update_floor_display()
	floor_changed.emit(current_floor)
	open_doors()
