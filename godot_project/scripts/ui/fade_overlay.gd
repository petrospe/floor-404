class_name FadeOverlay
extends CanvasLayer
## Full-screen black fade used by hazard respawns. Not a HUD.

const GROUP := &"fade_overlay"

var _rect: ColorRect
var _tween: Tween


static func find_or_create(tree: SceneTree) -> FadeOverlay:
	if tree == null:
		return null
	for node: Node in tree.get_nodes_in_group(GROUP):
		if node is FadeOverlay:
			return node
	var overlay := FadeOverlay.new()
	overlay.name = "FadeOverlay"
	tree.root.add_child(overlay)
	return overlay


func _ready() -> void:
	layer = 100
	add_to_group(GROUP)
	_rect = get_node_or_null(^"ColorRect") as ColorRect
	if _rect == null:
		_rect = ColorRect.new()
		_rect.name = "ColorRect"
		_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_rect.color = Color(0.0, 0.0, 0.0, 0.0)
		_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		add_child(_rect)


func fade_to(alpha: float, duration: float) -> void:
	if _rect == null:
		return
	var target := clampf(alpha, 0.0, 1.0)
	if _tween != null and _tween.is_valid():
		_tween.kill()
	if duration <= 0.0:
		_set_alpha(target)
		return
	_tween = create_tween()
	_tween.tween_property(_rect, "color:a", target, duration)
	await _tween.finished


func _set_alpha(alpha: float) -> void:
	var color := _rect.color
	color.a = alpha
	_rect.color = color
