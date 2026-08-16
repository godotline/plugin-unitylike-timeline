# Unity: ColorGradingMixerBehaviour.cs
@tool
class_name ColorGradingMixer
extends TimelineMixer

## Godot 4 note: Color Grading lives on Environment.adjustment_*:
## brightness -> adjustment_brightness; contrast -> adjustment_contrast;
## saturation -> adjustment_saturation.
## hueShift / temperature / tint have NO direct Godot equivalent — data preserved
## but not applied (documented). adjustment_enabled gates the whole effect.

var _original_brightness: float = 0.0
var _original_contrast: float = 0.0
var _original_saturation: float = 0.0
var _original_enabled: bool = false


## Unity: first ProcessFrame — cache original values.
func on_first_frame() -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	_original_brightness = env.adjustment_brightness
	_original_contrast = env.adjustment_contrast
	_original_saturation = env.adjustment_saturation
	_original_enabled = env.adjustment_enabled


## Unity: ProcessFrame — offset-form blend then clamp to Unity's ranges.
func process_frame(inputs: Array, time: float, delta: float) -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	if not _first_frame_done:
		on_first_frame()
		_first_frame_done = true

	var final_brightness: float = _original_brightness
	var final_contrast: float = _original_contrast
	var final_saturation: float = _original_saturation
	var final_enabled: bool = _original_enabled
	var total_weight: float = 0.0
	var max_weight: float = 0.0

	for i in inputs.size():
		var entry: Dictionary = inputs[i]
		var behaviour: ColorGradingBehaviour = entry["behaviour"] as ColorGradingBehaviour
		var weight: float = entry["weight"] as float
		if behaviour == null or weight <= 0.0:
			continue
		final_brightness += (behaviour.brightness - _original_brightness) * weight
		final_contrast += (behaviour.contrast - _original_contrast) * weight
		final_saturation += (behaviour.saturation - _original_saturation) * weight
		total_weight += weight
		if weight > max_weight:
			max_weight = weight
			final_enabled = behaviour.enableColorGrading

	# Unity clamps.
	if total_weight > 0.0:
		final_brightness = clampf(final_brightness, -100.0, 100.0)
		final_contrast = clampf(final_contrast, -100.0, 100.0)
		final_saturation = clampf(final_saturation, -100.0, 100.0)

	env.adjustment_enabled = final_enabled
	env.adjustment_brightness = final_brightness
	env.adjustment_contrast = final_contrast
	env.adjustment_saturation = final_saturation


## Unity: OnPlayableDestroy — restore original values.
func on_playable_destroy() -> void:
	var env: Environment = _resolve_env()
	if env == null or not _first_frame_done:
		return
	env.adjustment_enabled = _original_enabled
	env.adjustment_brightness = _original_brightness
	env.adjustment_contrast = _original_contrast
	env.adjustment_saturation = _original_saturation
	_first_frame_done = false


## Resolve the target Environment: bound WorldEnvironment -> bound Camera3D ->
## Player scene camera (mirrors SetFog.gd resolution, adapted for RefCounted).
func _resolve_env() -> Environment:
	if bound != null and bound is WorldEnvironment:
		return (bound as WorldEnvironment).environment
	if bound != null and bound is Camera3D:
		return (bound as Camera3D).environment
	if Player.instance != null and is_instance_valid(Player.instance):
		var cam: Camera3D = Player.instance.get_scene_camera()
		if cam != null:
			return cam.environment
	return null
