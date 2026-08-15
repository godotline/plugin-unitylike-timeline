@tool
class_name ActivationTrack
extends TimelineTrack

## Unity ActivationTrack analog: toggles the bound object's active/visible state
## for the duration of each clip. Uses the non-mixer lifecycle path.

var _previous_states: Dictionary = {}


func _init() -> void:
	track_color = Color(0.85, 0.45, 0.25)


func get_clip_class() -> Script:
	return preload("res://addons/timeline/tracks/activation_clip.gd")


func get_display_name() -> String:
	return "Activation"


func validate_binding(bound: Object) -> bool:
	return bound != null and bound is CanvasItem


func on_clip_entered(clip: TimelineClip, bound: Object) -> void:
	if bound == null or not is_instance_valid(bound):
		return
	var behaviour: ActivationBehaviour = clip.template as ActivationBehaviour
	if behaviour == null:
		return
	var instance_id: int = bound.get_instance_id()
	if not _previous_states.has(instance_id):
		_previous_states[instance_id] = bool(bound.get("visible"))
	bound.set("visible", behaviour.active)


func on_clip_exited(clip: TimelineClip, bound: Object) -> void:
	if bound == null or not is_instance_valid(bound):
		return
	var instance_id: int = bound.get_instance_id()
	if not _previous_states.has(instance_id):
		return
	bound.set("visible", _previous_states[instance_id])
	_previous_states.erase(instance_id)


func on_playable_destroy(bound: Object) -> void:
	if bound == null or not is_instance_valid(bound):
		return
	var instance_id: int = bound.get_instance_id()
	if not _previous_states.has(instance_id):
		return
	bound.set("visible", _previous_states[instance_id])
	_previous_states.erase(instance_id)


func process_clip(clip: TimelineClip, clip_time: float, delta: float, bound: Object) -> void:
	pass
