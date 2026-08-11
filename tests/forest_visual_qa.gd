extends Node

const BIOME_ELIGIBILITY := preload("res://scenes/world/biome_eligibility.gd")
const CAPTURE_ENABLED := false
const CAPTURE_TAG := "wind_pass1"
const PRINT_BIOME_PROFILE := false
const DEBUG_BIOME_MASK_ENABLED := false
const VIEWS := [
	{"name": "spawn", "xz": Vector2(0.0, 750.0), "yaw": 0.0, "pitch": -14.0},
	{"name": "beach_side", "xz": Vector2(0.0, 750.0), "yaw": 90.0, "pitch": -12.0},
	{"name": "forest_edge", "xz": Vector2(4.6, 635.0), "yaw": 0.0, "pitch": -10.0},
	{"name": "forest_edge_wind_later", "xz": Vector2(4.6, 635.0), "yaw": 0.0, "pitch": -10.0},
	{"name": "deep_forest", "xz": Vector2(-1.0, 585.0), "yaw": 0.0, "pitch": -8.0},
	{"name": "deep_canopy", "xz": Vector2(-1.0, 585.0), "yaw": 0.0, "pitch": 18.0},
	{"name": "deep_interior", "xz": Vector2(34.0, 585.0), "yaw": -18.0, "pitch": -6.0},
	{"name": "deep_interior_canopy", "xz": Vector2(34.0, 585.0), "yaw": -18.0, "pitch": 16.0},
	{"name": "large_tree_scale", "tree_tier": 0, "near": Vector2(22.0, 590.0), "pitch": 8.0},
	{"name": "medium_tree_scale", "tree_tier": 1, "near": Vector2(-22.0, 590.0), "pitch": 8.0},
]


func _ready() -> void:
	if CAPTURE_ENABLED:
		_capture_views.call_deferred()


func _capture_views() -> void:
	var world := get_tree().current_scene
	var terrain := world.find_child("Terrain3D", true, false) as Terrain3D
	var player := world.find_child("PlayerPrototype", true, false) as CharacterBody3D
	if terrain == null or terrain.data == null or player == null:
		push_warning("ForestVisualQA could not find Terrain3D or PlayerPrototype.")
		return
	var biome := world.find_child("BiomeEligibility", true, false)
	if biome == null:
		push_warning("ForestVisualQA could not find BiomeEligibility.")
		return
	biome.configure(terrain)
	if PRINT_BIOME_PROFILE:
		_print_spawn_biome_profile(biome)

	await get_tree().create_timer(3.0).timeout
	var forest_cover := world.find_child("IslandForestCover", true, false)
	for view: Dictionary in VIEWS:
		var xz: Vector2
		var yaw := float(view.get("yaw", 0.0))
		if view.has("tree_tier") and forest_cover != null:
			var tree_sample: Dictionary = forest_cover.get_qa_tree_sample(int(view.tree_tier), view.near)
			if tree_sample.is_empty():
				continue
			var tree_position: Vector2 = tree_sample.position
			xz = tree_position + Vector2(0.0, 13.0)
			print(
				"FOREST_QA_TREE view=%s target=(%.1f,%.1f) height=%.2f crown=%.2f" % [
					view.name, tree_position.x, tree_position.y, tree_sample.height, tree_sample.crown,
				]
			)
		else:
			xz = view.xz
		var sample_position := Vector3(xz.x, 0.0, xz.y)
		var terrain_height := terrain.data.get_height(sample_position)
		if is_nan(terrain_height):
			continue

		player.global_position = Vector3(xz.x, terrain_height + 1.05, xz.y)
		player.rotation.y = deg_to_rad(yaw)
		player.velocity = Vector3.ZERO
		var pivot := player.get_node_or_null("CameraPivot") as Node3D
		if pivot != null:
			pivot.rotation.x = deg_to_rad(float(view.pitch))

		for _frame in 24:
			await get_tree().physics_frame
		var benchmark_start := Time.get_ticks_usec()
		for _frame in 90:
			await get_tree().process_frame
		var measured_fps := 90.0 / maxf(float(Time.get_ticks_usec() - benchmark_start) / 1000000.0, 0.001)
		var debug_label := player.get_node_or_null("DebugOverlay/Panel/Label") as Label
		if debug_label != null:
			debug_label.text = "FPS (90f avg): %.1f\nPosition: (%.1f, %.1f, %.1f)\nSpeed: 0.0 m/s\nGrounded: %s" % [
				measured_fps,
				player.global_position.x,
				player.global_position.y,
				player.global_position.z,
				player.is_on_floor(),
			]
		await RenderingServer.frame_post_draw

		var screenshot_path := "user://forest_qa_%s_%s.png" % [CAPTURE_TAG, view.name]
		var save_error := get_viewport().get_texture().get_image().save_png(screenshot_path)
		print(
			"FOREST_QA tag=%s view=%s fps=%.1f player=(%.1f, %.1f, %.1f) screenshot=%s save_error=%d" % [
				CAPTURE_TAG,
				view.name,
				measured_fps,
				player.global_position.x,
				player.global_position.y,
				player.global_position.z,
				ProjectSettings.globalize_path(screenshot_path),
				save_error,
			]
		)

	if DEBUG_BIOME_MASK_ENABLED:
		await _capture_biome_mask(terrain, biome, player)


func _print_spawn_biome_profile(biome: Node) -> void:
	for z_position in range(760, 399, -10):
		var world_position := Vector3(0.0, 0.0, float(z_position))
		var sample: Dictionary = biome.get_texture_sample(world_position)
		var biome_class: int = biome.classify(world_position)
		print(
			"BIOME_PROFILE z=%d base=%d overlay=%d blend=%.2f dominant=%d class=%s" % [
				z_position,
				int(sample.get("base_id", -1)),
				int(sample.get("overlay_id", -1)),
				float(sample.get("blend", 0.0)),
				int(sample.get("dominant_id", -1)),
				biome.get_class_name(biome_class),
			]
		)


func _capture_biome_mask(terrain: Terrain3D, biome: Node, player: CharacterBody3D) -> void:
	var debug_root := Node3D.new()
	debug_root.name = "BiomeMaskDebug"
	add_child(debug_root)
	var transforms_by_class: Dictionary = {}
	for biome_class in BIOME_ELIGIBILITY.VegetationClass.values():
		transforms_by_class[biome_class] = []

	for z_position in range(580, 761, 4):
		for x_position in range(-80, 81, 4):
			var sample_position := Vector3(float(x_position), 0.0, float(z_position))
			var height := terrain.data.get_height(sample_position)
			if is_nan(height):
				continue
			var biome_class: int = biome.classify(sample_position)
			transforms_by_class[biome_class].append(
				Transform3D(Basis.IDENTITY, Vector3(sample_position.x, height + 0.08, sample_position.z))
			)

	var colors := {
		BIOME_ELIGIBILITY.VegetationClass.SAND: Color(0.95, 0.03, 0.03),
		BIOME_ELIGIBILITY.VegetationClass.BEACH_CLEAR: Color(1.0, 0.38, 0.0),
		BIOME_ELIGIBILITY.VegetationClass.BEACH_TRANSITION_LOW: Color(1.0, 0.78, 0.0),
		BIOME_ELIGIBILITY.VegetationClass.BEACH_TRANSITION_HIGH: Color(1.0, 0.95, 0.0),
		BIOME_ELIGIBILITY.VegetationClass.MEADOW: Color(0.15, 0.75, 1.0),
		BIOME_ELIGIBILITY.VegetationClass.FOREST: Color(0.05, 0.9, 0.12),
		BIOME_ELIGIBILITY.VegetationClass.OTHER: Color(0.65, 0.15, 0.9),
	}
	for biome_class: int in transforms_by_class:
		var transforms: Array = transforms_by_class[biome_class]
		if transforms.is_empty():
			continue
		var material := StandardMaterial3D.new()
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		material.albedo_color = colors[biome_class]
		var marker_mesh := BoxMesh.new()
		marker_mesh.size = Vector3(2.6, 0.05, 2.6)
		marker_mesh.material = material
		var marker_multimesh := MultiMesh.new()
		marker_multimesh.transform_format = MultiMesh.TRANSFORM_3D
		marker_multimesh.mesh = marker_mesh
		marker_multimesh.instance_count = transforms.size()
		for index in transforms.size():
			marker_multimesh.set_instance_transform(index, transforms[index])
		var marker_layer := MultiMeshInstance3D.new()
		marker_layer.multimesh = marker_multimesh
		marker_layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		debug_root.add_child(marker_layer)

	var xz := Vector2(0.0, 655.0)
	var player_height := terrain.data.get_height(Vector3(xz.x, 0.0, xz.y))
	player.global_position = Vector3(xz.x, player_height + 1.05, xz.y)
	player.rotation.y = 0.0
	player.velocity = Vector3.ZERO
	var pivot := player.get_node_or_null("CameraPivot") as Node3D
	if pivot != null:
		pivot.rotation.x = deg_to_rad(-30.0)
	for _frame in 18:
		await get_tree().physics_frame
	await get_tree().create_timer(1.0).timeout
	await RenderingServer.frame_post_draw
	var screenshot_path := "user://forest_qa_%s_biome_mask.png" % CAPTURE_TAG
	var save_error := get_viewport().get_texture().get_image().save_png(screenshot_path)
	print(
		"FOREST_QA tag=%s view=biome_mask fps=%d screenshot=%s save_error=%d" % [
			CAPTURE_TAG,
			Engine.get_frames_per_second(),
			ProjectSettings.globalize_path(screenshot_path),
			save_error,
		]
	)
	debug_root.queue_free()
