@tool
class_name TimelinePropertyEditor
extends VBoxContainer

## Small Inspector-style editor used by the Timeline dock for Track and Clip
## resources. It intentionally uses native Godot controls so exported fields on
## custom tracks/clips become editable without writing a new editor for each
## track type.

signal property_changed(property: StringName, old_value: Variant, value: Variant)

var _object: Object = null
var _filter: Callable = Callable()
var _building: bool = false
var _title: String = ""


func setup(object: Object, filter: Callable = Callable()) -> void:
	_object = object
	_filter = filter
	_rebuild()


func set_title(text: String) -> void:
	_title = text
	if _object != null:
		_rebuild()


func clear() -> void:
	_object = null
	_filter = Callable()
	for child: Node in get_children():
		child.queue_free()


func refresh_values() -> void:
	if _object != null:
		_rebuild()


func _rebuild() -> void:
	_building = true
	for child: Node in get_children():
		child.queue_free()
	if _object == null:
		_building = false
		return
	var title: Label = Label.new()
	title.text = _title if not _title.is_empty() else _object.get_class()
	title.add_theme_font_size_override("font_size", 13)
	add_child(title)
	for info: Dictionary in _object.get_property_list():
		var property_name: StringName = info.get("name", &"") as StringName
		var usage: int = int(info.get("usage", 0))
		if property_name == &"script" or property_name == &"template":
			continue
		if not (usage & PROPERTY_USAGE_EDITOR):
			continue
		if not _filter.is_null() and not bool(_filter.call(property_name, info)):
			continue
		_add_property(info)
	_building = false


func _add_property(info: Dictionary) -> void:
	var property_name: StringName = info.get("name", &"") as StringName
	var row: HBoxContainer = HBoxContainer.new()
	row.custom_minimum_size = Vector2(0.0, 26.0)
	var label: Label = Label.new()
	label.text = String(property_name)
	label.custom_minimum_size = Vector2(150.0, 0.0)
	label.tooltip_text = String(property_name)
	row.add_child(label)
	var control: Control = _make_control(info)
	if control == null:
		row.queue_free()
		return
	control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(control)
	add_child(row)


func _make_control(info: Dictionary) -> Control:
	var property_name: StringName = info.get("name", &"") as StringName
	var type: int = int(info.get("type", TYPE_NIL))
	var hint: int = int(info.get("hint", PROPERTY_HINT_NONE))
	var hint_string: String = String(info.get("hint_string", ""))
	var value: Variant = _object.get(property_name)
	if hint == PROPERTY_HINT_ENUM:
		var option: OptionButton = OptionButton.new()
		var names: PackedStringArray = hint_string.split(",", false)
		for index: int in names.size():
			option.add_item(names[index].strip_edges(), index)
		option.selected = int(value)
		option.item_selected.connect(func(index: int) -> void: _emit_value(property_name, index))
		return option
	match type:
		TYPE_BOOL:
			var check: CheckBox = CheckBox.new()
			check.button_pressed = bool(value)
			check.toggled.connect(func(next: bool) -> void: _emit_value(property_name, next))
			return check
		TYPE_INT, TYPE_FLOAT:
			var spin: SpinBox = SpinBox.new()
			spin.allow_greater = true
			spin.allow_lesser = true
			spin.value = float(value)
			spin.step = 1.0 if type == TYPE_INT else 0.01
			if hint == PROPERTY_HINT_RANGE:
				var range_values: PackedStringArray = hint_string.split(",", false)
				if range_values.size() >= 2:
					spin.min_value = float(range_values[0])
					spin.max_value = float(range_values[1])
				if range_values.size() >= 3:
					spin.step = float(range_values[2])
			spin.value_changed.connect(func(next: float) -> void: _emit_value(property_name, int(next) if type == TYPE_INT else next))
			return spin
		TYPE_STRING, TYPE_STRING_NAME, TYPE_NODE_PATH:
			var edit: LineEdit = LineEdit.new()
			edit.text = String(value)
			edit.text_submitted.connect(func(next: String) -> void: _emit_value(property_name, _convert_text(type, next)))
			edit.focus_exited.connect(func() -> void: _emit_value(property_name, _convert_text(type, edit.text)))
			return edit
		TYPE_COLOR:
			var picker: ColorPickerButton = ColorPickerButton.new()
			picker.color = value as Color
			picker.custom_minimum_size = Vector2(80.0, 24.0)
			picker.color_changed.connect(func(next: Color) -> void: _emit_value(property_name, next))
			return picker
		TYPE_VECTOR2:
			return _make_vector_control(property_name, value as Vector2, false)
		TYPE_VECTOR3:
			return _make_vector3_control(property_name, value as Vector3)
		TYPE_VECTOR4:
			return _make_vector4_control(property_name, value as Vector4)
		TYPE_OBJECT:
			return _make_object_control(property_name, value)
	return null


func _make_object_control(property_name: StringName, value: Variant) -> Control:
	var box: HBoxContainer = HBoxContainer.new()
	var label: Label = Label.new()
	if value == null:
		label.text = "(空)"
	else:
		label.text = String(value)
		label.tooltip_text = String(value)
	label.clip_text = true
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	box.add_child(label)
	if value != null:
		var edit_btn: Button = Button.new()
		edit_btn.text = "编辑"
		edit_btn.custom_minimum_size = Vector2(48.0, 0.0)
		edit_btn.pressed.connect(func() -> void: _edit_resource(value))
		box.add_child(edit_btn)
		var clear_btn: Button = Button.new()
		clear_btn.text = "清除"
		clear_btn.custom_minimum_size = Vector2(48.0, 0.0)
		clear_btn.pressed.connect(func() -> void: _emit_value(property_name, null))
		box.add_child(clear_btn)
	return box


func _edit_resource(value: Variant) -> void:
	if value is Resource:
		EditorInterface.edit_resource(value as Resource)


func _make_vector_control(property_name: StringName, value: Vector2, _compact: bool) -> Control:
	var box: HBoxContainer = HBoxContainer.new()
	for axis: String in ["X", "Y"]:
		var spin: SpinBox = SpinBox.new()
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.step = 0.01
		spin.value = value.x if axis == "X" else value.y
		spin.tooltip_text = axis
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value_changed.connect(func(_next: float) -> void: _emit_vector2(property_name, box))
		box.add_child(spin)
	return box


func _make_vector3_control(property_name: StringName, value: Vector3) -> Control:
	var box: HBoxContainer = HBoxContainer.new()
	for axis: String in ["X", "Y", "Z"]:
		var spin: SpinBox = SpinBox.new()
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.step = 0.01
		spin.value = value.x if axis == "X" else value.y if axis == "Y" else value.z
		spin.tooltip_text = axis
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value_changed.connect(func(_next: float) -> void: _emit_vector3(property_name, box))
		box.add_child(spin)
	return box


func _make_vector4_control(property_name: StringName, value: Vector4) -> Control:
	var box: HBoxContainer = HBoxContainer.new()
	for axis: String in ["X", "Y", "Z", "W"]:
		var spin: SpinBox = SpinBox.new()
		spin.allow_greater = true
		spin.allow_lesser = true
		spin.step = 0.01
		spin.value = value.x if axis == "X" else value.y if axis == "Y" else value.z if axis == "Z" else value.w
		spin.tooltip_text = axis
		spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		spin.value_changed.connect(func(_next: float) -> void: _emit_vector4(property_name, box))
		box.add_child(spin)
	return box


func _emit_vector2(property_name: StringName, box: HBoxContainer) -> void:
	_emit_value(property_name, Vector2((box.get_child(0) as SpinBox).value, (box.get_child(1) as SpinBox).value))


func _emit_vector3(property_name: StringName, box: HBoxContainer) -> void:
	_emit_value(property_name, Vector3((box.get_child(0) as SpinBox).value, (box.get_child(1) as SpinBox).value, (box.get_child(2) as SpinBox).value))


func _emit_vector4(property_name: StringName, box: HBoxContainer) -> void:
	_emit_value(property_name, Vector4((box.get_child(0) as SpinBox).value, (box.get_child(1) as SpinBox).value, (box.get_child(2) as SpinBox).value, (box.get_child(3) as SpinBox).value))


func _convert_text(type: int, value: String) -> Variant:
	if type == TYPE_STRING_NAME:
		return StringName(value)
	if type == TYPE_NODE_PATH:
		return NodePath(value)
	return value


func _emit_value(property_name: StringName, value: Variant) -> void:
	if _building or _object == null:
		return
	var old_value: Variant = _object.get(property_name)
	_object.set(property_name, value)
	_object.notify_property_list_changed()
	property_changed.emit(property_name, old_value, value)
