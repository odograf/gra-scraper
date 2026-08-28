class_name PauseMenu
extends CanvasLayer

const SaveManagerScript := preload("res://scripts/save_manager.gd")

signal resume_requested
signal save_slot_requested(slot: int)
signal main_menu_requested

var main_box: VBoxContainer
var save_box: VBoxContainer
var status_label: Label

func _ready() -> void:
	layer = 50
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_ui()
	visible = false

func open_menu() -> void:
	visible = true
	_show_main_options()

func close_menu() -> void:
	visible = false

func show_save_result(slot: int, succeeded: bool) -> void:
	if succeeded:
		status_label.text = "Zapisano grę w slocie %d." % slot
		_refresh_slots()
	else:
		status_label.text = "Nie udało się zapisać gry w slocie %d." % slot

func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	if save_box.visible:
		_show_main_options()
	else:
		resume_requested.emit()
	get_viewport().set_input_as_handled()

func _build_ui() -> void:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color("#080a08df")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(650, 480)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 15)
	panel.add_child(shell)
	var title := _label("PAUZA", 34, Color("#efb647"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.add_child(title)
	var line := _label("ZŁOMIARZ RPG", 12, Color("#949b8b"))
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.add_child(line)
	shell.add_child(HSeparator.new())

	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 11)
	shell.add_child(main_box)
	var resume := _button("WRÓĆ DO GRY")
	resume.pressed.connect(func() -> void: resume_requested.emit())
	main_box.add_child(resume)
	var save := _button("ZAPISZ GRĘ")
	save.pressed.connect(_show_save_slots)
	main_box.add_child(save)
	var menu := _button("MENU GŁÓWNE")
	menu.pressed.connect(func() -> void: main_menu_requested.emit())
	main_box.add_child(menu)

	save_box = VBoxContainer.new()
	save_box.add_theme_constant_override("separation", 9)
	shell.add_child(save_box)
	for slot in range(1, 4):
		var slot_button := _button("")
		slot_button.name = "Slot%d" % slot
		slot_button.pressed.connect(_request_save_slot.bind(slot))
		save_box.add_child(slot_button)
	var back := _button("WSTECZ")
	back.pressed.connect(_show_main_options)
	save_box.add_child(back)

	status_label = _label("", 13, Color("#d0ccb9"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 44
	shell.add_child(status_label)

func _show_main_options() -> void:
	main_box.visible = true
	save_box.visible = false
	status_label.text = "Esc wraca do gry. Zapis jest możliwy w jednym z trzech slotów."
	_focus_first(main_box)

func _show_save_slots() -> void:
	main_box.visible = false
	save_box.visible = true
	status_label.text = "Wybierz slot. Istniejący zapis zostanie zastąpiony."
	_refresh_slots()
	_focus_first(save_box)

func _refresh_slots() -> void:
	for slot in range(1, 4):
		var button := save_box.get_node("Slot%d" % slot) as Button
		var summary: Dictionary = _save_manager().slot_summary(slot)
		if summary.exists:
			button.text = "SLOT %d  •  POZIOM %d  •  %s" % [slot, int(summary.level), String(summary.saved_at)]
		else:
			button.text = "SLOT %d  •  PUSTY" % slot

func _request_save_slot(slot: int) -> void:
	save_slot_requested.emit(slot)

func _save_manager() -> GameSaveManager:
	var manager := get_node_or_null("/root/SaveManager") as GameSaveManager
	if manager == null:
		manager = SaveManagerScript.new() as GameSaveManager
		manager.name = "SaveManager"
		get_tree().root.add_child(manager)
	return manager

func _focus_first(root: Control) -> void:
	for child in root.get_children():
		if child is Button and not child.disabled:
			(child as Button).grab_focus()
			return

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(530, 56)
	button.add_theme_font_size_override("font_size", 16)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#2d312a")
	normal.border_color = Color("#5f6558")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(10)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#625331")
	hover.border_color = Color("#c8a04e")
	var focus: StyleBoxFlat = hover.duplicate()
	focus.border_color = Color("#f1cc71")
	focus.set_border_width_all(4)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focus)
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171a16f7")
	style.border_color = Color("#77745f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(32)
	style.shadow_color = Color("#000000aa")
	style.shadow_size = 18
	return style

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
