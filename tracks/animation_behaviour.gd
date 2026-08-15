@tool
class_name AnimationBehaviour
extends TimelineBehaviour

## Animation track clip behaviour: names the animation, playback speed, looping,
## and whether playback stops when the playhead leaves the clip.

@export var anim_name: StringName = &""
@export var speed_scale: float = 1.0
@export var loop: bool = false
@export var stop_on_exit: bool = true
