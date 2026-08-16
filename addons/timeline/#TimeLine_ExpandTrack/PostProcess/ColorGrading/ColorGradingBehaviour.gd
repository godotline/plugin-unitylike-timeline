# Unity: ColorGradingBehaviour.cs
@tool
class_name ColorGradingBehaviour
extends TimelineBehaviour

## Unity: public ColorGradingBehaviour — serialized clip data. Ranges from Unity:
## brightness/contrast/saturation/temperature/tint -100~100, hueShift -180~180.
## Godot 4 note: white balance (temperature/tint) has NO Environment equivalent —
## kept for data parity, ignored by the mixer.

@export var enableColorGrading: bool = true

@export_range(-100.0, 100.0, 1.0) var brightness: float = 0.0
@export_range(-100.0, 100.0, 1.0) var contrast: float = 0.0
@export_range(-100.0, 100.0, 1.0) var saturation: float = 0.0
@export_range(-180.0, 180.0, 1.0) var hueShift: float = 0.0
@export_range(-100.0, 100.0, 1.0) var temperature: float = 0.0
@export_range(-100.0, 100.0, 1.0) var tint: float = 0.0
