# Unity: VignetteBehaviour.cs
@tool
class_name VignetteBehaviour
extends TimelineBehaviour

## Unity: public VignetteBehaviour — serialized clip data. Ranges from Unity:
## intensity 0~1, center (0~1, 0~1), roundness 0~1, rounded bool, color.

@export var enableVignette: bool = true

@export_range(0.0, 1.0, 0.01) var intensity: float = 0.0
@export var center: Vector2 = Vector2(0.5, 0.5)
@export_range(0.0, 1.0, 0.01) var roundness: float = 1.0
@export var rounded: bool = false
@export var color: Color = Color.BLACK
