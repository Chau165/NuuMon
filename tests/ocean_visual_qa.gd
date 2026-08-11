extends Node3D

@export var capture_name := "baseline"
@export var warmup_seconds := 4.0
@export var sample_seconds := 3.0
@export var quit_after_capture := false

@onready var world: Node3D = $WorldIsland
@onready var camera: Camera3D = $CaptureCamera

var _sample_elapsed := 0.0
var _sample_frames := 0
var _sampling := false
var _minimum_fps := INF
var _maximum_frame_time_ms := 0.0


func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_hide_gameplay_debug_ui()
	_place_camera_at_shoreline()
	camera.make_current()
	await get_tree().create_timer(warmup_seconds).timeout
	_sampling = true
	await get_tree().create_timer(sample_seconds).timeout
	_sampling = false
	await RenderingServer.frame_post_draw
	_capture_and_quit()


func _process(delta: float) -> void:
	if not _sampling:
		return
	_sample_elapsed += delta
	_sample_frames += 1
	if delta > 0.0:
		_minimum_fps = minf(_minimum_fps, 1.0 / delta)
		_maximum_frame_time_ms = maxf(_maximum_frame_time_ms, delta * 1000.0)


func _hide_gameplay_debug_ui() -> void:
	var debug_overlay := world.get_node_or_null("PlayerPrototype/DebugOverlay") as CanvasLayer
	if debug_overlay != null:
		debug_overlay.visible = false


func _place_camera_at_shoreline() -> void:
	var terrain := world.get_node_or_null("Terrain3D") as Terrain3D
	var shoreline_z := 760.0
	if terrain != null and terrain.data != null:
		var last_land_z := shoreline_z
		for sample_z in range(600, 1101, 2):
			var height := terrain.data.get_height(Vector3(0.0, 0.0, float(sample_z)))
			if not is_nan(height) and height > 0.35:
				last_land_z = float(sample_z)
			elif last_land_z > 600.0:
				break
		shoreline_z = last_land_z

	var camera_position := Vector3(54.0, 20.0, shoreline_z + 92.0)
	var camera_target := Vector3(0.0, 1.2, shoreline_z - 18.0)
	camera.global_position = camera_position
	camera.look_at(camera_target, Vector3.UP)
	print("OCEAN_QA_CAMERA shoreline_z=%.1f camera=%s target=%s" % [shoreline_z, camera_position, camera_target])


func _capture_and_quit() -> void:
	var capture_dir := "res://tests/screenshots"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(capture_dir))
	var screenshot_path := "%s/ocean_%s.png" % [capture_dir, capture_name]
	var image := get_viewport().get_texture().get_image()
	var save_error := image.save_png(screenshot_path)
	var average_fps := 0.0
	if _sample_elapsed > 0.0:
		average_fps = float(_sample_frames) / _sample_elapsed
	print(
		"OCEAN_QA_CAPTURE pass=%s average_fps=%.1f min_fps=%.1f max_frame_ms=%.2f engine_fps=%d screenshot=%s save_error=%d" % [
			capture_name,
			average_fps,
			_minimum_fps,
			_maximum_frame_time_ms,
			Engine.get_frames_per_second(),
			ProjectSettings.globalize_path(screenshot_path),
			save_error,
		]
	)
	if quit_after_capture:
		get_tree().quit()
