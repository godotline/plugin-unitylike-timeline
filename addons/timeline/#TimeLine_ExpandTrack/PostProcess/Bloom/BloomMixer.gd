# Unity: BloomMixerBehaviour.cs
@tool
class_name BloomMixer
extends TimelineMixer

## Godot 4 note: Unity's Bloom is GLOW in Godot — mapped to Environment.glow_*:
## enableBloom -> glow_enabled; intensity -> glow_intensity;
## threshold -> glow_hdr_threshold; softKnee -> glow_hdr_scale (closest);
## diffusion -> glow_bloom. Ranges preserved from Unity.
## Unity's PostProcessVolume profile settings -> Environment on the bound camera.

var _original_intensity: float = 0.3
var _original_threshold: float = 1.0
var _original_hdr_scale: float = 2.0
var _original_bloom: float = 0.0
var _original_enabled: bool = false


## Unity: first ProcessFrame — cache original values (defaults are script defaults).
func on_first_frame() -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	_original_intensity = env.glow_intensity
	_original_threshold = env.glow_hdr_threshold
	_original_hdr_scale = env.glow_hdr_scale
	_original_bloom = env.glow_bloom
	_original_enabled = env.glow_enabled


## Unity: ProcessFrame — offset-form blend: final = original + Sum((input - original) * weight),
## then clamp to Unity's ranges. enableBloom follows the clip with the greatest weight.
func process_frame(inputs: Array, time: float, delta: float) -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	if not _first_frame_done:
		on_first_frame()
		_first_frame_done = true

	var final_intensity: float = _original_intensity
	var final_threshold: float = _original_threshold
	var final_hdr_scale: float = _original_hdr_scale
	var final_bloom: float = _original_bloom
	var final_enabled: bool = _original_enabled
	var total_weight: float = 0.0
	var max_weight: float = 0.0

	for i in inputs.size():
		var entry: Dictionary = inputs[i]
		var behaviour: BloomBehaviour = entry["behaviour"] as BloomBehaviour
		var weight: float = entry["weight"] as float
		if behaviour == null or weight <= 0.0:
			continue
		final_intensity += (behaviour.intensity - _original_intensity) * weight
		final_threshold += (behaviour.threshold - _original_threshold) * weight
		final_hdr_scale += (behaviour.softKnee - _original_hdr_scale) * weight
		final_bloom += (behaviour.diffusion - _original_bloom) * weight
		total_weight += weight
		if weight > max_weight:
			max_weight = weight
			final_enabled = behaviour.enableBloom

	# Unity clamps.
	if total_weight > 0.0:
		final_intensity = clampf(final_intensity, 0.0, 10.0)
		final_threshold = clampf(final_threshold, 0.0, 10.0)
		final_hdr_scale = clampf(final_hdr_scale, 0.0, 1.0)
		final_bloom = clampf(final_bloom, 1.0, 10.0)

	env.glow_enabled = final_enabled
	env.glow_intensity = final_intensity
	env.glow_hdr_threshold = final_threshold
	env.glow_hdr_scale = final_hdr_scale
	env.glow_bloom = final_bloom


## Unity: OnPlayableDestroy — restore original values.
func on_playable_destroy() -> void:
	var env: Environment = _resolve_env()
	if env == null or not _first_frame_done:
		return
	env.glow_enabled = _original_enabled
	env.glow_intensity = _original_intensity
	env.glow_hdr_threshold = _original_threshold
	env.glow_hdr_scale = _original_hdr_scale
	env.glow_bloom = _original_bloom
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
