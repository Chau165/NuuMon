extends Node3D

enum TreeTier { LARGE, MEDIUM, SAPLING }

const PRINT_ASSET_AABB := false

const TREE_SCENES: Array[PackedScene] = [
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/MapleTree_1.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/MapleTree_2.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/MapleTree_3.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/MapleTree_4.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/MapleTree_5.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/BirchTree_1.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/BirchTree_2.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/BirchTree_3.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/BirchTree_4.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/BirchTree_5.gltf"),
]
const TREE_NAMES := [
	"Maple1", "Maple2", "Maple3", "Maple4", "Maple5",
	"Birch1", "Birch2", "Birch3", "Birch4", "Birch5",
]
const LARGE_MODEL_INDICES := [0, 1, 2, 4]
const MEDIUM_MODEL_INDICES := [0, 3, 4, 5, 6, 7, 9]
const SAPLING_MODEL_INDICES := [3, 5, 7, 8, 9]

const DEAD_TREE_SCENES: Array[PackedScene] = [
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_1.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_2.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_3.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_4.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_5.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_6.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_7.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_8.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_9.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/DeadTree_10.gltf"),
]
const ROCK_SCENES: Array[PackedScene] = [
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Rock_Medium_1.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Rock_Medium_2.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Rock_Medium_3.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Round_1.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Round_2.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Round_3.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Round_4.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Round_5.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Square_1.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Square_2.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Square_3.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Pebble_Square_4.gltf"),
]
const UNDERSTORY_SCENES: Array[PackedScene] = [
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Bush.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Bush_Flowers.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Bush_Large.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Bush_Large_Flowers.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Bush_Small.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Bush_Small_Flowers.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Fern_1.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Plant_1.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Plant_1_Big.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Plant_7.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Plant_7_Big.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Clover_1.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Clover_2.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Mushroom_Common.gltf"),
	preload("res://asset/Stylized Nature MegaKit[Standard]/glTF/Mushroom_Laetiporus.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Flower_1_Clump.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Flower_2_Clump.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Flower_3_Clump.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Flower_4_Clump.gltf"),
	preload("res://asset/Ultimate Stylized Nature - May 2022/glTF/Flower_5_Clump.gltf"),
]
const UNDERSTORY_NAMES := [
	"Bush", "BushFlowers", "BushLarge", "BushLargeFlowers", "BushSmall", "BushSmallFlowers",
	"Fern1", "Plant1", "Plant1Big", "Plant7", "Plant7Big", "Clover1", "Clover2",
	"MushroomCommon", "MushroomLaetiporus",
	"Flower1Clump", "Flower2Clump", "Flower3Clump", "Flower4Clump", "Flower5Clump",
]
const BUSH_MODEL_INDICES := [0, 1, 2, 3, 4, 5]
const FERN_MODEL_INDICES := [6]
const PLANT_MODEL_INDICES := [7, 8, 9, 10, 11, 12]
const MUSHROOM_MODEL_INDICES := [13, 14]
const FLOWER_MODEL_INDICES := [15, 16, 17, 18, 19]
const MEDIUM_ROCK_MODEL_INDICES := [0, 1, 2]

const MAP_HALF_EXTENT := 1024
const CLUSTER_CELL_SIZE := 22
const UNDERSTORY_CELL_SIZE := 6
const DETAIL_CELL_SIZE := 14
const RENDER_CHUNK_SIZE := 96.0
const SPAWN_POSITION := Vector2(0.0, 750.0)
const SPAWN_CLEAR_RADIUS := 12.0
const LOCAL_METRIC_CENTER := Vector2(0.0, 585.0)
const LOCAL_METRIC_RADIUS := 60.0
const CLEARING_CENTERS := [
	Vector2(-260.0, 230.0),
	Vector2(245.0, 100.0),
	Vector2(110.0, -330.0),
]
const CLEARING_RADII := [
	Vector2(130.0, 95.0),
	Vector2(120.0, 105.0),
	Vector2(125.0, 90.0),
]
const REPLACED_PROP_NAMES := [
	"Tree", "Pine", "Birch", "Bush", "Flower", "Rock", "Fern", "Plant", "Clover", "Mushroom",
]

@export_group("Forest Coverage")
@export_range(0.0, 1.0, 0.01) var forest_cluster_density := 0.78
@export_range(0.0, 1.0, 0.01) var understory_density := 0.82
@export_range(0.0, 60.0, 0.5) var maximum_slope_degrees := 38.0

var _terrain: Terrain3D
var _biome: Node
var _tree_meshes: Array[Mesh] = []
var _tree_sizes: Array[Vector2] = []
var _understory_meshes: Array[Mesh] = []
var _understory_sizes: Array[Vector2] = []
var _rock_meshes: Array[Mesh] = []
var _rock_sizes: Array[Vector2] = []
var _dead_tree_meshes: Array[Mesh] = []
var _dead_tree_sizes: Array[Vector2] = []
var _tree_stats: Array[Dictionary] = []
var _understory_stats: Array[Dictionary] = []


func _ready() -> void:
	_initialize.call_deferred()


func _initialize() -> void:
	var world := get_tree().current_scene
	if world == null:
		return
	_terrain = world.find_child("Terrain3D", true, false) as Terrain3D
	_biome = world.find_child("BiomeEligibility", true, false)
	if _terrain == null or _terrain.data == null or _biome == null:
		push_warning("IslandForestCover could not find Terrain3D data or BiomeEligibility.")
		return
	_biome.configure(_terrain)
	_prepare_tree_assets()
	_prepare_nature_assets()

	var hidden_instances := _hide_replaced_environment_props(world)
	var tree_counts := _generate_tree_clusters()
	var understory_counts := _generate_understory()
	var detail_counts := _generate_forest_details()
	_print_world_size_report()
	_print_local_metrics()
	print(
		"FOREST_CLUSTER_PASS large=%d medium=%d sapling=%d clusters=%d hidden_legacy=%d" % [
			tree_counts.large,
			tree_counts.medium,
			tree_counts.sapling,
			tree_counts.clusters,
			hidden_instances,
		]
	)
	print(
		"FOREST_UNDERSTORY_PASS bushes=%d ferns=%d plants_clover=%d mushrooms=%d flowers=%d rocks=%d dead_trees=%d" % [
			understory_counts.bushes,
			understory_counts.ferns,
			understory_counts.plants_clover,
			understory_counts.mushrooms,
			understory_counts.flowers,
			detail_counts.rocks,
			detail_counts.dead_trees,
		]
	)


func _prepare_tree_assets() -> void:
	_tree_meshes.clear()
	_tree_sizes.clear()
	for index in TREE_SCENES.size():
		var mesh := _load_first_mesh(TREE_SCENES[index])
		_tree_meshes.append(mesh)
		if mesh == null:
			_tree_sizes.append(Vector2.ONE)
			continue
		var source_size := mesh.get_aabb().size
		var crown_width := maxf(source_size.x, source_size.z)
		_tree_sizes.append(Vector2(crown_width, source_size.y))
		if PRINT_ASSET_AABB:
			print(
				"TREE_SOURCE_AABB model=%s width=%.2f height=%.2f triangles=%d" % [
					TREE_NAMES[index], crown_width, source_size.y, int(float(mesh.get_faces().size()) / 3.0),
				]
			)


func _prepare_nature_assets() -> void:
	_prepare_mesh_group(UNDERSTORY_SCENES, _understory_meshes, _understory_sizes, "UNDERSTORY")
	_prepare_mesh_group(ROCK_SCENES, _rock_meshes, _rock_sizes, "ROCK")
	_prepare_mesh_group(DEAD_TREE_SCENES, _dead_tree_meshes, _dead_tree_sizes, "DEAD_TREE")


func _prepare_mesh_group(
	scenes: Array[PackedScene],
	meshes: Array[Mesh],
	sizes: Array[Vector2],
	group_name: String
) -> void:
	meshes.clear()
	sizes.clear()
	for index in scenes.size():
		var mesh := _load_first_mesh(scenes[index])
		meshes.append(mesh)
		if mesh == null:
			sizes.append(Vector2.ONE)
			continue
		var source_size := mesh.get_aabb().size
		var width := maxf(source_size.x, source_size.z)
		sizes.append(Vector2(width, source_size.y))
		if PRINT_ASSET_AABB:
			print(
				"NATURE_SOURCE_AABB group=%s index=%d width=%.2f height=%.2f triangles=%d" % [
					group_name, index, width, source_size.y, int(float(mesh.get_faces().size()) / 3.0),
				]
			)


func _generate_tree_clusters() -> Dictionary:
	var large_sets := _new_mesh_sets(TREE_SCENES.size())
	var medium_sets := _new_mesh_sets(TREE_SCENES.size())
	var sapling_sets := _new_mesh_sets(TREE_SCENES.size())
	var tier_sets := {
		TreeTier.LARGE: large_sets,
		TreeTier.MEDIUM: medium_sets,
		TreeTier.SAPLING: sapling_sets,
	}
	var counts := {"large": 0, "medium": 0, "sapling": 0, "clusters": 0}
	var maximum_slope_cosine := cos(deg_to_rad(maximum_slope_degrees))

	for grid_z in range(-MAP_HALF_EXTENT, MAP_HALF_EXTENT + 1, CLUSTER_CELL_SIZE):
		for grid_x in range(-MAP_HALF_EXTENT, MAP_HALF_EXTENT + 1, CLUSTER_CELL_SIZE):
			var random := RandomNumberGenerator.new()
			random.seed = hash(Vector2i(grid_x * 11, grid_z * 11))
			var center_xz := Vector2(
				grid_x + random.randf_range(-CLUSTER_CELL_SIZE * 0.42, CLUSTER_CELL_SIZE * 0.42),
				grid_z + random.randf_range(-CLUSTER_CELL_SIZE * 0.42, CLUSTER_CELL_SIZE * 0.42)
			)
			if _is_in_clearing(center_xz):
				continue
			var center_surface := _sample_forest_surface(center_xz, maximum_slope_cosine)
			if center_surface.is_empty():
				continue
			var forest_strength: float = float(_biome.get_forest_strength(Vector3(center_xz.x, 0.0, center_xz.y)))
			if random.randf() > forest_cluster_density * lerpf(0.62, 1.0, forest_strength):
				continue
			_spawn_tree_cluster(tier_sets, center_xz, forest_strength, random, maximum_slope_cosine, counts)
			counts.clusters += 1

	_add_entrance_clusters(tier_sets, maximum_slope_cosine, counts)
	_add_tree_sets("ForestLarge", large_sets, 155.0, false)
	_add_tree_sets("ForestMedium", medium_sets, 92.0, false)
	_add_tree_sets("ForestSapling", sapling_sets, 62.0, false)
	return counts


func _spawn_tree_cluster(
	tier_sets: Dictionary,
	center_xz: Vector2,
	forest_strength: float,
	random: RandomNumberGenerator,
	maximum_slope_cosine: float,
	counts: Dictionary
) -> void:
	var placed_positions: Array[Vector2] = []
	var large_count := 1 + int(random.randf() < forest_strength * 0.82)
	var medium_count := random.randi_range(2, 4) + int(forest_strength > 0.82)
	var sapling_count := random.randi_range(3, 6)
	for _member in large_count:
		_try_add_tree(tier_sets, TreeTier.LARGE, center_xz, 0.0, 7.0, 5.8, placed_positions, random, maximum_slope_cosine, counts)
	for _member in medium_count:
		_try_add_tree(tier_sets, TreeTier.MEDIUM, center_xz, 2.5, 10.5, 3.3, placed_positions, random, maximum_slope_cosine, counts)
	for _member in sapling_count:
		_try_add_tree(tier_sets, TreeTier.SAPLING, center_xz, 1.5, 12.5, 1.45, placed_positions, random, maximum_slope_cosine, counts)


func _try_add_tree(
	tier_sets: Dictionary,
	tier: int,
	center_xz: Vector2,
	minimum_radius: float,
	maximum_radius: float,
	minimum_spacing: float,
	placed_positions: Array[Vector2],
	random: RandomNumberGenerator,
	maximum_slope_cosine: float,
	counts: Dictionary
) -> bool:
	for _attempt in 10:
		var direction := Vector2.from_angle(random.randf_range(-PI, PI))
		var candidate_xz := center_xz + direction * random.randf_range(minimum_radius, maximum_radius)
		if _is_reserved_area(candidate_xz):
			continue
		var overlaps_member := false
		for placed_position in placed_positions:
			if candidate_xz.distance_to(placed_position) < minimum_spacing:
				overlaps_member = true
				break
		if overlaps_member:
			continue
		var surface := _sample_forest_surface(candidate_xz, maximum_slope_cosine)
		if surface.is_empty():
			continue
		var model_index := _pick_tree_model(tier, random)
		var transform_info := _make_tree_transform(model_index, tier, surface.position, random)
		var transform_sets: Array = tier_sets[tier]
		transform_sets[model_index].append(transform_info.transform)
		placed_positions.append(candidate_xz)
		_tree_stats.append({
			"position": candidate_xz,
			"tier": tier,
			"height": transform_info.height,
			"crown": transform_info.crown,
		})
		if tier == TreeTier.LARGE:
			counts.large += 1
		elif tier == TreeTier.MEDIUM:
			counts.medium += 1
		else:
			counts.sapling += 1
		return true
	return false


func _pick_tree_model(tier: int, random: RandomNumberGenerator) -> int:
	var candidates: Array
	if tier == TreeTier.LARGE:
		candidates = LARGE_MODEL_INDICES
	elif tier == TreeTier.MEDIUM:
		candidates = MEDIUM_MODEL_INDICES
	else:
		candidates = SAPLING_MODEL_INDICES
	return int(candidates[random.randi_range(0, candidates.size() - 1)])


func _make_tree_transform(
	model_index: int,
	tier: int,
	world_position: Vector3,
	random: RandomNumberGenerator
) -> Dictionary:
	var target_height: float
	var target_crown: float
	if tier == TreeTier.LARGE:
		target_height = random.randf_range(10.0, 14.0)
		target_crown = random.randf_range(7.8, 11.0)
	elif tier == TreeTier.MEDIUM:
		target_height = random.randf_range(6.5, 9.3)
		target_crown = random.randf_range(4.8, 7.2)
	else:
		target_height = random.randf_range(3.0, 5.0)
		target_crown = random.randf_range(2.0, 3.8)

	var source_size: Vector2 = _tree_sizes[model_index]
	var requested_xz_scale := target_crown / maxf(source_size.x, 0.001)
	var requested_y_scale := target_height / maxf(source_size.y, 0.001)
	var base_scale := (requested_xz_scale + requested_y_scale) * 0.5
	var xz_scale := clampf(requested_xz_scale, base_scale * 0.84, base_scale * 1.16)
	var y_scale := clampf(requested_y_scale, base_scale * 0.84, base_scale * 1.16)
	var random_variation := random.randf_range(0.90, 1.10) if tier != TreeTier.SAPLING else random.randf_range(0.84, 1.16)
	xz_scale *= random_variation
	y_scale *= random_variation

	var tree_basis := Basis(Vector3.UP, random.randf_range(-PI, PI))
	tree_basis = tree_basis.scaled(Vector3(xz_scale, y_scale, xz_scale))
	return {
		"transform": Transform3D(tree_basis, world_position),
		"height": source_size.y * y_scale,
		"crown": source_size.x * xz_scale,
	}


func _add_entrance_clusters(tier_sets: Dictionary, maximum_slope_cosine: float, counts: Dictionary) -> void:
	var random := RandomNumberGenerator.new()
	random.seed = 40817
	for depth in [112.0, 132.0, 154.0, 179.0, 207.0, 238.0]:
		var path_center_x := _spawn_path_center_x(depth)
		for side in [-1.0, 1.0]:
			var center_xz := SPAWN_POSITION + Vector2(
				path_center_x + side * random.randf_range(10.0, 16.0),
				-depth
			)
			var surface := _sample_forest_surface(center_xz, maximum_slope_cosine)
			if surface.is_empty():
				continue
			_spawn_tree_cluster(tier_sets, center_xz, 1.0, random, maximum_slope_cosine, counts)
			counts.clusters += 1


func _generate_understory() -> Dictionary:
	var transform_sets := _new_mesh_sets(UNDERSTORY_SCENES.size())
	var counts := {"bushes": 0, "ferns": 0, "plants_clover": 0, "mushrooms": 0, "flowers": 0}
	var maximum_slope_cosine := cos(deg_to_rad(maximum_slope_degrees))

	for grid_z in range(-MAP_HALF_EXTENT, MAP_HALF_EXTENT + 1, UNDERSTORY_CELL_SIZE):
		for grid_x in range(-MAP_HALF_EXTENT, MAP_HALF_EXTENT + 1, UNDERSTORY_CELL_SIZE):
			var random := RandomNumberGenerator.new()
			random.seed = hash(Vector2i(grid_x * 5, grid_z * 5))
			var sample_xz := Vector2(
				grid_x + random.randf_range(-UNDERSTORY_CELL_SIZE * 0.46, UNDERSTORY_CELL_SIZE * 0.46),
				grid_z + random.randf_range(-UNDERSTORY_CELL_SIZE * 0.46, UNDERSTORY_CELL_SIZE * 0.46)
			)
			if _is_reserved_area(sample_xz):
				continue
			var surface := _sample_understory_surface(sample_xz, maximum_slope_cosine)
			if surface.is_empty():
				continue
			var biome_density := float(surface.biome_density)
			if random.randf() > understory_density * biome_density:
				continue
			_append_understory(transform_sets, surface, random, counts)

			if random.randf() < 0.28 * biome_density:
				var companion_direction := Vector2.from_angle(random.randf_range(-PI, PI))
				var companion_xz := sample_xz + companion_direction * random.randf_range(1.3, 3.2)
				if not _is_reserved_area(companion_xz):
					var companion_surface := _sample_understory_surface(companion_xz, maximum_slope_cosine)
					if not companion_surface.is_empty():
						_append_understory(transform_sets, companion_surface, random, counts)

	for model_index in UNDERSTORY_SCENES.size():
		_add_multimesh_layer(
			"ForestUnderstory_%s" % UNDERSTORY_NAMES[model_index],
			_understory_meshes[model_index],
			transform_sets[model_index],
			_understory_draw_distance(model_index),
			false
		)
	return counts


func _append_understory(
	transform_sets: Array,
	surface: Dictionary,
	random: RandomNumberGenerator,
	counts: Dictionary
) -> void:
	var model_index := _pick_understory_model(random)
	transform_sets[model_index].append(
		_make_understory_transform(model_index, surface.position, surface.normal, random)
	)
	var occlusion_radius := 0.25
	if model_index in BUSH_MODEL_INDICES:
		counts.bushes += 1
		occlusion_radius = 0.9
	elif model_index in FERN_MODEL_INDICES:
		counts.ferns += 1
		occlusion_radius = 0.72
	elif model_index in PLANT_MODEL_INDICES:
		counts.plants_clover += 1
		occlusion_radius = 0.46
	elif model_index in MUSHROOM_MODEL_INDICES:
		counts.mushrooms += 1
		occlusion_radius = 0.28
	else:
		counts.flowers += 1
	_understory_stats.append({"position": Vector2(surface.position.x, surface.position.z), "radius": occlusion_radius})


func _pick_understory_model(random: RandomNumberGenerator) -> int:
	var roll := random.randf()
	if roll < 0.40:
		return _pick_model_index(BUSH_MODEL_INDICES, random)
	if roll < 0.58:
		return _pick_model_index(FERN_MODEL_INDICES, random)
	if roll < 0.84:
		return _pick_model_index(PLANT_MODEL_INDICES, random)
	if roll < 0.93:
		return _pick_model_index(MUSHROOM_MODEL_INDICES, random)
	return _pick_model_index(FLOWER_MODEL_INDICES, random)


func _pick_model_index(candidates: Array, random: RandomNumberGenerator) -> int:
	return int(candidates[random.randi_range(0, candidates.size() - 1)])


func _understory_draw_distance(model_index: int) -> float:
	if model_index in BUSH_MODEL_INDICES or model_index in FERN_MODEL_INDICES:
		return 62.0
	if model_index in PLANT_MODEL_INDICES:
		return 50.0
	if model_index in MUSHROOM_MODEL_INDICES:
		return 34.0
	return 42.0


func _make_understory_transform(
	model_index: int,
	world_position: Vector3,
	normal: Vector3,
	random: RandomNumberGenerator
) -> Transform3D:
	var width_range: Vector2
	var height_range: Vector2
	if model_index in BUSH_MODEL_INDICES:
		width_range = Vector2(1.25, 2.55)
		height_range = Vector2(0.78, 1.62)
	elif model_index in FERN_MODEL_INDICES:
		width_range = Vector2(1.15, 2.35)
		height_range = Vector2(0.35, 0.82)
	elif model_index in PLANT_MODEL_INDICES:
		width_range = Vector2(0.48, 1.28)
		height_range = Vector2(0.18, 0.78)
	elif model_index in MUSHROOM_MODEL_INDICES:
		width_range = Vector2(0.24, 0.78)
		height_range = Vector2(0.15, 0.52)
	else:
		width_range = Vector2(0.22, 0.68)
		height_range = Vector2(0.25, 0.74)
	return _make_target_surface_transform(
		world_position,
		normal,
		random,
		_understory_sizes[model_index],
		width_range,
		height_range
	)


func _generate_forest_details() -> Dictionary:
	var rock_sets := _new_mesh_sets(ROCK_SCENES.size())
	var dead_tree_sets := _new_mesh_sets(DEAD_TREE_SCENES.size())
	var counts := {"rocks": 0, "dead_trees": 0}
	var maximum_slope_cosine := cos(deg_to_rad(maximum_slope_degrees))

	for grid_z in range(-MAP_HALF_EXTENT, MAP_HALF_EXTENT + 1, DETAIL_CELL_SIZE):
		for grid_x in range(-MAP_HALF_EXTENT, MAP_HALF_EXTENT + 1, DETAIL_CELL_SIZE):
			var random := RandomNumberGenerator.new()
			random.seed = hash(Vector2i(grid_x * 7, grid_z * 7))
			var sample_xz := Vector2(
				grid_x + random.randf_range(-DETAIL_CELL_SIZE * 0.44, DETAIL_CELL_SIZE * 0.44),
				grid_z + random.randf_range(-DETAIL_CELL_SIZE * 0.44, DETAIL_CELL_SIZE * 0.44)
			)
			if _is_reserved_area(sample_xz):
				continue
			var surface := _sample_forest_surface(sample_xz, maximum_slope_cosine)
			if surface.is_empty():
				continue
			if random.randf() < 0.16:
				_append_rock(rock_sets, surface, random)
				counts.rocks += 1
				if random.randf() < 0.38:
					for _companion in random.randi_range(1, 2):
						var direction := Vector2.from_angle(random.randf_range(-PI, PI))
						var companion_xz := sample_xz + direction * random.randf_range(0.55, 2.8)
						if _is_reserved_area(companion_xz):
							continue
						var companion_surface := _sample_forest_surface(companion_xz, maximum_slope_cosine)
						if companion_surface.is_empty():
							continue
						_append_rock(rock_sets, companion_surface, random)
						counts.rocks += 1
			if random.randf() < 0.018:
				var dead_index := random.randi_range(0, DEAD_TREE_SCENES.size() - 1)
				dead_tree_sets[dead_index].append(
					_make_target_surface_transform(
						surface.position,
						surface.normal,
						random,
						_dead_tree_sizes[dead_index],
						Vector2(2.2, 6.8),
						Vector2(4.0, 8.8)
					)
				)
				counts.dead_trees += 1

	for index in ROCK_SCENES.size():
		_add_multimesh_layer("ForestRock_%d" % index, _rock_meshes[index], rock_sets[index], 72.0, false)
	for index in DEAD_TREE_SCENES.size():
		_add_multimesh_layer("ForestDeadTree_%d" % index, _dead_tree_meshes[index], dead_tree_sets[index], 100.0, false)
	return counts


func _append_rock(transform_sets: Array, surface: Dictionary, random: RandomNumberGenerator) -> void:
	var model_index: int
	var width_range: Vector2
	var height_range: Vector2
	if random.randf() < 0.28:
		model_index = _pick_model_index(MEDIUM_ROCK_MODEL_INDICES, random)
		width_range = Vector2(0.85, 2.55)
		height_range = Vector2(0.45, 1.65)
	else:
		model_index = random.randi_range(3, ROCK_SCENES.size() - 1)
		width_range = Vector2(0.18, 0.72)
		height_range = Vector2(0.05, 0.22)
	transform_sets[model_index].append(
		_make_target_surface_transform(
			surface.position,
			surface.normal,
			random,
			_rock_sizes[model_index],
			width_range,
			height_range
		)
	)


func _sample_forest_surface(sample_xz: Vector2, maximum_slope_cosine: float) -> Dictionary:
	var sample_position := Vector3(sample_xz.x, 0.0, sample_xz.y)
	var height := _terrain.data.get_height(sample_position)
	if is_nan(height) or not _biome.is_forest_position(sample_position):
		return {}
	var terrain_normal := _terrain.data.get_normal(sample_position)
	if is_nan(terrain_normal.x) or terrain_normal.y < maximum_slope_cosine:
		return {}
	return {"position": Vector3(sample_xz.x, height, sample_xz.y), "normal": terrain_normal}


func _sample_understory_surface(sample_xz: Vector2, maximum_slope_cosine: float) -> Dictionary:
	var sample_position := Vector3(sample_xz.x, 0.0, sample_xz.y)
	var height := _terrain.data.get_height(sample_position)
	if is_nan(height):
		return {}
	var biome_density: float = float(_biome.get_understory_density_multiplier(sample_position))
	if biome_density <= 0.0:
		return {}
	var terrain_normal := _terrain.data.get_normal(sample_position)
	if is_nan(terrain_normal.x) or terrain_normal.y < maximum_slope_cosine:
		return {}
	return {
		"position": Vector3(sample_xz.x, height, sample_xz.y),
		"normal": terrain_normal,
		"biome_density": biome_density,
	}


func _make_target_surface_transform(
	world_position: Vector3,
	normal: Vector3,
	random: RandomNumberGenerator,
	source_size: Vector2,
	target_width_range: Vector2,
	target_height_range: Vector2
) -> Transform3D:
	var tangent := Vector3.RIGHT.slide(normal).normalized()
	if tangent.length_squared() < 0.001:
		tangent = Vector3.FORWARD.slide(normal).normalized()
	var bitangent := tangent.cross(normal).normalized()
	var instance_basis := Basis(tangent, normal, bitangent).rotated(normal, random.randf_range(-PI, PI))
	var target_width := random.randf_range(target_width_range.x, target_width_range.y)
	var target_height := random.randf_range(target_height_range.x, target_height_range.y)
	var requested_horizontal := target_width / maxf(source_size.x, 0.001)
	var requested_vertical := target_height / maxf(source_size.y, 0.001)
	var base_scale := (requested_horizontal + requested_vertical) * 0.5
	var horizontal_scale := clampf(requested_horizontal, base_scale * 0.68, base_scale * 1.32)
	var vertical_scale := clampf(requested_vertical, base_scale * 0.68, base_scale * 1.32)
	instance_basis = instance_basis.scaled(Vector3(horizontal_scale, vertical_scale, horizontal_scale))
	return Transform3D(instance_basis, world_position)


func _new_mesh_sets(size: int) -> Array:
	var sets: Array = []
	for _index in size:
		sets.append([])
	return sets


func _add_tree_sets(layer_prefix: String, transform_sets: Array, draw_distance: float, cast_shadows: bool) -> void:
	for model_index in TREE_SCENES.size():
		_add_multimesh_layer(
			"%s_%s" % [layer_prefix, TREE_NAMES[model_index]],
			_tree_meshes[model_index],
			transform_sets[model_index],
			draw_distance,
			cast_shadows
		)


func _add_multimesh_layer(
	layer_name: String,
	mesh: Mesh,
	transforms: Array,
	draw_distance: float,
	cast_shadows: bool
) -> void:
	if mesh == null or transforms.is_empty():
		return
	var layer_group := Node3D.new()
	layer_group.name = layer_name
	add_child(layer_group)
	var transforms_by_chunk: Dictionary = {}
	for world_transform: Transform3D in transforms:
		var chunk_coordinate := Vector2i(
			floori(world_transform.origin.x / RENDER_CHUNK_SIZE),
			floori(world_transform.origin.z / RENDER_CHUNK_SIZE)
		)
		if not transforms_by_chunk.has(chunk_coordinate):
			transforms_by_chunk[chunk_coordinate] = []
		var chunk_origin := Vector3(
			(float(chunk_coordinate.x) + 0.5) * RENDER_CHUNK_SIZE,
			0.0,
			(float(chunk_coordinate.y) + 0.5) * RENDER_CHUNK_SIZE
		)
		var local_transform := world_transform
		local_transform.origin -= chunk_origin
		transforms_by_chunk[chunk_coordinate].append(local_transform)

	for chunk_coordinate: Vector2i in transforms_by_chunk:
		_add_multimesh_chunk(
			layer_group,
			mesh,
			chunk_coordinate,
			transforms_by_chunk[chunk_coordinate],
			draw_distance,
			cast_shadows
		)


func _add_multimesh_chunk(
	layer_group: Node3D,
	mesh: Mesh,
	chunk_coordinate: Vector2i,
	transforms: Array,
	draw_distance: float,
	cast_shadows: bool
) -> void:
	var layer := MultiMeshInstance3D.new()
	layer.name = "Chunk_%d_%d" % [chunk_coordinate.x, chunk_coordinate.y]
	layer.position = Vector3(
		(float(chunk_coordinate.x) + 0.5) * RENDER_CHUNK_SIZE,
		0.0,
		(float(chunk_coordinate.y) + 0.5) * RENDER_CHUNK_SIZE
	)
	layer.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if cast_shadows else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	layer.visibility_range_end = draw_distance
	layer.visibility_range_end_margin = 12.0
	layer.visibility_range_fade_mode = GeometryInstance3D.VISIBILITY_RANGE_FADE_SELF
	layer.extra_cull_margin = 4.0

	var generated_multimesh := MultiMesh.new()
	generated_multimesh.transform_format = MultiMesh.TRANSFORM_3D
	generated_multimesh.mesh = mesh
	generated_multimesh.instance_count = transforms.size()
	var minimum_y := INF
	var maximum_y := -INF
	for index in transforms.size():
		var instance_transform: Transform3D = transforms[index]
		generated_multimesh.set_instance_transform(index, instance_transform)
		minimum_y = minf(minimum_y, instance_transform.origin.y)
		maximum_y = maxf(maximum_y, instance_transform.origin.y)
	generated_multimesh.custom_aabb = AABB(
		Vector3(-RENDER_CHUNK_SIZE * 0.5 - 12.0, minimum_y - 3.0, -RENDER_CHUNK_SIZE * 0.5 - 12.0),
		Vector3(RENDER_CHUNK_SIZE + 24.0, maximum_y - minimum_y + 22.0, RENDER_CHUNK_SIZE + 24.0)
	)
	layer.multimesh = generated_multimesh
	layer_group.add_child(layer)


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


func _hide_replaced_environment_props(world: Node) -> int:
	var auto_environment := world.find_child("AutoEnvironment", true, false)
	if auto_environment == null:
		return 0
	return _hide_replaced_props_recursive(auto_environment)


func _hide_replaced_props_recursive(parent: Node) -> int:
	var hidden_count := 0
	for child in parent.get_children():
		if child is MultiMeshInstance3D and _is_replaced_prop(String(child.name)):
			var instance := child as MultiMeshInstance3D
			if instance.multimesh != null:
				hidden_count += instance.multimesh.instance_count
			instance.visible = false
		hidden_count += _hide_replaced_props_recursive(child)
	return hidden_count


func _is_replaced_prop(prop_name: String) -> bool:
	for category_name in REPLACED_PROP_NAMES:
		if category_name in prop_name:
			return true
	return false


func _is_reserved_area(world_xz: Vector2) -> bool:
	return world_xz.distance_to(SPAWN_POSITION) < SPAWN_CLEAR_RADIUS or _is_spawn_path(world_xz) or _is_in_clearing(world_xz)


func _is_spawn_path(world_xz: Vector2) -> bool:
	var local := world_xz - SPAWN_POSITION
	var depth := -local.y
	if depth < 96.0 or depth > 255.0:
		return false
	var width := lerpf(3.4, 2.4, clampf((depth - 96.0) / 159.0, 0.0, 1.0))
	return absf(local.x - _spawn_path_center_x(depth)) < width


func _spawn_path_center_x(depth: float) -> float:
	return sin((depth - 96.0) * 0.048) * 5.8


func _is_in_clearing(world_xz: Vector2) -> bool:
	for index in CLEARING_CENTERS.size():
		var offset: Vector2 = world_xz - CLEARING_CENTERS[index]
		var radius: Vector2 = CLEARING_RADII[index]
		var ellipse_distance := (offset.x * offset.x) / (radius.x * radius.x)
		ellipse_distance += (offset.y * offset.y) / (radius.y * radius.y)
		if ellipse_distance <= 1.0:
			return true
	return false


func get_qa_tree_sample(tier: int, near_position: Vector2) -> Dictionary:
	var nearest_tree: Dictionary = {}
	var nearest_distance := INF
	for tree: Dictionary in _tree_stats:
		if int(tree.tier) != tier:
			continue
		var tree_position: Vector2 = tree.position
		var distance := tree_position.distance_to(near_position)
		if distance < nearest_distance:
			nearest_distance = distance
			nearest_tree = tree
	return nearest_tree


func _print_world_size_report() -> void:
	for tier in [TreeTier.LARGE, TreeTier.MEDIUM, TreeTier.SAPLING]:
		var minimum_height := INF
		var maximum_height := 0.0
		var minimum_crown := INF
		var maximum_crown := 0.0
		for tree: Dictionary in _tree_stats:
			if int(tree.tier) != tier:
				continue
			minimum_height = minf(minimum_height, float(tree.height))
			maximum_height = maxf(maximum_height, float(tree.height))
			minimum_crown = minf(minimum_crown, float(tree.crown))
			maximum_crown = maxf(maximum_crown, float(tree.crown))
		if minimum_height < INF:
			print(
				"TREE_WORLD_SIZE tier=%s height=%.2f-%.2f crown=%.2f-%.2f" % [
					TreeTier.keys()[tier], minimum_height, maximum_height, minimum_crown, maximum_crown,
				]
			)


func _print_local_metrics() -> void:
	var local_trees: Array[Dictionary] = []
	for tree: Dictionary in _tree_stats:
		var tree_position: Vector2 = tree.position
		if tree_position.distance_to(LOCAL_METRIC_CENTER) <= LOCAL_METRIC_RADIUS:
			local_trees.append(tree)
	var area := PI * LOCAL_METRIC_RADIUS * LOCAL_METRIC_RADIUS
	var trees_per_100 := float(local_trees.size()) / area * 100.0
	var average_nearest := _average_nearest_neighbor(local_trees)
	var canopy_coverage := _estimate_canopy_coverage(local_trees)
	var average_los := _estimate_line_of_sight(local_trees)
	print(
		"FOREST_LOCAL_METRICS center=(%.0f,%.0f) trees_per_100m2=%.2f nearest_neighbor=%.2fm canopy_coverage=%.0f%% visible_ground=%.0f%% approx_los=%.1fm" % [
			LOCAL_METRIC_CENTER.x,
			LOCAL_METRIC_CENTER.y,
			trees_per_100,
			average_nearest,
			canopy_coverage * 100.0,
			(1.0 - canopy_coverage) * 100.0,
			average_los,
		]
	)


func _average_nearest_neighbor(trees: Array[Dictionary]) -> float:
	if trees.size() < 2:
		return 0.0
	var distance_sum := 0.0
	for index in trees.size():
		var nearest := INF
		var tree_position: Vector2 = trees[index].position
		for other_index in trees.size():
			if index == other_index:
				continue
			nearest = minf(nearest, tree_position.distance_to(trees[other_index].position))
		distance_sum += nearest
	return distance_sum / trees.size()


func _estimate_canopy_coverage(trees: Array[Dictionary]) -> float:
	var covered_samples := 0
	var sample_count := 0
	for local_z in range(-60, 61, 3):
		for local_x in range(-60, 61, 3):
			var sample := LOCAL_METRIC_CENTER + Vector2(local_x, local_z)
			if sample.distance_to(LOCAL_METRIC_CENTER) > LOCAL_METRIC_RADIUS:
				continue
			sample_count += 1
			for tree: Dictionary in trees:
				if sample.distance_to(tree.position) <= float(tree.crown) * 0.5:
					covered_samples += 1
					break
	return float(covered_samples) / maxf(float(sample_count), 1.0)


func _estimate_line_of_sight(trees: Array[Dictionary]) -> float:
	var local_understory: Array[Dictionary] = []
	for plant: Dictionary in _understory_stats:
		var plant_position: Vector2 = plant.position
		if plant_position.distance_to(LOCAL_METRIC_CENTER) <= 82.0:
			local_understory.append(plant)
	var distance_sum := 0.0
	var ray_count := 16
	for ray_index in ray_count:
		var direction := Vector2.from_angle(TAU * float(ray_index) / float(ray_count))
		var hit_distance := 80.0
		for distance in range(4, 81, 2):
			var sample := LOCAL_METRIC_CENTER + direction * float(distance)
			var blocked := false
			for tree: Dictionary in trees:
				if sample.distance_to(tree.position) <= maxf(0.8, float(tree.crown) * 0.16):
					blocked = true
					break
			if not blocked:
				for plant: Dictionary in local_understory:
					if sample.distance_to(plant.position) <= float(plant.radius):
						blocked = true
						break
			if blocked:
				hit_distance = float(distance)
				break
		distance_sum += hit_distance
	return distance_sum / float(ray_count)
