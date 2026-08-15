class_name TimelineMixer
extends RefCounted

## Unity MixerBehaviour analog. One instance per track; receives blended clip inputs
## each frame and writes results to the bound object.

var bound: Object = null
var _first_frame_done: bool = false


## Unity first ProcessFrame: cache current target values.
func on_first_frame() -> void:
	pass


## Unity ProcessFrame. inputs is an Array of Dictionary with keys:
## {clip: TimelineClip, behaviour: TimelineBehaviour, weight: float, clip_time: float}.
func process_frame(inputs: Array, time: float, delta: float) -> void:
	pass


## Unity OnPlayableDestroy: restore default values.
func on_playable_destroy() -> void:
	pass
