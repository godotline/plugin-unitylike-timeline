@tool
class_name TransformTrack
extends TimelineTrack

## Demo custom track: interpolates position / rotation (euler degrees) / scale of a
## Node3D over the clip's duration in the director's process loop. Uses the
## non-mixer path (process_clip), proving the extension API's second evaluation mode.

var _initial_transforms: Dictionary = {}
var _match_anchors: Dictionary = {}
var _match_author_starts: Dictionary = {}

## Track mask, Unity AnimationTrack "mask" analog: disabled channels are left
## untouched by this track.
@export var mask_position: bool = true
@export var mask_rotation: bool = true
@export var mask_scale: bool = true

func _init() -> void:
	track_color = Color(0.3, 0.6, 0.9)


func get_clip_class() -> Script:
	return preload("res://addons/timeline/tracks/transform_clip.gd")


func get_display_name() -> String:
	return "Transform"


func on_clip_entered(clip: TimelineClip, bound: Object) -> void:
	if bound == null or not (bound is Node3D):
		return
	var node: Node3D = bound as Node3D
	var instance_id: int = node.get_instance_id()
	if not _initial_transforms.has(instance_id):
		_initial_transforms[instance_id] = node.transform
	var behaviour: TransformBehaviour = clip.template as TransformBehaviour
	if match_offset_start and behaviour != null:
		_match_anchors[instance_id] = node.transform
		if behaviour.keyframes.size() >= 2:
			var start_sample: Dictionary = _sample_keyframes(behaviour.keyframes, 0.0)
			_match_author_starts[instance_id] = start_sample.get("pos", Vector3.ZERO) as Vector3
		else:
			_match_author_starts[instance_id] = behaviour.start_pos
	apply_track_offset(bound)


func process_clip(clip: TimelineClip, clip_time: float, delta: float, bound: Object) -> void:
	if bound == null or not (bound is Node3D):
		return
	var behaviour: TransformBehaviour = clip.template as TransformBehaviour
	if behaviour == null or clip.duration <= 0.0:
		return
	var node: Node3D = bound as Node3D
	if behaviour.keyframes.size() >= 2:
		var sample: Dictionary = _sample_keyframes(behaviour.keyframes, clip_time / clip.duration)
		if mask_position:
			node.position = sample.get("pos", Vector3.ZERO) as Vector3
		if mask_rotation:
			node.rotation_degrees = sample.get("rot", Vector3.ZERO) as Vector3
		if mask_scale:
			node.scale = sample.get("scale", Vector3.ONE) as Vector3
		_apply_match_offset(node, behaviour)
		return
	var eased: float = Tween.interpolate_value(0.0, 1.0, clip_time, clip.duration, behaviour.trans_type, behaviour.ease_type)
	eased = clampf(eased, 0.0, 1.0)
	if mask_position:
		node.position = behaviour.start_pos.lerp(behaviour.end_pos, eased)
	_apply_match_offset(node, behaviour)
	if mask_rotation:
		node.rotation_degrees = behaviour.start_rot.lerp(behaviour.end_rot, eased)
	if mask_scale:
		node.scale = behaviour.start_scale.lerp(behaviour.end_scale, eased)


func _sample_keyframes(keyframes: Array[Dictionary], normalized_time: float) -> Dictionary:
	var t: float = clampf(normalized_time, 0.0, 1.0)
	var prev: Dictionary = keyframes[0]
	var next: Dictionary = keyframes[keyframes.size() - 1]
	for i: int in range(1, keyframes.size()):
		var current: Dictionary = keyframes[i]
		if t <= float(current.get("time", 1.0)):
			next = current
			break
		prev = current
	var prev_time: float = float(prev.get("time", 0.0))
	var next_time: float = float(next.get("time", 1.0))
	var span: float = maxf(next_time - prev_time, 0.0001)
	var u: float = clampf((t - prev_time) / span, 0.0, 1.0)
	return {
		"pos": (prev.get("pos", Vector3.ZERO) as Vector3).lerp(next.get("pos", Vector3.ZERO) as Vector3, u),
		"rot": (prev.get("rot", Vector3.ZERO) as Vector3).lerp(next.get("rot", Vector3.ZERO) as Vector3, u),
		"scale": (prev.get("scale", Vector3.ONE) as Vector3).lerp(next.get("scale", Vector3.ONE) as Vector3, u),
	}


func _apply_match_offset(node: Node3D, behaviour: TransformBehaviour) -> void:
	if not match_offset_start or behaviour == null:
		return
	var instance_id: int = node.get_instance_id()
	if not _match_anchors.has(instance_id) or not _match_author_starts.has(instance_id):
		return
	var anchor: Transform3D = _match_anchors[instance_id]
	var author_start: Vector3 = _match_author_starts[instance_id]
	node.position += anchor.origin - author_start


func on_playable_destroy(bound: Object) -> void:
	if bound == null or not is_instance_valid(bound) or not (bound is Node3D):
		return
	restore_track_offset(bound)
	var node: Node3D = bound as Node3D
	var instance_id: int = node.get_instance_id()
	if not _initial_transforms.has(instance_id):
		return
	var initial_transform: Transform3D = _initial_transforms[instance_id]
	node.transform = initial_transform
	_initial_transforms.erase(instance_id)
	_match_anchors.erase(instance_id)
	_match_author_starts.erase(instance_id)
