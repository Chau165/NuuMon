extends CharacterBody3D

@export_group("Movement")
@export var walk_speed := 5.0
@export var sprint_speed := 9.0
@export var jump_velocity := 7.0
@export var acceleration := 20.0
@export var deceleration := 25.0
@export var visual_turn_speed := 10.0

@export_group("Camera")
@export var mouse_sensitivity := 0.0025
@export var min_pitch_degrees := -60.0
@export var max_pitch_degrees := 30.0

@export_group("Recovery")
@export var fall_reset_y := -20.0
@export var spawn_height_offset := 0.25

@onready var visual: Node3D = $Visual
@onready var camera_pivot: Node3D = $CameraPivot
@onready var camera: Camera3D = $CameraPivot/SpringArm3D/Camera3D
@onready var debug_label: Label = $DebugOverlay/Panel/Label

var gravity := 9.8
var spawn_position := Vector3.ZERO
var spawn_yaw := 0.0


func _ready() -> void:
	gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity", 9.8))
	_setup_spawn()
	_ensure_runtime_input_actions()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	camera.make_current()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotate_y(-event.relative.x * mouse_sensitivity)
		camera_pivot.rotate_x(-event.relative.y * mouse_sensitivity)
		camera_pivot.rotation.x = clampf(
			camera_pivot.rotation.x,
			deg_to_rad(min_pitch_degrees),
			deg_to_rad(max_pitch_degrees)
		)
		return

	if event.is_action_pressed("toggle_mouse_capture"):
		Input.mouse_mode = (
			Input.MOUSE_MODE_VISIBLE
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED
			else Input.MOUSE_MODE_CAPTURED
		)
	elif event.is_action_pressed("reset_player"):
		reset_to_spawn()


func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity

	var input_vector := Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction := _get_camera_relative_direction(input_vector)
	var target_speed := sprint_speed if Input.is_action_pressed("sprint") else walk_speed
	var rate := acceleration if direction != Vector3.ZERO else deceleration

	velocity.x = move_toward(velocity.x, direction.x * target_speed, rate * delta)
	velocity.z = move_toward(velocity.z, direction.z * target_speed, rate * delta)

	if direction != Vector3.ZERO:
		var target_yaw := atan2(direction.x, direction.z)
		visual.global_rotation.y = lerp_angle(
			visual.global_rotation.y,
			target_yaw,
			visual_turn_speed * delta
		)

	move_and_slide()
	if global_position.y < fall_reset_y:
		reset_to_spawn()

	_update_debug_overlay()


func reset_to_spawn() -> void:
	global_position = spawn_position
	rotation.y = spawn_yaw
	velocity = Vector3.ZERO


func _setup_spawn() -> void:
	spawn_position = global_position
	spawn_yaw = global_rotation.y
	var world := get_parent()
	if world == null:
		return

	var marker := world.get_node_or_null("SpawnPoints/PlayerSpawn") as Marker3D
	if marker == null:
		return

	spawn_position = marker.global_position + Vector3.UP * spawn_height_offset
	spawn_yaw = marker.global_rotation.y
	reset_to_spawn()


func _get_camera_relative_direction(input_vector: Vector2) -> Vector3:
	if input_vector == Vector2.ZERO:
		return Vector3.ZERO

	var camera_forward := -camera.global_transform.basis.z
	var camera_right := camera.global_transform.basis.x
	camera_forward.y = 0.0
	camera_right.y = 0.0
	return (camera_right.normalized() * input_vector.x - camera_forward.normalized() * input_vector.y).normalized()


func _ensure_runtime_input_actions() -> void:
	var fallback_keys := {
		"move_forward": KEY_W,
		"move_backward": KEY_S,
		"move_left": KEY_A,
		"move_right": KEY_D,
		"jump": KEY_SPACE,
		"sprint": KEY_SHIFT,
		"toggle_mouse_capture": KEY_ESCAPE,
		"reset_player": KEY_R,
	}
	for action: StringName in fallback_keys:
		if InputMap.has_action(action):
			continue
		InputMap.add_action(action)
		var fallback_event := InputEventKey.new()
		fallback_event.keycode = fallback_keys[action]
		InputMap.action_add_event(action, fallback_event)


func _update_debug_overlay() -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	debug_label.text = "FPS: %d\nPosition: (%.1f, %.1f, %.1f)\nSpeed: %.1f m/s\nGrounded: %s" % [
		Engine.get_frames_per_second(),
		global_position.x,
		global_position.y,
		global_position.z,
		horizontal_speed,
		is_on_floor(),
	]
