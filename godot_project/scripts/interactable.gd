class_name Interactable
extends Node3D
## Base for objects the player can use with the interact key.
## Attach to a Node3D, or to a physics body the interaction ray can hit.
## Override _on_interact() for the actual behavior.

signal interacted(interactor: Node)
signal interaction_rejected(interactor: Node)

@export var interaction_enabled: bool = true


func interact(interactor: Node = null) -> void:
	if not can_interact(interactor):
		_on_interact_rejected(interactor)
		interaction_rejected.emit(interactor)
		return
	_on_interact(interactor)
	interacted.emit(interactor)


func can_interact(_interactor: Node = null) -> bool:
	return interaction_enabled and is_inside_tree()


## Override in subclasses. Called only when can_interact() is true.
func _on_interact(_interactor: Node = null) -> void:
	pass


## Override to react when interaction is refused (locked, disabled, and so on).
func _on_interact_rejected(_interactor: Node = null) -> void:
	pass
