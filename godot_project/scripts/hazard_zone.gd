class_name HazardZone
extends Area3D
## Lethal volume. Entering it fades out, respawns the player, then fades back in.

@export_range(0.0, 1.0, 0.01, "suffix:s") var fade_out_seconds: float = 0.1
@export_range(0.0, 1.0, 0.01, "suffix:s") var fade_in_seconds: float = 0.15


func _ready() -> void:
	monitoring = true
	monitorable = false
	_ensure_shape()
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node3D) -> void:
	var player := body as Player
	if player == null or player.is_respawning():
		return
	player.respawn(fade_out_seconds, fade_in_seconds)


func _ensure_shape() -> void:
	if get_node_or_null(^"CollisionShape3D") != null:
		return
	var shape_node := CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	shape_node.shape = box
	add_child(shape_node)
