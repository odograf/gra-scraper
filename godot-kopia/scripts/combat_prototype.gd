class_name CombatPrototype
extends Control

signal exit_requested(result: String)
signal combat_resolved(result: String)
signal player_health_changed(current_health: int, max_health: int)

const CombatRulesScript := preload("res://scripts/combat_rules.gd")
const CombatantConfigScript := preload("res://scripts/combatant_config.gd")

var rules
var move_buttons: Dictionary = {}
var player_health_bar: ProgressBar
var enemy_health_bar: ProgressBar
var player_health_label: Label
var enemy_health_label: Label
var player_state_label: Label
var enemy_state_label: Label
var round_label: Label
var combat_log: Label
var action_name_label: Label
var action_detail_label: Label
var header_label: Label
var enemy_name_label: Label
var result_box: VBoxContainer
var moves_grid: GridContainer
var busy := false
var player_motion_offset := Vector2.ZERO
var enemy_motion_offset := Vector2.ZERO
var player_stats := CombatantConfigScript.player()
var enemy_config := CombatantConfigScript.enemy("zadymiarz")
var enemy_name := "OSIEDLOWY ZADYMIARZ"
var enemy_intro := "Osiedlowy zadymiarz zagradza ci drogę. Wybierz ruch."
var enemy_kind := "human"
var enemy_max_health := CombatRulesScript.ENEMY_MAX_HEALTH
var enemy_damage_bonus := 0
var enemy_accuracy_bonus := 0.0
var enemy_texture: Texture2D
var combat_location := "WALKA POD KIOSKIEM"

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	rules = CombatRulesScript.new()
	_build_interface()
	visible = false

func start_fight(seed := 0) -> void:
	rules.configure_enemy_stats(enemy_config)
	rules.reset(seed, player_stats)
	busy = false
	player_motion_offset = Vector2.ZERO
	enemy_motion_offset = Vector2.ZERO
	visible = true
	moves_grid.visible = true
	result_box.visible = false
	header_label.text = "%s  •  ESC — WRÓĆ NA MAPĘ" % combat_location
	enemy_name_label.text = enemy_name
	combat_log.text = enemy_intro
	_show_action_details("quick")
	_update_interface(rules.snapshot())
	_set_moves_enabled(true)
	call_deferred("_focus_first_move")
	queue_redraw()

func set_player_stats(stats: Dictionary) -> void:
	player_stats = stats.duplicate(true)

func configure_enemy_from_definition(config: Dictionary, texture: Texture2D) -> void:
	enemy_config = config.duplicate(true)
	enemy_name = String(config.get("display_name", "Przeciwnik")).to_upper()
	enemy_texture = texture
	enemy_intro = String(config.get("intro", "Kliknij przeciwnika, aby zaatakować."))
	enemy_kind = String(config.get("kind", "human"))
	combat_location = String(config.get("location", "WALKA"))
	enemy_max_health = int(config.get("max_health", CombatRulesScript.ENEMY_MAX_HEALTH))

func show_reward_text(text: String) -> void:
	action_detail_label.text += "\n" + text

func close_fight() -> void:
	visible = false

func _process(_delta: float) -> void:
	if visible:
		queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not visible or busy or rules.finished:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _enemy_click_rect().has_point(event.position):
			accept_event()
			_choose_action("quick")

func _enemy_click_rect() -> Rect2:
	var size := get_viewport_rect().size
	return Rect2(Vector2(size.x - 535, 0), Vector2(470, 445))

func _draw() -> void:
	var size := get_viewport_rect().size
	draw_rect(Rect2(Vector2.ZERO, size), Color("#10130f"))
	draw_rect(Rect2(0, 0, size.x, 445), Color("#495047"))
	for y in range(56, 445, 56):
		draw_line(Vector2(0, y), Vector2(size.x, y), Color("#3b413a"), 3.0)
	for x in range(145, int(size.x), 250):
		draw_line(Vector2(x, 0), Vector2(x, 445), Color("#414740"), 2.0)
	draw_rect(Rect2(0, 330, size.x, 115), Color("#403c31"))
	_draw_ground_shadow(Vector2(270, 373), Vector2(170, 25))
	_draw_ground_shadow(Vector2(size.x - 280, 255), Vector2(155, 22))
	_draw_fighter(Vector2(270, 345) + player_motion_offset, true)
	if enemy_texture != null:
		var enemy_rect := Rect2(Vector2(size.x - 535, -22) + enemy_motion_offset, Vector2(470, 470))
		draw_texture_rect(enemy_texture, enemy_rect, false)
	else:
		_draw_fighter(Vector2(size.x - 280, 228) + enemy_motion_offset, false)

func _draw_ground_shadow(center: Vector2, radii: Vector2) -> void:
	var points := PackedVector2Array()
	for index in range(32):
		var angle := TAU * float(index) / 32.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	draw_colored_polygon(points, Color("#11130f66"))

func _draw_fighter(feet: Vector2, is_player: bool) -> void:
	var direction := 1.0 if is_player else -1.0
	var body_color := Color("#53644f") if is_player else Color("#75473a")
	var skin := Color("#b18c67")
	var outline := Color("#22241f")
	var head := feet + Vector2(0, -150)
	draw_line(feet + Vector2(-18, -10), feet + Vector2(-30, -70), outline, 25.0, true)
	draw_line(feet + Vector2(18, -10), feet + Vector2(25, -70), outline, 25.0, true)
	draw_polygon(PackedVector2Array([
		feet + Vector2(-48, -68), feet + Vector2(-38, -132),
		feet + Vector2(36, -132), feet + Vector2(52, -68)
	]), PackedColorArray([body_color]))
	draw_line(feet + Vector2(-32, -118), feet + Vector2(-78 * direction, -82), outline, 19.0, true)
	draw_line(feet + Vector2(30, -118), feet + Vector2(72 * direction, -105), outline, 19.0, true)
	draw_circle(head, 28.0, skin)
	draw_arc(head, 29.0, PI, TAU, 18, outline, 13.0, true)
	if is_player:
		var bag_center := feet + Vector2(86, -57)
		draw_rect(Rect2(bag_center - Vector2(23, 29), Vector2(46, 58)), Color("#b5954f"), false, 7.0)
		draw_arc(bag_center + Vector2(0, -28), 17.0, PI, TAU, 12, Color("#b5954f"), 6.0, true)
	else:
		draw_line(head + Vector2(-12, 3), head + Vector2(-3, 1), Color("#2b211b"), 3.0)

func _build_interface() -> void:
	header_label = _label("WALKA POD KIOSKIEM  •  ESC — WRÓĆ NA MAPĘ", 14, Color("#e9c477"))
	header_label.position = Vector2(24, 15)
	header_label.size = Vector2(620, 26)
	add_child(header_label)

	var enemy_card := _status_card("OSIEDLOWY ZADYMIARZ", Vector2(55, 55), Vector2(390, 128), false)
	enemy_name_label = enemy_card.name_label
	enemy_health_bar = enemy_card.bar
	enemy_health_label = enemy_card.health
	enemy_state_label = enemy_card.state
	var player_card := _status_card("ZBIERACZ", Vector2(785, 285), Vector2(440, 135), true)
	player_health_bar = player_card.bar
	player_health_label = player_card.health
	player_state_label = player_card.state

	var bottom_panel := PanelContainer.new()
	bottom_panel.name = "PanelRuchow"
	bottom_panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_panel.offset_left = 20
	bottom_panel.offset_right = -20
	bottom_panel.offset_top = -265
	bottom_panel.offset_bottom = -18
	bottom_panel.add_theme_stylebox_override("panel", _panel_style(Color("#20231f"), Color("#aaa087"), 3))
	add_child(bottom_panel)

	var main_row := HBoxContainer.new()
	main_row.add_theme_constant_override("separation", 14)
	bottom_panel.add_child(main_row)
	var left_box := VBoxContainer.new()
	left_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left_box.add_theme_constant_override("separation", 10)
	main_row.add_child(left_box)
	combat_log = _label("", 15, Color("#eee6d7"))
	combat_log.name = "DziennikWalki"
	combat_log.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	combat_log.custom_minimum_size = Vector2(0, 62)
	left_box.add_child(combat_log)
	moves_grid = GridContainer.new()
	moves_grid.name = "Ruchy"
	moves_grid.columns = 2
	moves_grid.add_theme_constant_override("h_separation", 9)
	moves_grid.add_theme_constant_override("v_separation", 9)
	left_box.add_child(moves_grid)
	_add_move("quick", "SZYBKI CIOS")
	_add_move("heavy", "SILNY ATAK")
	_add_move("guard", "GARDA")
	_add_move("sidestep", "SKACZ NA BOKI")

	var details := VBoxContainer.new()
	details.name = "SzczegolyRuchu"
	details.custom_minimum_size = Vector2(350, 0)
	details.add_theme_constant_override("separation", 10)
	main_row.add_child(details)
	round_label = _label("TURA 1", 13, Color("#b9d18e"))
	round_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	details.add_child(round_label)
	action_name_label = _label("SZYBKI CIOS", 21, Color("#efb647"))
	details.add_child(action_name_label)
	action_detail_label = _label("", 13, Color("#d6d0c2"))
	action_detail_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	action_detail_label.custom_minimum_size.y = 105
	details.add_child(action_detail_label)
	details.add_child(_label("Kliknij wroga — atak  •  Enter — wybrany ruch", 11, Color("#aaa79e")))

	result_box = VBoxContainer.new()
	result_box.name = "WynikWalki"
	result_box.visible = false
	result_box.add_theme_constant_override("separation", 8)
	left_box.add_child(result_box)
	var restart := _button("REWANŻ")
	restart.name = "Rewanz"
	restart.pressed.connect(start_fight)
	result_box.add_child(restart)
	var exit := _button("WRÓĆ NA MAPĘ")
	exit.name = "PowrotNaMape"
	exit.pressed.connect(func() -> void: exit_requested.emit(rules.result))
	result_box.add_child(exit)

func _status_card(title: String, position: Vector2, size: Vector2, is_player: bool) -> Dictionary:
	var panel := PanelContainer.new()
	panel.position = position
	panel.size = size
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#e4ddc8"), Color("#302d26"), 3))
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var name_label := _label(title, 17, Color("#28251f"))
	box.add_child(name_label)
	var state := _label("GOTOWY" if is_player else "CZUJNY", 11, Color("#76562d"))
	box.add_child(state)
	var bar := ProgressBar.new()
	bar.name = "ZdrowieBohatera" if is_player else "ZdrowiePrzeciwnika"
	bar.max_value = CombatRulesScript.PLAYER_MAX_HEALTH if is_player else CombatRulesScript.ENEMY_MAX_HEALTH
	bar.show_percentage = false
	bar.custom_minimum_size.y = 18
	bar.add_theme_stylebox_override("background", _panel_style(Color("#6b6558"), Color.TRANSPARENT, 0))
	bar.add_theme_stylebox_override("fill", _panel_style(Color("#4a9b5c"), Color.TRANSPARENT, 0))
	box.add_child(bar)
	var health := _label("", 12, Color("#28251f"))
	health.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(health)
	return {"bar": bar, "health": health, "state": state, "name_label": name_label}

func _add_move(action_id: String, text: String) -> void:
	var button := _button(text)
	button.name = "Ruch_" + action_id
	button.custom_minimum_size = Vector2(0, 58)
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	button.focus_entered.connect(_show_action_details.bind(action_id))
	button.mouse_entered.connect(_show_action_details.bind(action_id))
	button.pressed.connect(_choose_action.bind(action_id))
	moves_grid.add_child(button)
	move_buttons[action_id] = button

func _show_action_details(action_id: String) -> void:
	match action_id:
		"quick":
			action_name_label.text = "SZYBKI CIOS"
			var quick_accuracy := mini(98, 92 + int(player_stats.agility) * 2)
			var quick_damage := int(player_stats.attack) + int(player_stats.get("strength", 0))
			action_detail_label.text = "Celność: %d%%\nAtak: %d  •  Zasięg: %d pola\nKliknij bezpośrednio w przeciwnika." % [quick_accuracy, quick_damage, int(player_stats.attack_range)]
		"heavy":
			action_name_label.text = "SILNY ATAK"
			var heavy_accuracy := mini(98, 78 + int(player_stats.agility))
			var heavy_bonus := int(player_stats.strength) * 2
			action_detail_label.text = "Celność: %d%%\nObrażenia: %d–%d\nPierwsza tura ładuje zamach; Siła daje podwójny bonus." % [heavy_accuracy, 14 + heavy_bonus, 17 + heavy_bonus]
		"guard":
			action_name_label.text = "GARDA"
			action_detail_label.text = "Redukcja: 60%\nDziała przed atakiem. Zatrzymanie ciężkiego ciosu daje przewagę."
		"sidestep":
			action_name_label.text = "SKACZ NA BOKI"
			var evade_chance := mini(80, 50 + int(player_stats.agility) * 5)
			action_detail_label.text = "Czas: 3 tury\nSzansa uniku: %d%%\nZwinność zwiększa szansę o 5%% za punkt." % evade_chance

func _choose_action(action_id: String) -> void:
	if busy or rules.finished:
		return
	busy = true
	_set_moves_enabled(false)
	var state: Dictionary = await _play_round(action_id)
	if not rules.finished and bool(state.heavy_charged):
		combat_log.text = "Trzymasz zamach. %s widzi, że za chwilę uderzysz..." % enemy_name.capitalize()
		await get_tree().create_timer(0.7).timeout
		state = await _play_round("heavy")
	busy = false
	if rules.finished:
		_show_result()
	else:
		_set_moves_enabled(true)
		_focus_first_move()

func _play_round(action_id: String) -> Dictionary:
	var state: Dictionary = rules.resolve_round(action_id)
	for event in state.events:
		await _animate_event(event)
	_update_interface(state)
	return state

func _animate_event(event: Dictionary) -> void:
	combat_log.text = String(event.message)
	var kind := String(event.kind)
	var actor := String(event.actor)
	match kind:
		"attack":
			await _animate_lunge(actor)
			if actor == "player":
				await _animate_health_bar(enemy_health_bar, int(event.enemy_health))
				_flash_status(enemy_health_bar)
			else:
				await _animate_health_bar(player_health_bar, int(event.player_health))
				_flash_status(player_health_bar)
		"miss":
			await _animate_lunge(actor)
		"evade":
			await _animate_lunge("enemy")
			await _animate_sidestep()
		"charge":
			await _animate_charge()
		"guard":
			await _animate_guard(actor)
		"sidestep":
			await _animate_sidestep()
		"result":
			await get_tree().create_timer(0.35).timeout
	await get_tree().create_timer(0.28).timeout

func _animate_lunge(actor: String) -> void:
	var property := "player_motion_offset" if actor == "player" else "enemy_motion_offset"
	var forward := Vector2(58, -3) if actor == "player" else Vector2(-58, 3)
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(self, property, forward, 0.15)
	tween.tween_property(self, property, Vector2.ZERO, 0.19)
	await tween.finished

func _animate_charge() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "player_motion_offset", Vector2(-18, -7), 0.24)
	tween.tween_property(self, "player_motion_offset", Vector2(-10, 0), 0.24)
	await tween.finished

func _animate_guard(actor: String) -> void:
	var property := "player_motion_offset" if actor == "player" else "enemy_motion_offset"
	var tween := create_tween()
	tween.tween_property(self, property, Vector2(0, -9), 0.14)
	tween.tween_property(self, property, Vector2.ZERO, 0.2)
	await tween.finished

func _animate_sidestep() -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.tween_property(self, "player_motion_offset", Vector2(-42, 0), 0.16)
	tween.tween_property(self, "player_motion_offset", Vector2(42, 0), 0.22)
	tween.tween_property(self, "player_motion_offset", Vector2.ZERO, 0.16)
	await tween.finished

func _animate_health_bar(bar: ProgressBar, target_value: int) -> void:
	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(bar, "value", float(target_value), 0.46)
	await tween.finished
	if bar == player_health_bar:
		player_health_label.text = "%d / %d ŻYCIA" % [target_value, rules.player_max_health]
	else:
		enemy_health_label.text = "%d / %d ŻYCIA" % [target_value, rules.enemy_max_health]

func _update_interface(state: Dictionary) -> void:
	player_health_bar.max_value = int(state.player_max_health)
	enemy_health_bar.max_value = int(state.enemy_max_health)
	player_health_bar.value = int(state.player_health)
	enemy_health_bar.value = int(state.enemy_health)
	player_health_label.text = "%d / %d ŻYCIA" % [state.player_health, state.player_max_health]
	enemy_health_label.text = "%d / %d ŻYCIA" % [state.enemy_health, state.enemy_max_health]
	player_state_label.text = String(state.player_state)
	enemy_state_label.text = String(state.enemy_state)
	round_label.text = "TURA %d" % int(state.round)
	player_health_changed.emit(int(state.player_health), int(state.player_max_health))

func _show_result() -> void:
	_set_moves_enabled(false)
	moves_grid.visible = false
	result_box.visible = true
	action_name_label.text = "ZWYCIĘSTWO" if rules.result == "victory" else "PORAŻKA"
	action_detail_label.text = "Prototyp kończy starcie bez trwałych konsekwencji. Możesz od razu rozegrać rewanż."
	combat_resolved.emit(rules.result)
	(result_box.get_child(0) as Button).grab_focus()

func _set_moves_enabled(enabled: bool) -> void:
	for button in move_buttons.values():
		(button as Button).disabled = not enabled

func _focus_first_move() -> void:
	if visible and moves_grid.visible:
		(move_buttons["quick"] as Button).grab_focus()

func _flash_status(bar: ProgressBar) -> void:
	var card := bar.get_parent().get_parent() as Control
	var tween := create_tween()
	tween.tween_property(card, "modulate", Color("#ff8b75"), 0.08)
	tween.tween_property(card, "modulate", Color.WHITE, 0.16)

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.add_theme_font_size_override("font_size", 15)
	button.add_theme_color_override("font_color", Color("#eee6d7"))
	button.add_theme_color_override("font_hover_color", Color("#fff2c5"))
	button.add_theme_color_override("font_focus_color", Color("#fff2c5"))
	button.add_theme_stylebox_override("normal", _panel_style(Color("#343832"), Color("#696a5c"), 2))
	button.add_theme_stylebox_override("hover", _panel_style(Color("#4a4d40"), Color("#c7a85e"), 2))
	button.add_theme_stylebox_override("pressed", _panel_style(Color("#6a5530"), Color("#efc870"), 3))
	button.add_theme_stylebox_override("focus", _panel_style(Color("#4a4d40"), Color("#f1cf78"), 3))
	return button

func _panel_style(background: Color, border: Color, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.corner_radius_top_left = 3
	style.corner_radius_top_right = 3
	style.corner_radius_bottom_left = 3
	style.corner_radius_bottom_right = 3
	style.content_margin_left = 14
	style.content_margin_right = 14
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	return style
