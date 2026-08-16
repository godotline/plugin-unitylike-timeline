@tool
class_name TimelineAsset
extends Resource

## Unity TimelineAsset analog. Container of TimelineTracks; evaluated by TimelineDirector.

@export var asset_name: String = "Timeline"
@export var fps: int = 60
@export var duration: float = 0.0  # 0.0 = auto-computed from clips
@export var play_range_enabled: bool = false
@export var play_range_start: float = 0.0
@export var play_range_end: float = 0.0
@export var tracks: Array[TimelineTrack] = []
@export var markers: Array[TimelineMarker] = []


## Appends a track and refreshes the Inspector.
func add_track(track: TimelineTrack) -> void:
	tracks.append(track)
	notify_property_list_changed()


## Removes a track.
func remove_track(track: TimelineTrack) -> void:
	tracks.erase(track)


## Creates a group track with no clips. Groups only organize child tracks.
func create_group_track(group_name: String = "Group") -> TimelineTrack:
	var group: TimelineTrack = TimelineTrack.new()
	group.track_name = group_name
	group.is_group = true
	group.track_color = Color(0.45, 0.45, 0.5)
	return group


## Moves a track under a group (or back to the root when group is null).
func move_track_into_group(group: TimelineTrack, track: TimelineTrack) -> bool:
	if track == null or track == group:
		return false
	if group != null and (not group.is_group or group.has_descendant(track) or track.has_descendant(group)):
		return false
	_remove_track_from_parent(track)
	if group == null:
		tracks.append(track)
	else:
		group.add_child_track(track)
	notify_property_list_changed()
	return true


## Removes a track together with its whole child-track tree.
func remove_track_tree(track: TimelineTrack) -> void:
	if track == null:
		return
	for child: TimelineTrack in track.child_tracks.duplicate():
		remove_track_tree(child)
	_remove_track_from_parent(track)
	notify_property_list_changed()


func _remove_track_from_parent(track: TimelineTrack) -> void:
	if tracks.has(track):
		tracks.erase(track)
		return
	for parent: TimelineTrack in get_all_tracks():
		if parent.child_tracks.has(track):
			parent.child_tracks.erase(track)
			return


func add_marker(marker: TimelineMarker) -> void:
	if marker == null or markers.has(marker):
		return
	markers.append(marker)
	TimelineMarker.sort_markers(markers)
	notify_property_list_changed()


func remove_marker(marker: TimelineMarker) -> void:
	markers.erase(marker)
	notify_property_list_changed()


## Returns the number of tracks.
func get_track_count() -> int:
	return tracks.size()


## Returns the explicit duration if set, otherwise the max clip end across all tracks.
func get_duration() -> float:
	if duration > 0.0:
		return duration
	var max_end: float = 0.0
	for track: TimelineTrack in get_all_tracks():
		if track == null or track.is_group:
			continue
		for clip: TimelineClip in track.clips:
			if clip == null:
				continue
			max_end = maxf(max_end, clip.get_end())
	return max_end


func get_play_range_end() -> float:
	if play_range_enabled and play_range_end > play_range_start:
		return play_range_end
	return get_duration()


func get_all_tracks() -> Array[TimelineTrack]:
	var result: Array[TimelineTrack] = []
	for track: TimelineTrack in tracks:
		_append_track_tree(track, result)
	return result


func _append_track_tree(track: TimelineTrack, result: Array[TimelineTrack]) -> void:
	if track == null:
		return
	result.append(track)
	for child: TimelineTrack in track.child_tracks:
		_append_track_tree(child, result)


## Deep-duplicates this asset including all tracks and clips.
## NOTE: not named duplicate_deep() — Resource already has a native
## duplicate_deep(Resource.DeepDuplicateMode) method in Godot 4.7 (signature clash).
func deep_copy() -> TimelineAsset:
	var copy: TimelineAsset = duplicate(true) as TimelineAsset
	copy.tracks.clear()
	for track: TimelineTrack in tracks:
		copy.tracks.append(track.duplicate(true) as TimelineTrack)
	return copy
