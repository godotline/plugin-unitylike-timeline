@tool
class_name AudioBehaviour
extends TimelineBehaviour

## Unity AudioTrack ClipBehaviour analog: stream, volume and pitch applied while
## the playhead is inside the clip.

@export var stream: AudioStream = null
@export var volume_db: float = 0.0
@export var pitch_scale: float = 1.0
@export var loop: bool = false
@export var stop_on_exit: bool = true
