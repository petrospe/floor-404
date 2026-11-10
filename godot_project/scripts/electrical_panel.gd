class_name ElectricalPanel
extends StaticBody3D

const UI := preload("res://scripts/electrical_panel_ui.gd")
## Wall panel. Eight wires, one mapped elevator. A finished panel stays green.

@export var panel_id: String = ""
@export var show_plate: bool = true

var _lamp_mat: StandardMaterial3D


func _ready() -> void:
	_build()
	_apply_lamp()
	if not GameState.panel_completed.is_connected(_on_panel_completed):
		GameState.panel_completed.connect(_on_panel_completed)


func interact(_interactor: Node = null) -> void:
	if GameState.is_panel_complete(panel_id):
		return
	UI.open(self)


func mark_repaired() -> void:
	_apply_lamp()


func _on_panel_completed(id: String) -> void:
	if id == panel_id:
		_apply_lamp()


func _apply_lamp() -> void:
	if _lamp_mat == null:
		return
	if GameState.is_panel_complete(panel_id):
		_lamp_mat.albedo_color = Color(0.15, 0.55, 0.28)
		_lamp_mat.emission = Color(0.25, 1.0, 0.45)
		_lamp_mat.emission_energy_multiplier = 2.2
	else:
		_lamp_mat.albedo_color = Color(0.28, 0.16, 0.08)
		_lamp_mat.emission = Color(0.35, 0.12, 0.04)
		_lamp_mat.emission_energy_multiplier = 0.35


func _build() -> void:
	var steel := _mat(Color(0.55, 0.56, 0.58), 0.45, 0.35)
	var dark := _mat(Color(0.08, 0.09, 0.1), 0.55, 0.1)
	_lamp_mat = _mat(Color(0.28, 0.16, 0.08), 0.4, 0.05)
	_lamp_mat.emission_enabled = true
	if show_plate:
		_box(Vector3(0.0, 0.0, -0.02), Vector3(0.62, 0.84, 0.04), steel)
		_box(Vector3(0.0, 0.02, -0.045), Vector3(0.46, 0.62, 0.012), dark)
	else:
		_box(Vector3(0.0, 0.0, -0.02), Vector3(0.5, 0.7, 0.04), steel)
	_box(Vector3(0.22, 0.32, -0.05), Vector3(0.06, 0.06, 0.02), _lamp_mat)
	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(0.64, 0.9, 0.08)
	shape.shape = box
	shape.position = Vector3(0.0, 0.0, -0.03)
	add_child(shape)


func _box(at: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = at
	mesh.material_override = material
	add_child(mesh)


func _mat(color: Color, rough: float, metal: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = rough
	material.metallic = metal
	return material
