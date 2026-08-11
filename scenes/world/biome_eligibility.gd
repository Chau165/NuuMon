class_name BiomeEligibility
extends Node

enum VegetationClass {
	SAND,
	BEACH_CLEAR,
	BEACH_TRANSITION_LOW,
	BEACH_TRANSITION_HIGH,
	MEADOW,
	FOREST,
	OTHER,
}

const SAND_TEXTURE_IDS := [0, 1]
const MEADOW_TEXTURE_IDS := [2]
const FOREST_TEXTURE_IDS := [3, 4]
const VEGETATION_TEXTURE_IDS := [2, 3, 4]
const FOREST_GATEWAY_ORIGIN := Vector2(0.0, 750.0)
const SAMPLE_DIRECTIONS := [
	Vector2(1.0, 0.0),
	Vector2(0.70710678, 0.70710678),
	Vector2(0.0, 1.0),
	Vector2(-0.70710678, 0.70710678),
	Vector2(-1.0, 0.0),
	Vector2(-0.70710678, -0.70710678),
	Vector2(0.0, -1.0),
	Vector2(0.70710678, -0.70710678),
]

@export var cache_cell_size := 2.0

var _terrain: Terrain3D
var _class_cache: Dictionary = {}
var _forest_noise := FastNoiseLite.new()
var _forest_detail_noise := FastNoiseLite.new()
var _noise_configured := false


func _ready() -> void:
	_configure_noise()


func configure(terrain: Terrain3D) -> void:
	_configure_noise()
	if terrain == _terrain:
		return
	_terrain = terrain
	_class_cache.clear()


func get_texture_sample(world_position: Vector3) -> Dictionary:
	if _terrain == null or _terrain.data == null:
		return {}
	var texture_info := _terrain.data.get_texture_id(world_position)
	var base_id := int(texture_info.x)
	var overlay_id := int(texture_info.y)
	var blend := clampf(texture_info.z, 0.0, 1.0)
	return {
		"base_id": base_id,
		"overlay_id": overlay_id,
		"blend": blend,
		"dominant_id": overlay_id if blend >= 0.5 else base_id,
	}


func get_dominant_texture_id(world_position: Vector3) -> int:
	var sample := get_texture_sample(world_position)
	return int(sample.get("dominant_id", -1))


func is_sand_position(world_position: Vector3) -> bool:
	return get_dominant_texture_id(world_position) in SAND_TEXTURE_IDS


func is_forest_position(world_position: Vector3) -> bool:
	var biome_class := classify(world_position)
	if biome_class not in [VegetationClass.MEADOW, VegetationClass.FOREST]:
		return false
	return get_forest_strength(world_position) >= 0.42


func is_transition_position(world_position: Vector3) -> bool:
	var biome_class := classify(world_position)
	return biome_class in [
		VegetationClass.BEACH_CLEAR,
		VegetationClass.BEACH_TRANSITION_LOW,
		VegetationClass.BEACH_TRANSITION_HIGH,
	]


func classify(world_position: Vector3) -> int:
	var cache_key := Vector2i(
		floori(world_position.x / cache_cell_size),
		floori(world_position.z / cache_cell_size)
	)
	if _class_cache.has(cache_key):
		return int(_class_cache[cache_key])

	var dominant_id := get_dominant_texture_id(world_position)
	var result := VegetationClass.OTHER
	if dominant_id in SAND_TEXTURE_IDS:
		result = VegetationClass.SAND
	elif dominant_id in VEGETATION_TEXTURE_IDS:
		var sand_distance_band := _find_sand_distance_band(world_position)
		if sand_distance_band == 1:
			result = VegetationClass.BEACH_CLEAR
		elif sand_distance_band == 2:
			result = VegetationClass.BEACH_TRANSITION_LOW
		elif sand_distance_band == 3:
			result = VegetationClass.BEACH_TRANSITION_HIGH
		elif dominant_id in FOREST_TEXTURE_IDS:
			result = VegetationClass.FOREST
		else:
			result = VegetationClass.MEADOW

	_class_cache[cache_key] = result
	return result


func get_grass_density_multiplier(world_position: Vector3) -> float:
	var biome_class := classify(world_position)
	match biome_class:
		VegetationClass.BEACH_TRANSITION_LOW:
			return 0.08
		VegetationClass.BEACH_TRANSITION_HIGH:
			return 0.28
		VegetationClass.MEADOW, VegetationClass.FOREST:
			if is_forest_position(world_position):
				return 0.08 if get_dominant_texture_id(world_position) == 4 else 0.14
			return 1.0
		_:
			return 0.0


func get_understory_density_multiplier(world_position: Vector3) -> float:
	var biome_class := classify(world_position)
	match biome_class:
		VegetationClass.BEACH_TRANSITION_LOW:
			return 0.08
		VegetationClass.BEACH_TRANSITION_HIGH:
			return 0.28
		VegetationClass.MEADOW, VegetationClass.FOREST:
			return get_forest_strength(world_position) if is_forest_position(world_position) else 0.0
		_:
			return 0.0


func get_class_name(biome_class: int) -> String:
	return VegetationClass.keys()[biome_class]


func get_forest_strength(world_position: Vector3) -> float:
	_configure_noise()
	var world_xz := Vector2(world_position.x, world_position.z)
	var broad := remap(_forest_noise.get_noise_2d(world_xz.x, world_xz.y), -1.0, 1.0, 0.0, 1.0)
	var detail := remap(_forest_detail_noise.get_noise_2d(world_xz.x, world_xz.y), -1.0, 1.0, 0.0, 1.0)
	var procedural_strength := smoothstep(0.34, 0.72, broad * 0.72 + detail * 0.28)

	var local := world_xz - FOREST_GATEWAY_ORIGIN
	var inland_depth := -local.y
	var depth_window := smoothstep(98.0, 145.0, inland_depth)
	depth_window *= 1.0 - smoothstep(390.0, 500.0, inland_depth)
	var lateral_window := 1.0 - smoothstep(150.0, 290.0, absf(local.x))
	var gateway_strength := depth_window * lateral_window

	if get_dominant_texture_id(world_position) in FOREST_TEXTURE_IDS:
		procedural_strength = maxf(procedural_strength, 0.78)
	return clampf(maxf(procedural_strength, gateway_strength), 0.0, 1.0)


func _configure_noise() -> void:
	if _noise_configured:
		return
	_noise_configured = true
	_forest_noise.seed = 73129
	_forest_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_forest_noise.frequency = 0.0026
	_forest_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_forest_noise.fractal_octaves = 3
	_forest_detail_noise.seed = 91427
	_forest_detail_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	_forest_detail_noise.frequency = 0.010
	_forest_detail_noise.fractal_type = FastNoiseLite.FRACTAL_FBM
	_forest_detail_noise.fractal_octaves = 2


func _find_sand_distance_band(world_position: Vector3) -> int:
	for band_index in 3:
		var near_radius := float(band_index * 4 + 2)
		var far_radius := float((band_index + 1) * 4)
		for direction: Vector2 in SAMPLE_DIRECTIONS:
			if _is_sand_offset(world_position, direction * near_radius):
				return band_index + 1
			if _is_sand_offset(world_position, direction * far_radius):
				return band_index + 1
	return 0


func _is_sand_offset(world_position: Vector3, offset: Vector2) -> bool:
	var sample_position := world_position + Vector3(offset.x, 0.0, offset.y)
	return get_dominant_texture_id(sample_position) in SAND_TEXTURE_IDS
