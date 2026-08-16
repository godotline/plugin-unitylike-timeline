# Unity: AmbientOcclusionMixerBehaviour.cs
@tool
class_name AmbientOcclusionMixer
extends TimelineMixer

## Godot 4 note: Ambient Occlusion lives on Environment.ssao_* (screen-space AO):
## intensity -> ssao_intensity; radius -> ssao_radius; enabled -> ssao_enabled.
## Godot has separate SSIL (ssil_*) for indirect light — not driven by this port.
## Unity intensity range 0~4, radius 0.1~10 preserved.

var _original_intensity: float = 1.0
var _original_radius: float = 0.3
var _original_enabled: bool = false


## Unity: first ProcessFrame — cache original values.
func on_first_frame() -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	_original_intensity = env.ssao_intensity
	_original_radius = env.ssao_radius
	_original_enabled = env.ssao_enabled


## Unity: ProcessFrame — offset-form blend then clamp to Unity's ranges.
func process_frame(inputs: Array, time: float, delta: float) -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	if not _first_frame_done:
		on_first_frame()
		_first_frame_done = true

	var final_intensity: float = _original_intensity
	var final_radius: float = _original_radius
	var final_enabled: bool = _original_enabled
	var total_weight: float = 0.0
	var max_weight: float = 0.0

	for i in inputs.size():
		var entry: Dictionary = inputs[i]
		var behaviour: AmbientOcclusionBehaviour = entry["behaviour"] as AmbientOcclusionBehaviour
		var weight: float = entry["weight"] as float
		if behaviour == null or weight <= 0.0:
			continue
		final_intensity += (behaviour.intensity - _original_intensity) * weight
		final_radius += (behaviour.radius - _original_radius) * weight
		total_weight += weight
		if weight > max_weight:
			max_weight = weight
			final_enabled = behaviour.enableAmbientOcclusion

	# Unity clamps.
	if total_weight > 0.0:
		final_intensity = clampf(final_intensity, 0.0, 4.0)
		final_radius = clampf(final_radius, 0.1, 10.0)

	env.ssao_enabled = final_enabled
	env.ssao_intensity = final_intensity
	env.ssao_radius = final_radius


## Unity: OnPlayableDestroy — restore original values.
func on_playable_destroy() -> void:
	var env: Environment = _resolve_env()
	if env == null or not _first_frame_done:
		return
	env.ssao_enabled = _original_enabled
	env.ssao_intensity = _original_intensity
	env.ssao_radius = _original_radius
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
