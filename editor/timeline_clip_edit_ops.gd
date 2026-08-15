@tool
class_name TimelineClipEditOps
extends RefCounted

## Pure planning helpers for Unity-style clip edits. Every function returns a
## Dictionary describing the changes; the dock applies them through the editor
## undo system so all mutations stay undoable.

enum EditMode { MIX, RIPPLE, REPLACE }

const TimelineClipClass := preload("res://addons/timeline/core/timeline_clip.gd")


## Plans moving a set of clips by delta_start. Returns:
## { "moved": {clip: new_start}, "resized": {clip: [new_start, new_duration]}, "removed": [clip...] }
static func plan_move(clips: Array[TimelineClip], delta_start: float, edit_mode: int, all_clips: Array[TimelineClip] = []) -> Dictionary:
	var result: Dictionary = {
		"moved": {},
		"resized": {},
		"removed": [],
	}
	if clips.is_empty() or is_zero_approx(delta_start):
		return result
	var moving: Dictionary = {}
	var min_start: float = INF
	var max_end: float = -INF
	for clip: TimelineClip in clips:
		if clip == null:
			continue
		moving[clip] = true
		min_start = minf(min_start, clip.start)
		max_end = maxf(max_end, clip.get_end())
	var new_min_start: float = min_start + delta_start
	if new_min_start < 0.0:
		delta_start = -min_start
	for clip: TimelineClip in clips:
		if clip == null:
			continue
		(result["moved"] as Dictionary)[clip] = maxf(0.0, clip.start + delta_start)
	if edit_mode == EditMode.RIPPLE:
		var shift: float = delta_start
		for other: TimelineClip in all_clips:
			if other == null or moving.has(other):
				continue
			if other.start >= max_end:
				(result["moved"] as Dictionary)[other] = maxf(0.0, other.start + shift)
	elif edit_mode == EditMode.REPLACE:
		var new_max_end: float = new_min_start + (max_end - min_start)
		for other: TimelineClip in all_clips:
			if other == null or moving.has(other):
				continue
			var other_end: float = other.get_end()
			if other_end <= new_min_start or other.start >= new_max_end:
				continue
			if other.start >= new_min_start and other_end <= new_max_end:
				(result["removed"] as Array).append(other)
			elif other.start < new_min_start and other_end > new_max_end:
				(result["resized"] as Dictionary)[other] = [other.start, new_min_start - other.start]
			elif other.start >= new_min_start:
				(result["resized"] as Dictionary)[other] = [new_max_end, other_end - new_max_end]
			else:
				(result["resized"] as Dictionary)[other] = [other.start, new_min_start - other.start]
	return result


## Plans resizing one clip. Returns the same shape as plan_move.
static func plan_resize(clip: TimelineClip, new_start: float, new_duration: float, edit_mode: int, all_clips: Array[TimelineClip] = []) -> Dictionary:
	var result: Dictionary = {
		"moved": {},
		"resized": {},
		"removed": [],
	}
	if clip == null:
		return result
	var safe_start: float = maxf(0.0, new_start)
	var safe_duration: float = maxf(0.05, new_duration)
	var old_end: float = clip.get_end()
	var new_end: float = safe_start + safe_duration
	if edit_mode == EditMode.RIPPLE:
		var shift: float = new_end - old_end
		for other: TimelineClip in all_clips:
			if other == null or other == clip:
				continue
			if other.start >= old_end:
				(result["moved"] as Dictionary)[other] = maxf(0.0, other.start + shift)
	elif edit_mode == EditMode.REPLACE:
		for other: TimelineClip in all_clips:
			if other == null or other == clip:
				continue
			var other_end: float = other.get_end()
			if other_end <= safe_start or other.start >= new_end:
				continue
			if other.start >= safe_start and other_end <= new_end:
				(result["removed"] as Array).append(other)
			elif other.start < safe_start and other_end > new_end:
				(result["resized"] as Dictionary)[other] = [other.start, safe_start - other.start]
			elif other.start >= safe_start:
				(result["resized"] as Dictionary)[other] = [new_end, other_end - new_end]
			else:
				(result["resized"] as Dictionary)[other] = [other.start, safe_start - other.start]
	(result["resized"] as Dictionary)[clip] = [safe_start, safe_duration]
	return result


## Deep-duplicates clips and offsets each copy by one duration so they appear
## immediately after the originals.
static func duplicate_clips(clips: Array[TimelineClip]) -> Array[TimelineClip]:
	var copies: Array[TimelineClip] = []
	for clip: TimelineClip in clips:
		if clip == null:
			continue
		var copy: TimelineClip = clip.duplicate_clip()
		copy.start = clip.get_end()
		copies.append(copy)
	return copies
