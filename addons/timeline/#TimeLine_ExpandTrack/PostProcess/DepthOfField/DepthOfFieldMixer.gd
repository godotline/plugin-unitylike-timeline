# Unity: DepthOfFieldMixerBehaviour.cs
@tool
class_name DepthOfFieldMixer
extends TimelineMixer

## Godot 4 note: DOF does NOT live on Environment — it lives on
## CameraAttributesPractical (assigned to Camera3D.attributes). This mixer
## resolves/creates the CameraAttributesPractical on the bound camera.
## Unity mapping: focusDistance -> dof_blur_far_distance + dof_blur_near_distance
## (approx); aperture + focalLength -> dof_blur_amount (physical lens blur).

var _original_focus_distance: float = 10.0
var _original_aperture: float = 5.6
var _original_focal_length: float = 50.0
var _original_enabled: bool = false
var _original_dof_amount: float = 0.0
var _attrs: CameraAttributesPractical = null


## Unity: first ProcessFrame — cache original values from the bound profile.
func on_first_frame() -> void:
	_attrs = _resolve_attrs()
	if _attrs == null:
		return
	_original_focus_distance = _attrs.dof_blur_far_distance
	_original_aperture = _attrs.dof_blur_amount
	_original_focal_length = _attrs.dof_blur_far_transition
	_original_enabled = _attrs.dof_blur_far_enabled


## Unity: ProcessFrame — offset-form blend then clamp to Unity's ranges.
func process_frame(inputs: Array, time: float, delta: float) -> void:
	_attrs = _resolve_attrs()
	if _attrs == null:
		return
	if not _first_frame_done:
		on_first_frame()
		_first_frame_done = true

	var final_focus_distance: float = _original_focus_distance
	var final_aperture: float = _original_aperture
	var final_focal_length: float = _original_focal_length
	var final_enabled: bool = _original_enabled
	var total_weight: float = 0.0
	var max_weight: float = 0.0

	for i in inputs.size():
		var entry: Dictionary = inputs[i]
		var behaviour: DepthOfFieldBehaviour = entry["behaviour"] as DepthOfFieldBehaviour
		var weight: float = entry["weight"] as float
		if behaviour == null or weight <= 0.0:
			continue
		final_focus_distance += (behaviour.focusDistance - _original_focus_distance) * weight
		final_aperture += (behaviour.aperture - _original_aperture) * weight
		final_focal_length += (behaviour.focalLength - _original_focal_length) * weight
		total_weight += weight
		if weight > max_weight:
			max_weight = weight
			final_enabled = behaviour.enableDepthOfField

	# Unity clamps.
	if total_weight > 0.0:
		final_focus_distance = clampf(final_focus_distance, 0.0, 100.0)
		final_aperture = clampf(final_aperture, 0.1, 32.0)
		final_focal_length = clampf(final_focal_length, 12.0, 400.0)

	_attrs.dof_blur_far_enabled = final_enabled
	_attrs.dof_blur_near_enabled = final_enabled
	_attrs.dof_blur_far_distance = final_focus_distance
	_attrs.dof_blur_near_distance = final_focus_distance
	_attrs.dof_blur_amount = final_aperture
	_attrs.dof_blur_far_transition = final_focal_length


## Unity: OnPlayableDestroy — restore original values.
func on_playable_destroy() -> void:
	if not _first_frame_done or _attrs == null:
		return
	_attrs.dof_blur_far_enabled = _original_enabled
	_attrs.dof_blur_near_enabled = _original_enabled
	_attrs.dof_blur_far_distance = _original_focus_distance
	_attrs.dof_blur_near_distance = _original_focus_distance
	_attrs.dof_blur_amount = _original_aperture
	_attrs.dof_blur_far_transition = _original_focal_length
	_first_frame_done = false


## Resolve the CameraAttributesPractical: bound Camera3D.attributes, else
## Player scene camera attributes; creates one when absent (so DOF applies).
func _resolve_attrs() -> CameraAttributesPractical:
	var cam: Camera3D = _resolve_camera()
	if cam == null:
		return null
	if cam.attributes is CameraAttributesPractical:
		return cam.attributes as CameraAttributesPractical
	var attrs: CameraAttributesPractical = CameraAttributesPractical.new()
	cam.attributes = attrs
	return attrs


func _resolve_camera() -> Camera3D:
	if bound != null and bound is Camera3D:
		return bound as Camera3D
	if bound != null and bound is WorldEnvironment:
		return null
	if Player.instance != null and is_instance_valid(Player.instance):
		return Player.instance.get_scene_camera()
	return null
