class_name CheckpointZone
extends Area3D
## Marks the player's safe pose when they enter. Requires a CollisionShape3D.

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
	player.last_safe_transform = player.global_transform


func _ensure_shape() -> void:
	if get_node_or_null(^"CollisionShape3D") != null:
		return
	var shape_node := CollisionShape3D.new()
	shape_node.name = "CollisionShape3D"
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 2.0, 2.0)
	shape_node.shape = box
	add_child(shape_node)
