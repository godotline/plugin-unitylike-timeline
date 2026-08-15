@tool
class_name TimelineClip
extends Resource

## Unity TimelineClip + PlayableAsset template analog. Holds timeline placement data
## plus a `template` TimelineBehaviour that carries the clip's serialized data.

@export var clip_name: String = "Clip"
@export var start: float = 0.0
@export var duration: float = 1.0
@export var blend_in: float = 0.0
@export var blend_out: float = 0.0
@export var enabled: bool = true
@export var template: TimelineBehaviour = null  # clip data (subclass provides typed template)

## Unity Timeline clip editing/runtime options.
enum ExtrapolationMode { NONE, HOLD, LOOP, PINGPONG }
enum MixMode { MIX, ADDITIVE, OVERRIDE }

## Source time inside the playable asset. This is separate from the timeline
## placement so a clip can trim its source without moving its lane position.
@export var clip_in: float = 0.0
## Playback rate. Values below zero play the source backwards.
@export var speed: float = 1.0
## Ease durations used by the editor and director's weight calculation.
@export var ease_in_duration: float = 0.0
@export var ease_out_duration: float = 0.0
@export var pre_extrapolation: ExtrapolationMode = ExtrapolationMode.NONE
@export var post_extrapolation: ExtrapolationMode = ExtrapolationMode.NONE
@export var mix_mode: MixMode = MixMode.MIX
## Optional custom blend curve. Null uses linear ease values.
@export var blend_curve: Curve = null


## End time of the clip (start + duration).
func get_end() -> float:
	return start + duration


## Deep-duplicates this clip, including its behaviour template.
func duplicate_clip() -> TimelineClip:
	return duplicate(true) as TimelineClip


## Whether this clip overlaps another clip's lane range.
func overlaps(other: TimelineClip) -> bool:
	if other == null:
		return false
	return start < other.get_end() and other.start < get_end()


## Clamps duration to a sane minimum and keeps the clip in non-negative time.
func clamp_duration(min_duration: float = 0.05) -> void:
	duration = maxf(min_duration, duration)
	if start < 0.0:
		duration = maxf(min_duration, duration + start)
		start = 0.0


## Time relative to the clip's start.
func get_local_time(time: float) -> float:
	return (time - start) * speed + clip_in


## Whether the given timeline time falls inside this clip.
func contains_time(time: float) -> bool:
	return time >= start and time < get_end()


## Returns a playable source time, including pre/post extrapolation. The
## director uses this for clips that support holding or looping past their lane.
func get_extrapolated_time(time: float) -> float:
	var local: float = get_local_time(time)
	var source_duration: float = maxf(duration * absf(speed), 0.0001)
	if time < start:
		match pre_extrapolation:
			ExtrapolationMode.HOLD:
				return clip_in
			ExtrapolationMode.LOOP:
				return clip_in + fposmod(local - clip_in, source_duration)
			ExtrapolationMode.PINGPONG:
				return clip_in + _ping_pong(local - clip_in, source_duration)
	elif time >= get_end():
		match post_extrapolation:
			ExtrapolationMode.HOLD:
				return clip_in + source_duration
			ExtrapolationMode.LOOP:
				return clip_in + fposmod(local - clip_in, source_duration)
			ExtrapolationMode.PINGPONG:
				return clip_in + _ping_pong(local - clip_in, source_duration)
	return local


func supports_extrapolation(time: float) -> bool:
	if contains_time(time):
		return true
	if time < start:
		return pre_extrapolation != ExtrapolationMode.NONE
	return post_extrapolation != ExtrapolationMode.NONE


func _ping_pong(value: float, period: float) -> float:
	var cycle: float = fposmod(value, period * 2.0)
	return cycle if cycle <= period else period * 2.0 - cycle
