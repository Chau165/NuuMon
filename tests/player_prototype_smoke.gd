extends SceneTree

const PLAYER_SCENE_PATH := "res://player/prototype/PlayerPrototype.tscn"
const REQUIRED_INPUTS := [
	"move_forward",
	"move_backward",
	"move_left",
	"move_right",
	"jump",
	"sprint",
]


func _initialize() -> void:
	for action in REQUIRED_INPUTS:
		if not InputMap.has_action(action):
			_fail("Missing input action: %s" % action)
			return

	var packed_scene := load(PLAYER_SCENE_PATH) as PackedScene
	if packed_scene == null:
		_fail("PlayerPrototype scene is missing")
		return

	var player := packed_scene.instantiate() as CharacterBody3D
	if player == null:
		_fail("PlayerPrototype root must be a CharacterBody3D")
		return

	for node_path in ["CollisionShape3D", "Visual", "CameraPivot/SpringArm3D/Camera3D"]:
		if player.get_node_or_null(node_path) == null:
			_fail("Missing player node: %s" % node_path)
			return

	var collision_shape := player.get_node("CollisionShape3D") as CollisionShape3D
	if not collision_shape.shape is CapsuleShape3D:
		_fail("Player collision must use CapsuleShape3D")
		return

	if not player.has_method("reset_to_spawn"):
		_fail("Player must provide reset_to_spawn()")
		return

	if player.floor_max_angle < deg_to_rad(40.0) or player.floor_max_angle > deg_to_rad(50.0):
		_fail("Player floor_max_angle must be suitable for terrain testing")
		return

	print("Player prototype smoke test passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
