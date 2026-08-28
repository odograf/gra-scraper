extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const SaveManagerScript := preload("res://scripts/save_manager.gd")

var main_box: VBoxContainer
var load_box: VBoxContainer
var status_label: Label

func _ready() -> void:
	_build_ui()
	_show_main_options()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and load_box.visible:
		_show_main_options()
		get_viewport().set_input_as_handled()

func _build_ui() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var background := ColorRect.new()
	background.color = Color("#11130ff8")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(background)

	var grime := ColorRect.new()
	grime.color = Color("#30332866")
	grime.position = Vector2(0, 460)
	grime.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	grime.offset_top = -260
	grime.offset_bottom = 0
	grime.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(grime)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(660, 530)
	panel.add_theme_stylebox_override("panel", _panel_style())
	center.add_child(panel)
	var shell := VBoxContainer.new()
	shell.add_theme_constant_override("separation", 18)
	panel.add_child(shell)

	var kicker := _label("POLSKIE OSIEDLE  •  WALKA O KAŻDY DZIEŃ", 13, Color("#9da48f"))
	kicker.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.add_child(kicker)
	var title := _label("ZŁOMIARZ RPG", 42, Color("#efb647"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_color_override("font_shadow_color", Color("#000000cc"))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	shell.add_child(title)
	var subtitle := _label("ZBIERAJ  •  PRZETRWAJ  •  ZBUDUJ SWÓJ REWIR", 14, Color("#d4d0bd"))
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	shell.add_child(subtitle)
	shell.add_child(HSeparator.new())

	main_box = VBoxContainer.new()
	main_box.add_theme_constant_override("separation", 12)
	shell.add_child(main_box)
	var new_game := _button("NOWA GRA")
	new_game.pressed.connect(_start_new_game)
	main_box.add_child(new_game)
	var load_game := _button("WCZYTAJ GRĘ")
	load_game.pressed.connect(_show_load_slots)
	main_box.add_child(load_game)
	var quit := _button("WYJŚCIE")
	quit.pressed.connect(get_tree().quit)
	main_box.add_child(quit)

	load_box = VBoxContainer.new()
	load_box.add_theme_constant_override("separation", 10)
	shell.add_child(load_box)
	for slot in range(1, 4):
		var slot_button := _button("")
		slot_button.name = "Slot%d" % slot
		slot_button.pressed.connect(_load_slot.bind(slot))
		load_box.add_child(slot_button)
	var back := _button("WSTECZ")
	back.pressed.connect(_show_main_options)
	load_box.add_child(back)

	status_label = _label("", 13, Color("#c9c5b4"))
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	status_label.custom_minimum_size.y = 42
	shell.add_child(status_label)

func _show_main_options() -> void:
	main_box.visible = true
	load_box.visible = false
	status_label.text = "Nowa gra rozpoczyna FAB-01 od początku. Zapisy pozostają w swoich slotach."
	_focus_first(main_box)

func _show_load_slots() -> void:
	main_box.visible = false
	load_box.visible = true
	status_label.text = "Wybierz zapis do wczytania."
	_refresh_slots()
	_focus_first(load_box)

func _refresh_slots() -> void:
	for slot in range(1, 4):
		var button := load_box.get_node("Slot%d" % slot) as Button
		var summary: Dictionary = _save_manager().slot_summary(slot)
		button.disabled = not bool(summary.exists)
		if summary.exists:
			button.text = "SLOT %d  •  POZIOM %d  •  %s" % [slot, int(summary.level), String(summary.saved_at)]
		else:
			button.text = "SLOT %d  •  PUSTY" % slot

func _start_new_game() -> void:
	_save_manager().start_new_game()
	get_tree().change_scene_to_file(GAME_SCENE)

func _load_slot(slot: int) -> void:
	if not _save_manager().request_load(slot):
		status_label.text = "Nie udało się odczytać slotu %d." % slot
		return
	get_tree().change_scene_to_file(GAME_SCENE)

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
	button.custom_minimum_size = Vector2(540, 58)
	button.add_theme_font_size_override("font_size", 17)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#2c3029")
	normal.border_color = Color("#626757")
	normal.set_border_width_all(2)
	normal.set_corner_radius_all(4)
	normal.set_content_margin_all(12)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#5e5030")
	hover.border_color = Color("#cda24d")
	var focus: StyleBoxFlat = hover.duplicate()
	focus.border_color = Color("#f3ce73")
	focus.set_border_width_all(4)
	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color("#20231f")
	disabled.border_color = Color("#3e423a")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_disabled_color", Color("#73776d"))
	return button

func _panel_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#171a16f2")
	style.border_color = Color("#77745f")
	style.set_border_width_all(3)
	style.set_corner_radius_all(7)
	style.set_content_margin_all(34)
	style.shadow_color = Color("#000000aa")
	style.shadow_size = 18
	return style

func _label(text: String, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	return label
