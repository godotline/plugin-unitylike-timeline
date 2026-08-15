@tool
class_name TimelineTrack
extends Resource

## Unity TrackAsset analog. Subclass to extend: override get_clip_class(), has_mixer(),
## create_mixer(), process_clip() and the lifecycle callbacks for custom behaviour.

@export var track_name: String = "Track"
@export var track_color: Color = Color(0.6, 0.6, 0.6)
@export var enabled: bool = true
@export var muted: bool = false
@export var locked: bool = false
@export var collapsed: bool = false
## Group tracks own child tracks while remaining resources in the same asset.
@export var is_group: bool = false
@export var child_tracks: Array[TimelineTrack] = []
@export var bound_path: NodePath = NodePath()  # resolved relative to TimelineDirector
@export var clips: Array[TimelineClip] = []

## Unity AnimationTrack-style offset applied to the bound node while the track
## is active. Match Offsets snap the clip start/end to the node's current pose.
@export var track_offset_position: Vector3 = Vector3.ZERO
@export var track_offset_rotation: Vector3 = Vector3.ZERO
@export var track_offset_scale: Vector3 = Vector3.ONE
@export var match_offset_start: bool = false
@export var match_offset_end: bool = false

# --- Extension API (override in subclasses) ---

## Clip script used for Add-Clip.
func get_clip_class() -> Script:
	return preload("res://addons/timeline/core/timeline_clip.gd")


## Unity: CreateTrackMixer? — whether this track uses a mixer.
func has_mixer() -> bool:
	return false


## Unity: CreateTrackMixer — returns the mixer instance, or null if none.
func create_mixer() -> TimelineMixer:
	return null


## Non-mixer evaluation path: process a single clip's frame.
func process_clip(clip: TimelineClip, clip_time: float, delta: float, bound: Object) -> void:
	pass


## Fired once when the playhead enters the clip.
func on_clip_entered(clip: TimelineClip, bound: Object) -> void:
	pass


## Fired once when the playhead leaves the clip.
func on_clip_exited(clip: TimelineClip, bound: Object) -> void:
	pass


## Called when the director stops or is destroyed. Non-mixer tracks can use
## this to restore state cached during preview or playback.
func on_playable_destroy(bound: Object) -> void:
	pass


## Optional bound-type check.
func validate_binding(bound: Object) -> bool:
	return true


## Name shown in the editor dock.
func get_display_name() -> String:
	return track_name


func add_clip(clip: TimelineClip) -> void:
	if clip == null:
		return
	clips.append(clip)
	notify_property_list_changed()


func remove_clip(clip: TimelineClip) -> void:
	clips.erase(clip)
	notify_property_list_changed()


func add_child_track(track: TimelineTrack) -> void:
	if track == null:
		return
	if track == self or track.has_descendant(self):
		return
	child_tracks.append(track)
	is_group = true
	notify_property_list_changed()


func remove_child_track(track: TimelineTrack) -> void:
	child_tracks.erase(track)
	notify_property_list_changed()


## Returns every descendant track (children and grandchildren), excluding self.
func get_all_descendants() -> Array[TimelineTrack]:
	var result: Array[TimelineTrack] = []
	_append_descendants(self, result)
	return result


## Whether candidate appears anywhere below this track (cycle guard).
func has_descendant(candidate: TimelineTrack) -> bool:
	if candidate == null or candidate == self:
		return false
	return get_all_descendants().has(candidate)


func _append_descendants(track: TimelineTrack, result: Array[TimelineTrack]) -> void:
	for child: TimelineTrack in track.child_tracks:
		if child == null:
			continue
		result.append(child)
		_append_descendants(child, result)


## Applies this track's offset to a Node3D and caches the pre-offset transform.
## Returns true when the bound node was modified.
func apply_track_offset(bound: Object) -> bool:
	if bound == null or not (bound is Node3D):
		return false
	var node: Node3D = bound as Node3D
	var instance_id: int = node.get_instance_id()
	if not _track_offset_bases.has(instance_id):
		_track_offset_bases[instance_id] = node.transform
	if match_offset_start:
		_track_offset_matches[instance_id] = node.transform
	node.position += track_offset_position
	node.rotation_degrees += track_offset_rotation
	node.scale *= track_offset_scale
	return true


## Restores the cached pre-offset transform.
func restore_track_offset(bound: Object) -> void:
	if bound == null or not is_instance_valid(bound) or not (bound is Node3D):
		return
	var node: Node3D = bound as Node3D
	var instance_id: int = node.get_instance_id()
	if _track_offset_bases.has(instance_id):
		var base_transform: Transform3D = _track_offset_bases[instance_id]
		if match_offset_end and _track_offset_matches.has(instance_id):
			node.transform = _track_offset_matches[instance_id]
		else:
			node.transform = base_transform
		_track_offset_bases.erase(instance_id)
		_track_offset_matches.erase(instance_id)


var _track_offset_bases: Dictionary = {}
var _track_offset_matches: Dictionary = {}
