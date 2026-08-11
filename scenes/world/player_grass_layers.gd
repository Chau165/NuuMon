extends MultiMeshInstance3D

const MEDIUM_GRASS_SCENE: PackedScene = preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Grass_Common_Short.gltf")
const TALL_GRASS_SCENE: PackedScene = preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Grass_Wispy_Tall.gltf")
const GRASS_SHADER: Shader = preload("res://scenes/world/stylized_grass.gdshader")
const GRASS_TEXTURE_IDS := [2, 3]
const BENCHMARK_CAPTURE_ENABLED := false
const BENCHMARK_CAPTURE_TAG := "after_final_60fps"
const TURF_MESH_HEIGHT := 0.13

@export_group("Distance Rings")
@export var near_radius := 15.0
@export var middle_radius := 30.0
@export var far_radius := 52.0
@export var rebuild_distance := 10.0
@export_range(0.0, 60.0, 0.5) var max_slope_degrees := 42.0

@export_group("Turf Density")
@export var near_turf_spacing := 0.22
@export_range(0.0, 1.0, 0.01) var near_turf_density := 0.80
@export var middle_turf_spacing := 0.35
@export_range(0.0, 1.0, 0.01) var middle_turf_density := 0.58
@export var far_turf_spacing := 0.60
@export_range(0.0, 1.0, 0.01) var far_turf_density := 0.23

@export_group("Grass Sizes")
@export var turf_height_range := Vector2(0.055, 0.16)
@export var medium_height_range := Vector2(0.22, 0.38)
@export var tall_height_range := Vector2(0.42, 0.72)

var _terrain: Terrain3D
var _player: Node3D
var _medium_layer: MultiMeshInstance3D
var _tall_layer: MultiMeshInstance3D
var _last_center := Vector2(INF, INF)
var _patch_noise := FastNoiseLite.new()
var _medium_mesh_height := 1.0
var _tall_mesh_height := 1.0
var _last_counts := Vector3i.ZERO


func _ready() -> void:
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_patch_noise.seed = 48271
	_patch_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_patch_noise.frequency = 0.028
	_patch_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_patch_noise.fractal_octaves = 3
	_initialize.call_deferred()


func _process(_delta: float) -> void:
	if _terrain == null or _player == null:
		return

	var player_xz := Vector2(_player.global_position.x, _player.global_position.z)
	if player_xz.distance_to(_last_center) >= rebuild_distance:
		_rebuild_field(player_xz)


func _initialize() -> void:
	var world := get_tree().current_scene
	if world == null:
		return

	_terrain = world.find_child("Terrain3D", true, false) as Terrain3D
	_player = world.find_child("PlayerPrototype", true, false) as Node3D
	if _terrain == null or _terrain.data == null or _player == null:
		push_warning("PlayerGrassLayers could not find Terrain3D or PlayerPrototype.")
		return

	var turf_mesh := _create_turf_mesh()
	var medium_mesh := _load_first_mesh(MEDIUM_GRASS_SCENE)
	var tall_mesh := _load_first_mesh(TALL_GRASS_SCENE)
	if medium_mesh == null or tall_mesh == null:
		push_warning("PlayerGrassLayers could not load medium or tall grass meshes.")
		return

	_medium_mesh_height = maxf(medium_mesh.get_aabb().size.y, 0.001)
	_tall_mesh_height = maxf(tall_mesh.get_aabb().size.y, 0.001)

	multimesh = _create_multimesh(turf_mesh)
	material_override = _create_material(turf_mesh, Color("1d7305"), Color("2b8409"), 0.007, 0.03, 0.04, 0.0)
	visibility_range_end = far_radius + 8.0
	extra_cull_margin = 1.0

	_medium_layer = _create_layer(
		"MediumGrass",
		medium_mesh,
		_create_material(medium_mesh, Color("1a6807"), Color("28790b"), 0.02, 0.04, 0.05, 0.0),
		48.0,
		GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	)
	_tall_layer = _create_layer(
		"TallGrassAccents",
		tall_mesh,
		_create_material(tall_mesh, Color("195f09"), Color("246f0d"), 0.03, 0.05, 0.06, 0.0),
		44.0,
		GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	)

	_rebuild_field(Vector2(_player.global_position.x, _player.global_position.z))
	visible = true
	_capture_visual_benchmark.call_deferred()


func _create_multimesh(source_mesh: Mesh) -> MultiMesh:
	var result := MultiMesh.new()
	result.transform_format = MultiMesh.TRANSFORM_3D
	result.use_custom_data = true
	result.mesh = source_mesh
	return result


func _create_layer(
	layer_name: String,
	source_mesh: Mesh,
	layer_material: ShaderMaterial,
	draw_distance: float,
	shadow_mode: GeometryInstance3D.ShadowCastingSetting
) -> MultiMeshInstance3D:
	var layer := MultiMeshInstance3D.new()
	layer.name = layer_name
	layer.multimesh = _create_multimesh(source_mesh)
	layer.material_override = layer_material
	layer.cast_shadow = shadow_mode
	layer.visibility_range_end = draw_distance
	layer.extra_cull_margin = 1.0
	add_child(layer)
	return layer


func _load_first_mesh(scene: PackedScene) -> Mesh:
	var source := scene.instantiate()
	var source_mesh := _find_mesh(source)
	source.free()
	return source_mesh


func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var child_mesh := _find_mesh(child)
		if child_mesh != null:
			return child_mesh
	return null


func _create_turf_mesh() -> ArrayMesh:
	var vertices: Array[Vector3] = []
	var normals: Array[Vector3] = []
	var indices: Array[int] = []
	for blade_index in 2:
		var yaw := float(blade_index) * PI * 0.5 + 0.23
		var base_offset := Vector3.ZERO
		var height := TURF_MESH_HEIGHT * (1.0 - float(blade_index) * 0.12)
		var width := 0.036 - float(blade_index) * 0.006
		var reach := 0.032 + float(blade_index) * 0.008
		_append_turf_blade(vertices, normals, indices, base_offset, yaw, height, width, reach)

	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = PackedVector3Array(vertices)
	arrays[Mesh.ARRAY_NORMAL] = PackedVector3Array(normals)
	arrays[Mesh.ARRAY_INDEX] = PackedInt32Array(indices)
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


func _append_turf_blade(
	vertices: Array[Vector3],
	normals: Array[Vector3],
	indices: Array[int],
	base_offset: Vector3,
	yaw: float,
	height: float,
	width: float,
	reach: float
) -> void:
	var forward := Vector3(sin(yaw), 0.0, cos(yaw))
	var side := Vector3(forward.z, 0.0, -forward.x)
	var base_center := base_offset
	var middle_center := base_offset + forward * reach * 0.52 + Vector3.UP * height * 0.57
	var tip_center := base_offset + forward * reach + Vector3.UP * height
	var start := vertices.size()
	vertices.append(base_center - side * width * 0.42)
	vertices.append(base_center + side * width * 0.42)
	vertices.append(middle_center - side * width * 0.5)
	vertices.append(middle_center + side * width * 0.5)
	vertices.append(tip_center)
	for _vertex_index in 5:
		# Upward normals keep the low turf evenly lit regardless of blade direction.
		normals.append(Vector3.UP)
	indices.append_array([
		start,
		start + 1,
		start + 2,
		start + 1,
		start + 3,
		start + 2,
		start + 2,
		start + 3,
		start + 4,
	])


func _create_material(
	source_mesh: Mesh,
	base_color: Color,
	tip_color: Color,
	wind_strength: float,
	patch_strength: float,
	instance_color_strength: float,
	emission_strength: float
) -> ShaderMaterial:
	var mesh_aabb := source_mesh.get_aabb()
	var material := ShaderMaterial.new()
	material.shader = GRASS_SHADER
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("tip_color", tip_color)
	material.set_shader_parameter("wind_strength", wind_strength)
	material.set_shader_parameter("patch_strength", patch_strength)
	material.set_shader_parameter("instance_color_strength", instance_color_strength)
	material.set_shader_parameter("emission_strength", emission_strength)
	material.set_shader_parameter("mesh_bottom", mesh_aabb.position.y)
	material.set_shader_parameter("mesh_height", maxf(mesh_aabb.size.y, 0.001))
	return material


func _rebuild_field(player_xz: Vector2) -> void:
	var snapped_center := Vector2(
		roundf(player_xz.x / rebuild_distance) * rebuild_distance,
		roundf(player_xz.y / rebuild_distance) * rebuild_distance
	)
	if snapped_center == _last_center:
		return
	_last_center = snapped_center
	global_position = Vector3(snapped_center.x, 0.0, snapped_center.y)

	var turf_transforms: Array[Transform3D] = []
	var turf_custom_data: Array[Color] = []
	var medium_transforms: Array[Transform3D] = []
	var medium_custom_data: Array[Color] = []
	var tall_transforms: Array[Transform3D] = []
	var tall_custom_data: Array[Color] = []

	_append_ring(turf_transforms, turf_custom_data, snapped_center, 0.0, near_radius, near_turf_spacing, near_turf_density, TURF_MESH_HEIGHT, turf_height_range, Vector2(0.82, 1.24), 101, 0.10, 0.0, false)
	_append_ring(turf_transforms, turf_custom_data, snapped_center, near_radius, middle_radius, middle_turf_spacing, middle_turf_density, TURF_MESH_HEIGHT, Vector2(0.05, 0.14), Vector2(0.80, 1.26), 102, 0.14, 0.0, false)
	_append_ring(turf_transforms, turf_custom_data, snapped_center, middle_radius, far_radius, far_turf_spacing, far_turf_density, TURF_MESH_HEIGHT, Vector2(0.045, 0.12), Vector2(0.76, 1.20), 103, 0.22, 7.0, false)

	_append_ring(medium_transforms, medium_custom_data, snapped_center, 0.0, near_radius, 0.78, 0.55, _medium_mesh_height, medium_height_range, Vector2(0.82, 1.24), 201, 0.38, 0.0, true)
	_append_ring(medium_transforms, medium_custom_data, snapped_center, near_radius, middle_radius, 0.95, 0.52, _medium_mesh_height, medium_height_range, Vector2(0.78, 1.22), 202, 0.46, 0.0, true)
	_append_ring(medium_transforms, medium_custom_data, snapped_center, middle_radius, 45.0, 1.65, 0.30, _medium_mesh_height, Vector2(0.20, 0.34), Vector2(0.72, 1.16), 203, 0.56, 6.0, true)

	_append_ring(tall_transforms, tall_custom_data, snapped_center, 0.0, near_radius, 1.50, 0.38, _tall_mesh_height, tall_height_range, Vector2(0.78, 1.18), 301, 0.60, 0.0, true)
	_append_ring(tall_transforms, tall_custom_data, snapped_center, near_radius, middle_radius, 1.95, 0.36, _tall_mesh_height, tall_height_range, Vector2(0.74, 1.16), 302, 0.66, 0.0, true)
	_append_ring(tall_transforms, tall_custom_data, snapped_center, middle_radius, 42.0, 2.75, 0.22, _tall_mesh_height, Vector2(0.40, 0.64), Vector2(0.70, 1.12), 303, 0.73, 5.0, true)

	_apply_instances(self, turf_transforms, turf_custom_data, far_radius, turf_height_range.y)
	_apply_instances(_medium_layer, medium_transforms, medium_custom_data, 45.0, medium_height_range.y)
	_apply_instances(_tall_layer, tall_transforms, tall_custom_data, 42.0, tall_height_range.y)
	_last_counts = Vector3i(turf_transforms.size(), medium_transforms.size(), tall_transforms.size())
	print(
		"GRASS_LAYERS turf=%d medium=%d tall=%d rings=0-%.0f/%.0f/%.0f heights=%.2f-%.2f/%.2f-%.2f/%.2f-%.2f" % [
			_last_counts.x,
			_last_counts.y,
			_last_counts.z,
			near_radius,
			middle_radius,
			far_radius,
			turf_height_range.x,
			turf_height_range.y,
			medium_height_range.x,
			medium_height_range.y,
			tall_height_range.x,
			tall_height_range.y,
		]
	)


func _append_ring(
	transforms: Array[Transform3D],
	custom_data: Array[Color],
	center: Vector2,
	inner_radius: float,
	outer_radius: float,
	spacing: float,
	spawn_density: float,
	mesh_height: float,
	height_range: Vector2,
	xz_scale_range: Vector2,
	seed_offset: int,
	patch_influence: float,
	edge_fade_width: float,
	normalize_width_to_height: bool
) -> void:
	var half_cells := ceili(outer_radius / spacing)
	var maximum_slope_cosine := cos(deg_to_rad(max_slope_degrees))
	var center_cell_x := floori(center.x / spacing)
	var center_cell_z := floori(center.y / spacing)
	var random := RandomNumberGenerator.new()

	for grid_z in range(-half_cells, half_cells + 1):
		for grid_x in range(-half_cells, half_cells + 1):
			var world_cell_x := center_cell_x + grid_x
			var world_cell_z := center_cell_z + grid_z
			random.seed = hash(Vector3i(world_cell_x, world_cell_z, seed_offset))
			var jitter := spacing * 0.42
			var world_x := world_cell_x * spacing + random.randf_range(-jitter, jitter)
			var world_z := world_cell_z * spacing + random.randf_range(-jitter, jitter)
			var offset_xz := Vector2(world_x - center.x, world_z - center.y)
			var distance := offset_xz.length()
			if distance < inner_radius or distance >= outer_radius:
				continue

			var patch_value := remap(_patch_noise.get_noise_2d(world_x, world_z), -1.0, 1.0, 0.0, 1.0)
			var patch_multiplier := lerpf(1.0 - patch_influence, 1.0 + patch_influence * 0.32, smoothstep(0.16, 0.84, patch_value))
			var edge_multiplier := 1.0
			if edge_fade_width > 0.0:
				edge_multiplier = 1.0 - smoothstep(outer_radius - edge_fade_width, outer_radius, distance)
			var sample_position := Vector3(world_x, 0.0, world_z)
			var texture_weight := _get_grass_texture_weight(sample_position)
			var effective_density := clampf(spawn_density * patch_multiplier * edge_multiplier * texture_weight, 0.0, 1.0)
			if random.randf() > effective_density:
				continue

			var terrain_height := _terrain.data.get_height(sample_position)
			if is_nan(terrain_height):
				continue
			var terrain_normal := _terrain.data.get_normal(sample_position)
			if is_nan(terrain_normal.x) or terrain_normal.y < maximum_slope_cosine:
				continue

			var target_height := random.randf_range(height_range.x, height_range.y)
			var scale_y := target_height / mesh_height
			var width_base := scale_y if normalize_width_to_height else 1.0
			var scale_x := width_base * random.randf_range(xz_scale_range.x, xz_scale_range.y)
			var scale_z := width_base * random.randf_range(xz_scale_range.x, xz_scale_range.y)
			var instance_basis := _basis_from_normal(terrain_normal, random.randf_range(-PI, PI))
			instance_basis = instance_basis.scaled(Vector3(scale_x, scale_y, scale_z))
			transforms.append(Transform3D(instance_basis, Vector3(offset_xz.x, terrain_height + 0.012, offset_xz.y)))
			custom_data.append(Color(random.randf(), 0.0, 0.0, 1.0))


func _apply_instances(
	layer: MultiMeshInstance3D,
	transforms: Array[Transform3D],
	custom_data: Array[Color],
	radius: float,
	maximum_blade_height: float
) -> void:
	var layer_multimesh := layer.multimesh
	layer_multimesh.instance_count = transforms.size()
	var minimum_y := INF
	var maximum_y := -INF
	for index in transforms.size():
		layer_multimesh.set_instance_transform(index, transforms[index])
		layer_multimesh.set_instance_custom_data(index, custom_data[index])
		minimum_y = minf(minimum_y, transforms[index].origin.y)
		maximum_y = maxf(maximum_y, transforms[index].origin.y)
	layer_multimesh.visible_instance_count = transforms.size()

	if not transforms.is_empty():
		layer_multimesh.custom_aabb = AABB(
			Vector3(-radius, minimum_y - 1.0, -radius),
			Vector3(radius * 2.0, maximum_y - minimum_y + maximum_blade_height + 2.0, radius * 2.0)
		)


func _get_grass_texture_weight(world_position: Vector3) -> float:
	var texture_info := _terrain.data.get_texture_id(world_position)
	var base_id := int(texture_info.x)
	var overlay_id := int(texture_info.y)
	var blend := texture_info.z
	var weight := 0.0
	if base_id in GRASS_TEXTURE_IDS:
		weight += 1.0 - blend
	if overlay_id in GRASS_TEXTURE_IDS:
		weight += blend
	return clampf(weight, 0.0, 1.0)


func _basis_from_normal(terrain_normal: Vector3, yaw_angle: float) -> Basis:
	var tangent := Vector3.RIGHT.slide(terrain_normal).normalized()
	if tangent.length_squared() < 0.001:
		tangent = Vector3.FORWARD.slide(terrain_normal).normalized()
	var bitangent := tangent.cross(terrain_normal).normalized()
	return Basis(tangent, terrain_normal, bitangent).rotated(terrain_normal, yaw_angle)


func _capture_visual_benchmark() -> void:
	if not BENCHMARK_CAPTURE_ENABLED:
		return

	var benchmark_xz := Vector2(0.0, 630.0)
	var benchmark_sample := Vector3(benchmark_xz.x, 0.0, benchmark_xz.y)
	var benchmark_height := _terrain.data.get_height(benchmark_sample)
	if is_nan(benchmark_height):
		push_warning("Grass benchmark could not sample terrain height.")
		return

	_player.global_position = Vector3(benchmark_xz.x, benchmark_height + 1.05, benchmark_xz.y)
	_player.rotation.y = 0.0
	if _player is CharacterBody3D:
		(_player as CharacterBody3D).velocity = Vector3.ZERO
	var pivot := _player.get_node_or_null("CameraPivot") as Node3D
	if pivot != null:
		pivot.rotation = Vector3(deg_to_rad(-24.0), 0.0, 0.0)

	for _frame in 24:
		await get_tree().physics_frame
	await get_tree().create_timer(1.5).timeout
	await RenderingServer.frame_post_draw

	var screenshot_path := "user://grass_benchmark_%s.png" % BENCHMARK_CAPTURE_TAG
	var save_error := get_viewport().get_texture().get_image().save_png(screenshot_path)
	print(
		"GRASS_BENCHMARK tag=%s turf=%d medium=%d tall=%d fps=%d screenshot=%s save_error=%d" % [
			BENCHMARK_CAPTURE_TAG,
			_last_counts.x,
			_last_counts.y,
			_last_counts.z,
			Engine.get_frames_per_second(),
			ProjectSettings.globalize_path(screenshot_path),
			save_error,
		]
	)
