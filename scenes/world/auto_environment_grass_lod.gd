extends Node3D

const STYLIZED_GRASS_SHADER := preload("res://scenes/world/stylized_grass.gdshader")

@export_group("Legacy Baked Grass")
@export var enable_baked_grass := false

@export_group("Grass Density")
@export_range(0.0, 1.0, 0.01) var beach_density := 0.03
@export_range(0.0, 1.0, 0.01) var meadow_density := 1.0
@export_range(0.0, 1.0, 0.01) var forest_density := 0.85
@export_range(0.0, 1.0, 0.01) var foothill_density := 0.4
@export_range(0.0, 1.0, 0.01) var alpine_density := 0.06
@export_range(0.0, 1.0, 0.01) var tall_grass_ratio := 0.18

@export_group("Grass Clustering")
@export_range(1.0, 5.0, 0.05) var meadow_short_multiplier := 4.0
@export_range(1.0, 4.0, 0.05) var forest_short_multiplier := 2.5
@export_range(1.0, 3.0, 0.05) var foothill_short_multiplier := 1.6

@export_group("Grass Draw Distance")
@export var beach_draw_distance := 85.0
@export var meadow_draw_distance := 190.0
@export var forest_draw_distance := 165.0
@export var foothill_draw_distance := 120.0
@export var alpine_draw_distance := 80.0


func _ready() -> void:
	_apply_biome("Beach", beach_density, beach_draw_distance, 1.0, _create_grass_material(Color("59682f"), Color("89974e"), 0.025))
	_apply_biome("Meadow", meadow_density, meadow_draw_distance, meadow_short_multiplier, _create_grass_material(Color("236b31"), Color("70c84f"), 0.05))
	_apply_biome("Forest", forest_density, forest_draw_distance, forest_short_multiplier, _create_grass_material(Color("184a29"), Color("55943f"), 0.035))
	_apply_biome("Mountain", foothill_density, foothill_draw_distance, foothill_short_multiplier, _create_grass_material(Color("3d6034"), Color("819254"), 0.045))
	_apply_biome("Alpine", alpine_density, alpine_draw_distance, 1.0, _create_grass_material(Color("536447"), Color("8a9a70"), 0.055))
	_apply_biome("Snow", 0.0, alpine_draw_distance, 1.0, null)


func _create_grass_material(base_color: Color, tip_color: Color, wind_strength: float) -> ShaderMaterial:
	var material := ShaderMaterial.new()
	material.shader = STYLIZED_GRASS_SHADER
	material.set_shader_parameter("base_color", base_color)
	material.set_shader_parameter("tip_color", tip_color)
	material.set_shader_parameter("wind_strength", wind_strength)
	return material


func _apply_biome(biome_name: String, density: float, draw_distance: float, short_multiplier: float, material: ShaderMaterial) -> void:
	var biome := get_node_or_null(biome_name)
	if biome == null:
		return

	for child in biome.get_children():
		if child is not MultiMeshInstance3D or not child.name.begins_with("Grass"):
			continue

		var grass := child as MultiMeshInstance3D
		grass.visible = enable_baked_grass
		if not enable_baked_grass:
			continue

		var grass_name := String(grass.name)
		var instance_density := density
		var cluster_multiplier := maxf(1.0, short_multiplier * 0.55)
		if "Tall" in grass_name:
			instance_density *= tall_grass_ratio
			cluster_multiplier = 1.0
		elif "Short" in grass_name:
			cluster_multiplier = short_multiplier

		grass.material_override = material
		grass.extra_cull_margin = 0.25
		grass.visibility_range_end = draw_distance
		grass.visibility_range_end_margin = minf(30.0, draw_distance * 0.18)
		if grass.multimesh != null:
			_expand_cluster(grass, cluster_multiplier)
			grass.multimesh.visible_instance_count = roundi(grass.multimesh.instance_count * instance_density)


func _expand_cluster(grass: MultiMeshInstance3D, multiplier: float) -> void:
	var multimesh := grass.multimesh
	var source_count := multimesh.instance_count
	var target_count := roundi(source_count * multiplier)
	if source_count == 0 or target_count <= source_count:
		return

	var source_transforms: Array[Transform3D] = []
	for index in source_count:
		source_transforms.append(multimesh.get_instance_transform(index))

	multimesh.instance_count = target_count
	for index in source_count:
		multimesh.set_instance_transform(index, source_transforms[index])

	var random := RandomNumberGenerator.new()
	random.seed = hash(grass.get_path())
	for index in range(source_count, target_count):
		var source := source_transforms[index % source_count]
		var offset := Vector3(random.randf_range(-1.1, 1.1), 0.0, random.randf_range(-1.1, 1.1))
		var yaw_angle := random.randf_range(-PI, PI)
		var instance_scale := random.randf_range(0.8, 1.15)
		var instance_basis := Basis(Vector3.UP, yaw_angle).scaled(Vector3.ONE * instance_scale)
		multimesh.set_instance_transform(index, Transform3D(instance_basis, source.origin + offset))
