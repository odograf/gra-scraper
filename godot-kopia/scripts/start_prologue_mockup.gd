extends Node2D

const PlayerScript := preload("res://scripts/player.gd")
const PlayerStateScript := preload("res://scripts/player_state.gd")
const StarterBagScript := preload("res://scripts/starter_bag.gd")
const PickupCanScript := preload("res://scripts/pickup_can.gd")
const WildDogEnemyScript := preload("res://scripts/wild_dog_enemy.gd")
const SewerRatEnemyScript := preload("res://scripts/sewer_rat_enemy.gd")
const PrologueState := preload("res://scripts/prologue_mockup_state.gd")

const GRASS_TEXTURE := preload("res://assets/terrain/grass_base_v1.png")
const ASPHALT_TEXTURE := preload("res://assets/terrain/asphalt_base_v1.png")
const SIDEWALK_TEXTURE := preload("res://assets/terrain/sidewalk_base_v1.png")
const BINS_TEXTURE := preload("res://assets/props/trash_bins.png")
const CAN_CRATE_TEXTURE := preload("res://assets/props/crate_cans_v1.png")
const SCRAP_CRATE_TEXTURE := preload("res://assets/props/crate_scrap_v1.png")
const FENCE_TEXTURE := preload("res://assets/props/fence_segments_v1.png")

const WORLD_SIZE := Vector2(2600, 1500)
const TILE_SIZE := 64.0
const MELINA_RECT := Rect2(192, 576, TILE_SIZE * 3.0, TILE_SIZE * 9.0)
const EXIT_POSITION := Vector2(288, 570)
const OUTSIDE_SPAWN := Vector2(1010, 940)
const OUTSIDE_SCENE := "res://scenes/start_suburb_mockup.tscn"
const MELINA_SCENE := "res://scenes/melina_prologue_mockup.tscn"
const MAIN_SCENE := "res://scenes/main.tscn"
const NORTH_GATE_CENTER := 1360.0
const NORTH_GATE_HALF_WIDTH := 180.0
const HUD_CAMERA_BOTTOM_CLEARANCE_PX := 62.0

enum Stage { INTRO_DIALOGUE, TAKE_BAG, BAG_DIALOGUE, COLLECT_CANS, CANS_DIALOGUE, EXIT_MELINA, OUTSIDE }
enum Location { MELINA, SUBURB }

@export var location_mode := Location.MELINA

var stage := Stage.INTRO_DIALOGUE
var player: Player
var player_state: PlayerState
var starter_bag: StarterBag
var active_cans: Array[PickupCan] = []
var enemies: Array[RealtimeEnemy] = []
var cans_collected := 0
var transition_in_progress := false

var dialogue_overlay: Control
var dialogue_label: Label
var dialogue_counter: Label
var dialogue_pages: Array[String] = []
var dialogue_page := 0
var dialogue_finished := Callable()
var phase_label: Label
var status_label: Label
var hint_label: Label
var health_label: Label
var health_bar: ProgressBar
var weapon_overlay: Control
var weapon_box: VBoxContainer
var weapon_open := false

func _ready() -> void:
	_create_static_geometry()
	_create_player()
	if location_mode == Location.MELINA:
		PrologueState.begin_new_run()
		_create_tutorial_objects()
	else:
		PrologueState.prepare_outside_preview()
		cans_collected = PrologueState.cans_collected
		stage = Stage.OUTSIDE
		_create_environment_assets()
		_create_enemies()
	_create_ui()
	_update_ui()
	if location_mode == Location.MELINA:
		_show_intro_dialogue()
	else:
		dialogue_overlay.visible = false
		_set_hint("Samotny pies jest najbliżej. I — wybór broni torbowej.")
	queue_redraw()

func _physics_process(_delta: float) -> void:
	if location_mode != Location.SUBURB or player == null or not is_instance_valid(player):
		return
	if player.global_position.y <= 42.0 and absf(player.global_position.x - NORTH_GATE_CENTER) <= NORTH_GATE_HALF_WIDTH:
		_try_enter_main_map()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if weapon_open:
			_close_weapon_inventory()
		elif PrologueState.has_bag:
			_open_weapon_inventory()
		else:
			_set_hint("Najpierw podnieś siateczkę.")
		get_viewport().set_input_as_handled()
		return
	if weapon_open:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_ESCAPE:
			_close_weapon_inventory()
			get_viewport().set_input_as_handled()
		return
	if dialogue_overlay != null and dialogue_overlay.visible:
		return
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_RIGHT and stage == Stage.OUTSIDE:
			if player.start_spin_attack():
				get_viewport().set_input_as_handled()
			return
		if event.button_index == MOUSE_BUTTON_LEFT:
			var world_position := get_global_mouse_position()
			var enemy := _enemy_at(world_position)
			if stage == Stage.OUTSIDE and enemy != null:
				if not player.is_action_busy() and player.request_target_attack(enemy):
					get_viewport().set_input_as_handled()
				return
			if stage == Stage.EXIT_MELINA and world_position.distance_to(EXIT_POSITION) <= 60.0:
				_handle_exit_click()
				return
			if not _click_hits_pickup(world_position):
				player.set_move_target(world_position)
				get_viewport().set_input_as_handled()
			return
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.keycode == KEY_ENTER:
		_try_nearby_interaction()
	elif event.keycode == KEY_F1:
		get_tree().change_scene_to_file(MAIN_SCENE)
	elif event.keycode == KEY_F2:
		get_tree().change_scene_to_file(MELINA_SCENE)

func _draw() -> void:
	if location_mode == Location.MELINA:
		_draw_melina()
	else:
		_draw_outdoor_ground()
		_draw_outdoor_buildings()
	_draw_route_markers()

func _draw_outdoor_ground() -> void:
	draw_rect(Rect2(Vector2.ZERO, WORLD_SIZE), Color("#676950"))
	_draw_tiled_texture(GRASS_TEXTURE, Rect2(700, 0, 1900, 1500), Color("#a3a287"))
	_draw_tiled_texture(ASPHALT_TEXTURE, Rect2(1180, 0, 360, 1500), Color("#c2c0b6"))
	_draw_tiled_texture(SIDEWALK_TEXTURE, Rect2(1090, 0, 90, 1500), Color.WHITE)
	_draw_tiled_texture(SIDEWALK_TEXTURE, Rect2(1540, 0, 90, 1500), Color.WHITE)
	for y in range(30, 1500, 128):
		draw_rect(Rect2(1354, y, 12, 64), Color("#d2b76d"))

func _draw_melina() -> void:
	# Dokładnie trzy kratki szerokości między bryłami budynków.
	draw_rect(Rect2(0, 420, 192, 940), Color("#292d29"))
	draw_rect(Rect2(384, 420, 300, 940), Color("#2e312c"))
	for y in range(int(MELINA_RECT.position.y), int(MELINA_RECT.end.y), int(TILE_SIZE)):
		for x in range(int(MELINA_RECT.position.x), int(MELINA_RECT.end.x), int(TILE_SIZE)):
			var tile_index := int((x + y) / TILE_SIZE)
			var shade := Color("#56534a") if tile_index % 2 == 0 else Color("#5d594e")
			draw_rect(Rect2(x, y, TILE_SIZE, TILE_SIZE), shade)
			draw_line(Vector2(x, y + TILE_SIZE), Vector2(x + TILE_SIZE, y + TILE_SIZE), Color("#403f39"), 1.0)
	draw_rect(Rect2(192, 548, 56, 28), Color("#343630"))
	draw_rect(Rect2(328, 548, 56, 28), Color("#343630"))
	draw_rect(Rect2(248, 548, 80, 28), Color("#6d4a39") if stage < Stage.EXIT_MELINA else Color("#967049"))
	draw_line(Vector2(248, 576), Vector2(328, 576), Color("#c6b17d"), 4.0)
	draw_rect(Rect2(210, 1180, 156, 90), Color("#373832"))
	draw_rect(Rect2(220, 1190, 136, 65), Color("#766d58"))
	draw_string(ThemeDB.fallback_font, Vector2(205, 520), "MELINA STARTOWA  •  3 KRATKI", HORIZONTAL_ALIGNMENT_LEFT, -1, 15, Color("#d5c48c"))
	for mark in [Vector2(225, 680), Vector2(346, 750), Vector2(260, 920), Vector2(330, 1080)]:
		draw_line(mark, mark + Vector2(18, 7), Color("#343630"), 3.0)

func _draw_outdoor_buildings() -> void:
	# Placeholder rozwalonej szopy — docelowo zastąpi go osobny asset z listy.
	draw_rect(Rect2(780, 650, 360, 250), Color("#343832"))
	draw_colored_polygon(PackedVector2Array([Vector2(750, 680), Vector2(820, 610), Vector2(1090, 625), Vector2(1160, 680)]), Color("#51443a"))
	for x in range(800, 1130, 44):
		draw_line(Vector2(x, 690), Vector2(x - 18, 885), Color("#5c6258"), 4.0)
	draw_rect(Rect2(930, 760, 90, 140), Color("#171b19"))
	draw_string(ThemeDB.fallback_font, Vector2(818, 720), "ROZWALONA SZOPA", HORIZONTAL_ALIGNMENT_CENTER, 280, 18, Color("#d5c48c"))
	# Podmiejskie garaże i domy jako bryły zastępcze.
	for rect in [Rect2(1660, 120, 360, 220), Rect2(2070, 100, 420, 260), Rect2(1760, 1120, 500, 210)]:
		draw_rect(rect, Color("#55594f"))
		draw_rect(Rect2(rect.position + Vector2(18, rect.size.y - 90), Vector2(rect.size.x - 36, 90)), Color("#353c38"))
	draw_rect(Rect2(1880, 810, 420, 150), Color("#4e514a"))
	draw_circle(Vector2(2090, 935), 54, Color("#252b27"), false, 8.0)
	draw_string(ThemeDB.fallback_font, Vector2(1900, 995), "ODPŁYW / STADO SZCZURÓW", HORIZONTAL_ALIGNMENT_CENTER, 380, 16, Color("#d8c998"))

func _draw_route_markers() -> void:
	if location_mode == Location.MELINA and stage == Stage.EXIT_MELINA:
		draw_arc(EXIT_POSITION, 52, 0.0, TAU, 32, Color("#efb647"), 4.0)
		draw_string(ThemeDB.fallback_font, EXIT_POSITION + Vector2(-85, -72), "WYJŚCIE ODBLOKOWANE", HORIZONTAL_ALIGNMENT_CENTER, 170, 14, Color("#efb647"))
	if stage == Stage.OUTSIDE:
		draw_string(ThemeDB.fallback_font, Vector2(830, 560), "PRZEDMIEŚCIE — DROGA DO AUTOMATU", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color("#efe1b7"))
		draw_line(Vector2(NORTH_GATE_CENTER, 150), Vector2(NORTH_GATE_CENTER, 55), Color("#efb647"), 8.0)
		draw_colored_polygon(PackedVector2Array([
			Vector2(NORTH_GATE_CENTER, 38),
			Vector2(NORTH_GATE_CENTER - 24, 76),
			Vector2(NORTH_GATE_CENTER + 24, 76)
		]), Color("#efb647"))
		draw_string(ThemeDB.fallback_font, Vector2(NORTH_GATE_CENTER - 190, 185), "PÓŁNOC — OSIEDLE", HORIZONTAL_ALIGNMENT_CENTER, 380, 20, Color("#efcf77"))

func _draw_tiled_texture(texture: Texture2D, area: Rect2, tint: Color) -> void:
	var tile := Vector2(128, 128)
	for y in range(int(area.position.y), int(area.end.y), int(tile.y)):
		for x in range(int(area.position.x), int(area.end.x), int(tile.x)):
			draw_texture_rect(texture, Rect2(x, y, tile.x, tile.y), false, tint)

func _create_player() -> void:
	player_state = PlayerStateScript.new() as PlayerState
	player_state.name = "StanBohatera"
	add_child(player_state)
	player_state.health_changed.connect(_on_player_health_changed)
	player = PlayerScript.new() as Player
	player.name = "Bohater"
	player.position = Vector2(288, 1110) if location_mode == Location.MELINA else OUTSIDE_SPAWN
	player.z_index = 10
	player.player_state = player_state
	add_child(player)
	player.equip_bag_weapon(StringName(PrologueState.equipped_bag_weapon))
	if location_mode == Location.SUBURB and PrologueState.current_health >= 0:
		player_state.synchronize_health(PrologueState.current_health, PrologueState.maximum_health)
	var camera := Camera2D.new()
	camera.name = "Kamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 8.0
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WORLD_SIZE.x)
	camera.limit_bottom = int(WORLD_SIZE.y + HUD_CAMERA_BOTTOM_CLEARANCE_PX)
	player.add_child(camera)

func _create_tutorial_objects() -> void:
	starter_bag = StarterBagScript.new() as StarterBag
	starter_bag.name = "SiateczkaStartowa"
	starter_bag.position = Vector2(288, 1030)
	starter_bag.z_index = 9
	starter_bag.player = player
	starter_bag.picked_up.connect(_on_bag_picked)
	starter_bag.out_of_range.connect(func() -> void: _set_hint("Podejdź bliżej do siateczki."))
	add_child(starter_bag)
	var can_positions := [
		Vector2(230, 930), Vector2(345, 890), Vector2(245, 820),
		Vector2(335, 770), Vector2(235, 700), Vector2(340, 650)
	]
	for index in range(can_positions.size()):
		var can := PickupCanScript.new() as PickupCan
		can.name = "PuszkaSamouczek%d" % (index + 1)
		can.position = can_positions[index]
		can.rotation = float(index % 3 - 1) * 0.28
		can.z_index = 8
		can.player = player
		can.can_accept_callback = func() -> bool: return stage == Stage.COLLECT_CANS
		can.collected.connect(_on_can_collected.bind(can))
		can.inventory_full.connect(func() -> void: _set_hint("Najpierw podnieś siateczkę."))
		can.out_of_range.connect(func() -> void: _set_hint("Podejdź bliżej do puszki."))
		add_child(can)
		active_cans.append(can)

func _create_enemies() -> void:
	_create_dog("PiesPrzySzopie", Vector2(1190, 810))
	_create_dog("WatahaPies1", Vector2(1700, 550))
	_create_dog("WatahaPies2", Vector2(1815, 620))
	for index in range(4):
		_create_rat("Szczor%d" % (index + 1), Vector2(1990 + (index % 2) * 105, 850 + (index / 2) * 95))

func _create_dog(node_name: String, enemy_position: Vector2) -> void:
	var dog := WildDogEnemyScript.new() as WildDogEnemy
	dog.name = node_name
	dog.position = enemy_position
	dog.z_index = 8
	dog.player = player
	dog.active = true
	dog.attack_landed.connect(_on_enemy_attack)
	dog.defeated.connect(_on_enemy_defeated.bind(dog))
	add_child(dog)
	enemies.append(dog)

func _create_rat(node_name: String, enemy_position: Vector2) -> void:
	var rat := SewerRatEnemyScript.new() as SewerRatEnemy
	rat.name = node_name
	rat.position = enemy_position
	rat.z_index = 8
	rat.player = player
	rat.active = true
	rat.attack_landed.connect(_on_enemy_attack)
	rat.defeated.connect(_on_enemy_defeated.bind(rat))
	add_child(rat)
	enemies.append(rat)

func _create_environment_assets() -> void:
	_add_sprite("KoszePrzyDrodze", BINS_TEXTURE, Vector2(1580, 920), 0.18, 4)
	_add_sprite("SkrzynkaPuszek", CAN_CRATE_TEXTURE, Vector2(1080, 1070), 0.16, 4)
	_add_sprite("SkrzynkaZlomu", SCRAP_CRATE_TEXTURE, Vector2(2330, 1080), 0.16, 4)
	var fence_frame := AtlasTexture.new()
	fence_frame.atlas = FENCE_TEXTURE
	fence_frame.region = Rect2(0, 0, 724, 724)
	for x in range(720, 1100, 120):
		_add_sprite("Plot%d" % x, fence_frame, Vector2(x, 1170), 0.18, 3)

func _add_sprite(node_name: String, texture: Texture2D, sprite_position: Vector2, sprite_scale: float, sprite_z: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = sprite_position
	sprite.scale = Vector2.ONE * sprite_scale
	sprite.z_index = sprite_z
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)

func _create_static_geometry() -> void:
	if location_mode == Location.SUBURB:
		var gate_left := NORTH_GATE_CENTER - NORTH_GATE_HALF_WIDTH
		var gate_right := NORTH_GATE_CENTER + NORTH_GATE_HALF_WIDTH
		_add_static_rect(Rect2(-30, -30, gate_left + 30, 40), "GranicaGoraLewa")
		_add_static_rect(Rect2(gate_right, -30, WORLD_SIZE.x - gate_right + 30, 40), "GranicaGoraPrawa")
	else:
		_add_static_rect(Rect2(-30, -30, WORLD_SIZE.x + 60, 40), "GranicaGora")
	_add_static_rect(Rect2(-30, WORLD_SIZE.y - 10, WORLD_SIZE.x + 60, 40), "GranicaDol")
	_add_static_rect(Rect2(-30, 0, 40, WORLD_SIZE.y), "GranicaLewa")
	_add_static_rect(Rect2(WORLD_SIZE.x - 10, 0, 40, WORLD_SIZE.y), "GranicaPrawa")
	if location_mode == Location.MELINA:
		_add_static_rect(Rect2(176, 548, 16, 812), "ScianaMelinyLewa")
		_add_static_rect(Rect2(384, 548, 16, 812), "ScianaMelinyPrawa")
		_add_static_rect(Rect2(192, 1344, 192, 16), "ScianaMelinyDol")
		_add_static_rect(Rect2(192, 548, 56, 28), "ScianaNadDrzwiamiLewa")
		_add_static_rect(Rect2(328, 548, 56, 28), "ScianaNadDrzwiamiPrawa")
		_add_static_rect(Rect2(248, 548, 80, 28), "DrzwiMeliny")
	else:
		_add_static_rect(Rect2(780, 650, 150, 250), "SzopaLewa")
		_add_static_rect(Rect2(1020, 650, 120, 250), "SzopaPrawa")
		_add_static_rect(Rect2(1660, 120, 360, 220), "GarazePolnoc")
		_add_static_rect(Rect2(2070, 100, 420, 260), "DomyPolnoc")
		_add_static_rect(Rect2(1760, 1120, 500, 210), "GarazeDol")

func _add_static_rect(rect: Rect2, node_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	body.collision_layer = 1
	body.collision_mask = 0
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "InterfejsMockupu"
	canvas.layer = 20
	add_child(canvas)
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(20, 18)
	top_panel.custom_minimum_size = Vector2(560, 116)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color("#171b19e8"), Color("#5d6659")))
	canvas.add_child(top_panel)
	var top_box := VBoxContainer.new()
	top_box.add_theme_constant_override("separation", 4)
	top_panel.add_child(top_box)
	phase_label = _label("", 18, Color("#efb647"))
	status_label = _label("", 14, Color("#eee6d7"))
	hint_label = _label("", 12, Color("#b9d18e"))
	top_box.add_child(phase_label)
	top_box.add_child(status_label)
	top_box.add_child(hint_label)
	_create_health_hud(canvas)
	_create_dialogue_ui(canvas)
	_create_weapon_inventory_ui(canvas)

func _create_weapon_inventory_ui(canvas: CanvasLayer) -> void:
	weapon_overlay = Control.new()
	weapon_overlay.name = "WyborBroniTorbowej"
	weapon_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	weapon_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	weapon_overlay.visible = false
	canvas.add_child(weapon_overlay)
	var shade := ColorRect.new()
	shade.color = Color("#0709069c")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	weapon_overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-270, -190)
	panel.custom_minimum_size = Vector2(540, 380)
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#151914fa"), Color("#c8a85e"), 3))
	weapon_overlay.add_child(panel)
	weapon_box = VBoxContainer.new()
	weapon_box.add_theme_constant_override("separation", 12)
	panel.add_child(weapon_box)
	_rebuild_weapon_inventory()

func _rebuild_weapon_inventory() -> void:
	if weapon_box == null:
		return
	for child in weapon_box.get_children():
		weapon_box.remove_child(child)
		child.queue_free()
	var title := _label("BROŃ TORBOWA", 25, Color("#efb647"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_box.add_child(title)
	var description := _label("Pojemnik na łupy i broń są osobnym wyposażeniem.\nZmiana torby nie zmienia animacji ciała bohatera.", 14, Color("#ddd5c4"))
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	weapon_box.add_child(description)
	_add_weapon_choice(&"plastic_bag", "REKLAMÓWKA")
	_add_weapon_choice(&"black_sack", "CZARNY WOREK")
	var close := _weapon_button("ZAMKNIJ — I / ESC")
	close.pressed.connect(_close_weapon_inventory)
	weapon_box.add_child(close)

func _add_weapon_choice(weapon_id: StringName, display_name: String) -> void:
	var equipped := PrologueState.equipped_bag_weapon == String(weapon_id)
	var prefix := "[W DŁONI] " if equipped else "WEŹ "
	var button := _weapon_button(prefix + display_name)
	button.disabled = equipped
	button.pressed.connect(func() -> void: _equip_prologue_weapon(weapon_id))
	weapon_box.add_child(button)

func _weapon_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(480, 48)
	button.add_theme_font_size_override("font_size", 16)
	return button

func _open_weapon_inventory() -> void:
	weapon_open = true
	player.cancel_move_target()
	player.set_physics_process(false)
	_rebuild_weapon_inventory()
	weapon_overlay.visible = true

func _close_weapon_inventory() -> void:
	weapon_open = false
	weapon_overlay.visible = false
	if dialogue_overlay == null or not dialogue_overlay.visible:
		player.set_physics_process(player_state.current_health > 0)

func _equip_prologue_weapon(weapon_id: StringName) -> void:
	if player.equip_bag_weapon(weapon_id):
		PrologueState.equipped_bag_weapon = String(weapon_id)
		_set_hint("Broń w dłoni: %s." % player.equipped_bag_weapon_name())
	_rebuild_weapon_inventory()

func _create_health_hud(canvas: CanvasLayer) -> void:
	var panel := PanelContainer.new()
	panel.name = "DolnyHUDPrologu"
	panel.anchor_left = 0.33
	panel.anchor_right = 0.67
	panel.anchor_top = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_top = -58
	panel.offset_bottom = -14
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _compact_panel_style(Color("#151814f2"), Color("#77745f")))
	canvas.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 3)
	panel.add_child(box)
	health_label = _label("ŻYCIE: 100/100", 11, Color("#f0d5cb"))
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(health_label)
	health_bar = ProgressBar.new()
	health_bar.name = "ZdrowieBohateraHUD"
	health_bar.min_value = 0.0
	health_bar.max_value = 100.0
	health_bar.show_percentage = false
	health_bar.custom_minimum_size.y = 13
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#090b09ed")
	background.border_color = Color("#56584d")
	background.set_border_width_all(1)
	background.set_corner_radius_all(3)
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color("#a83d35")
	fill.set_corner_radius_all(2)
	health_bar.add_theme_stylebox_override("background", background)
	health_bar.add_theme_stylebox_override("fill", fill)
	box.add_child(health_bar)

func _create_dialogue_ui(canvas: CanvasLayer) -> void:
	dialogue_overlay = Control.new()
	dialogue_overlay.name = "DialogKlikany"
	dialogue_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dialogue_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dialogue_overlay.visible = false
	dialogue_overlay.gui_input.connect(_on_dialogue_input)
	canvas.add_child(dialogue_overlay)
	var shade := ColorRect.new()
	shade.color = Color("#0709064d")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	dialogue_overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 54
	panel.offset_right = -54
	panel.offset_top = -245
	panel.offset_bottom = -32
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#101722f4"), Color("#d7c38d"), 4))
	dialogue_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(box)
	var speaker := _label("MŁODY", 19, Color("#efb647"))
	speaker.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(speaker)
	dialogue_label = _label("", 22, Color("#f0eadc"))
	dialogue_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialogue_label.custom_minimum_size = Vector2(1080, 100)
	dialogue_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	dialogue_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(dialogue_label)
	dialogue_counter = _label("", 12, Color("#aeb9c7"))
	dialogue_counter.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue_counter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(dialogue_counter)

func _show_intro_dialogue() -> void:
	stage = Stage.INTRO_DIALOGUE
	_show_dialogue([
		"Ale mam kaca. No nic, pora go wyleczyć.",
		"Problem jest taki, że nie ma za co.",
		"Wezmę siateczkę i idę po puszki."
	], _begin_bag_step)

func _begin_bag_step() -> void:
	stage = Stage.TAKE_BAG
	player.set_physics_process(true)
	_set_hint("Podejdź do reklamówki i kliknij ją albo naciśnij Enter.")
	_update_ui()

func _on_bag_picked() -> void:
	stage = Stage.BAG_DIALOGUE
	starter_bag = null
	PrologueState.has_bag = true
	_show_dialogue([
		"Jest i siateczka. Nie tylko bagaż, ale i broń prawdziwego mężczyzny.",
		"Zbiorę kilka puszek w melinie. Jestem jak perpetuum mobile."
	], _begin_can_step)

func _begin_can_step() -> void:
	stage = Stage.COLLECT_CANS
	player.set_physics_process(true)
	_set_hint("Zbierz wszystkie sześć puszek w melinie. I — wybór broni.")
	_update_ui()

func _on_can_collected(can: PickupCan) -> void:
	if stage != Stage.COLLECT_CANS:
		return
	active_cans.erase(can)
	_register_mock_can()

func _register_mock_can() -> void:
	cans_collected = mini(6, cans_collected + 1)
	PrologueState.cans_collected = cans_collected
	_update_ui()
	if cans_collected >= 6:
		stage = Stage.CANS_DIALOGUE
		_show_dialogue([
			"Pora iść do automatu i zarobić nieco grosza.",
			"Ciekawe, czy te wygłodniałe psy nadal kręcą się na zewnątrz."
		], _unlock_exit)

func _unlock_exit() -> void:
	stage = Stage.EXIT_MELINA
	player.set_physics_process(true)
	_set_hint("Podejdź do drzwi i kliknij przejście albo naciśnij Enter.")
	_update_ui()
	queue_redraw()

func _try_exit_melina() -> bool:
	if stage != Stage.EXIT_MELINA:
		_set_hint("Najpierw zbierz wszystkie puszki.")
		return false
	if player.global_position.distance_to(EXIT_POSITION) > 150.0:
		_set_hint("Podejdź bliżej do drzwi.")
		return false
	player.cancel_move_target()
	PrologueState.has_bag = true
	PrologueState.cans_collected = cans_collected
	PrologueState.capture_health(player_state.current_health, player_state.maximum_health)
	var error := get_tree().change_scene_to_file(OUTSIDE_SCENE)
	if error != OK:
		_set_hint("Nie udało się wczytać przedmieścia.")
		return false
	return true

func _handle_exit_click() -> bool:
	# change_scene_to_file() może natychmiast odłączyć starą scenę od viewportu.
	# Dlatego kliknięcie oznaczamy jako obsłużone przed rozpoczęciem przejścia.
	var viewport := get_viewport()
	if viewport != null:
		viewport.set_input_as_handled()
	return _try_exit_melina()

func _try_enter_main_map() -> bool:
	if location_mode != Location.SUBURB or transition_in_progress:
		return false
	transition_in_progress = true
	player.cancel_move_target()
	PrologueState.has_bag = true
	PrologueState.cans_collected = maxi(6, cans_collected)
	PrologueState.prepare_main_entry(player_state.current_health, player_state.maximum_health)
	var error := get_tree().change_scene_to_file(MAIN_SCENE)
	if error != OK:
		transition_in_progress = false
		PrologueState.main_entry_pending = false
		_set_hint("Nie udało się wczytać osiedla na północy.")
		return false
	return true

func _try_nearby_interaction() -> void:
	if stage == Stage.TAKE_BAG and starter_bag != null and is_instance_valid(starter_bag):
		starter_bag.try_collect()
		return
	if stage == Stage.COLLECT_CANS:
		var nearest: PickupCan
		var nearest_distance := INF
		for can in active_cans:
			if not is_instance_valid(can):
				continue
			var distance := player.global_position.distance_to(can.global_position)
			if distance < nearest_distance:
				nearest = can
				nearest_distance = distance
		if nearest != null:
			nearest.try_collect()
		return
	if stage == Stage.EXIT_MELINA:
		_try_exit_melina()

func _show_dialogue(pages: Array[String], finished: Callable) -> void:
	dialogue_pages = pages
	dialogue_page = 0
	dialogue_finished = finished
	dialogue_overlay.visible = true
	player.cancel_move_target()
	player.set_physics_process(false)
	_refresh_dialogue_page()
	_update_ui()

func _on_dialogue_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_advance_dialogue()
		get_viewport().set_input_as_handled()

func _advance_dialogue() -> void:
	if not dialogue_overlay.visible:
		return
	dialogue_page += 1
	if dialogue_page < dialogue_pages.size():
		_refresh_dialogue_page()
		return
	dialogue_overlay.visible = false
	var finished := dialogue_finished
	dialogue_finished = Callable()
	if finished.is_valid():
		finished.call()

func _refresh_dialogue_page() -> void:
	dialogue_label.text = dialogue_pages[dialogue_page]
	dialogue_counter.text = "LEWY KLIK — DALEJ     %d/%d" % [dialogue_page + 1, dialogue_pages.size()]

func _enemy_at(world_position: Vector2) -> RealtimeEnemy:
	var nearest: RealtimeEnemy
	var nearest_distance := 82.0
	for enemy in enemies:
		if not is_instance_valid(enemy) or enemy.dead:
			continue
		var distance := world_position.distance_to(enemy.global_position)
		if distance < nearest_distance:
			nearest = enemy
			nearest_distance = distance
	return nearest

func _click_hits_pickup(world_position: Vector2) -> bool:
	if starter_bag != null and is_instance_valid(starter_bag) and world_position.distance_to(starter_bag.global_position) <= 42.0:
		return true
	for can in active_cans:
		if is_instance_valid(can) and world_position.distance_to(can.global_position) <= 36.0:
			return true
	return false

func _on_enemy_attack(damage: int) -> void:
	player_state.apply_damage(damage)
	_update_ui()
	if player_state.current_health <= 0:
		player.set_physics_process(false)
		for enemy in enemies:
			if is_instance_valid(enemy):
				enemy.active = false
		_set_hint("Bohater został powalony — to mockup rozmieszczenia zagrożeń.")

func _on_enemy_defeated(enemy: RealtimeEnemy) -> void:
	enemies.erase(enemy)
	_set_hint("Zagrożenie pokonane. Możesz badać dalszą część przedmieścia.")

func _on_player_health_changed(_current: int, _maximum: int) -> void:
	_update_ui()

func _update_ui() -> void:
	if phase_label == null:
		return
	var phase_texts := [
		"PROLOG-00 — POBUDKA", "PROLOG-00 — PODNIEŚ SIATECZKĘ", "PROLOG-00 — SIATECZKA",
		"PROLOG-00 — ZBIERZ 6 PUSZEK", "PROLOG-00 — WYJŚCIE", "PROLOG-00 — DRZWI", "PRZEDMIEŚCIE"
	]
	phase_label.text = phase_texts[stage]
	status_label.text = "PUSZKI: %d/6  •  BROŃ: %s" % [cans_collected, player.equipped_bag_weapon_name().to_upper()]
	if health_label != null and health_bar != null:
		health_label.text = "ŻYCIE: %d/%d" % [player_state.current_health, player_state.maximum_health]
		health_bar.max_value = player_state.maximum_health
		health_bar.value = player_state.current_health

func _set_hint(text: String) -> void:
	if hint_label != null:
		hint_label.text = text

func _panel_style(background: Color, border: Color, width := 2) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = background
	style.border_color = border
	style.set_border_width_all(width)
	style.set_content_margin_all(14)
	style.shadow_color = Color("#05070588")
	style.shadow_size = 8
	return style

func _compact_panel_style(background: Color, border: Color) -> StyleBoxFlat:
	var style := _panel_style(background, border)
	style.set_content_margin_all(6)
	style.shadow_size = 5
	return style

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label
