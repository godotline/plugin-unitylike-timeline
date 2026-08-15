@tool
class_name TimelineTrackHeader
extends HBoxContainer

## Unity-style track header: color swatch, rename-by-double-click, enable/mute/
## lock/collapse toggles, binding button, duplicate/delete buttons and a
## right-click context menu. The dock owns the undo system; this component only
## emits signals.

signal toggle_requested(track: TimelineTrack, property: StringName, value: bool)
signal rename_requested(track: TimelineTrack, new_name: String)
signal color_change_requested(track: TimelineTrack, color: Color)
signal delete_requested(track: TimelineTrack)
signal duplicate_requested(track: TimelineTrack)
signal context_action(track: TimelineTrack, action: StringName)
signal binding_button_pressed(track: TimelineTrack)

var _track: TimelineTrack = null
var _depth: int = 0
var _color_button: ColorPickerButton = null
var _name_label: Label = null
var _name_edit: LineEdit = null
var _enable_button: Button = null
var _mute_button: Button = null
var _lock_button: Button = null
var _collapse_button: Button = null
var _binding_button: Button = null
var _context_menu: PopupMenu = null


func setup(track: TimelineTrack, depth: int = 0) -> void:
	_track = track
	_depth = maxi(0, depth)
	_build_ui()
	refresh()


func _build_ui() -> void:
	for child: Node in get_children():
		child.queue_free()
	custom_minimum_size = Vector2(320.0, 40.0)
	var indent: Control = Control.new()
	indent.custom_minimum_size = Vector2(float(_depth * 14), 0.0)
	add_child(indent)
	_color_button = ColorPickerButton.new()
	_color_button.flat = true
	_color_button.custom_minimum_size = Vector2(18.0, 18.0)
	_color_button.tooltip_text = "轨道颜色"
	_color_button.color_changed.connect(_on_color_changed)
	add_child(_color_button)
	_name_label = Label.new()
	_name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_label.clip_text = true
	_name_label.mouse_filter = Control.MOUSE_FILTER_STOP
	_name_label.gui_input.connect(_on_name_label_input)
	add_child(_name_label)
	_name_edit = LineEdit.new()
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.visible = false
	_name_edit.text_submitted.connect(_on_rename_submitted)
	_name_edit.focus_exited.connect(_on_rename_focus_lost)
	add_child(_name_edit)
	_enable_button = _make_toggle("E", "启用", &"enabled")
	_mute_button = _make_toggle("M", "静音", &"muted")
	_lock_button = _make_toggle("L", "锁定", &"locked")
	_collapse_button = _make_toggle(">", "折叠", &"collapsed")
	_binding_button = Button.new()
	_binding_button.flat = true
	_binding_button.custom_minimum_size = Vector2(54.0, 22.0)
	_binding_button.tooltip_text = "绑定对象"
	_binding_button.pressed.connect(func() -> void: binding_button_pressed.emit(_track))
	add_child(_binding_button)
	var duplicate_button: Button = _make_icon_button("Duplicate", "D", "重复轨道")
	duplicate_button.pressed.connect(func() -> void: duplicate_requested.emit(_track))
	add_child(duplicate_button)
	var delete_button: Button = _make_icon_button("Remove", "X", "删除轨道")
	delete_button.pressed.connect(func() -> void: delete_requested.emit(_track))
	add_child(delete_button)
	_build_context_menu()


func _make_toggle(fallback: String, tooltip: String, _property: StringName) -> Button:
	var button: Button = _make_icon_button("", fallback, tooltip)
	button.toggle_mode = true
	button.toggled.connect(func(value: bool) -> void: toggle_requested.emit(_track, _property, value))
	return button


func _make_icon_button(icon_name: String, fallback: String, tooltip: String) -> Button:
	var button: Button = Button.new()
	var icon: Texture2D = get_theme_icon(icon_name, "EditorIcons") if not icon_name.is_empty() else null
	if icon != null:
		button.icon = icon
	else:
		button.text = fallback
	button.flat = true
	button.tooltip_text = tooltip
	button.custom_minimum_size = Vector2(24.0, 22.0)
	return button


func _build_context_menu() -> void:
	if _context_menu != null:
		return
	_context_menu = PopupMenu.new()
	_context_menu.add_item("重命名", 0)
	_context_menu.add_item("选择颜色", 1)
	_context_menu.add_separator()
	_context_menu.add_item("启用", 2)
	_context_menu.add_item("静音", 3)
	_context_menu.add_item("锁定", 4)
	if _track != null and _track.is_group:
		_context_menu.add_item("折叠", 5)
		_context_menu.add_separator()
		_context_menu.add_item("添加子轨道", 6)
	_context_menu.add_separator()
	_context_menu.add_item("重复", 7)
	_context_menu.add_item("删除", 8)
	_context_menu.id_pressed.connect(_on_context_id_pressed)
	add_child(_context_menu)


func _on_context_id_pressed(id: int) -> void:
	if _track == null:
		return
	var action: StringName = &""
	match id:
		0:
			action = &"rename"
		1:
			action = &"color"
		2:
			action = &"toggle_enabled"
		3:
			action = &"toggle_muted"
		4:
			action = &"toggle_locked"
		5:
			action = &"toggle_collapsed"
		6:
			action = &"add_child_track"
		7:
			action = &"duplicate"
		8:
			action = &"delete"
	context_action.emit(_track, action)


func refresh() -> void:
	if _track == null:
		return
	if _color_button != null:
		_color_button.color = _track.track_color
	if _name_label != null:
		_name_label.text = _track.get_display_name()
	if _name_edit != null:
		_name_edit.text = _track.get_display_name()
	_set_toggle(_enable_button, _track.enabled)
	_set_toggle(_mute_button, _track.muted)
	_set_toggle(_lock_button, _track.locked)
	_set_toggle(_collapse_button, _track.collapsed)
	if _binding_button != null:
		_binding_button.text = _get_bound_name()
	if _context_menu != null:
		_build_context_menu()
	queue_redraw()


func _set_toggle(button: Button, value: bool) -> void:
	if button == null:
		return
	button.set_pressed_no_signal(value)
	button.modulate = Color(1, 1, 1, 1.0 if value else 0.45)


func _get_bound_name() -> String:
	if _track == null or _track.bound_path.is_empty():
		return "未绑定"
	return String(_track.bound_path).get_file().trim_suffix(":1").trim_suffix(".tscn")


func _on_color_changed(color: Color) -> void:
	if _track != null:
		color_change_requested.emit(_track, color)


func _on_name_label_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mb: InputEventMouseButton = event as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT and mb.pressed and mb.double_click:
			_start_rename()
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if _context_menu != null:
				_context_menu.position = get_global_mouse_position()
				_context_menu.popup()


func _start_rename() -> void:
	if _track == null or _name_label == null or _name_edit == null:
		return
	_name_label.visible = false
	_name_edit.visible = true
	_name_edit.text = _track.get_display_name()
	_name_edit.grab_focus()
	_name_edit.select_all()


func _on_rename_submitted(text: String) -> void:
	_finish_rename(text)


func _on_rename_focus_lost() -> void:
	if _name_edit != null and _name_edit.visible:
		_finish_rename(_name_edit.text)


func _finish_rename(text: String) -> void:
	if _track != null:
		rename_requested.emit(_track, text.strip_edges())
	if _name_label != null:
		_name_label.visible = true
	if _name_edit != null:
		_name_edit.visible = false
