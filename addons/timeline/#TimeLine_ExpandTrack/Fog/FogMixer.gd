# Unity: FogMixerBehaviour.cs
@tool
class_name FogMixer
extends TimelineMixer

## Cached environment defaults captured on first frame (Unity Default_Fog* fields).
var _default_color: Color = Color.WHITE
var _default_density: float = 0.0
var _default_begin: float = 0.0
var _default_end: float = 0.0
var _default_fog_enabled: bool = false
var _default_fog_mode: int = Environment.FogMode.FOG_MODE_EXPONENTIAL


## Unity: first ProcessFrame — cache current fog values before blending.
func on_first_frame() -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	_default_color = env.fog_light_color
	_default_density = env.fog_density
	_default_begin = env.fog_depth_begin
	_default_end = env.fog_depth_end
	_default_fog_enabled = env.fog_enabled
	_default_fog_mode = env.fog_mode


## Unity: ProcessFrame — weighted blend of all active clips:
## final = blended + default * (1 - totalWeight).
func process_frame(inputs: Array, time: float, delta: float) -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	if not _first_frame_done:
		on_first_frame()
		_first_frame_done = true

	# NOTE: not Color.TRANSPARENT — that constant is (1,1,1,0) in Godot, not (0,0,0,0)!
	var blended_color: Color = Color(0, 0, 0, 0)
	var blended_begin: float = 0.0
	var blended_end: float = 0.0
	var blended_density: float = 0.0
	var total_weight: float = 0.0
	var target_mode: int = FogBehaviour.FogModeEnum.LINEAR

	for i in inputs.size():
		var entry: Dictionary = inputs[i]
		var behaviour: FogBehaviour = entry["behaviour"] as FogBehaviour
		var weight: float = entry["weight"] as float
		if behaviour == null or weight <= 0.0:
			continue
		target_mode = behaviour.TargetFogMode
		blended_color += behaviour.TargetFogColor * weight
		if behaviour.is_linear():
			blended_begin += behaviour.FogStartDistance * weight
			blended_end += behaviour.FogEndDistance * weight
		else:
			blended_density += behaviour.FogDensity * weight
		total_weight += weight

	# Unity leaves fog enabled while the track is playing (RenderSettings.fog).
	env.fog_enabled = true
	# Overlapping clips can push totalWeight above 1.0 — clamp the default residue.
	var residue: float = clampf(1.0 - total_weight, 0.0, 1.0)
	env.fog_light_color = blended_color + _default_color * residue
	if target_mode == FogBehaviour.FogModeEnum.LINEAR:
		# Unity FogMode.Linear <-> Godot fog_mode = DEPTH (fog_depth_begin/end).
		env.fog_mode = Environment.FogMode.FOG_MODE_DEPTH
		env.fog_depth_begin = blended_begin + _default_begin * residue
		env.fog_depth_end = blended_end + _default_end * residue
	else:
		env.fog_mode = Environment.FogMode.FOG_MODE_EXPONENTIAL
		env.fog_density = blended_density + _default_density * residue


## Unity: OnPlayableDestroy — restore cached defaults.
func on_playable_destroy() -> void:
	var env: Environment = _resolve_env()
	if env == null or not _first_frame_done:
		return
	env.fog_light_color = _default_color
	env.fog_density = _default_density
	env.fog_depth_begin = _default_begin
	env.fog_depth_end = _default_end
	env.fog_enabled = _default_fog_enabled
	env.fog_mode = _default_fog_mode
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
