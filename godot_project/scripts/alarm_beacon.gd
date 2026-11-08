extends Node3D
## Wall beacon. The red lens and the spill breathe together.

var lamp: OmniLight3D
var lens: StandardMaterial3D
var core: StandardMaterial3D
var _time := 0.0


func _process(delta: float) -> void:
	_time += delta
	var pulse := 0.55 + 0.45 * sin(_time * 2.4)
	if lamp != null:
		lamp.light_energy = lerpf(1.5, 3.6, pulse)
	if lens != null:
		lens.emission_energy_multiplier = lerpf(0.6, 2.0, pulse)
	if core != null:
		core.emission_energy_multiplier = lerpf(2.0, 5.0, pulse)
