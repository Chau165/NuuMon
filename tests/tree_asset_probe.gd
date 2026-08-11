extends Node

const PROBE_ENABLED := false
const ASSET_ROOTS := [
	"res://asset/Stylized Nature MegaKit[Standard]/glTF",
	"res://asset/Ultimate Stylized Nature - May 2022/glTF",
]


func _ready() -> void:
	if PROBE_ENABLED:
		_probe_assets.call_deferred()


func _probe_assets() -> void:
	var report: Array[Dictionary] = []
	for asset_root in ASSET_ROOTS:
		for file_name in DirAccess.get_files_at(asset_root):
			if not _is_tree_candidate(file_name):
				continue
			var resource_path := "%s/%s" % [asset_root, file_name]
			var packed_scene := load(resource_path) as PackedScene
			if packed_scene == null:
				continue
			var source := packed_scene.instantiate()
			var mesh := _find_mesh(source)
			source.free()
			if mesh == null:
				continue
			var bounds := mesh.get_aabb()
			var size := bounds.size
			var row := {
				"path": resource_path,
				"width": maxf(size.x, size.z),
				"height": size.y,
				"depth": minf(size.x, size.z),
				"surfaces": mesh.get_surface_count(),
				"triangles": int(float(mesh.get_faces().size()) / 3.0),
			}
			report.append(row)
			print(
				"TREE_AABB file=%s width=%.2f height=%.2f depth=%.2f surfaces=%d triangles=%d" % [
					file_name,
					row.width,
					row.height,
					row.depth,
					row.surfaces,
					row.triangles,
				]
			)

	report.sort_custom(func(left: Dictionary, right: Dictionary) -> bool: return float(left.width) > float(right.width))
	var report_path := "user://tree_asset_aabb.json"
	var report_file := FileAccess.open(report_path, FileAccess.WRITE)
	if report_file != null:
		report_file.store_string(JSON.stringify(report, "\t"))
	print("TREE_AABB_REPORT count=%d path=%s" % [report.size(), ProjectSettings.globalize_path(report_path)])


func _is_tree_candidate(file_name: String) -> bool:
	var lower_name := file_name.to_lower()
	if not lower_name.ends_with(".gltf"):
		return false
	return (
		"tree" in lower_name
		or "bush" in lower_name
		or "fern" in lower_name
		or "plant" in lower_name
		or "clover" in lower_name
		or "mushroom" in lower_name
		or "flower" in lower_name
		or "grass" in lower_name
		or "rock" in lower_name
		or "pebble" in lower_name
	)


func _find_mesh(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return (node as MeshInstance3D).mesh
	for child in node.get_children():
		var child_mesh := _find_mesh(child)
		if child_mesh != null:
			return child_mesh
	return null
