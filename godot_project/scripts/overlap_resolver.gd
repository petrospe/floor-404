class_name OverlapResolver
extends RefCounted
## After the rooms are furnished, movable props that intersect something else
## step away in small increments. If every nearby spot is still blocked, the
## prop is removed.

const STEP := 0.22
const MAX_STEPS := 7
const PAD := 0.1


static func resolve(tree: SceneTree, blocked: Callable) -> void:
	var fixed: Array[Rect2] = []
	for node in tree.get_nodes_in_group("overlap_fixed"):
		if node is Node3D:
			var rect := _footprint(node as Node3D)
			if rect.size.x > 0.02 and rect.size.y > 0.02:
				fixed.append(rect)
	var movables: Array[Dictionary] = []
	for node in tree.get_nodes_in_group("overlap_movable"):
		if node is Node3D:
			var body := node as Node3D
			var rect := _footprint(body).grow(PAD)
			if rect.size.x <= 0.02 or rect.size.y <= 0.02:
				continue
			movables.append({
				"node": body,
				"rect": rect,
				"home": body.global_position,
			})
	for item in movables:
		_settle(item, movables, fixed, blocked)


static func _settle(item: Dictionary, movables: Array[Dictionary], fixed: Array[Rect2], blocked: Callable) -> void:
	var node: Node3D = item.node
	if not is_instance_valid(node):
		return
	if _clear(item.rect, item, movables, fixed, blocked):
		return
	var home: Vector3 = item.home
	var away := _away(item.rect, item, movables, fixed)
	var base: Rect2 = item.rect
	for step in range(1, MAX_STEPS + 1):
		var dist := STEP * float(step)
		for dir in _dirs(away):
			var pos := home + dir * dist
			var rect := Rect2(base.position + Vector2(pos.x - home.x, pos.z - home.z), base.size)
			if not _clear(rect, item, movables, fixed, blocked):
				continue
			node.global_position = pos
			item.rect = rect
			item.home = pos
			return
	node.queue_free()
	item.rect = Rect2()


static func _clear(rect: Rect2, item: Dictionary, movables: Array[Dictionary], fixed: Array[Rect2], blocked: Callable) -> bool:
	if rect.size.x < 0.01:
		return true
	for other in fixed:
		if rect.intersects(other):
			return false
	for other_item in movables:
		if other_item == item:
			continue
		var other: Rect2 = other_item.rect
		if other.size.x < 0.01:
			continue
		if rect.intersects(other):
			return false
	return not _hits_block(rect, blocked)


static func _hits_block(rect: Rect2, blocked: Callable) -> bool:
	var nx := maxi(2, int(ceil(rect.size.x / 0.18)))
	var nz := maxi(2, int(ceil(rect.size.y / 0.18)))
	for ix in nx + 1:
		for iz in nz + 1:
			var x := rect.position.x + rect.size.x * float(ix) / float(nx)
			var z := rect.position.y + rect.size.y * float(iz) / float(nz)
			if bool(blocked.call(Vector3(x, 0.0, z))):
				return true
	return false


static func _away(rect: Rect2, item: Dictionary, movables: Array[Dictionary], fixed: Array[Rect2]) -> Vector3:
	var push := Vector2.ZERO
	var center := rect.get_center()
	for other in fixed:
		if rect.intersects(other):
			push += _delta(center, other.get_center())
	for other_item in movables:
		if other_item == item:
			continue
		var other: Rect2 = other_item.rect
		if other.size.x < 0.01 or not rect.intersects(other):
			continue
		push += _delta(center, other.get_center())
	if push.length() < 0.001:
		return Vector3(1.0, 0.0, 0.0)
	var flat := Vector3(push.x, 0.0, push.y).normalized()
	return flat


static func _delta(center: Vector2, other: Vector2) -> Vector2:
	var delta := center - other
	if delta.length() < 0.001:
		return Vector2(1.0, 0.0)
	return delta.normalized()


static func _dirs(away: Vector3) -> Array[Vector3]:
	var angles: Array[float] = [0.0, 35.0, -35.0, 75.0, -75.0, 120.0, -120.0, 180.0]
	var out: Array[Vector3] = []
	for deg in angles:
		out.append(away.rotated(Vector3.UP, deg_to_rad(deg)))
	return out


static func _footprint(root: Node3D) -> Rect2:
	var min_x := INF
	var max_x := -INF
	var min_z := INF
	var max_z := -INF
	var pending: Array[Node] = [root]
	while not pending.is_empty():
		var node: Node = pending.pop_back()
		if node is MeshInstance3D:
			var mesh_node := node as MeshInstance3D
			if mesh_node.mesh != null:
				var ab := mesh_node.get_aabb()
				for i in 8:
					var corner := Vector3(
						ab.position.x if (i & 1) == 0 else ab.end.x,
						ab.position.y if (i & 2) == 0 else ab.end.y,
						ab.position.z if (i & 4) == 0 else ab.end.z
					)
					var world: Vector3 = mesh_node.global_transform * corner
					min_x = minf(min_x, world.x)
					max_x = maxf(max_x, world.x)
					min_z = minf(min_z, world.z)
					max_z = maxf(max_z, world.z)
		for child in node.get_children():
			pending.append(child)
	if min_x > max_x:
		return Rect2()
	return Rect2(min_x, min_z, max_x - min_x, max_z - min_z)
