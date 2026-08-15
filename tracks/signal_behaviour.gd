@tool
class_name SignalBehaviour
extends TimelineBehaviour

## Signal track clip behaviour: method name and optional argument fired on the
## bound object when the playhead enters the clip.

@export var method_name: StringName = &""
@export var arg: Variant = null
