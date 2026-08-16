# Unity: EnvironmentMixerBehaviour.cs
@tool
class_name EnvironmentMixer
extends TimelineMixer

## Cached environment defaults captured on first frame (Unity m_DefaultSky/Equator/Ground/Mode).
var _default_color: Color = Color.WHITE
var _default_sky_contrib: float = 0.0
var _default_source: int = Environment.AmbientSource.AMBIENT_SOURCE_COLOR


## Unity: first ProcessFrame — cache current ambient values before blending.
func on_first_frame() -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	_default_color = env.ambient_light_color
	_default_sky_contrib = env.ambient_light_sky_contribution
	_default_source = env.ambient_light_source


## Unity: ProcessFrame — weighted blend with invWeight = 1 - clamp01(totalWeight).
## Restores defaults when no input is active (Unity RestoreDefaults branch).
func process_frame(inputs: Array, time: float, delta: float) -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	if not _first_frame_done:
		on_first_frame()
		_first_frame_done = true

	var blended: Color = Color(0, 0, 0, 0)
	var total: float = 0.0
	var target_source: int = Environment.AmbientSource.AMBIENT_SOURCE_COLOR

	for i in inputs.size():
		var entry: Dictionary = inputs[i]
		var behaviour: EnvironmentBehaviour = entry["behaviour"] as EnvironmentBehaviour
		var weight: float = entry["weight"] as float
		if behaviour == null or weight <= 0.0:
			continue
		if behaviour.mode == EnvironmentBehaviour.RenderMode.TRILIGHT:
			# Unity Trilight: ambientSkyColor/EquatorColor/GroundColor. Godot 4 has a single
			# ambient color (no trilight), so we average the three HDR colors.
			var avg: Color = (behaviour.Sky_HDR + behaviour.Equator_HDR + behaviour.Ground_HDR) / 3.0
			blended += avg * weight
		else:
			blended += behaviour.Ambient_Color * weight
		total += weight

	if total > 0.0:
		var residue: float = clampf(1.0 - total, 0.0, 1.0)
		env.ambient_light_source = target_source
		env.ambient_light_color = blended + _default_color * residue
	else:
		RestoreDefaults()


## Unity: private void RestoreDefaults() — reapplies cached ambient values.
func RestoreDefaults() -> void:
	var env: Environment = _resolve_env()
	if env == null:
		return
	env.ambient_light_source = _default_source
	env.ambient_light_color = _default_color
	env.ambient_light_sky_contribution = _default_sky_contrib


## Unity: OnPlayableDestroy — restore defaults then reset first-frame flag.
func on_playable_destroy() -> void:
	if not _first_frame_done:
		return
	RestoreDefaults()
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
