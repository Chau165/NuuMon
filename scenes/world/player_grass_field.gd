extends MultiMeshInstance3D

const GRASS_SCENE: PackedScene = preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Grass_Common_Short.gltf")
const GRASS_SHADER := preload("res://scenes/world/stylized_grass.gdshader")
const GRASS_TEXTURE_IDS := [2, 3]

@export_group("Coverage")
@export var field_radius := 34.0
@export var cell_size := 0.55
@export_range(0.0, 1.0, 0.01) var density := 0.88
@export var rebuild_distance := 7.0
@export_range(0.0, 60.0, 0.5) var max_slope_degrees := 42.0

@export_group("Grass Shape")
@export var minimum_scale := 0.17
@export var maximum_scale := 0.3
@export var position_jitter := 0.25

var _terrain: Terrain3D
var _player: Node3D
var _last_center := Vector2(INF, INF)
var _patch_noise := FastNoiseLite.new()


func _ready() -> void:
	visible = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_patch_noise.seed = 48271
	_patch_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_patch_noise.frequency = 0.035
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
		push_warning("PlayerGrassField could not find Terrain3D or PlayerPrototype.")
		return

	var source_scene := GRASS_SCENE.instantiate()
	var source_mesh := _find_mesh(source_scene)
	source_scene.free()
	if source_mesh == null:
		push_warning("PlayerGrassField could not load Grass_Common_Short mesh.")
		return

	multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.mesh = source_mesh
	material_override = _create_material()
	_rebuild_field(Vector2(_player.global_position.x, _player.global_position.z))
	visible = true


func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var child_mesh := _find_mesh(child)
		if child_mesh != null:
			return child_mesh
	return null


func _create_material() -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = GRASS_SHADER
	material.set_shader_parameter("base_color", Color("276f30"))
	material.set_shader_parameter("tip_color", Color("4e9f3c"))
	material.set_shader_parameter("wind_strength", 0.045)
	material.set_shader_parameter("patch_strength", 0.08)
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

	var transforms: Array[Transform3D] = []
	var minimum_height := INF
	var maximum_height := -INF
	var half_cells := ceili(field_radius / cell_size)
	var maximum_slope_cosine := cos(deg_to_rad(max_slope_degrees))

	for grid_z in range(-half_cells, half_cells + 1):
		for grid_x in range(-half_cells, half_cells + 1):
			var world_cell_x := floori(snapped_center.x / cell_size) + grid_x
			var world_cell_z := floori(snapped_center.y / cell_size) + grid_z
			var random := RandomNumberGenerator.new()
			random.seed = hash(Vector2i(world_cell_x, world_cell_z))
			var world_x := world_cell_x * cell_size + random.randf_range(-position_jitter, position_jitter)
			var world_z := world_cell_z * cell_size + random.randf_range(-position_jitter, position_jitter)
			var offset_xz := Vector2(world_x - snapped_center.x, world_z - snapped_center.y)
			var normalized_distance := offset_xz.length() / field_radius
			if normalized_distance >= 1.0:
				continue

			var radial_density := 1.0 - smoothstep(0.72, 1.0, normalized_distance)
			var patch_value := remap(_patch_noise.get_noise_2d(world_x, world_z), -1.0, 1.0, 0.0, 1.0)
			var patch_density := lerpf(0.28, 1.0, smoothstep(0.22, 0.78, patch_value))
			var sample_position := Vector3(world_x, 0.0, world_z)
			var texture_weight := _get_grass_texture_weight(sample_position)
			if random.randf() > density * patch_density * radial_density * texture_weight:
				continue

			var height := _terrain.data.get_height(sample_position)
			if is_nan(height):
				continue
			var terrain_normal := _terrain.data.get_normal(sample_position)
			if is_nan(terrain_normal.x) or terrain_normal.y < maximum_slope_cosine:
				continue

			var instance_scale := random.randf_range(minimum_scale, maximum_scale)
			var instance_basis := _basis_from_normal(terrain_normal, random.randf_range(-PI, PI))
			instance_basis = instance_basis.scaled(Vector3.ONE * instance_scale)
			transforms.append(Transform3D(instance_basis, Vector3(offset_xz.x, height, offset_xz.y)))
			minimum_height = minf(minimum_height, height)
			maximum_height = maxf(maximum_height, height)

	multimesh.instance_count = transforms.size()
	for index in transforms.size():
		multimesh.set_instance_transform(index, transforms[index])
	multimesh.visible_instance_count = transforms.size()

	if not transforms.is_empty():
		multimesh.custom_aabb = AABB(
			Vector3(-field_radius, minimum_height - 2.0, -field_radius),
			Vector3(field_radius * 2.0, maximum_height - minimum_height + 5.0, field_radius * 2.0)
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
	var bitangent := tangent.cross(terrain_normal).normalized()
	return Basis(tangent, terrain_normal, bitangent).rotated(terrain_normal, yaw_angle)
