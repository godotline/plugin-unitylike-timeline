@tool
class_name ControlBehaviour
extends TimelineBehaviour

## Control Track clip data: which sub-timeline to play and how to restore.

@export var sub_timeline: TimelineAsset = null
@export var autoplay: bool = true
@export var restore_on_exit: bool = true
