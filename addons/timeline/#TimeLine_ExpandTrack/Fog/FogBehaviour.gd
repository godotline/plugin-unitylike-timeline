# Unity: FogBehaviour.cs
@tool
class_name FogBehaviour
extends TimelineBehaviour

## Unity: public FogMode TargetFogMode (serialized field). Kept PascalCase for
## Unity serialization parity per AGENTS.md. FogModeEnum.LINEAR maps to Godot
## Environment.FogMode.DEPTH (fog_depth_begin/end); EXPONENTIAL maps to fog_density.
enum FogModeEnum { LINEAR, EXPONENTIAL }

@export var TargetFogMode: FogModeEnum = FogModeEnum.LINEAR
@export var TargetFogColor: Color = Color.WHITE
## Unity: [ShowIf("IsLinear")] — only meaningful in LINEAR mode.
@export var FogStartDistance: float = 10.0
@export var FogEndDistance: float = 100.0
## Unity: [HideIf("IsLinear")] — only meaningful in EXPONENTIAL mode.
@export var FogDensity: float = 0.01


## Unity: private bool IsLinear => TargetFogMode == FogMode.Linear
func is_linear() -> bool:
	return TargetFogMode == FogModeEnum.LINEAR
