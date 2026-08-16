@tool
class_name MaterialMixer
extends TimelineMixer

## Unity: MaterialMixerBehaviour.cs
## Caches the bound material's default color/emission on the first frame, then each
## frame blends weighted clip inputs with the defaults as residue:
##   final = blended + default * (1 - total_weight)
## Emission is always enabled while playing (Unity EnableKeyword("_EMISSION")); the
## previous emission_enabled state is restored on destroy.

var _default_color: Color = Color.WHITE
var _default_emission: Color = Color.BLACK
var _default_emission_enabled: bool = false
var _mat: StandardMaterial3D = null


## Resolves the StandardMaterial3D to blend: the bound GeometryInstance3D's
## material_override. If the override is already a StandardMaterial3D it is returned
## (even when shared between instances — acceptable for this port, matching Unity's
## Material asset binding closely enough). If it is a non-standard material, null is
## returned (cannot blend). If absent, a new StandardMaterial3D is created and assigned.
func _resolve_mat() -> StandardMaterial3D:
	if bound == null:
		return null
	var gi: GeometryInstance3D = bound as GeometryInstance3D
	if gi == null:
		return null
	if gi.material_override is StandardMaterial3D:
		return gi.material_override as StandardMaterial3D
	if gi.material_override != null:
		return null
	var mat: StandardMaterial3D = StandardMaterial3D.new()
	gi.material_override = mat
	return mat


func on_first_frame() -> void:
	_mat = _resolve_mat()
	if _mat == null:
		return
	_default_color = _mat.albedo_color
	_default_emission = _mat.emission
	_default_emission_enabled = _mat.emission_enabled


func process_frame(inputs: Array, time: float, delta: float) -> void:
	_mat = _resolve_mat()
	if _mat == null:
		return
	if not _first_frame_done:
		on_first_frame()
		_first_frame_done = true
	var blended_color: Color = Color(0, 0, 0, 0)
	var blended_emission: Color = Color(0, 0, 0, 0)
	var total: float = 0.0
	for entry in inputs:
		var behaviour: MaterialBehaviour = entry.behaviour as MaterialBehaviour
		var weight: float = entry.weight as float
		if behaviour == null or weight <= 0.0:
			continue
		blended_color += behaviour.TargetColor * weight
		blended_emission += behaviour.TargetHDRColor * weight
		total += weight
	var residue: float = clampf(1.0 - total, 0.0, 1.0)
	_mat.albedo_color = blended_color + _default_color * residue
	# Unity EnableKeyword("_EMISSION") → Godot emission_enabled. HDR values > 1.0 are
	# supported directly by Godot's emission color (emission_energy_multiplier stays 1.0).
	_mat.emission_enabled = true
	_mat.emission = blended_emission + _default_emission * residue


func on_playable_destroy() -> void:
	if not _first_frame_done or _mat == null:
		return
	_mat.albedo_color = _default_color
	_mat.emission = _default_emission
	_mat.emission_enabled = _default_emission_enabled
	_first_frame_done = false
