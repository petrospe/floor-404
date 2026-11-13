extends Node3D
## Forwards use of the floor cabinet to the nearest electrical panel.
## This does not move, scale, or replace the cabinet mesh.

const REACH := 7.0


func interact(interactor: Node = null) -> void:
	var panel := _nearest_panel()
	if panel != null:
		panel.interact(interactor)


func _nearest_panel() -> Node:
	var best: Node = null
	var best_distance := REACH
	for node in get_tree().get_nodes_in_group(&"electrical_panel"):
		if not node is Node3D or not node.has_method(&"interact"):
			continue
		var distance := global_position.distance_to((node as Node3D).global_position)
		if distance < best_distance:
			best = node
			best_distance = distance
	return best
