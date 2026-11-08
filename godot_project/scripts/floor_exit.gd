extends StaticBody3D
## Upside-down red EXIT. Interacting fades out and leaves the floor.

var _leaving := false


func interact(_interactor: Node = null) -> void:
	if _leaving:
		return
	_leaving = true
	var overlay := FadeOverlay.find_or_create(get_tree())
	if overlay != null:
		await overlay.fade_to(1.0, 0.45)
	if is_inside_tree():
		get_tree().quit()
