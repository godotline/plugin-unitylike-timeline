@tool
extends Control

## Timeline dock: the editor UI for the timeline plugin.
## New/Load/Save TimelineAsset, transport controls, track rows with draggable
## clips, add-track menu from TimelineRegistry, selection panel, and live
## playback through a TimelineDirector found in the edited scene.

const TimelineAssetClass := preload("res://addons/timeline/core/timeline_asset.gd")
const TimelineTrackClass := preload("res://addons/timeline/core/timeline_track.gd")
const TimelineDirectorClass := preload("res://addons/timeline/core/timeline_director.gd")
const TimelineClipClass := preload("res://addons/timeline/core/timeline_clip.gd")
const TimelineTrackRowClass := preload("res://addons/timeline/editor/timeline_track_row.gd")
const TimelineRulerClass := preload("res://addons/timeline/editor/timeline_ruler.gd")
const TimelinePlayheadClass := preload("res://addons/timeline/editor/timeline_playhead.gd")
const TimelineAddTrackMenuClass := preload("res://addons/timeline/editor/timeline_add_track_menu.gd")
const TimelinePropertyEditorClass := preload("res://addons/timeline/editor/timeline_property_editor.gd")
const TimelineCurveEditorClass := preload("res://addons/timeline/editor/timeline_curve_editor.gd")
const TimelineMarkerClass := preload("res://addons/timeline/core/timeline_marker.gd")
const TimelineSignalEmitterClass := preload("res://addons/timeline/core/timeline_signal_emitter.gd")
const TimelineSignalAssetClass := preload("res://addons/timeline/core/timeline_signal_asset.gd")

const _LABEL_WIDTH: float = 320.0
const _ROW_HEIGHT: float = 40.0
const _RULER_HEIGHT: float = 24.0
const _MIN_TIMELINE_WIDTH: float = 1200.0
const _MIN_TIMELINE_HEIGHT: float = 80.0

var _asset: TimelineAsset = null
var _pps: float = 60.0
var _snap: bool = true
var _selected_clip: TimelineClip = null
var _selected_track: TimelineTrack = null
var _selected_clips: Array[TimelineClip] = []
var _director: TimelineDirector = null
var _edit_mode: int = 0

var _time_label: Label = null
var _time_spin: SpinBox = null
var _play_button: Button = null
var _toolbar: HBoxContainer = null
var _ruler_row: HBoxContainer = null
var _body: HBoxContainer = null
var _ruler_scroll: ScrollContainer = null
var _label_scroll: ScrollContainer = null
var _clip_scroll: ScrollContainer = null
var _ruler: Control = null
var _ruler_stack: Control = null
var _label_column: VBoxContainer = null
var _clip_column: VBoxContainer = null
var _timeline_stack: Control = null
var _playhead: Control = null
var _hint_label: Label = null
var _add_director_button: Button = null
var _name_edit: LineEdit = null
var _start_spin: SpinBox = null
var _duration_spin: SpinBox = null
var _enabled_check: CheckBox = null
var _selection_panel: VBoxContainer = null
var _selection_scroll: ScrollContainer = null
var _clip_editor: VBoxContainer = null
var _template_editor: VBoxContainer = null
var _curve_title: Label = null
var _curve_editor: TimelineCurveEditor = null
var _track_editor: VBoxContainer = null
var _binding_edit: LineEdit = null
var _fps_spin: SpinBox = null
var _play_range_check: CheckBox = null
var _play_range_start_spin: SpinBox = null
var _play_range_end_spin: SpinBox = null
var _loop_mode: OptionButton = null
var _syncing_scroll: bool = false
var _selected_marker: TimelineMarker = null
var _multi_label: Label = null
var _name_row: HBoxContainer = null
var _start_row: HBoxContainer = null
var _duration_row: HBoxContainer = null
var _marker_title: Label = null
var _marker_name_row: HBoxContainer = null
var _marker_time_row: HBoxContainer = null
var _marker_once_row: HBoxContainer = null
var _marker_delete_btn: Button = null
var _marker_name_edit: LineEdit = null
var _marker_time_spin: SpinBox = null
var _marker_enabled_check: CheckBox = null
var _marker_once_check: CheckBox = null
var _marker_editor: TimelinePropertyEditor = null
var _template_title: Label = null
var _track_title: Label = null
var _clipboard: Array = []
var _record_btn: Button = null
var _recording: bool = false
var _record_buffer: Array[Dictionary] = []
var _record_last_sample: float = 0.0


func _ready() -> void:
	_build_toolbar()
	_build_content()
	_build_bottom()
	resized.connect(_layout_ui)
	_layout_ui()
	EditorInterface.get_selection().selection_changed.connect(_on_editor_selection_changed)
	set_process(true)


func _build_toolbar() -> void:
	_toolbar = HBoxContainer.new()
	_toolbar.custom_minimum_size = Vector2(0, 26)
	var preview_check: CheckBox = CheckBox.new()
	preview_check.text = "Preview"
	preview_check.button_pressed = true
	var new_btn: Button = Button.new()
	new_btn.text = "新建"
	new_btn.pressed.connect(_on_new)
	var load_btn: Button = Button.new()
	load_btn.text = "加载"
	load_btn.pressed.connect(_on_load)
	var save_btn: Button = Button.new()
	save_btn.text = "保存"
	save_btn.pressed.connect(_on_save)
	var seek_start_btn: Button = _make_icon_button("MoveLeft", "|<", "跳到开始", _on_seek_start)
	var step_back_btn: Button = _make_icon_button("Back", "<", "后退一帧", _on_step_back)
	_play_button = _make_icon_button("Play", ">", "播放", _on_play_pressed)
	var step_forward_btn: Button = _make_icon_button("Forward", ">|", "前进一帧", _on_step_forward)
	var seek_end_btn: Button = _make_icon_button("MoveRight", ">|", "跳到结尾", _on_seek_end)
	var stop_btn: Button = _make_icon_button("Stop", "[]", "停止", _on_stop_pressed)
	_record_btn = _make_icon_button("Record", "●", "录制选中 Transform Clip 关键帧", _on_record_pressed)
	_time_spin = SpinBox.new()
	_time_spin.min_value = 0.0
	_time_spin.max_value = 100000.0
	_time_spin.step = 1.0 / 60.0
	_time_spin.custom_minimum_size = Vector2(96.0, 0)
	_time_spin.value_changed.connect(_on_time_changed)
	_time_label = Label.new()
	_time_label.text = "/ 0.00"
	_time_label.custom_minimum_size = Vector2(72.0, 0)
	var zoom_slider: HSlider = HSlider.new()
	zoom_slider.min_value = 20.0
	zoom_slider.max_value = 200.0
	zoom_slider.value = 60.0
	zoom_slider.step = 1.0
	zoom_slider.custom_minimum_size = Vector2(120, 0)
	zoom_slider.value_changed.connect(_set_pps)
	var snap_check: CheckBox = CheckBox.new()
	snap_check.text = "吸附"
	snap_check.button_pressed = true
	snap_check.toggled.connect(func(toggled: bool) -> void: _on_snap_toggled(toggled))
	var mode_label: Label = Label.new()
	mode_label.text = "编辑"
	var edit_mode: OptionButton = OptionButton.new()
	edit_mode.add_item("Mix", 0)
	edit_mode.add_item("Ripple", 1)
	edit_mode.add_item("Replace", 2)
	edit_mode.selected = 0
	edit_mode.tooltip_text = "Clip 编辑模式"
	edit_mode.item_selected.connect(func(index: int) -> void: _edit_mode = index)
	var wrap_label: Label = Label.new()
	wrap_label.text = "结束"
	_loop_mode = OptionButton.new()
	_loop_mode.add_item("停止", TimelineDirector.WrapMode.NONE)
	_loop_mode.add_item("保持", TimelineDirector.WrapMode.HOLD)
	_loop_mode.add_item("循环", TimelineDirector.WrapMode.LOOP)
	_loop_mode.add_item("往返", TimelineDirector.WrapMode.PINGPONG)
	_loop_mode.selected = 0
	_loop_mode.item_selected.connect(_on_wrap_mode_changed)
	_fps_spin = SpinBox.new()
	_fps_spin.min_value = 1.0
	_fps_spin.max_value = 240.0
	_fps_spin.step = 1.0
	_fps_spin.value = 60.0
	_fps_spin.custom_minimum_size = Vector2(64.0, 0.0)
	_fps_spin.tooltip_text = "帧率"
	_fps_spin.value_changed.connect(_on_fps_changed)
	var range_label: Label = Label.new()
	range_label.text = "范围"
	_play_range_check = CheckBox.new()
	_play_range_check.tooltip_text = "启用播放范围"
	_play_range_check.toggled.connect(_on_play_range_toggled)
	_play_range_start_spin = SpinBox.new()
	_play_range_start_spin.min_value = 0.0
	_play_range_start_spin.max_value = 100000.0
	_play_range_start_spin.step = 0.01
	_play_range_start_spin.custom_minimum_size = Vector2(70.0, 0.0)
	_play_range_start_spin.value_changed.connect(_on_play_range_start_changed)
	_play_range_end_spin = SpinBox.new()
	_play_range_end_spin.min_value = 0.0
	_play_range_end_spin.max_value = 100000.0
	_play_range_end_spin.step = 0.01
	_play_range_end_spin.custom_minimum_size = Vector2(70.0, 0.0)
	_play_range_end_spin.value_changed.connect(_on_play_range_end_changed)
	_toolbar.add_child(preview_check)
	_toolbar.add_child(new_btn)
	_toolbar.add_child(load_btn)
	_toolbar.add_child(save_btn)
	_toolbar.add_child(seek_start_btn)
	_toolbar.add_child(step_back_btn)
	_toolbar.add_child(_play_button)
	_toolbar.add_child(step_forward_btn)
	_toolbar.add_child(seek_end_btn)
	_toolbar.add_child(stop_btn)
	_toolbar.add_child(_record_btn)
	_toolbar.add_child(_time_spin)
	_toolbar.add_child(_time_label)
	_toolbar.add_child(zoom_slider)
	_toolbar.add_child(snap_check)
	_toolbar.add_child(mode_label)
	_toolbar.add_child(edit_mode)
	_toolbar.add_child(wrap_label)
	_toolbar.add_child(_loop_mode)
	_toolbar.add_child(range_label)
	_toolbar.add_child(_play_range_check)
	_toolbar.add_child(_play_range_start_spin)
	_toolbar.add_child(_play_range_end_spin)
	_toolbar.add_child(_fps_spin)
	add_child(_toolbar)


func _make_icon_button(icon_name: String, fallback_text: String, tooltip: String, action: Callable) -> Button:
	var button: Button = Button.new()
	var icon: Texture2D = get_theme_icon(icon_name, "EditorIcons")
	if icon != null:
		button.icon = icon
	else:
		button.text = fallback_text
	button.tooltip_text = tooltip
	button.flat = true
	button.custom_minimum_size = Vector2(28.0, 24.0)
	button.pressed.connect(action)
	return button


func _build_content() -> void:
	_ruler_row = HBoxContainer.new()
	_ruler_row.custom_minimum_size = Vector2(0, _RULER_HEIGHT)
	var track_header: HBoxContainer = HBoxContainer.new()
	track_header.custom_minimum_size = Vector2(_LABEL_WIDTH, _RULER_HEIGHT)
	var add_track_btn: Button = _make_icon_button("Add", "+", "添加轨道", _on_add_track)
	track_header.add_child(add_track_btn)
	var add_marker_btn: Button = _make_icon_button("Add", "+M", "添加 Marker", _on_add_marker)
	track_header.add_child(add_marker_btn)
	var add_signal_btn: Button = _make_icon_button("Add", "+S", "添加 Signal Emitter", _on_add_signal_emitter)
	track_header.add_child(add_signal_btn)
	var track_header_spacer: Control = Control.new()
	track_header_spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track_header.add_child(track_header_spacer)
	_ruler_scroll = ScrollContainer.new()
	_ruler_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_ruler_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	_ruler_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_ruler_stack = Control.new()
	_ruler_stack.custom_minimum_size = Vector2(_MIN_TIMELINE_WIDTH, _RULER_HEIGHT)
	_ruler = TimelineRulerClass.new()
	_ruler.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_ruler_stack.add_child(_ruler)
	_ruler_scroll.add_child(_ruler_stack)
	_ruler_row.add_child(track_header)
	_ruler_row.add_child(_ruler_scroll)
	add_child(_ruler_row)

	_body = HBoxContainer.new()
	_body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_label_scroll = ScrollContainer.new()
	_label_scroll.custom_minimum_size = Vector2(_LABEL_WIDTH, 0)
	_label_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_label_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	# The fixed track header only scrolls vertically with the clip lanes.
	_label_column = VBoxContainer.new()
	_label_column.custom_minimum_size = Vector2(_LABEL_WIDTH, 0)
	_label_scroll.add_child(_label_column)
	_clip_scroll = ScrollContainer.new()
	_clip_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_clip_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	_clip_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_clip_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	# All time-based content is in this one coordinate space.
	_timeline_stack = Control.new()
	_timeline_stack.custom_minimum_size = Vector2(_MIN_TIMELINE_WIDTH, _MIN_TIMELINE_HEIGHT)
	_clip_column = VBoxContainer.new()
	_clip_column.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_timeline_stack.add_child(_clip_column)
	_playhead = TimelinePlayheadClass.new()
	_playhead.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_playhead.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_timeline_stack.add_child(_playhead)
	_clip_scroll.add_child(_timeline_stack)
	_body.add_child(_label_scroll)
	_body.add_child(_clip_scroll)
	add_child(_body)

	_ruler.connect("seek_requested", Callable(self, "_on_ruler_seek_requested"))
	_ruler.connect("marker_selected", Callable(self, "_on_marker_selected"))
	_ruler.connect("marker_moved", Callable(self, "_on_marker_moved"))
	_ruler.connect("marker_add_requested", Callable(self, "_on_marker_add_at"))
	_ruler.connect("marker_move_committed", Callable(self, "_on_marker_move_committed"))
	_ruler_scroll.get_h_scroll_bar().value_changed.connect(_on_ruler_horizontal_scrolled)
	_clip_scroll.get_h_scroll_bar().value_changed.connect(_on_clip_horizontal_scrolled)
	_label_scroll.get_v_scroll_bar().value_changed.connect(_on_label_vertical_scrolled)
	_clip_scroll.get_v_scroll_bar().value_changed.connect(_on_clip_vertical_scrolled)


func _layout_ui() -> void:
	if _toolbar == null or _ruler_row == null or _body == null:
		return
	# Editor theme scale can make controls taller than their requested size.
	var toolbar_height: float = maxf(30.0, _toolbar.get_combined_minimum_size().y)
	var ruler_height: float = maxf(_RULER_HEIGHT, _ruler_row.get_combined_minimum_size().y)
	_place_top(_toolbar, 0.0, toolbar_height)
	_place_top(_ruler_row, toolbar_height, ruler_height)
	var body_top: float = toolbar_height + ruler_height
	var bottom_height: float = 0.0
	if _selection_panel != null and _selection_panel.visible:
		bottom_height = minf(320.0, maxf(180.0, _selection_panel.get_combined_minimum_size().y))
	_place_top(_body, body_top, maxf(0.0, size.y - body_top - bottom_height))
	if _selection_panel != null and _selection_panel.visible:
		_place_top(_selection_scroll, size.y - bottom_height, bottom_height)
	if _hint_label != null and _hint_label.visible:
		_place_top(_hint_label, body_top, 24.0)
	if _add_director_button != null and _add_director_button.visible:
		_place_top(_add_director_button, body_top + 24.0, 30.0)


func _place_top(control: Control, top: float, height: float) -> void:
	control.anchor_left = 0.0
	control.anchor_top = 0.0
	control.anchor_right = 1.0
	control.anchor_bottom = 0.0
	control.offset_left = 0.0
	control.offset_top = top
	control.offset_right = 0.0
	control.offset_bottom = top + height


func _build_bottom() -> void:
	_hint_label = Label.new()
	_hint_label.text = "场景中没有 TimelineDirector"
	_hint_label.visible = false
	_add_director_button = Button.new()
	_add_director_button.text = "添加 TimelineDirector"
	_add_director_button.visible = false
	_add_director_button.pressed.connect(_on_add_director)
	_selection_scroll = ScrollContainer.new()
	_selection_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_selection_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	_selection_scroll.custom_minimum_size = Vector2(0.0, 180.0)
	_selection_panel = VBoxContainer.new()
	_selection_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_selection_panel.visible = false
	_multi_label = Label.new()
	_multi_label.visible = false
	_selection_panel.add_child(_multi_label)
	_name_row = HBoxContainer.new()
	var name_label: Label = Label.new()
	name_label.text = "名称"
	_name_edit = LineEdit.new()
	_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_name_edit.text_changed.connect(_on_name_changed)
	_name_row.add_child(name_label)
	_name_row.add_child(_name_edit)
	_start_row = HBoxContainer.new()
	var start_label: Label = Label.new()
	start_label.text = "开始"
	_start_spin = SpinBox.new()
	_start_spin.min_value = -1000.0
	_start_spin.max_value = 100000.0
	_start_spin.step = 0.01
	_start_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_start_spin.value_changed.connect(_on_start_changed)
	_start_row.add_child(start_label)
	_start_row.add_child(_start_spin)
	_duration_row = HBoxContainer.new()
	var duration_label: Label = Label.new()
	duration_label.text = "时长"
	_duration_spin = SpinBox.new()
	_duration_spin.min_value = 0.001
	_duration_spin.max_value = 100000.0
	_duration_spin.step = 0.01
	_duration_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_duration_spin.value_changed.connect(_on_duration_changed)
	_duration_row.add_child(duration_label)
	_duration_row.add_child(_duration_spin)
	_enabled_check = CheckBox.new()
	_enabled_check.text = "启用"
	_enabled_check.toggled.connect(_on_enabled_changed)
	_selection_panel.add_child(_name_row)
	_selection_panel.add_child(_start_row)
	_selection_panel.add_child(_duration_row)
	_selection_panel.add_child(_enabled_check)
	_clip_editor = TimelinePropertyEditorClass.new()
	_clip_editor.add_theme_constant_override("separation", 2)
	_clip_editor.property_changed.connect(_on_clip_dynamic_property_changed)
	_selection_panel.add_child(_clip_editor)
	_template_title = Label.new()
	_template_title.text = "Clip 参数"
	_selection_panel.add_child(_template_title)
	_template_editor = TimelinePropertyEditorClass.new()
	_template_editor.add_theme_constant_override("separation", 2)
	_template_editor.property_changed.connect(_on_template_property_changed)
	_selection_panel.add_child(_template_editor)
	_curve_title = Label.new()
	_curve_title.text = "曲线编辑"
	_curve_title.visible = false
	_selection_panel.add_child(_curve_title)
	_curve_editor = TimelineCurveEditorClass.new()
	_curve_editor.keyframes_changed.connect(_on_curve_keyframes_changed)
	_selection_panel.add_child(_curve_editor)
	_track_title = Label.new()
	_track_title.text = "Track 参数"
	_selection_panel.add_child(_track_title)
	_track_editor = TimelinePropertyEditorClass.new()
	_track_editor.add_theme_constant_override("separation", 2)
	_track_editor.property_changed.connect(_on_track_dynamic_property_changed)
	_selection_panel.add_child(_track_editor)
	_marker_title = Label.new()
	_marker_title.text = "Marker 参数"
	_marker_title.visible = false
	_selection_panel.add_child(_marker_title)
	_marker_name_row = HBoxContainer.new()
	var marker_name_label: Label = Label.new()
	marker_name_label.text = "名称"
	_marker_name_edit = LineEdit.new()
	_marker_name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_marker_name_edit.text_changed.connect(_on_marker_name_changed)
	_marker_name_row.add_child(marker_name_label)
	_marker_name_row.add_child(_marker_name_edit)
	_marker_time_row = HBoxContainer.new()
	var marker_time_label: Label = Label.new()
	marker_time_label.text = "时间"
	_marker_time_spin = SpinBox.new()
	_marker_time_spin.min_value = 0.0
	_marker_time_spin.max_value = 100000.0
	_marker_time_spin.step = 1.0 / 60.0
	_marker_time_spin.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_marker_time_spin.value_changed.connect(_on_marker_time_changed)
	_marker_time_row.add_child(marker_time_label)
	_marker_time_row.add_child(_marker_time_spin)
	_marker_enabled_check = CheckBox.new()
	_marker_enabled_check.text = "启用"
	_marker_enabled_check.toggled.connect(_on_marker_enabled_changed)
	_marker_once_row = HBoxContainer.new()
	_marker_once_check = CheckBox.new()
	_marker_once_check.text = "只触发一次"
	_marker_once_check.toggled.connect(_on_marker_once_changed)
	_marker_once_row.add_child(_marker_once_check)
	_marker_delete_btn = Button.new()
	_marker_delete_btn.text = "删除 Marker"
	_marker_delete_btn.pressed.connect(_on_marker_delete)
	_marker_editor = TimelinePropertyEditorClass.new()
	_marker_editor.add_theme_constant_override("separation", 2)
	_marker_editor.property_changed.connect(_on_marker_template_property_changed)
	_selection_panel.add_child(_marker_name_row)
	_selection_panel.add_child(_marker_time_row)
	_selection_panel.add_child(_marker_enabled_check)
	_selection_panel.add_child(_marker_once_row)
	_selection_panel.add_child(_marker_delete_btn)
	_selection_panel.add_child(_marker_editor)
	add_child(_hint_label)
	add_child(_add_director_button)
	_selection_scroll.add_child(_selection_panel)
	add_child(_selection_scroll)


## --- Asset lifecycle ---

func _on_new() -> void:
	_asset = TimelineAssetClass.new()
	_asset.asset_name = "New Timeline"
	_selected_clip = null
	_selected_track = null
	_refresh()
	_update_selection_panel()


func _on_load() -> void:
	var fd: FileDialog = FileDialog.new()
	fd.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	fd.filters = PackedStringArray(["*.tres"])
	fd.file_selected.connect(_on_load_path)
	add_child(fd)
	fd.popup_centered(Vector2i(500, 400))


func _on_load_path(path: String) -> void:
	var loaded: Resource = load(path)
	if loaded is TimelineAsset:
		_asset = loaded
		_selected_clip = null
		_selected_track = null
		_refresh()
		_update_selection_panel()


func _on_save() -> void:
	if _asset == null:
		return
	if _asset.resource_path.is_empty():
		var fd: FileDialog = FileDialog.new()
		fd.file_mode = FileDialog.FILE_MODE_SAVE_FILE
		fd.filters = PackedStringArray(["*.tres"])
		fd.file_selected.connect(_on_save_path)
		add_child(fd)
		fd.popup_centered(Vector2i(500, 400))
	else:
		ResourceSaver.save(_asset, _asset.resource_path)


func _on_save_path(path: String) -> void:
	_asset.resource_path = path
	ResourceSaver.save(_asset, path)


func _save_if_persisted() -> void:
	if _asset != null and not _asset.resource_path.is_empty():
		ResourceSaver.save(_asset, _asset.resource_path)


## --- Tracks / clips ---

func _on_add_track() -> void:
	if _asset == null:
		return
	var menu: PopupMenu = TimelineAddTrackMenuClass.new()
	add_child(menu)
	menu.call("build_from_registry")
	menu.connect("track_chosen", Callable(self, "_on_track_chosen"))
	menu.popup_centered(Vector2i(240, 320))


func _on_track_chosen(entry: Dictionary) -> void:
	var script: Script = entry["script"] as Script
	if _asset == null:
		return
	var track: TimelineTrack = null
	if script == null:
		track = _asset.create_group_track()
	else:
		track = script.new()
		track.track_name = entry["display_name"] as String
	var old: Array = _asset.tracks.duplicate()
	_asset.tracks.append(track)
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("添加轨道")
	ur.add_do_property(_asset, "tracks", _asset.tracks)
	ur.add_undo_property(_asset, "tracks", old)
	ur.commit_action()
	notify_property_list_changed()
	_save_if_persisted()
	_refresh()


func _on_track_delete(track: TimelineTrack) -> void:
	if _asset == null:
		return
	var info: Dictionary = _parent_info_of(track)
	if info.is_empty():
		return
	var parent_array: Array = info["array"] as Array
	var old: Array = parent_array.duplicate()
	if info["owner"] is TimelineAsset:
		_asset.remove_track_tree(track)
	else:
		parent_array.erase(track)
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("删除轨道")
	ur.add_do_property(info["owner"], info["property"], parent_array)
	ur.add_undo_property(info["owner"], info["property"], old)
	ur.commit_action()
	_save_if_persisted()
	_refresh()


func _on_mute_toggled(track: TimelineTrack, muted: bool) -> void:
	if track != null:
		track.muted = muted
		_save_if_persisted()


func _on_lock_toggled(track: TimelineTrack, locked: bool) -> void:
	if track != null:
		track.locked = locked
		_save_if_persisted()
		_refresh()


func _on_track_collapse(track: TimelineTrack) -> void:
	if track == null:
		return
	track.collapsed = not track.collapsed
	_save_if_persisted()
	_refresh()


func _on_track_selected(track: TimelineTrack) -> void:
	_selected_marker = null
	_selected_clip = null
	_selected_clips.clear()
	_selected_track = track
	_update_selection_panel()
	_apply_selection_visuals()


func _on_clip_selected(clip: TimelineClip, track: TimelineTrack, additive: bool) -> void:
	_selected_marker = null
	_selected_track = track
	if additive:
		if _selected_clips.has(clip):
			_selected_clips.erase(clip)
		else:
			_selected_clips.append(clip)
		_selected_clip = _selected_clips.back() as TimelineClip if not _selected_clips.is_empty() else null
	else:
		_selected_clips = [clip]
		_selected_clip = clip
	_update_selection_panel()
	_apply_selection_visuals()


func _on_track_row_clip_selected(clip: TimelineClip, track: TimelineTrack) -> void:
	_selected_marker = null
	_selected_track = track
	_selected_clip = clip


func _on_selection_changed(clips: Array[TimelineClip], track: TimelineTrack) -> void:
	_selected_clips = clips
	_selected_clip = clips.back() as TimelineClip if not clips.is_empty() else null
	_selected_track = track
	_selected_marker = null
	_update_selection_panel()
	_apply_selection_visuals()


func _on_multi_move(clips: Array[TimelineClip], delta_start: float) -> void:
	if clips.is_empty() or is_zero_approx(delta_start):
		return
	var grouped: Dictionary = {}
	for clip: TimelineClip in clips:
		var track: TimelineTrack = _track_of(clip)
		if track == null:
			continue
		if not grouped.has(track):
			grouped[track] = []
		(grouped[track] as Array).append(clip)
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("移动多个 Clip")
	for track_key: Variant in grouped.keys():
		var track: TimelineTrack = track_key as TimelineTrack
		var moved: Array = grouped[track_key] as Array
		var min_start: float = INF
		for clip: TimelineClip in moved:
			min_start = minf(min_start, clip.start)
			var old_start: float = clip.start
			var new_start: float = maxf(0.0, clip.start + delta_start)
			clip.start = new_start
			ur.add_do_property(clip, "start", new_start)
			ur.add_undo_property(clip, "start", old_start)
		if _edit_mode == 1:
			_ripple_shift(track, min_start, delta_start, ur)
		if _edit_mode == 2:
			var range_start: float = INF
			var range_end: float = -INF
			for clip: TimelineClip in moved:
				range_start = minf(range_start, clip.start)
				range_end = maxf(range_end, clip.get_end())
			_replace_overlaps(track, range_start, range_end, moved, ur)
	ur.commit_action()
	_save_if_persisted()
	_refresh()


func _on_clip_action(action: StringName, clip: TimelineClip, track: TimelineTrack) -> void:
	if clip == null:
		return
	_selected_track = track
	if not _selected_clips.has(clip):
		_selected_clips = [clip]
		_selected_clip = clip
	match action:
		&"copy":
			_copy_selected_clips()
		&"paste":
			_paste_clipboard()
		&"duplicate":
			_duplicate_selected_clips()
		&"rename":
			if _selected_clips.size() <= 1:
				_prompt_rename_clip(clip)
		&"toggle_enabled":
			_toggle_clip_enabled(clip)
		&"delete":
			_delete_selected_clips()
		&"clear_keyframes":
			_clear_clip_keyframes(clip)


func _toggle_clip_enabled(clip: TimelineClip) -> void:
	if clip == null:
		return
	var old: bool = clip.enabled
	_register_property_change(clip, &"enabled", old, not old, "切换 Clip 启用")
	_refresh()


func _clear_clip_keyframes(clip: TimelineClip) -> void:
	if clip == null or clip.template == null:
		return
	if not (clip.template is TransformBehaviour):
		return
	var behaviour: TransformBehaviour = clip.template as TransformBehaviour
	if behaviour.keyframes.is_empty():
		return
	_register_property_change(behaviour, &"keyframes", behaviour.keyframes, [], "清空关键帧")
	_refresh()


func _on_clip_move(clip: TimelineClip, new_start: float) -> void:
	if clip == null:
		return
	var moving: Array = _selected_clips.duplicate()
	if not moving.has(clip):
		moving = [clip]
	var grouped: Dictionary = {}
	for c: TimelineClip in moving:
		var t: TimelineTrack = _track_of(c)
		if t == null:
			continue
		if not grouped.has(t):
			grouped[t] = []
		(grouped[t] as Array).append(c)
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("移动 Clip")
	var delta: float = new_start - clip.start
	for track_key: Variant in grouped.keys():
		var t: TimelineTrack = track_key as TimelineTrack
		var clips_on_track: Array = grouped[track_key] as Array
		var min_start: float = INF
		for c: TimelineClip in clips_on_track:
			min_start = minf(min_start, c.start)
		var old_starts: Array = []
		var new_starts: Array = []
		for c: TimelineClip in clips_on_track:
			var target: float = maxf(0.0, c.start + delta)
			old_starts.append(c.start)
			new_starts.append(target)
			c.start = target
		for i: int in old_starts.size():
			ur.add_do_property(clips_on_track[i], "start", new_starts[i])
			ur.add_undo_property(clips_on_track[i], "start", old_starts[i])
		if _edit_mode == 1:
			_ripple_shift(t, min_start, delta, ur)
		if _edit_mode == 2:
			var new_range_start: float = INF
			var new_range_end: float = -INF
			for c: TimelineClip in clips_on_track:
				new_range_start = minf(new_range_start, c.start)
				new_range_end = maxf(new_range_end, c.get_end())
			_replace_overlaps(t, new_range_start, new_range_end, moving, ur)
	ur.commit_action()
	_save_if_persisted()
	_refresh()


func _on_clip_resize(clip: TimelineClip, new_start: float, new_duration: float) -> void:
	if clip == null:
		return
	var old_start: float = clip.start
	var old_duration: float = clip.duration
	var old_end: float = old_start + old_duration
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("缩放 Clip")
	clip.start = new_start
	clip.duration = new_duration
	ur.add_do_property(clip, "start", new_start)
	ur.add_do_property(clip, "duration", new_duration)
	ur.add_undo_property(clip, "start", old_start)
	ur.add_undo_property(clip, "duration", old_duration)
	var t: TimelineTrack = _track_of(clip)
	if t != null:
		if _edit_mode == 1:
			var delta_end: float = (new_start + new_duration) - old_end
			_ripple_shift(t, old_end, delta_end, ur, [clip])
		if _edit_mode == 2:
			_replace_overlaps(t, new_start, new_start + new_duration, [clip], ur)
	ur.commit_action()
	_save_if_persisted()
	_refresh()


func _ripple_shift(track: TimelineTrack, from_time: float, delta: float, ur: EditorUndoRedoManager, exclude: Array = []) -> void:
	if absf(delta) < 0.0001:
		return
	for clip: TimelineClip in track.clips:
		if clip.start < from_time or exclude.has(clip):
			continue
		var old: float = clip.start
		clip.start = maxf(0.0, clip.start + delta)
		ur.add_do_property(clip, "start", clip.start)
		ur.add_undo_property(clip, "start", old)


func _replace_overlaps(track: TimelineTrack, range_start: float, range_end: float, keep: Array, ur: EditorUndoRedoManager) -> void:
	var to_remove: Array = []
	for clip: TimelineClip in track.clips:
		if keep.has(clip):
			continue
		if clip.get_end() > range_start and clip.start < range_end:
			to_remove.append(clip)
	if to_remove.is_empty():
		return
	var old: Array = track.clips.duplicate()
	for clip: TimelineClip in to_remove:
		track.clips.erase(clip)
	ur.add_do_property(track, "clips", track.clips)
	ur.add_undo_property(track, "clips", old)


func _track_of(clip: TimelineClip) -> TimelineTrack:
	if clip == null or _asset == null:
		return null
	for track: TimelineTrack in _asset.get_all_tracks():
		if track.clips.has(clip):
			return track
	return null


func _parent_info_of(track: TimelineTrack) -> Dictionary:
	if _asset != null and _asset.tracks.has(track):
		return {"owner": _asset, "property": &"tracks", "array": _asset.tracks}
	for parent: TimelineTrack in _asset.get_all_tracks():
		if parent != track and parent.child_tracks.has(track):
			return {"owner": parent, "property": &"child_tracks", "array": parent.child_tracks}
	return {}


func _on_pick_binding(track: TimelineTrack) -> void:
	if track == null:
		return
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		return
	var menu: PopupMenu = PopupMenu.new()
	add_child(menu)
	menu.add_item("清除绑定", -1)
	var paths: PackedStringArray = []
	_collect_binding_nodes(root, paths)
	for index: int in paths.size():
		menu.add_item(paths[index], index)
	menu.id_pressed.connect(_on_binding_chosen.bind(track, paths))
	menu.popup_centered(Vector2i(320, 420))


func _collect_binding_nodes(node: Node, paths: PackedStringArray) -> void:
	if node == null:
		return
	if _director != null and is_instance_valid(_director):
		paths.append(String(_director.get_path_to(node)))
	else:
		paths.append(String(node.get_path()))
	for child: Node in node.get_children():
		_collect_binding_nodes(child, paths)


func _on_binding_chosen(id: int, track: TimelineTrack, paths: PackedStringArray) -> void:
	var old: NodePath = track.bound_path
	var new_path: NodePath = NodePath()
	if id >= 0 and id < paths.size():
		new_path = NodePath(paths[id])
	_undo_single_property(track, &"bound_path", new_path, old, "修改绑定")
	_refresh()


func _on_track_menu(track: TimelineTrack) -> void:
	if track == null:
		return
	var menu: PopupMenu = PopupMenu.new()
	add_child(menu)
	var add_clip_id: int = 0
	var add_child_id: int = 1
	var rename_id: int = 2
	var duplicate_id: int = 3
	var up_id: int = 4
	var down_id: int = 5
	var delete_id: int = 6
	menu.add_item("添加 Clip", add_clip_id)
	if track.is_group:
		menu.add_item("新建子轨道", add_child_id)
	menu.add_item("重命名", rename_id)
	menu.add_item("复制轨道", duplicate_id)
	menu.add_item("上移", up_id)
	menu.add_item("下移", down_id)
	menu.add_item("删除轨道", delete_id)
	menu.id_pressed.connect(_on_track_menu_action.bind(track, add_clip_id, add_child_id, rename_id, duplicate_id, up_id, down_id, delete_id))
	menu.popup_centered(Vector2i(220, 320))


func _on_track_menu_action(id: int, track: TimelineTrack, add_clip_id: int, add_child_id: int, rename_id: int, duplicate_id: int, up_id: int, down_id: int, delete_id: int) -> void:
	match id:
		add_clip_id:
			_add_clip_to_track(track, -1.0)
		add_child_id:
			_on_add_child_track(track)
		rename_id:
			_prompt_rename_track(track)
		duplicate_id:
			_duplicate_track(track)
		up_id:
			_move_track(track, -1)
		down_id:
			_move_track(track, 1)
		delete_id:
			_on_track_delete(track)


func _add_clip_to_track(track: TimelineTrack, at_time: float) -> void:
	if track == null or track.is_group:
		return
	var clip: TimelineClip = track.get_clip_class().new()
	if at_time < 0.0:
		at_time = _director.time if _director != null else 0.0
	clip.start = at_time
	var old: Array = track.clips.duplicate()
	track.clips.append(clip)
	_undo_array_commit([track], [&"clips"], [track.clips], [old], "添加 Clip")
	_selected_marker = null
	_selected_track = track
	_selected_clips = [clip]
	_selected_clip = clip
	_update_selection_panel()
	_apply_selection_visuals()


func _on_add_child_track(parent: TimelineTrack) -> void:
	if _asset == null or parent == null:
		return
	var menu: PopupMenu = TimelineAddTrackMenuClass.new()
	add_child(menu)
	menu.call("build_from_registry")
	menu.connect("track_chosen", Callable(self, "_on_child_track_chosen").bind(parent))
	menu.popup_centered(Vector2i(240, 320))


func _on_child_track_chosen(entry: Dictionary, parent: TimelineTrack) -> void:
	var script: Script = entry["script"] as Script
	if _asset == null or parent == null:
		return
	var track: TimelineTrack = null
	if script == null:
		track = _asset.create_group_track()
	else:
		track = script.new()
		track.track_name = entry["display_name"] as String
	var old: Array = parent.child_tracks.duplicate()
	parent.is_group = true
	parent.child_tracks.append(track)
	_undo_array_commit([parent], [&"child_tracks"], [parent.child_tracks], [old], "新建子轨道")
	_refresh()


func _duplicate_track(track: TimelineTrack) -> void:
	var info: Dictionary = _parent_info_of(track)
	if info.is_empty():
		return
	var parent: Array = info["array"] as Array
	var old: Array = parent.duplicate()
	var copy: TimelineTrack = track.duplicate(true) as TimelineTrack
	copy.track_name = track.track_name + " Copy"
	parent.insert(parent.find(track) + 1, copy)
	_undo_array_commit([info["owner"]], [info["property"]], [parent], [old], "复制轨道")
	_refresh()


func _move_track(track: TimelineTrack, offset: int) -> void:
	var info: Dictionary = _parent_info_of(track)
	if info.is_empty():
		return
	var parent: Array = info["array"] as Array
	var index: int = parent.find(track)
	var target: int = clampi(index + offset, 0, parent.size() - 1)
	if target == index:
		return
	var old: Array = parent.duplicate()
	parent.remove_at(index)
	parent.insert(target, track)
	_undo_array_commit([info["owner"]], [info["property"]], [parent], [old], "移动轨道")
	_refresh()


func _prompt_rename_track(track: TimelineTrack) -> void:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "重命名轨道"
	var edit: LineEdit = LineEdit.new()
	edit.text = track.track_name
	edit.custom_minimum_size = Vector2(260.0, 28.0)
	dialog.add_child(edit)
	dialog.confirmed.connect(_confirm_rename_track.bind(track, edit))
	add_child(dialog)
	dialog.popup_centered(Vector2i(320, 120))
	edit.grab_focus()


func _confirm_rename_track(track: TimelineTrack, edit: LineEdit) -> void:
	if track == null or edit == null:
		return
	var old_name: String = track.track_name
	_undo_single_property(track, &"track_name", edit.text, old_name, "重命名轨道")
	_refresh()


func _on_clip_context(clip: TimelineClip, track: TimelineTrack, global_pos: Vector2) -> void:
	_selected_track = track
	var menu: PopupMenu = PopupMenu.new()
	add_child(menu)
	menu.add_item("复制", 0)
	menu.add_item("粘贴", 1)
	menu.add_item("重复", 2)
	menu.add_item("重命名", 3)
	menu.add_item("删除", 4)
	menu.id_pressed.connect(_on_clip_menu_action)
	menu.position = Vector2i(global_pos)
	menu.popup()


func _on_clip_menu_action(id: int) -> void:
	match id:
		0:
			_copy_selected_clips()
		1:
			_paste_clipboard()
		2:
			_duplicate_selected_clips()
		3:
			if _selected_clip != null and _selected_clips.size() <= 1:
				_prompt_rename_clip(_selected_clip)
		4:
			_delete_selected_clips()


func _prompt_rename_clip(clip: TimelineClip) -> void:
	var dialog: ConfirmationDialog = ConfirmationDialog.new()
	dialog.title = "重命名 Clip"
	var edit: LineEdit = LineEdit.new()
	edit.text = clip.clip_name
	edit.custom_minimum_size = Vector2(260.0, 28.0)
	dialog.add_child(edit)
	dialog.confirmed.connect(_confirm_rename_clip.bind(clip, edit))
	add_child(dialog)
	dialog.popup_centered(Vector2i(320, 120))
	edit.grab_focus()


func _confirm_rename_clip(clip: TimelineClip, edit: LineEdit) -> void:
	if clip == null or edit == null:
		return
	_undo_single_property(clip, &"clip_name", edit.text, clip.clip_name, "重命名 Clip")
	_refresh()


func _copy_selected_clips() -> void:
	_clipboard.clear()
	for clip: TimelineClip in _selected_clips:
		_clipboard.append({"clip": clip.duplicate(true), "track": _track_of(clip)})


func _paste_clipboard() -> void:
	if _clipboard.is_empty():
		return
	var target: TimelineTrack = _selected_track
	if target == null and _selected_clip != null:
		target = _track_of(_selected_clip)
	if target == null:
		for track: TimelineTrack in _asset.get_all_tracks():
			if not track.is_group:
				target = track
				break
	if target == null:
		return
	var at_time: float = _director.time if _director != null else 0.0
	var old: Array = target.clips.duplicate()
	for entry: Dictionary in _clipboard:
		var copy: TimelineClip = (entry["clip"] as TimelineClip).duplicate(true) as TimelineClip
		copy.start = at_time
		target.clips.append(copy)
		at_time += copy.duration + 0.05
	_undo_array_commit([target], [&"clips"], [target.clips], [old], "粘贴 Clip")
	_refresh()


func _duplicate_selected_clips() -> void:
	if _selected_clips.is_empty():
		return
	var grouped: Dictionary = {}
	for clip: TimelineClip in _selected_clips:
		var track: TimelineTrack = _track_of(clip)
		if track == null:
			continue
		if not grouped.has(track):
			grouped[track] = []
		(grouped[track] as Array).append(clip)
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("重复 Clip")
	var new_selection: Array = []
	for track_key: Variant in grouped.keys():
		var track: TimelineTrack = track_key as TimelineTrack
		var old: Array = track.clips.duplicate()
		for clip: TimelineClip in (grouped[track_key] as Array):
			var copy: TimelineClip = clip.duplicate(true) as TimelineClip
			copy.start = clip.get_end() + 0.1
			track.clips.append(copy)
			new_selection.append(copy)
		ur.add_do_property(track, "clips", track.clips)
		ur.add_undo_property(track, "clips", old)
	ur.commit_action()
	_save_if_persisted()
	_selected_clips = new_selection
	_refresh()


func _delete_selected_clips() -> void:
	if _selected_clips.is_empty():
		return
	var grouped: Dictionary = {}
	for clip: TimelineClip in _selected_clips:
		var track: TimelineTrack = _track_of(clip)
		if track == null:
			continue
		if not grouped.has(track):
			grouped[track] = []
		(grouped[track] as Array).append(clip)
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("删除 Clip")
	for track_key: Variant in grouped.keys():
		var track: TimelineTrack = track_key as TimelineTrack
		var clips: Array = grouped[track_key] as Array
		var old: Array = track.clips.duplicate()
		var ripple_delta: float = 0.0
		var min_start: float = INF
		for clip: TimelineClip in clips:
			ripple_delta -= clip.duration
			min_start = minf(min_start, clip.start)
			track.clips.erase(clip)
		ur.add_do_property(track, "clips", track.clips)
		ur.add_undo_property(track, "clips", old)
		if _edit_mode == 1:
			for clip: TimelineClip in track.clips:
				if clip.start < min_start:
					continue
				var old_start: float = clip.start
				clip.start = maxf(0.0, clip.start + ripple_delta)
				ur.add_do_property(clip, "start", clip.start)
				ur.add_undo_property(clip, "start", old_start)
	ur.commit_action()
	_save_if_persisted()
	_selected_clips.clear()
	_selected_clip = null
	_refresh()
	_update_selection_panel()


func _select_all_clips() -> void:
	if _asset == null:
		return
	_selected_clips.clear()
	if _selected_track != null:
		_selected_clips.append_array(_selected_track.clips)
	else:
		for track: TimelineTrack in _asset.get_all_tracks():
			if not track.is_group:
				_selected_clips.append_array(track.clips)
	if not _selected_clips.is_empty():
		_selected_clip = _selected_clips.back() as TimelineClip
	_update_selection_panel()
	_apply_selection_visuals()


func _clear_selection() -> void:
	_selected_clips.clear()
	_selected_clip = null
	_selected_track = null
	_selected_marker = null
	_update_selection_panel()
	_apply_selection_visuals()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey:
		return
	var key: InputEventKey = event as InputEventKey
	if not key.pressed or key.echo:
		return
	if key.ctrl_pressed:
		match key.keycode:
			KEY_C:
				_copy_selected_clips()
			KEY_V:
				_paste_clipboard()
			KEY_D:
				_duplicate_selected_clips()
			KEY_A:
				_select_all_clips()
	elif key.keycode == KEY_DELETE or key.keycode == KEY_BACKSPACE:
		_delete_selected_clips()
	elif key.keycode == KEY_ESCAPE:
		_clear_selection()


func _undo_array_commit(objects: Array, properties: Array, new_values: Array, old_values: Array, action_name: String) -> void:
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action(action_name)
	for i: int in objects.size():
		ur.add_do_property(objects[i], properties[i], new_values[i])
		ur.add_undo_property(objects[i], properties[i], old_values[i])
	ur.commit_action()
	_save_if_persisted()
	notify_property_list_changed()


func _undo_single_property(object: Object, property_name: StringName, new_value: Variant, old_value: Variant, action_name: String) -> void:
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action(action_name)
	ur.add_do_property(object, property_name, new_value)
	ur.add_undo_property(object, property_name, old_value)
	ur.commit_action()
	_save_if_persisted()


func _on_add_marker() -> void:
	if _asset == null:
		return
	var marker: TimelineMarker = TimelineMarkerClass.new()
	marker.time = _director.time if _director != null else 0.0
	marker.marker_name = "Marker %d" % (_asset.markers.size() + 1)
	var old: Array = _asset.markers.duplicate()
	_asset.markers.append(marker)
	_undo_array_commit([_asset], [&"markers"], [_asset.markers], [old], "添加 Marker")
	_selected_clips.clear()
	_selected_clip = null
	_selected_track = null
	_selected_marker = marker
	_refresh()
	_update_selection_panel()


func _on_add_signal_emitter() -> void:
	if _asset == null:
		return
	var emitter: TimelineSignalEmitter = TimelineSignalEmitterClass.new()
	var signal_asset: TimelineSignalAsset = TimelineSignalAssetClass.new()
	signal_asset.signal_name = StringName("Signal %d" % (_asset.markers.size() + 1))
	emitter.signal_asset = signal_asset
	emitter.time = _director.time if _director != null else 0.0
	emitter.marker_name = signal_asset.get_display_name()
	var old: Array = _asset.markers.duplicate()
	_asset.markers.append(emitter)
	_undo_array_commit([_asset], [&"markers"], [_asset.markers], [old], "添加 Signal Emitter")
	_selected_clips.clear()
	_selected_clip = null
	_selected_track = null
	_selected_marker = emitter
	_refresh()
	_update_selection_panel()


func _on_marker_add_at(time: float) -> void:
	if _asset == null:
		return
	var marker: TimelineMarker = TimelineMarkerClass.new()
	marker.time = maxf(0.0, time)
	marker.marker_name = "Marker %d" % (_asset.markers.size() + 1)
	var old: Array = _asset.markers.duplicate()
	_asset.markers.append(marker)
	_undo_array_commit([_asset], [&"markers"], [_asset.markers], [old], "添加 Marker")
	_selected_marker = marker
	_refresh()
	_update_selection_panel()


func _on_marker_selected(marker: TimelineMarker) -> void:
	_selected_clips.clear()
	_selected_clip = null
	_selected_track = null
	_selected_marker = marker
	_update_selection_panel()
	_apply_selection_visuals()


func _on_marker_moved(marker: TimelineMarker, time: float) -> void:
	marker.time = maxf(0.0, time)
	_ruler.call("set_markers", _asset.markers)
	_update_selection_panel()


func _on_marker_move_committed(marker: TimelineMarker, time: float, old_time: float) -> void:
	_undo_single_property(marker, &"time", maxf(0.0, time), old_time, "移动 Marker")


func _on_marker_name_changed(new_text: String) -> void:
	if _selected_marker == null:
		return
	_undo_single_property(_selected_marker, &"marker_name", new_text, _selected_marker.marker_name, "重命名 Marker")
	_ruler.queue_redraw()


func _on_marker_time_changed(value: float) -> void:
	if _selected_marker == null:
		return
	_undo_single_property(_selected_marker, &"time", value, _selected_marker.time, "修改 Marker 时间")
	_ruler.queue_redraw()


func _on_marker_enabled_changed(toggled: bool) -> void:
	if _selected_marker == null:
		return
	_undo_single_property(_selected_marker, &"enabled", toggled, _selected_marker.enabled, "切换 Marker 启用")


func _on_marker_once_changed(toggled: bool) -> void:
	if _selected_marker == null:
		return
	_undo_single_property(_selected_marker, &"trigger_once", toggled, _selected_marker.trigger_once, "切换 Marker 只触发一次")


func _on_marker_delete() -> void:
	if _selected_marker == null:
		return
	var old: Array = _asset.markers.duplicate()
	_asset.markers.erase(_selected_marker)
	_undo_array_commit([_asset], [&"markers"], [_asset.markers], [old], "删除 Marker")
	_selected_marker = null
	_refresh()
	_update_selection_panel()


func _on_marker_template_property_changed(property_name: StringName, old_value: Variant, value: Variant) -> void:
	if _selected_marker == null:
		return
	if _selected_marker is TimelineSignalEmitter:
		_register_property_change(_selected_marker, property_name, old_value, value, "修改 Signal Emitter 参数")
	elif _selected_marker.template != null:
		_register_property_change(_selected_marker.template, property_name, old_value, value, "修改 Marker 参数")


func _signal_emitter_filter(property_name: StringName, _info: Dictionary) -> bool:
	return property_name in [&"signal_asset", &"receiver_path", &"arg", &"color"]


## --- Selection panel ---

func _update_selection_panel() -> void:
	var has_clip: bool = _selected_clip != null or _selected_clips.size() > 0
	var has_track: bool = _selected_track != null and not has_clip
	var has_marker: bool = _selected_marker != null
	var has_sel: bool = has_clip or has_track or has_marker
	_selection_panel.visible = has_sel
	_multi_label.visible = _selected_clips.size() > 1
	if _multi_label.visible:
		_multi_label.text = "已选 %d 个 Clip" % _selected_clips.size()
	var single_clip: bool = _selected_clip != null and _selected_clips.size() <= 1
	_name_row.visible = has_clip
	_start_row.visible = has_clip
	_duration_row.visible = has_clip
	_enabled_check.visible = has_clip
	_name_edit.editable = single_clip
	_start_spin.editable = single_clip
	_duration_spin.editable = single_clip
	_enabled_check.disabled = not single_clip
	if single_clip:
		_clip_editor.setup(_selected_clip, Callable(self, "_clip_extra_filter"))
		_template_editor.setup(_selected_clip.template, Callable(self, "_template_filter"))
		_clip_editor.visible = true
		_template_title.visible = true
		_template_editor.visible = true
		var has_curve: bool = _selected_clip.template is TransformBehaviour
		_curve_title.visible = has_curve
		_curve_editor.set_clip(_selected_clip)
	else:
		_clip_editor.clear()
		_template_editor.clear()
		_clip_editor.visible = false
		_template_editor.visible = false
		_template_title.visible = false
		_curve_title.visible = false
		_curve_editor.clear()
	_track_title.visible = has_track
	_track_editor.visible = has_track
	if has_track:
		_track_editor.setup(_selected_track, Callable(self, "_track_filter"))
	else:
		_track_editor.clear()
	_marker_title.visible = has_marker
	_marker_name_row.visible = has_marker
	_marker_time_row.visible = has_marker
	_marker_enabled_check.visible = has_marker
	_marker_once_row.visible = has_marker
	_marker_delete_btn.visible = has_marker
	_marker_editor.visible = has_marker
	if has_marker:
		if _selected_marker is TimelineSignalEmitter:
			_marker_editor.setup(_selected_marker, Callable(self, "_signal_emitter_filter"))
		else:
			_marker_editor.setup(_selected_marker.template, Callable(self, "_template_filter"))
		_marker_name_edit.set_block_signals(true)
		_marker_name_edit.text = _selected_marker.marker_name
		_marker_name_edit.set_block_signals(false)
		_marker_time_spin.set_block_signals(true)
		_marker_time_spin.value = _selected_marker.time
		_marker_time_spin.set_block_signals(false)
		_marker_enabled_check.set_block_signals(true)
		_marker_enabled_check.button_pressed = _selected_marker.enabled
		_marker_enabled_check.set_block_signals(false)
		_marker_once_check.set_block_signals(true)
		_marker_once_check.button_pressed = _selected_marker.trigger_once
		_marker_once_check.set_block_signals(false)
	else:
		_marker_editor.clear()
	if not has_sel:
		_layout_ui()
		return
	if not single_clip:
		_layout_ui()
		return
	_name_edit.set_block_signals(true)
	_name_edit.text = _selected_clip.clip_name
	_name_edit.set_block_signals(false)
	_start_spin.set_block_signals(true)
	_start_spin.value = _selected_clip.start
	_start_spin.set_block_signals(false)
	_duration_spin.set_block_signals(true)
	_duration_spin.value = _selected_clip.duration
	_duration_spin.set_block_signals(false)
	_enabled_check.set_block_signals(true)
	_enabled_check.button_pressed = _selected_clip.enabled
	_enabled_check.set_block_signals(false)
	_layout_ui()


func _clip_extra_filter(property_name: StringName, _info: Dictionary) -> bool:
	return property_name in [&"blend_in", &"blend_out", &"clip_in", &"speed", &"ease_in_duration", &"ease_out_duration", &"pre_extrapolation", &"post_extrapolation", &"mix_mode", &"blend_curve"]


func _template_filter(property_name: StringName, _info: Dictionary) -> bool:
	return property_name != &"resource_local_to_scene"


func _track_filter(property_name: StringName, _info: Dictionary) -> bool:
	if property_name in [&"track_name", &"track_color", &"enabled", &"muted", &"locked", &"collapsed", &"is_group", &"bound_path", &"track_offset_position", &"track_offset_rotation", &"track_offset_scale", &"match_offset_start", &"match_offset_end"]:
		return true
	if property_name in [&"clips", &"child_tracks", &"script", &"resource_local_to_scene"]:
		return false
	return true


func _on_curve_keyframes_changed(keyframes: Array) -> void:
	if _selected_clip == null or _selected_clip.template == null:
		return
	if not (_selected_clip.template is TransformBehaviour):
		return
	var behaviour: TransformBehaviour = _selected_clip.template as TransformBehaviour
	var old_keyframes: Array = behaviour.keyframes.duplicate(true)
	_register_property_change(behaviour, &"keyframes", old_keyframes, keyframes.duplicate(true), "编辑关键帧")


func _on_clip_dynamic_property_changed(property_name: StringName, old_value: Variant, value: Variant) -> void:
	if _selected_clip == null:
		return
	_register_property_change(_selected_clip, property_name, old_value, value, "修改 Clip 参数")


func _on_template_property_changed(property_name: StringName, old_value: Variant, value: Variant) -> void:
	if _selected_clip == null or _selected_clip.template == null:
		return
	_register_property_change(_selected_clip.template, property_name, old_value, value, "修改 Clip 参数")


func _on_track_dynamic_property_changed(property_name: StringName, old_value: Variant, value: Variant) -> void:
	if _selected_track == null:
		return
	_register_property_change(_selected_track, property_name, old_value, value, "修改 Track 参数")
	if property_name == &"track_name" or property_name == &"track_color" or property_name == &"collapsed":
		_refresh()


func _register_property_change(object: Object, property_name: StringName, old_value: Variant, value: Variant, action_name: String) -> void:
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action(action_name)
	ur.add_do_property(object, property_name, value)
	ur.add_undo_property(object, property_name, old_value)
	ur.commit_action()
	_save_if_persisted()


func _on_name_changed(new_text: String) -> void:
	if _selected_clip == null:
		return
	var old: String = _selected_clip.clip_name
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("重命名 Clip")
	ur.add_do_property(_selected_clip, "clip_name", new_text)
	ur.add_undo_property(_selected_clip, "clip_name", old)
	ur.commit_action()
	_save_if_persisted()
	_refresh()


func _on_start_changed(value: float) -> void:
	if _selected_clip == null:
		return
	var old: float = _selected_clip.start
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("修改 Clip 开始")
	ur.add_do_property(_selected_clip, "start", value)
	ur.add_undo_property(_selected_clip, "start", old)
	ur.commit_action()
	_save_if_persisted()
	_refresh()


func _on_duration_changed(value: float) -> void:
	if _selected_clip == null:
		return
	var old: float = _selected_clip.duration
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("修改 Clip 时长")
	ur.add_do_property(_selected_clip, "duration", value)
	ur.add_undo_property(_selected_clip, "duration", old)
	ur.commit_action()
	_save_if_persisted()
	_refresh()


func _on_enabled_changed(toggled: bool) -> void:
	if _selected_clip == null:
		return
	var old: bool = _selected_clip.enabled
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("切换 Clip 启用")
	ur.add_do_property(_selected_clip, "enabled", toggled)
	ur.add_undo_property(_selected_clip, "enabled", old)
	ur.commit_action()
	_save_if_persisted()


func _on_fps_changed(value: float) -> void:
	if _asset == null:
		return
	var new_fps: int = maxi(1, roundi(value))
	if new_fps == _asset.fps:
		return
	_register_property_change(_asset, &"fps", _asset.fps, new_fps, "修改帧率")
	_time_spin.step = 1.0 / float(new_fps)
	_ruler.call("set_fps", new_fps)
	_refresh()


func _on_snap_toggled(toggled: bool) -> void:
	_snap = toggled
	_refresh()


func _on_wrap_mode_changed(index: int) -> void:
	if _director != null:
		_director.wrap_mode = int(_loop_mode.get_item_id(index))


func _on_play_range_toggled(toggled: bool) -> void:
	if _asset == null:
		return
	_register_property_change(_asset, &"play_range_enabled", not toggled, toggled, "切换播放范围")
	_refresh()


func _on_play_range_start_changed(value: float) -> void:
	if _asset == null:
		return
	_register_property_change(_asset, &"play_range_start", _asset.play_range_start, value, "修改播放范围开始")
	_refresh()


func _on_play_range_end_changed(value: float) -> void:
	if _asset == null:
		return
	_register_property_change(_asset, &"play_range_end", _asset.play_range_end, value, "修改播放范围结束")
	_refresh()


## --- Refresh ---

func _refresh() -> void:
	if _asset == null:
		return
	for child in _label_column.get_children():
		child.queue_free()
	for child in _clip_column.get_children():
		child.queue_free()
	var clip_width: float = maxf(_MIN_TIMELINE_WIDTH, _asset.get_duration() * _pps)
	_ruler_stack.custom_minimum_size = Vector2(clip_width, _RULER_HEIGHT)
	_label_column.custom_minimum_size = Vector2(_LABEL_WIDTH, 0.0)
	var content_height: float = 0.0
	for track: TimelineTrack in _asset.tracks:
		content_height = _build_track_rows(track, 0, content_height)
	content_height = maxf(_MIN_TIMELINE_HEIGHT, content_height)
	_timeline_stack.custom_minimum_size = Vector2(clip_width, content_height)
	_label_column.custom_minimum_size = Vector2(_LABEL_WIDTH, content_height)
	_ruler.call("set_duration", _asset.get_duration())
	_ruler.call("set_markers", _asset.markers)
	_ruler.call("set_fps", _asset.fps)
	_ruler.call("set_play_range", _asset.play_range_enabled, _asset.play_range_start, _asset.play_range_end)
	_playhead.call("set_duration", _asset.get_duration())
	if _fps_spin != null:
		_fps_spin.set_block_signals(true)
		_fps_spin.value = _asset.fps
		_fps_spin.set_block_signals(false)
	if _play_range_check != null:
		_play_range_check.set_pressed_no_signal(_asset.play_range_enabled)
		_play_range_start_spin.set_block_signals(true)
		_play_range_start_spin.value = _asset.play_range_start
		_play_range_start_spin.set_block_signals(false)
		_play_range_end_spin.set_block_signals(true)
		_play_range_end_spin.value = _asset.play_range_end
		_play_range_end_spin.set_block_signals(false)
	_time_spin.step = 1.0 / float(_asset.fps)
	_apply_selection_visuals()


func _build_track_rows(track: TimelineTrack, depth: int, y: float) -> float:
	if track == null:
		return y
	var label_row: HBoxContainer = _make_track_label_row(track, depth)
	var row_height: float = maxf(_ROW_HEIGHT, label_row.get_combined_minimum_size().y)
	label_row.custom_minimum_size = Vector2(_LABEL_WIDTH, row_height)
	_label_column.add_child(label_row)
	var row: Control = TimelineTrackRowClass.new()
	row.call("set_row_height", row_height)
	row.call("setup", track, _pps)
	row.call("set_clip_width", maxf(_MIN_TIMELINE_WIDTH, _asset.get_duration() * _pps))
	row.call("set_locked", track.locked)
	row.call("set_snap", _snap)
	row.connect("clip_selected", Callable(self, "_on_track_row_clip_selected"))
	row.connect("track_selected", Callable(self, "_on_track_selected"))
	row.connect("selection_changed", Callable(self, "_on_selection_changed"))
	row.connect("clip_move_requested", Callable(self, "_on_clip_move"))
	row.connect("clip_resize_requested", Callable(self, "_on_clip_resize"))
	row.connect("multi_move_requested", Callable(self, "_on_multi_move"))
	row.connect("clip_action_requested", Callable(self, "_on_clip_action"))
	_clip_column.add_child(row)
	y += row_height + _clip_column.get_theme_constant("separation")
	if track.is_group and not track.collapsed:
		for child: TimelineTrack in track.child_tracks:
			y = _build_track_rows(child, depth + 1, y)
	return y


func _make_track_label_row(track: TimelineTrack, depth: int) -> HBoxContainer:
	var label_row: HBoxContainer = HBoxContainer.new()
	label_row.custom_minimum_size = Vector2(_LABEL_WIDTH, _ROW_HEIGHT)
	var indent: Control = Control.new()
	indent.custom_minimum_size = Vector2(float(depth) * 16.0, 0.0)
	label_row.add_child(indent)
	if track.is_group:
		var collapse_btn: Button = Button.new()
		collapse_btn.text = ">" if track.collapsed else "v"
		collapse_btn.flat = true
		collapse_btn.custom_minimum_size = Vector2(24.0, 0.0)
		collapse_btn.tooltip_text = "折叠/展开组轨道"
		collapse_btn.pressed.connect(_on_track_collapse.bind(track))
		label_row.add_child(collapse_btn)
	var color_rect: ColorRect = ColorRect.new()
	color_rect.custom_minimum_size = Vector2(12, 12)
	color_rect.color = track.track_color
	label_row.add_child(color_rect)
	var name_btn: Button = Button.new()
	name_btn.text = track.get_display_name()
	name_btn.flat = true
	name_btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	name_btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_btn.clip_text = true
	name_btn.tooltip_text = "选择轨道"
	name_btn.pressed.connect(_on_track_selected.bind(track))
	label_row.add_child(name_btn)
	var mute_box: CheckBox = CheckBox.new()
	mute_box.button_pressed = track.muted
	mute_box.tooltip_text = "静音"
	mute_box.toggled.connect(_on_mute_toggled.bind(track))
	label_row.add_child(mute_box)
	var lock_box: CheckBox = CheckBox.new()
	lock_box.button_pressed = track.locked
	lock_box.tooltip_text = "锁定"
	lock_box.toggled.connect(_on_lock_toggled.bind(track))
	label_row.add_child(lock_box)
	var binding_btn: Button = Button.new()
	binding_btn.text = "绑定"
	binding_btn.flat = true
	binding_btn.custom_minimum_size = Vector2(56.0, 0.0)
	binding_btn.tooltip_text = "选择绑定对象"
	binding_btn.pressed.connect(_on_pick_binding.bind(track))
	label_row.add_child(binding_btn)
	var menu_btn: Button = Button.new()
	menu_btn.text = "⋮"
	menu_btn.flat = true
	menu_btn.custom_minimum_size = Vector2(24.0, 0.0)
	menu_btn.tooltip_text = "轨道菜单"
	menu_btn.pressed.connect(_on_track_menu.bind(track))
	label_row.add_child(menu_btn)
	var delete_btn: Button = Button.new()
	delete_btn.text = "X"
	delete_btn.flat = true
	delete_btn.custom_minimum_size = Vector2(24.0, 0.0)
	delete_btn.tooltip_text = "删除轨道"
	delete_btn.pressed.connect(_on_track_delete.bind(track))
	label_row.add_child(delete_btn)
	return label_row


func _apply_selection_visuals() -> void:
	for row: Node in _clip_column.get_children():
		if row.has_method("set_selected_clips"):
			row.call("set_selected_clips", _selected_clips)


func _set_pps(v: float) -> void:
	_pps = v
	_ruler.call("set_pps", v)
	_playhead.call("set_pps", v)
	_refresh()


func _on_ruler_seek_requested(time: float) -> void:
	if _director != null:
		_director.seek(time)


func _on_time_changed(time: float) -> void:
	if _director != null:
		_director.seek(time)


func _on_ruler_horizontal_scrolled(value: float) -> void:
	if _syncing_scroll:
		return
	_syncing_scroll = true
	_clip_scroll.scroll_horizontal = int(roundi(value))
	_syncing_scroll = false


func _on_clip_horizontal_scrolled(value: float) -> void:
	if _syncing_scroll:
		return
	_syncing_scroll = true
	_ruler_scroll.scroll_horizontal = int(roundi(value))
	_syncing_scroll = false


func _on_label_vertical_scrolled(value: float) -> void:
	if _syncing_scroll:
		return
	_syncing_scroll = true
	_clip_scroll.scroll_vertical = int(roundi(value))
	_syncing_scroll = false


func _on_clip_vertical_scrolled(value: float) -> void:
	if _syncing_scroll:
		return
	_syncing_scroll = true
	_label_scroll.scroll_vertical = int(roundi(value))
	_syncing_scroll = false


## --- Transport ---

func _find_director() -> TimelineDirector:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		return null
	return _find_director_in(root)


func _find_director_in(node: Node) -> TimelineDirector:
	if node is TimelineDirector:
		return node
	for child in node.get_children():
		var r: TimelineDirector = _find_director_in(child)
		if r != null:
			return r
	return null


func _on_add_director() -> void:
	var root: Node = EditorInterface.get_edited_scene_root()
	if root == null:
		return
	var director: Node = Node.new()
	director.set_script(TimelineDirectorClass)
	director.name = "TimelineDirector"
	var ur: EditorUndoRedoManager = EditorInterface.get_editor_undo_redo()
	ur.create_action("添加 TimelineDirector")
	ur.add_do_method(root, "add_child", director)
	ur.add_undo_method(root, "remove_child", director)
	ur.commit_action()
	EditorInterface.mark_scene_as_unsaved()
	_director = director as TimelineDirector


func _on_seek_start() -> void:
	if _director != null:
		_director.seek(0.0)


func _on_step_back() -> void:
	if _director != null:
		_director.seek(maxf(0.0, _director.time - (1.0 / 60.0)))


func _on_step_forward() -> void:
	if _director != null:
		_director.seek(minf(_director.get_duration(), _director.time + (1.0 / 60.0)))


func _on_seek_end() -> void:
	if _director != null:
		_director.seek(_director.get_duration())


func _on_play_pressed() -> void:
	if _director == null:
		return
	if _director.playing:
		_director.pause()
		_play_button.text = "播放"
	else:
		_director.play()
		_play_button.text = "暂停"


func _on_stop_pressed() -> void:
	if _director != null:
		_director.stop()
		_play_button.text = "播放"


func _on_record_pressed() -> void:
	if _recording:
		_finish_recording()
	else:
		_start_recording()


func _start_recording() -> void:
	if _selected_clip == null or _selected_clip.template == null:
		push_warning("录制需要先选中一个带 TransformBehaviour 的 Clip")
		return
	if not (_selected_clip.template is TransformBehaviour):
		push_warning("只有 Transform Clip 支持录制关键帧")
		return
	if _director == null:
		push_warning("场景中没有 TimelineDirector")
		return
	var track: TimelineTrack = _track_of(_selected_clip)
	if track == null:
		return
	var bound: Object = _director.get_bound(track)
	if bound == null or not (bound is Node3D):
		push_warning("选中的 Transform Clip 没有绑定 Node3D")
		return
	_recording = true
	_record_buffer.clear()
	_record_last_sample = _director.time
	_record_buffer.append(_sample_recorded_node(bound as Node3D, 0.0))
	if _record_btn != null:
		_record_btn.text = "■"


func _sample_recorded_node(node: Node3D, time: float) -> Dictionary:
	return {"time": time, "pos": node.position, "rot": node.rotation_degrees, "scale": node.scale}


func _finish_recording() -> void:
	_recording = false
	if _record_btn != null:
		_record_btn.text = "●"
	if _record_buffer.size() < 2 or _selected_clip == null or _selected_clip.template == null:
		_record_buffer.clear()
		return
	if not (_selected_clip.template is TransformBehaviour):
		_record_buffer.clear()
		return
	var behaviour: TransformBehaviour = _selected_clip.template as TransformBehaviour
	var first_time: float = float(_record_buffer[0].get("time", 0.0))
	var last_time: float = float(_record_buffer[_record_buffer.size() - 1].get("time", first_time + 1.0))
	var span: float = maxf(last_time - first_time, 0.0001)
	for entry: Dictionary in _record_buffer:
		entry["time"] = (float(entry.get("time", 0.0)) - first_time) / span
	var old_keyframes: Array = behaviour.keyframes.duplicate(true)
	_register_property_change(behaviour, &"keyframes", old_keyframes, _record_buffer, "录制关键帧")
	_record_buffer.clear()
	_refresh()


## 当 Director 首次被找到时，强制刷新 UI。
func _on_director_found() -> void:
	if _director.timeline != null:
		_asset = _director.timeline
		_refresh()


## 监听编辑器节点选中变化，如果选中了 TimelineDirector 则切换到该 Director。
func _on_editor_selection_changed() -> void:
	var selected: Array[Node] = EditorInterface.get_selection().get_selected_nodes()
	for node: Node in selected:
		if node is TimelineDirector:
			if _director != node:
				_director = node
				_on_director_found()
			return


func _process(_delta: float) -> void:
	if _director == null or not is_instance_valid(_director):
		_director = _find_director()
		if _director != null:
			_on_director_found()
	if _director == null:
		var visibility_changed: bool = not _hint_label.visible or not _add_director_button.visible
		_hint_label.visible = true
		_add_director_button.visible = true
		if visibility_changed:
			_layout_ui()
		return
	var visibility_changed: bool = _hint_label.visible or _add_director_button.visible
	_hint_label.visible = false
	_add_director_button.visible = false
	if visibility_changed:
		_layout_ui()
	if _director.timeline != null and _asset != _director.timeline:
		_asset = _director.timeline
		_refresh()
	if _recording:
		_update_recording()
	_time_spin.set_block_signals(true)
	_time_spin.value = _director.time
	_time_spin.set_block_signals(false)
	_time_label.text = "/ %.2f" % _director.get_duration()
	_ruler.call("set_time", _director.time)
	_playhead.call("set_time", _director.time)
	_ruler.queue_redraw()
	_playhead.queue_redraw()


func _update_recording() -> void:
	if _director == null or _selected_clip == null:
		_finish_recording()
		return
	if not _director.playing:
		_finish_recording()
		return
	var step: float = 1.0 / float(_asset.fps if _asset != null else 60)
	if _director.time - _record_last_sample < step:
		return
	var track: TimelineTrack = _track_of(_selected_clip)
	if track == null:
		_finish_recording()
		return
	var bound: Object = _director.get_bound(track)
	if bound == null or not (bound is Node3D):
		_finish_recording()
		return
	_record_last_sample = _director.time
	_record_buffer.append(_sample_recorded_node(bound as Node3D, _director.time))
