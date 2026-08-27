extends Node2D

const WorldMapScript := preload("res://scripts/world_map.gd")
const PlayerScript := preload("res://scripts/player.gd")
const PickupCanScript := preload("res://scripts/pickup_can.gd")
const CanMachineScript := preload("res://scripts/can_machine.gd")
const ShopDoorScript := preload("res://scripts/shop_door.gd")
const KioskCounterScript := preload("res://scripts/kiosk_counter.gd")
const MirekNPCScript := preload("res://scripts/mirek_npc.gd")
const ScrapFenceScript := preload("res://scripts/scrap_fence.gd")
const TrashSearchScript := preload("res://scripts/trash_search.gd")
const PlayerInventoryScript := preload("res://scripts/player_inventory.gd")
const StarterBagScript := preload("res://scripts/starter_bag.gd")
const CombatPrototypeScript := preload("res://scripts/combat_prototype.gd")
const CombatEnemyScript := preload("res://scripts/combat_enemy.gd")
const MapResidentScript := preload("res://scripts/map_resident.gd")
const CombatantConfigScript := preload("res://scripts/combatant_config.gd")
const LOADING_ART := preload("res://assets/loading/map_concept.png")
const MIREK_PORTRAIT := preload("res://assets/npcs/mirek.png")
const ZUL_1_MAP_TEXTURE := preload("res://assets/npcs/zul_1_idle_sheet_v2.png")
const BUREK_MAP_TEXTURE := preload("res://assets/animals/burek_idle_sheet_v2.png")
const ZUL_1_COMBAT_ART := preload("res://assets/npcs/zul_1_dialogue_combat_v1.png")
const BUREK_COMBAT_ART := preload("res://assets/animals/burek_dialogue_combat_v1.png")
const HENIEK_MAP_TEXTURE := preload("res://assets/npcs/heniek_idle_sheet_v1.png")
const HENIEK_PORTRAIT := preload("res://assets/npcs/heniek_portrait_v1.png")

const CAN_MACHINE_PRICE := 0.60
const SCRAP_CAN_PRICE := 0.85
const MESH_PRICE := 8.00
const WIRE_PRICE := 1.50
const BEER_COST := 4.00
const BEER_RESTORE := 35.0
const CIGARETTES_COST := 5.50
const CIGARETTES_RESTORE := 42.0
const KIOSK_CIGARETTES_COST := 5.00
const SMALL_VODKA_COST := 7.50
const SMALL_VODKA_RESTORE := 60.0
const LIGHT_ACTION_COST := 1.0
const CUT_ACTION_COST := 5.0
const REPAIR_PRICE_PER_POINT := 1.50
const CUT_DURATION := 4.0
const CAN_XP := 2
const HENIEK_QUEST_XP := 35
const HENIEK_QUEST_REWARD := 15.0
const HENIEK_WIRE_COST := 3
const FAB01_ID := "FAB-01"
const FAB01_TITLE := "Pierwszy kurs"
const FAB01_PICK_UP_BAG := "pick_up_bag"
const FAB01_BUY_NEEDS := "buy_needs"
const FAB01_FIND_MIREK := "find_mirek"
const FAB01_COMPLETED := "completed"
const BUREK_DOOR_POSITION := Vector2(2450, 470)
const BUREK_DEFEATED_POSITION := Vector2(2310, 520)
const ZUL_WAIT_POSITION := Vector2(1660, 690)
const ZUL_BLOCK_POSITION := Vector2(1460, 750)
const ZUL_DEFEATED_POSITION := Vector2(1660, 760)

enum QuestState { NOT_STARTED, NEED_CANS, HAS_SHEARS, CUT_MESH, COMPLETED }
enum HeniekQuestState { NOT_STARTED, FIND_HENIEK, NEED_WIRE, RETURN_KEY, COMPLETED }

var player: Player
var inventory: PlayerInventory
var cash := 5.00
var alcohol_level := 28.0
var nicotine_level := 24.0
var quest_state := QuestState.NOT_STARTED
var heniek_quest_state := HeniekQuestState.NOT_STARTED
var gameplay_active := false
var store_open := false
var kiosk_open := false
var inventory_open := false
var mirek_open := false
var heniek_open := false
var combat_open := false
var alcohol_warning_shown := false
var nicotine_warning_shown := false
var active_fence: ScrapFence
var trash_bin: TrashSearch
var trash_bins: Array[TrashSearch] = []
var action_elapsed := 0.0
var fab01_stage := FAB01_PICK_UP_BAG
var fab01_bag_picked := false
var fab01_bought_beer := false
var fab01_bought_cigarettes := false
var fab01_first_can_seen := false
var fab01_first_sale_seen := false
var starter_bag: Area2D
var combat_enemy: Area2D
var active_combatant_name := "zadymiarz"
var active_combatant_id := "zadymiarz"
var active_combatant_node: Node2D
var active_combat_xp_reward := 0
var burek_npc: MapResident
var zul_npc: MapResident
var heniek_npc: MapResident
var burek_defeated := false
var zul_defeated := false
var player_level := 1
var player_xp := 0
var stat_points := 0
var character_stats := CombatantConfigScript.player()
var player_max_health := int(CombatantConfigScript.PLAYER.max_health)
var player_health := player_max_health

var inventory_label: Label
var money_label: Label
var alcohol_label: Label
var nicotine_label: Label
var alcohol_bar: ProgressBar
var nicotine_bar: ProgressBar
var progression_label: Label
var health_label: Label
var health_bar: ProgressBar
var message_label: Label
var action_panel: PanelContainer
var action_bar: ProgressBar
var action_label: Label
var objective_label: Label
var fab01_intro_overlay: Control
var interaction_hint_label: Label
var focused_interactable: Node2D

var store_overlay: Control
var store_money_label: Label
var store_alcohol_bar: ProgressBar
var store_nicotine_bar: ProgressBar
var store_status_label: Label
var kiosk_overlay: Control
var kiosk_money_label: Label
var kiosk_nicotine_bar: ProgressBar
var kiosk_status_label: Label

var inventory_overlay: Control
var inventory_box: VBoxContainer
var mirek_overlay: Control
var mirek_content: VBoxContainer
var mirek_dialogue_label: Label
var mirek_choices: GridContainer
var mirek_text_tween: Tween
var heniek_overlay: Control
var heniek_content: VBoxContainer
var heniek_dialogue_label: Label
var heniek_choices: GridContainer
var heniek_text_tween: Tween
var combat_overlay: Control

func _ready() -> void:
	# Postacie na tej samej warstwie zasłaniają się według położenia stóp na osi Y.
	y_sort_enabled = true
	inventory = PlayerInventoryScript.new()
	inventory.changed.connect(_update_ui)
	_create_world()
	_create_player()
	_create_world_interactions()
	_create_pickups()
	_create_ui()
	_show_loading_screen()

func _process(delta: float) -> void:
	if not gameplay_active:
		_set_focused_interactable(null)
		return
	_update_interaction_focus()
	if active_fence != null:
		_process_cutting(delta)

func _unhandled_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if _modal_open() and event.keycode in [KEY_W, KEY_A, KEY_S, KEY_D]:
		_move_menu_focus(-1 if event.keycode in [KEY_W, KEY_A] else 1)
		get_viewport().set_input_as_handled()
		return
	if active_fence != null and event.keycode in [KEY_ESCAPE, KEY_LEFT, KEY_RIGHT, KEY_UP, KEY_DOWN, KEY_W, KEY_A, KEY_S, KEY_D]:
		_cancel_cutting()
		return
	if event.keycode == KEY_I:
		if not fab01_bag_picked:
			_show_message("Najpierw podnieś reklamówkę.", true)
			return
		if inventory_open:
			_close_inventory()
		elif not _modal_open() and active_fence == null:
			_open_inventory()
	elif event.keycode == KEY_ESCAPE:
		if combat_open: _close_combat_prototype()
		elif inventory_open: _close_inventory()
		elif heniek_open: _close_heniek()
		elif mirek_open: _close_mirek()
		elif kiosk_open: _close_kiosk()
		elif store_open: _close_store()
	elif mirek_open and event.keycode in [KEY_ENTER, KEY_SPACE]:
		_finish_mirek_line()
	elif heniek_open and event.keycode in [KEY_ENTER, KEY_SPACE]:
		_finish_heniek_line()
	elif event.keycode == KEY_ENTER and gameplay_active and not _modal_open() and active_fence == null:
		if _try_interact_nearby():
			get_viewport().set_input_as_handled()

func _try_interact_nearby() -> bool:
	_update_interaction_focus()
	if focused_interactable == null or not is_instance_valid(focused_interactable):
		return false
	var item := focused_interactable
	var interacted := bool(item.call("try_interact"))
	if interacted:
		_set_focused_interactable(null)
	return interacted

func _update_interaction_focus() -> void:
	if not gameplay_active or _modal_open() or active_fence != null or player == null or player.is_action_busy():
		_set_focused_interactable(null)
		return
	var nearest_item: Node2D
	var nearest_distance := INF
	for candidate in get_tree().get_nodes_in_group("keyboard_interactable"):
		if not candidate is Node2D or not candidate.has_method("is_player_nearby") or not candidate.has_method("set_interaction_focused"):
			continue
		if not bool(candidate.call("is_player_nearby")):
			continue
		var item := candidate as Node2D
		var distance := player.global_position.distance_to(item.global_position)
		if distance < nearest_distance:
			nearest_item = item
			nearest_distance = distance
	_set_focused_interactable(nearest_item)

func _set_focused_interactable(item: Node2D) -> void:
	if focused_interactable == item:
		if interaction_hint_label != null:
			interaction_hint_label.visible = focused_interactable != null
			if focused_interactable != null and focused_interactable.has_method("interaction_prompt"):
				interaction_hint_label.text = String(focused_interactable.call("interaction_prompt"))
		return
	if focused_interactable != null and is_instance_valid(focused_interactable) and focused_interactable.has_method("set_interaction_focused"):
		focused_interactable.call("set_interaction_focused", false)
	focused_interactable = item
	if focused_interactable != null and is_instance_valid(focused_interactable):
		focused_interactable.call("set_interaction_focused", true)
	if interaction_hint_label != null:
		interaction_hint_label.visible = focused_interactable != null
		if focused_interactable != null and focused_interactable.has_method("interaction_prompt"):
			interaction_hint_label.text = String(focused_interactable.call("interaction_prompt"))

# Zachowane nazwy pomagają starszym testom i ewentualnym zapisom narzędziowym.
func _update_pickup_focus() -> void:
	_update_interaction_focus()

func _try_pick_up_nearby_item() -> bool:
	return _try_interact_nearby()

func _move_menu_focus(step: int) -> void:
	var root_node: Node
	if heniek_open:
		root_node = heniek_choices
	elif mirek_open:
		root_node = mirek_choices
	elif store_open:
		root_node = store_overlay
	elif kiosk_open:
		root_node = kiosk_overlay
	elif inventory_open:
		root_node = inventory_box
	elif combat_open:
		root_node = combat_overlay
	if root_node == null:
		return
	var buttons: Array[Button] = []
	_collect_enabled_buttons(root_node, buttons)
	if buttons.is_empty():
		return
	var current := get_viewport().gui_get_focus_owner()
	var index := buttons.find(current)
	buttons[posmod(index + step, buttons.size())].grab_focus()

func _collect_enabled_buttons(node: Node, result: Array[Button]) -> void:
	if node is Button and node.visible and not node.disabled:
		result.append(node as Button)
	for child in node.get_children():
		_collect_enabled_buttons(child, result)

func _focus_first_enabled_button(root_node: Node) -> void:
	if root_node == null or not is_instance_valid(root_node):
		return
	var buttons: Array[Button] = []
	_collect_enabled_buttons(root_node, buttons)
	if not buttons.is_empty():
		buttons[0].grab_focus()

func _modal_open() -> bool:
	return store_open or kiosk_open or inventory_open or mirek_open or heniek_open or combat_open

func _create_world() -> void:
	var world := WorldMapScript.new()
	world.name = "Osiedle"
	world.y_sort_enabled = true
	add_child(world)

func _create_player() -> void:
	player = PlayerScript.new()
	player.name = "Bohater"
	player.position = Vector2(850, 600)
	player.z_index = 8
	add_child(player)
	var camera := Camera2D.new()
	camera.name = "Kamera"
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 7.0
	camera.zoom = Vector2(1.08, 1.08)
	camera.limit_left = 0
	camera.limit_top = 0
	camera.limit_right = int(WorldMapScript.WORLD_SIZE.x)
	camera.limit_bottom = int(WorldMapScript.WORLD_SIZE.y)
	camera.limit_smoothed = true
	player.add_child(camera)

func _create_world_interactions() -> void:
	starter_bag = StarterBagScript.new()
	starter_bag.name = "ReklamowkaStartowa"
	starter_bag.position = Vector2(815, 625)
	starter_bag.z_index = 12
	starter_bag.player = player
	starter_bag.picked_up.connect(_pick_up_starter_bag)
	starter_bag.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do reklamówki.", true))
	add_child(starter_bag)

	var machine := CanMachineScript.new()
	machine.name = "AutomatNaPuszki"
	machine.position = Vector2(835, 430)
	machine.z_index = 6
	machine.player = player
	machine.sell_requested.connect(_on_machine_sell_requested)
	machine.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do automatu.", true))
	add_child(machine)

	var door := ShopDoorScript.new()
	door.name = "WejscieDoSklepu"
	door.position = Vector2(2450, 450)
	door.z_index = 7
	door.player = player
	door.enter_requested.connect(_open_store)
	door.out_of_range.connect(func() -> void: _show_message("Podejdź do drzwi sklepu.", true))
	add_child(door)

	var kiosk := KioskCounterScript.new()
	kiosk.name = "OkienkoKiosku"
	kiosk.position = Vector2(1040, 520)
	kiosk.z_index = 7
	kiosk.player = player
	kiosk.open_requested.connect(_open_kiosk)
	kiosk.out_of_range.connect(func() -> void: _show_message("Podejdź do okienka kiosku.", true))
	add_child(kiosk)

	combat_enemy = CombatEnemyScript.new()
	combat_enemy.name = "ZadymiarzPodKioskiem"
	combat_enemy.position = Vector2(1160, 580)
	combat_enemy.z_index = 9
	combat_enemy.player = player
	combat_enemy.fight_requested.connect(_open_combat_prototype.bind("zadymiarz", null, null))
	combat_enemy.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do zadymiarza.", true))
	add_child(combat_enemy)

	var mirek := MirekNPCScript.new()
	mirek.name = "Mirek"
	mirek.position = Vector2(1460, 610)
	mirek.z_index = 8
	mirek.player = player
	mirek.interaction_requested.connect(_open_mirek)
	mirek.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do Mirka.", true))
	add_child(mirek)

	var zul_1 := MapResidentScript.new() as MapResident
	zul_1.name = "Zul1"
	zul_1.position = ZUL_WAIT_POSITION
	zul_1.z_index = 8
	zul_1.sprite_texture = ZUL_1_MAP_TEXTURE
	zul_1.sprite_grid = Vector2i(2, 2)
	zul_1.sprite_scale = 0.21
	zul_1.idle_fps = 2.6
	zul_1.display_name = "ŻUL 1"
	zul_1.player = player
	zul_1.fightable = true
	zul_1.interaction_target = "ŻULEM 1"
	zul_1.fight_requested.connect(_open_combat_prototype.bind("zul_1", ZUL_1_COMBAT_ART, zul_1))
	zul_1.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do Żula 1.", true))
	add_child(zul_1)
	zul_npc = zul_1
	zul_npc.set_fight_enabled(false)

	var burek := MapResidentScript.new() as MapResident
	burek.name = "Burek"
	burek.position = BUREK_DOOR_POSITION
	burek.z_index = 8
	burek.sprite_texture = BUREK_MAP_TEXTURE
	burek.sprite_grid = Vector2i(2, 2)
	burek.sprite_scale = 0.13
	burek.idle_fps = 3.0
	burek.head_band_ratio = 0.46
	burek.display_name = "BUREK"
	burek.body_radius = 16.0
	burek.body_height = 28.0
	burek.body_offset_y = -12.0
	burek.shadow_size = Vector2(28.0, 8.0)
	burek.player = player
	burek.fightable = true
	burek.interaction_target = "BURKIEM"
	burek.fight_requested.connect(_open_combat_prototype.bind("burek", BUREK_COMBAT_ART, burek))
	burek.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do Burka.", true))
	add_child(burek)
	burek_npc = burek

	var heniek := MapResidentScript.new() as MapResident
	heniek.name = "Heniek"
	heniek.position = Vector2(1210, 1335)
	heniek.z_index = 8
	heniek.sprite_texture = HENIEK_MAP_TEXTURE
	heniek.sprite_grid = Vector2i(2, 2)
	heniek.sprite_scale = 0.20
	heniek.idle_fps = 2.5
	heniek.head_band_ratio = 0.30
	heniek.display_name = "HENIEK"
	heniek.body_radius = 18.0
	heniek.body_height = 46.0
	heniek.body_offset_y = -21.0
	heniek.player = player
	heniek.talkable = true
	heniek.interaction_target = "HEŃKIEM"
	heniek.talk_requested.connect(_open_heniek)
	heniek.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do Heńka.", true))
	add_child(heniek)
	heniek_npc = heniek

	var fence := ScrapFenceScript.new()
	fence.name = "SiatkaDoWyciecia"
	fence.position = Vector2(490, 855)
	fence.z_index = 8
	fence.player = player
	fence.cut_requested.connect(_start_cutting)
	fence.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do fragmentu siatki.", true))
	add_child(fence)

	trash_bin = _create_trash_container("KonteneryStartowe", Vector2(300, 535))
	_create_trash_container("KonteneryZaUlica", Vector2(2020, 585), true)
	_create_trash_container("KonteneryPrzyGarazach", Vector2(2380, 1160), true)
	_create_trash_container("KonteneryNaPustymPlacu", Vector2(1540, 1370), true)

func _create_trash_container(node_name: String, container_position: Vector2, guaranteed_wire := false) -> TrashSearch:
	var container := TrashSearchScript.new() as TrashSearch
	container.name = node_name
	container.position = container_position
	container.guaranteed_wire = guaranteed_wire
	container.z_index = 9
	container.player = player
	container.search_requested.connect(_begin_search_trash)
	container.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej do kontenerów.", true))
	add_child(container)
	trash_bins.append(container)
	return container

func _create_pickups() -> void:
	# Pierwsze osiem puszek gwarantuje FAB-01; pozostałe nagradzają eksplorację większej mapy.
	var positions := [
		Vector2(620, 560), Vector2(770, 720), Vector2(960, 670), Vector2(1260, 610),
		Vector2(1480, 800), Vector2(520, 785), Vector2(1030, 610), Vector2(1260, 870),
		Vector2(1880, 280), Vector2(2010, 610), Vector2(2030, 720), Vector2(2310, 710),
		Vector2(2650, 600), Vector2(2680, 820), Vector2(2070, 980), Vector2(2250, 1260),
		Vector2(2510, 1370), Vector2(1790, 1240), Vector2(1450, 1460), Vector2(1090, 1320),
		Vector2(720, 1210), Vector2(390, 1390), Vector2(2650, 1510), Vector2(1900, 1490)
	]
	for index in range(positions.size()):
		var can := PickupCanScript.new()
		can.name = "Puszka%d" % (index + 1)
		can.position = positions[index]
		can.rotation = float(index % 3 - 1) * 0.35
		can.player = player
		can.can_accept_callback = func() -> bool: return fab01_bag_picked and inventory.can_add("can")
		can.collected.connect(_on_can_collected)
		can.out_of_range.connect(func() -> void: _show_message("Podejdź bliżej, żeby dosięgnąć puszki.", true))
		can.inventory_full.connect(_on_can_inventory_blocked)
		add_child(can)

func _create_ui() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "Interfejs"
	canvas.layer = 10
	add_child(canvas)
	_create_hud(canvas)
	_create_store_ui(canvas)
	_create_kiosk_ui(canvas)
	_create_inventory_ui(canvas)
	_create_mirek_ui(canvas)
	_create_heniek_ui(canvas)
	_create_action_ui(canvas)
	_create_combat_ui(canvas)
	_update_ui()

func _create_hud(canvas: CanvasLayer) -> void:
	var top_panel := PanelContainer.new()
	top_panel.position = Vector2(20, 20)
	top_panel.custom_minimum_size = Vector2(370, 264)
	top_panel.add_theme_stylebox_override("panel", _panel_style(Color("#181b19e8")))
	canvas.add_child(top_panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	top_panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	var title := _label("ZBIERACZ", 18, Color("#efb647"))
	title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(title)
	money_label = _label("", 16, Color("#b9d18e"))
	header.add_child(money_label)
	inventory_label = _label("", 12, Color("#eee6d7"))
	inventory_label.custom_minimum_size.y = 38
	box.add_child(inventory_label)
	progression_label = _label("", 12, Color("#efc870"))
	box.add_child(progression_label)
	health_label = _label("", 11, Color("#d8c69b"))
	box.add_child(health_label)
	health_bar = _need_bar(Color("#4a9b5c"))
	health_bar.name = "ZdrowieBohateraHUD"
	box.add_child(health_bar)
	alcohol_label = _label("", 11, Color("#d8c69b"))
	box.add_child(alcohol_label)
	alcohol_bar = _need_bar(Color("#b77745"))
	box.add_child(alcohol_bar)
	nicotine_label = _label("", 11, Color("#d8c69b"))
	box.add_child(nicotine_label)
	nicotine_bar = _need_bar(Color("#87985e"))
	box.add_child(nicotine_bar)

	message_label = _label("Strzałki / WASD — ruch  •  ENTER — akcja  •  I — ekwipunek", 14, Color("#eee6d7"))
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	message_label.add_theme_constant_override("shadow_offset_x", 2)
	message_label.add_theme_constant_override("shadow_offset_y", 2)
	message_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	message_label.offset_left = 160
	message_label.offset_right = -160
	message_label.offset_top = -58
	message_label.offset_bottom = -20
	canvas.add_child(message_label)
	interaction_hint_label = _label("ENTER  —  AKCJA", 12, Color("#ffe29a"))
	interaction_hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	interaction_hint_label.add_theme_color_override("font_shadow_color", Color("#000000dd"))
	interaction_hint_label.add_theme_constant_override("shadow_offset_x", 2)
	interaction_hint_label.add_theme_constant_override("shadow_offset_y", 2)
	interaction_hint_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	interaction_hint_label.offset_left = 450
	interaction_hint_label.offset_right = -450
	interaction_hint_label.offset_top = -91
	interaction_hint_label.offset_bottom = -67
	interaction_hint_label.visible = false
	canvas.add_child(interaction_hint_label)
	var hint := _label("AUTOMAT 0,60 ZŁ  •  MIREK 0,85 ZŁ PO ZADANIU", 10, Color("#c8c3b6"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	hint.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	hint.offset_left = -430
	hint.offset_right = -20
	hint.offset_top = 24
	hint.offset_bottom = 46
	canvas.add_child(hint)
	var objective_panel := PanelContainer.new()
	objective_panel.name = "CelFabularny"
	objective_panel.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	objective_panel.offset_left = -390
	objective_panel.offset_right = -20
	objective_panel.offset_top = 58
	objective_panel.offset_bottom = 172
	objective_panel.add_theme_stylebox_override("panel", _panel_style(Color("#171b19e8")))
	canvas.add_child(objective_panel)
	objective_label = _wrapped_label("", 13)
	objective_label.custom_minimum_size = Vector2(340, 84)
	objective_panel.add_child(objective_label)

func _create_store_ui(canvas: CanvasLayer) -> void:
	store_overlay = _modal_overlay(canvas, "WnetrzeSklepu")
	var panel := _modal_panel(store_overlay, Vector2(375, 80), Vector2(530, 560))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 12)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(_label("ŻUK GNOJARZ", 24, Color("#efb647")))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	store_money_label = _label("", 18, Color("#b9d18e"))
	header.add_child(store_money_label)
	box.add_child(HSeparator.new())
	box.add_child(_label("ALKOHOL", 12, Color("#d8c69b")))
	store_alcohol_bar = _need_bar(Color("#b77745"))
	store_alcohol_bar.custom_minimum_size.y = 20
	box.add_child(store_alcohol_bar)
	box.add_child(_label("NIKOTYNA", 12, Color("#d8c69b")))
	store_nicotine_bar = _need_bar(Color("#87985e"))
	store_nicotine_bar.custom_minimum_size.y = 20
	box.add_child(store_nicotine_bar)
	var beer_button := _menu_button("PIWO — 4,00 ZŁ\n+35 alkoholu")
	beer_button.pressed.connect(_buy_beer)
	box.add_child(beer_button)
	var vodka_button := _menu_button("MAŁPKA — 7,50 ZŁ\n+60 alkoholu")
	vodka_button.pressed.connect(_buy_small_vodka)
	box.add_child(vodka_button)
	var cigarettes_button := _menu_button("PAPIEROSY — 5,50 ZŁ\n+42 nikotyny")
	cigarettes_button.pressed.connect(_buy_cigarettes)
	box.add_child(cigarettes_button)
	store_status_label = _label("Kup tylko to, czego naprawdę potrzebujesz.", 12, Color("#aaa79e"))
	store_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(store_status_label)
	var exit_button := _menu_button("WYJDŹ ZE SKLEPU")
	exit_button.pressed.connect(_close_store)
	box.add_child(exit_button)

func _create_kiosk_ui(canvas: CanvasLayer) -> void:
	kiosk_overlay = _modal_overlay(canvas, "OkienkoKiosku")
	var panel := _modal_panel(kiosk_overlay, Vector2(390, 150), Vector2(500, 360))
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 14)
	panel.add_child(box)
	var header := HBoxContainer.new()
	box.add_child(header)
	header.add_child(_label("KIOSK", 24, Color("#efb647")))
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(spacer)
	kiosk_money_label = _label("", 18, Color("#b9d18e"))
	header.add_child(kiosk_money_label)
	box.add_child(HSeparator.new())
	box.add_child(_label("NIKOTYNA", 12, Color("#d8c69b")))
	kiosk_nicotine_bar = _need_bar(Color("#87985e"))
	kiosk_nicotine_bar.custom_minimum_size.y = 20
	box.add_child(kiosk_nicotine_bar)
	var cigarettes_button := _menu_button("PAPIEROSY — 5,00 ZŁ\n+42 nikotyny")
	cigarettes_button.pressed.connect(_buy_kiosk_cigarettes)
	box.add_child(cigarettes_button)
	kiosk_status_label = _label("W kiosku papierosy są tańsze niż w Żuku.", 12, Color("#aaa79e"))
	kiosk_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(kiosk_status_label)
	var exit_button := _menu_button("ODEJDŹ OD KIOSKU")
	exit_button.pressed.connect(_close_kiosk)
	box.add_child(exit_button)

func _create_inventory_ui(canvas: CanvasLayer) -> void:
	inventory_overlay = _modal_overlay(canvas, "Ekwipunek")
	var panel := _modal_panel(inventory_overlay, Vector2(220, 40), Vector2(840, 640))
	inventory_box = VBoxContainer.new()
	inventory_box.add_theme_constant_override("separation", 9)
	panel.add_child(inventory_box)

func _create_mirek_ui(canvas: CanvasLayer) -> void:
	mirek_overlay = _modal_overlay(canvas, "RozmowaZMirkem")
	var shade := mirek_overlay.get_child(0) as ColorRect
	shade.color = Color("#080b1059")
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 45
	panel.offset_right = -45
	panel.offset_top = -352
	panel.offset_bottom = -28
	panel.add_theme_stylebox_override("panel", _classic_dialogue_style())
	mirek_overlay.add_child(panel)
	mirek_content = VBoxContainer.new()
	mirek_content.add_theme_constant_override("separation", 8)
	panel.add_child(mirek_content)

func _create_heniek_ui(canvas: CanvasLayer) -> void:
	heniek_overlay = _modal_overlay(canvas, "RozmowaZHenkiem")
	var shade := heniek_overlay.get_child(0) as ColorRect
	shade.color = Color("#080b1059")
	var panel := PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 45
	panel.offset_right = -45
	panel.offset_top = -352
	panel.offset_bottom = -28
	panel.add_theme_stylebox_override("panel", _classic_dialogue_style())
	heniek_overlay.add_child(panel)
	heniek_content = VBoxContainer.new()
	heniek_content.add_theme_constant_override("separation", 8)
	panel.add_child(heniek_content)

func _create_action_ui(canvas: CanvasLayer) -> void:
	action_panel = PanelContainer.new()
	action_panel.position = Vector2(430, 590)
	action_panel.custom_minimum_size = Vector2(420, 80)
	action_panel.add_theme_stylebox_override("panel", _panel_style(Color("#181b19ee")))
	action_panel.visible = false
	canvas.add_child(action_panel)
	var box := VBoxContainer.new()
	action_panel.add_child(box)
	action_label = _label("WYCINANIE SIATKI", 13, Color("#efb647"))
	action_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(action_label)
	action_bar = _need_bar(Color("#c68c42"))
	action_bar.max_value = CUT_DURATION
	action_bar.custom_minimum_size = Vector2(390, 18)
	box.add_child(action_bar)
	var cancel := _label("Ruch lub ESC anuluje czynność", 10, Color("#aaa79e"))
	cancel.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(cancel)

func _create_combat_ui(canvas: CanvasLayer) -> void:
	combat_overlay = CombatPrototypeScript.new()
	combat_overlay.name = "PrototypWalki"
	combat_overlay.exit_requested.connect(_on_combat_exit_requested)
	combat_overlay.combat_resolved.connect(_on_combat_resolved)
	combat_overlay.player_health_changed.connect(_on_player_health_changed)
	canvas.add_child(combat_overlay)

func _open_combat_prototype(combatant_id := "zadymiarz", enemy_art: Texture2D = null, combatant_node: Node2D = null) -> void:
	if combat_open or not gameplay_active:
		return
	if not CombatantConfigScript.has_enemy(combatant_id):
		push_error("Brak konfiguracji przeciwnika: %s" % combatant_id)
		return
	if player_health <= 0:
		_show_message("Nie masz siły na kolejną walkę.", true)
		return
	if alcohol_level <= 0.0 or nicotine_level <= 0.0:
		_show_message("Nie możesz walczyć przy zerowym alkoholu lub nikotynie. Najpierw uzupełnij oba paski.", true)
		return
	if combatant_id == "zul_1" and quest_state != QuestState.COMPLETED:
		_show_message("Żul 1 nie zastawił jeszcze przejścia. Najpierw dokończ zlecenie Mirka z siatką.")
		return
	var enemy_config := CombatantConfigScript.enemy(combatant_id)
	combat_open = true
	active_combatant_name = String(enemy_config.display_name).to_lower()
	active_combatant_id = combatant_id
	active_combatant_node = combatant_node
	active_combat_xp_reward = int(enemy_config.xp_reward)
	_set_focused_interactable(null)
	player.set_physics_process(false)
	var combat_stats := character_stats.duplicate(true)
	combat_stats["current_health"] = player_health
	combat_overlay.set_player_stats(combat_stats)
	combat_overlay.configure_enemy_from_definition(enemy_config, enemy_art)
	combat_overlay.start_fight()

func _close_combat_prototype() -> void:
	if not combat_open:
		return
	if combat_overlay.rules.finished and combat_overlay.rules.result == "defeat":
		# Prototyp nie ma jeszcze leczenia ani konsekwencji porażki, więc nie może
		# zostawić gracza na 0 HP i trwale zablokować kolejnych starć.
		player_health = player_max_health
		_update_ui()
	combat_open = false
	combat_overlay.close_fight()
	player.set_physics_process(true)
	_show_message("Walka zakończona. %s nadal jest na mapie." % active_combatant_name.capitalize())

func _on_player_health_changed(current_health: int, max_health: int) -> void:
	player_max_health = max_health
	player_health = clampi(current_health, 0, player_max_health)
	_update_ui()

func _on_combat_exit_requested(_result: String) -> void:
	_close_combat_prototype()

func _on_combat_resolved(combat_result: String) -> void:
	if combat_result == "victory":
		if active_combatant_id == "burek":
			burek_defeated = true
		elif active_combatant_id == "zul_1":
			zul_defeated = true
		if active_combatant_node != null and is_instance_valid(active_combatant_node):
			if active_combatant_node.has_method("set_fight_enabled"):
				active_combatant_node.call("set_fight_enabled", false)
			var defeated_position := active_combatant_node.position
			if active_combatant_id == "burek":
				defeated_position = BUREK_DEFEATED_POSITION
			elif active_combatant_id == "zul_1":
				defeated_position = ZUL_DEFEATED_POSITION
			var retreat := create_tween()
			retreat.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			retreat.tween_property(active_combatant_node, "position", defeated_position, 0.7)
		var levels_gained := _award_xp(active_combat_xp_reward, "wygraną walkę")
		var reward_text := "+%d XP ZA ZWYCIĘSTWO" % active_combat_xp_reward
		if levels_gained > 0:
			reward_text += "  •  AWANS! POZIOM %d  •  +%d PUNKT STATYSTYKI" % [player_level, levels_gained]
		combat_overlay.show_reward_text(reward_text)

func _on_can_collected() -> void:
	if not inventory.add_item("can"):
		return
	_consume_needs(LIGHT_ACTION_COST)
	if not fab01_first_can_seen:
		fab01_first_can_seen = true
		_show_message("Sześćdziesiąt groszy. Jeszcze kilka i człowiek zaczyna liczyć w puszkach.")
	elif inventory.used_space() >= inventory.capacity():
		_show_message("Pełna. Więcej nie wejdzie, choćbym ją przekonywał.", true)
	else:
		_show_message("Podniesiono puszkę: %d szt." % inventory.item_count("can"))
	_award_xp(CAN_XP, "podniesioną puszkę")
	_update_ui()

func _on_can_inventory_blocked() -> void:
	if not fab01_bag_picked:
		_show_message("Nie mam jej gdzie schować. Najpierw reklamówka.", true)
	else:
		_show_message("Pełna. Więcej nie wejdzie, choćbym ją przekonywał.", true)

func _pick_up_starter_bag() -> void:
	fab01_bag_picked = true
	fab01_stage = FAB01_BUY_NEEDS
	_show_message("Pięć złotych. Brakuje cztery złote. Automat bierze puszki — jeśli jeszcze coś zostało po nocnych.")
	_update_ui()

func _on_machine_sell_requested() -> void:
	var amount := inventory.item_count("can")
	if amount <= 0:
		_show_message("Pojemnik jest pusty. Automat nie ma czego przyjąć.", true)
		return
	var earned := float(amount) * CAN_MACHINE_PRICE
	inventory.remove_item("can", amount)
	cash += earned
	_consume_needs(LIGHT_ACTION_COST)
	_update_ui()
	if not fab01_first_sale_seen:
		fab01_first_sale_seen = true
		_show_message("Mało. Ale łeb nie pyta, czy dużo. Automat wypłacił %s." % _money(earned))
	else:
		_show_message("Automat przyjął %d puszek: +%s. Mirek płaci lepiej." % [amount, _money(earned)])

func _start_cutting(fence: ScrapFence) -> void:
	if not inventory.has_tool("metal_shears"):
		_show_message("Potrzebujesz nożyc do metalu. Porozmawiaj z Mirkiem.", true)
		return
	if not inventory.can_add("mesh"):
		_show_message("Nie masz miejsca albo udźwigu na fragment siatki.", true)
		return
	if alcohol_level < CUT_ACTION_COST or nicotine_level < CUT_ACTION_COST:
		_show_message("Cięcie siatki wymaga co najmniej 5 punktów alkoholu i 5 nikotyny.", true)
		return
	active_fence = fence
	action_elapsed = 0.0
	action_bar.value = 0.0
	action_panel.visible = true
	player.set_physics_process(false)
	_show_message("Rozpoczynasz wycinanie siatki...")

func _process_cutting(delta: float) -> void:
	action_elapsed += delta
	action_bar.value = action_elapsed
	if action_elapsed >= CUT_DURATION:
		_complete_cutting()

func _complete_cutting() -> void:
	if active_fence == null:
		return
	var fence := active_fence
	active_fence = null
	action_panel.visible = false
	player.set_physics_process(true)
	if not inventory.add_item("mesh"):
		_show_message("Nie udało się schować siatki — brak miejsca.", true)
		return
	inventory.damage_tool("metal_shears")
	_consume_needs(CUT_ACTION_COST)
	fence.complete_cut()
	if quest_state == QuestState.HAS_SHEARS:
		quest_state = QuestState.CUT_MESH
	_show_message("Wycięto fragment siatki. Nożyce straciły 1 punkt trwałości.")

func _cancel_cutting() -> void:
	active_fence = null
	action_elapsed = 0.0
	action_panel.visible = false
	player.set_physics_process(true)
	_show_message("Przerwano wycinanie. Nożyce nie zostały zużyte.")

func _open_inventory() -> void:
	inventory_open = true
	player.set_physics_process(false)
	_rebuild_inventory_ui()
	inventory_overlay.visible = true
	call_deferred("_focus_first_enabled_button", inventory_box)

func _close_inventory() -> void:
	inventory_open = false
	inventory_overlay.visible = false
	player.set_physics_process(true)

func _rebuild_inventory_ui() -> void:
	_clear_container(inventory_box)
	inventory_box.add_child(_label("EKWIPUNEK I ROZWÓJ", 24, Color("#efb647")))
	inventory_box.add_child(_label("%s  •  miejsce %d/%d  •  waga %.2f/%.1f kg" % [inventory.container_name(), inventory.used_space(), inventory.capacity(), inventory.current_weight(), inventory.max_weight()], 14, Color("#eee6d7")))
	inventory_box.add_child(HSeparator.new())
	var columns := HBoxContainer.new()
	columns.add_theme_constant_override("separation", 20)
	columns.size_flags_vertical = Control.SIZE_EXPAND_FILL
	inventory_box.add_child(columns)
	var equipment_column := VBoxContainer.new()
	equipment_column.custom_minimum_size.x = 480
	equipment_column.add_theme_constant_override("separation", 8)
	columns.add_child(equipment_column)
	equipment_column.add_child(_label("PRZEDMIOTY", 13, Color("#d8c69b")))
	equipment_column.add_child(_label("Puszki: %d  •  Siatka: %d  •  Drut: %d" % [inventory.item_count("can"), inventory.item_count("mesh"), inventory.item_count("wire")], 14, Color("#eee6d7")))
	equipment_column.add_child(_label("NARZĘDZIA — nie zajmują miejsca ani udźwigu", 13, Color("#d8c69b")))
	var tool_text := "Brak"
	if inventory.tools.has("metal_shears"):
		tool_text = "Nożyce do metalu: %d/%d trwałości" % [inventory.tool_durability("metal_shears"), inventory.tool_max_durability("metal_shears")]
	equipment_column.add_child(_label(tool_text, 14, Color("#eee6d7")))
	equipment_column.add_child(_label("POJEMNIKI", 13, Color("#d8c69b")))
	for container_id in PlayerInventory.CONTAINERS:
		if inventory.owned_containers.has(container_id):
			var definition: Dictionary = PlayerInventory.CONTAINERS[container_id]
			var prefix := "[ZAŁOŻONY] " if inventory.equipped_container == container_id else "ZAŁÓŻ "
			var button := _menu_button(prefix + String(definition.name).to_upper() + "  •  %d miejsc / %.0f kg" % [definition.capacity, definition.max_weight])
			button.disabled = inventory.equipped_container == container_id
			button.pressed.connect(func() -> void: _equip_container(container_id))
			equipment_column.add_child(button)
	var stats_column := VBoxContainer.new()
	stats_column.custom_minimum_size.x = 285
	stats_column.add_theme_constant_override("separation", 8)
	columns.add_child(stats_column)
	stats_column.add_child(_label("ROZWÓJ BOHATERA", 13, Color("#d8c69b")))
	stats_column.add_child(_label("POZIOM %d  •  XP %d/%d" % [player_level, player_xp, _xp_for_next_level()], 16, Color("#efc870")))
	var xp_bar := _need_bar(Color("#c79b46"))
	xp_bar.name = "PasekDoswiadczenia"
	xp_bar.max_value = _xp_for_next_level()
	xp_bar.value = player_xp
	xp_bar.custom_minimum_size = Vector2(270, 16)
	stats_column.add_child(xp_bar)
	stats_column.add_child(_label("Punkty statystyk: %d" % stat_points, 14, Color("#b9d18e")))
	_add_stat_button(stats_column, "strength", "SIŁA", "+1 szybki / +2 silny")
	_add_stat_button(stats_column, "endurance", "KONDYCJA", "+5 maks. życia")
	_add_stat_button(stats_column, "agility", "ZWINNOŚĆ", "+celność / +5% uniku")
	stats_column.add_child(_label("Każdy nowy poziom daje 1 punkt.", 11, Color("#aaa79e")))
	var close := _menu_button("ZAMKNIJ — I / ESC")
	close.pressed.connect(_close_inventory)
	inventory_box.add_child(close)
	call_deferred("_focus_first_enabled_button", inventory_box)

func _add_stat_button(parent: VBoxContainer, stat_id: String, stat_name: String, effect: String) -> void:
	var button := _menu_button("%s %d  •  %s" % [stat_name, int(character_stats[stat_id]), effect])
	button.name = "Stat_" + stat_id
	button.custom_minimum_size = Vector2(270, 48)
	button.disabled = stat_points <= 0
	button.pressed.connect(func() -> void: _increase_stat(stat_id))
	parent.add_child(button)

func _equip_container(container_id: String) -> void:
	if inventory.equip_container(container_id):
		_show_message("Założono: %s." % inventory.container_name())
	else:
		_show_message("Ten pojemnik jest za mały na obecną zawartość.", true)
	_rebuild_inventory_ui()

func _xp_for_next_level() -> int:
	return 25 + (player_level - 1) * 20

func _award_xp(amount: int, source: String) -> int:
	if amount <= 0:
		return 0
	player_xp += amount
	var levels_gained := 0
	while player_xp >= _xp_for_next_level():
		player_xp -= _xp_for_next_level()
		player_level += 1
		stat_points += 1
		levels_gained += 1
	_update_ui()
	if levels_gained > 0 and not combat_open:
		_show_message("AWANS! Poziom %d. Otrzymujesz %d punkt statystyki za %s." % [player_level, levels_gained, source])
	return levels_gained

func _increase_stat(stat_id: String) -> void:
	if stat_points <= 0 or not character_stats.has(stat_id):
		return
	character_stats[stat_id] = int(character_stats[stat_id]) + 1
	if stat_id == "endurance":
		player_max_health += 5
		player_health += 5
	stat_points -= 1
	_update_ui()
	_rebuild_inventory_ui()

func _open_mirek() -> void:
	if fab01_stage == FAB01_FIND_MIREK:
		_complete_fab01()
	elif fab01_stage != FAB01_COMPLETED:
		_show_message("Najpierw muszę ogarnąć piwo i papierosy. Potem Mirek.", true)
		return
	if quest_state == QuestState.COMPLETED and not zul_defeated:
		_show_message("Żul 1 zastawił jedyne dojście do Mirka. Pokonaj go przed oddaniem drutu — zalecany poziom 3.", true)
		return
	mirek_open = true
	player.set_physics_process(false)
	_rebuild_mirek_ui()
	mirek_overlay.visible = true

func _close_mirek() -> void:
	if mirek_text_tween != null and mirek_text_tween.is_valid():
		mirek_text_tween.kill()
	mirek_open = false
	mirek_overlay.visible = false
	player.set_physics_process(true)
	_show_message("Kończysz rozmowę z Mirkiem.")

func _rebuild_mirek_ui() -> void:
	if mirek_text_tween != null and mirek_text_tween.is_valid():
		mirek_text_tween.kill()
	_clear_container(mirek_content)
	var header := HBoxContainer.new()
	mirek_content.add_child(header)
	var name_label := _label("MIREK", 20, Color("#f2d58b"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	header.add_child(_label("SKUP ZŁOMU   •   TWOJA GOTÓWKA: %s" % _money(cash), 14, Color("#b9cce0")))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	mirek_content.add_child(body)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(205, 255)
	portrait_frame.add_theme_stylebox_override("panel", _portrait_style())
	body.add_child(portrait_frame)
	var portrait := TextureRect.new()
	portrait.texture = MIREK_PORTRAIT
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	portrait_frame.add_child(portrait)
	var dialogue_side := VBoxContainer.new()
	dialogue_side.add_theme_constant_override("separation", 7)
	dialogue_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(dialogue_side)
	var text_frame := PanelContainer.new()
	text_frame.custom_minimum_size = Vector2(0, 88)
	text_frame.add_theme_stylebox_override("panel", _dialogue_text_style())
	dialogue_side.add_child(text_frame)
	mirek_dialogue_label = _wrapped_label("", 17)
	mirek_dialogue_label.custom_minimum_size = Vector2(0, 76)
	mirek_dialogue_label.gui_input.connect(_on_mirek_text_input)
	text_frame.add_child(mirek_dialogue_label)
	var hint := _label("ENTER / KLIK — pokaż całą kwestię", 10, Color("#8292a6"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue_side.add_child(hint)
	mirek_choices = GridContainer.new()
	mirek_choices.columns = 2
	mirek_choices.add_theme_constant_override("h_separation", 8)
	mirek_choices.add_theme_constant_override("v_separation", 6)
	dialogue_side.add_child(mirek_choices)
	var dialogue := ""
	match quest_state:
		QuestState.NOT_STARTED:
			dialogue = "Widzę, że zbierasz puszki. Przynieś mi cztery, a dam ci stare nożyce. Przy płocie jest kawał dobrej siatki."
			_add_mirek_button("PRZYJMIJ ZADANIE", _start_mirek_quest)
		QuestState.NEED_CANS:
			dialogue = "Potrzebuję czterech puszek. Masz teraz %d." % inventory.item_count("can")
			var deliver := _add_mirek_button("ODDAJ 4 PUSZKI", _deliver_quest_cans)
			deliver.disabled = inventory.item_count("can") < 4
		QuestState.HAS_SHEARS:
			dialogue = "Nożyce masz. Podejdź do podświetlonego fragmentu starego płotu i wytnij siatkę. Ruch przerwie pracę."
		QuestState.CUT_MESH:
			dialogue = "Masz siatkę? Za pierwszy kawałek dam ci 8 zł i otworzę normalny skup."
			var finish := _add_mirek_button("ODDAJ SIATKĘ — 8,00 ZŁ", _finish_mirek_quest)
			finish.disabled = inventory.item_count("mesh") < 1
		QuestState.COMPLETED:
			match heniek_quest_state:
				HeniekQuestState.NOT_STARTED:
					dialogue = "Interes się kręci. Mam też robotę przy Żuku — Heniek z garaży trzyma mój zapasowy klucz."
					_add_mirek_button("WEŹ NOWE ZLECENIE", _start_heniek_quest)
				HeniekQuestState.FIND_HENIEK, HeniekQuestState.NEED_WIRE:
					dialogue = "Heniek siedzi przy dolnych garażach. Dogadaj się z nim i przynieś mi klucz do Żuka."
				HeniekQuestState.RETURN_KEY:
					dialogue = "Masz klucz? Daj go tutaj. Za fatygę dostaniesz 15 zł i porządny kawał doświadczenia."
					var return_key := _add_mirek_button("ODDAJ KLUCZ DO ŻUKA", _return_zuk_key)
					return_key.disabled = inventory.item_count("zuk_key") <= 0
				HeniekQuestState.COMPLETED:
					dialogue = "Żuk znowu odpala. Dobra robota. Puszki płacę lepiej niż automat, kupuję metal i naprawiam nożyce."
			_add_trade_buttons()
	_add_mirek_button("ZAKOŃCZ ROZMOWĘ", _close_mirek)
	_start_mirek_line(dialogue)

func _start_mirek_quest() -> void:
	quest_state = QuestState.NEED_CANS
	_rebuild_mirek_ui()

func _deliver_quest_cans() -> void:
	if not inventory.remove_item("can", 4):
		return
	inventory.add_tool("metal_shears", 6)
	quest_state = QuestState.HAS_SHEARS
	_rebuild_mirek_ui()
	_show_message("Mirek oddaje ci nożyce. Wytnij siatkę i przynieś ją z powrotem.")

func _finish_mirek_quest() -> void:
	if not inventory.remove_item("mesh", 1):
		return
	cash += MESH_PRICE
	quest_state = QuestState.COMPLETED
	_update_ui()
	if mirek_text_tween != null and mirek_text_tween.is_valid():
		mirek_text_tween.kill()
	mirek_open = false
	mirek_overlay.visible = false
	player.set_physics_process(true)
	_activate_zul_blockade()

func _activate_zul_blockade() -> void:
	if zul_npc == null or not is_instance_valid(zul_npc) or zul_defeated:
		return
	zul_npc.set_fight_enabled(true)
	var approach := create_tween()
	approach.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	approach.tween_property(zul_npc, "position", ZUL_BLOCK_POSITION, 0.65)
	_show_message("Żul 1 wciska się w jedyne przejście do Mirka. Pokonaj go, zanim oddasz drut — najlepiej około 3 poziomu.")

func _start_heniek_quest() -> void:
	if quest_state != QuestState.COMPLETED or not zul_defeated or heniek_quest_state != HeniekQuestState.NOT_STARTED:
		return
	heniek_quest_state = HeniekQuestState.FIND_HENIEK
	_rebuild_mirek_ui()
	_update_ui()
	_show_message("FAB-03: Znajdź Heńka Mechanika przy dolnych garażach i odzyskaj klucz do Żuka.")

func _return_zuk_key() -> void:
	if heniek_quest_state != HeniekQuestState.RETURN_KEY or not inventory.remove_item("zuk_key", 1):
		return
	heniek_quest_state = HeniekQuestState.COMPLETED
	cash += HENIEK_QUEST_REWARD
	var levels_gained := _award_xp(HENIEK_QUEST_XP, "zlecenie Heńka")
	_update_ui()
	_rebuild_mirek_ui()
	var level_text := " Awans na poziom %d!" % player_level if levels_gained > 0 else ""
	_show_message("FAB-03 ukończone: Mirek odzyskał klucz. +15,00 zł i +35 XP.%s" % level_text)

func _open_heniek() -> void:
	heniek_open = true
	player.set_physics_process(false)
	_rebuild_heniek_ui()
	heniek_overlay.visible = true

func _close_heniek() -> void:
	if heniek_text_tween != null and heniek_text_tween.is_valid():
		heniek_text_tween.kill()
	heniek_open = false
	heniek_overlay.visible = false
	player.set_physics_process(true)
	_show_message("Kończysz rozmowę z Heńkiem.")

func _rebuild_heniek_ui() -> void:
	if heniek_text_tween != null and heniek_text_tween.is_valid():
		heniek_text_tween.kill()
	_clear_container(heniek_content)
	var header := HBoxContainer.new()
	heniek_content.add_child(header)
	var name_label := _label("HENIEK MECHANIK", 20, Color("#f2d58b"))
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(name_label)
	header.add_child(_label("DOLNE GARAŻE", 14, Color("#b9cce0")))
	var body := HBoxContainer.new()
	body.add_theme_constant_override("separation", 16)
	body.size_flags_vertical = Control.SIZE_EXPAND_FILL
	heniek_content.add_child(body)
	var portrait_frame := PanelContainer.new()
	portrait_frame.custom_minimum_size = Vector2(205, 255)
	portrait_frame.add_theme_stylebox_override("panel", _portrait_style())
	body.add_child(portrait_frame)
	var portrait := TextureRect.new()
	portrait.texture = HENIEK_PORTRAIT
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	portrait_frame.add_child(portrait)
	var dialogue_side := VBoxContainer.new()
	dialogue_side.add_theme_constant_override("separation", 7)
	dialogue_side.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body.add_child(dialogue_side)
	var text_frame := PanelContainer.new()
	text_frame.custom_minimum_size = Vector2(0, 88)
	text_frame.add_theme_stylebox_override("panel", _dialogue_text_style())
	dialogue_side.add_child(text_frame)
	heniek_dialogue_label = _wrapped_label("", 17)
	heniek_dialogue_label.custom_minimum_size = Vector2(0, 76)
	heniek_dialogue_label.gui_input.connect(_on_heniek_text_input)
	text_frame.add_child(heniek_dialogue_label)
	var hint := _label("ENTER / KLIK — pokaż całą kwestię", 10, Color("#8292a6"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	dialogue_side.add_child(hint)
	heniek_choices = GridContainer.new()
	heniek_choices.columns = 2
	heniek_choices.add_theme_constant_override("h_separation", 8)
	heniek_choices.add_theme_constant_override("v_separation", 6)
	dialogue_side.add_child(heniek_choices)
	var dialogue := ""
	match heniek_quest_state:
		HeniekQuestState.NOT_STARTED:
			dialogue = "Nie mam teraz czasu. Jak Mirek będzie czegoś chciał, sam cię tu przyśle."
		HeniekQuestState.FIND_HENIEK:
			dialogue = "Klucz mam, ale nic za darmo. Przynieś trzy kawałki drutu z dalszych kontenerów, to się dogadamy."
			_add_heniek_button("DOGADANE — ZDOBĘDĘ 3 DRUTY", _accept_heniek_deal)
		HeniekQuestState.NEED_WIRE:
			dialogue = "Potrzebuję trzech kawałków drutu. Masz teraz %d. W dalszych kontenerach powinien być pewny zapas." % inventory.item_count("wire")
			var give_wire := _add_heniek_button("ODDAJ 3 DRUTY", _give_wire_to_heniek)
			give_wire.disabled = inventory.item_count("wire") < HENIEK_WIRE_COST
		HeniekQuestState.RETURN_KEY:
			dialogue = "Masz klucz. Zanieś go Mirkowi, zanim znowu zgubi cierpliwość albo Żuka."
		HeniekQuestState.COMPLETED:
			dialogue = "Mirek odpalił Żuka? To dobrze. Następnym razem niech sobie dorobi trzeci klucz."
	_add_heniek_button("ZAKOŃCZ ROZMOWĘ", _close_heniek)
	_start_heniek_line(dialogue)

func _accept_heniek_deal() -> void:
	if heniek_quest_state != HeniekQuestState.FIND_HENIEK:
		return
	heniek_quest_state = HeniekQuestState.NEED_WIRE
	_update_ui()
	_rebuild_heniek_ui()

func _give_wire_to_heniek() -> void:
	if heniek_quest_state != HeniekQuestState.NEED_WIRE or not inventory.remove_item("wire", HENIEK_WIRE_COST):
		return
	inventory.add_item("zuk_key")
	heniek_quest_state = HeniekQuestState.RETURN_KEY
	_update_ui()
	_rebuild_heniek_ui()
	_show_message("Heniek oddaje zapasowy klucz do Żuka. Zanieś go Mirkowi.")

func _add_heniek_button(text: String, callback: Callable) -> Button:
	var button := _dialogue_button(text)
	button.pressed.connect(callback)
	heniek_choices.add_child(button)
	return button

func _start_heniek_line(text: String) -> void:
	heniek_dialogue_label.text = text
	heniek_dialogue_label.visible_characters = 0
	heniek_choices.visible = false
	var duration := clampf(float(text.length()) / 42.0, 0.7, 3.6)
	heniek_text_tween = create_tween()
	heniek_text_tween.tween_property(heniek_dialogue_label, "visible_characters", text.length(), duration)
	heniek_text_tween.tween_callback(_finish_heniek_line)

func _finish_heniek_line() -> void:
	if heniek_dialogue_label == null or not is_instance_valid(heniek_dialogue_label):
		return
	if heniek_text_tween != null and heniek_text_tween.is_valid():
		heniek_text_tween.kill()
	heniek_dialogue_label.visible_characters = -1
	if heniek_choices != null and is_instance_valid(heniek_choices):
		heniek_choices.visible = true
		call_deferred("_focus_first_enabled_button", heniek_choices)

func _on_heniek_text_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_heniek_line()

func _begin_search_trash(trash: TrashSearch) -> void:
	if not fab01_bag_picked:
		_show_message("Najpierw podnieś reklamówkę. Nie mam gdzie schować znalezisk.", true)
		return
	if player.is_action_busy():
		return
	trash.input_pickable = false
	if not player.play_action("rummage", trash.global_position):
		trash.input_pickable = true
		return
	_show_message("Grzebiesz w starym koszu...")
	await player.action_finished
	if not is_instance_valid(trash):
		return
	trash.input_pickable = true
	_search_trash(trash)

func _search_trash(trash: TrashSearch) -> void:
	trash.reveal_loot()
	if trash.is_empty():
		_show_message("Kosze są już puste.")
		return
	var collected_cans := 0
	var collected_wire := 0
	while trash.remaining_cans > 0 and inventory.can_add("can"):
		inventory.add_item("can")
		trash.remaining_cans -= 1
		collected_cans += 1
	while trash.remaining_wire > 0 and inventory.can_add("wire"):
		inventory.add_item("wire")
		trash.remaining_wire -= 1
		collected_wire += 1
	trash.queue_redraw()
	var found_parts: Array[String] = []
	if collected_cans > 0: found_parts.append("%d puszek" % collected_cans)
	if collected_wire > 0: found_parts.append("kawałek drutu")
	if found_parts.is_empty():
		_show_message("Nie masz miejsca na rzeczy znalezione w koszu.", true)
	elif trash.is_empty():
		_show_message("W koszu znaleziono: %s." % " i ".join(found_parts))
	else:
		_show_message("Zabrano: %s. Reszta została w koszu." % " i ".join(found_parts), true)
	if collected_cans > 0 or collected_wire > 0:
		_consume_needs(LIGHT_ACTION_COST)
	if collected_cans > 0:
		_award_xp(collected_cans * CAN_XP, "puszki znalezione w koszu")
	_update_ui()

func _add_trade_buttons() -> void:
	var sell_cans := _add_mirek_button("SPRZEDAJ PUSZKI — 0,85 ZŁ/SZT.", _sell_cans_at_scrap)
	sell_cans.disabled = inventory.item_count("can") <= 0
	var sell_mesh := _add_mirek_button("SPRZEDAJ SIATKĘ — 8,00 ZŁ/SZT.", _sell_mesh_at_scrap)
	sell_mesh.disabled = inventory.item_count("mesh") <= 0
	var sell_wire := _add_mirek_button("SPRZEDAJ DRUT — 1,50 ZŁ/SZT.", _sell_wire_at_scrap)
	sell_wire.disabled = inventory.item_count("wire") <= 0
	for container_id in ["large_bag", "bucket"]:
		var definition: Dictionary = PlayerInventory.CONTAINERS[container_id]
		var owned := inventory.owned_containers.has(container_id)
		var text := "KUP %s — %s" % [String(definition.name).to_upper(), _money(float(definition.price))]
		if owned: text = String(definition.name).to_upper() + " — KUPIONE"
		var buy := _dialogue_button(text)
		buy.disabled = owned
		buy.pressed.connect(func() -> void: _buy_container(container_id))
		mirek_choices.add_child(buy)
	var durability := inventory.tool_durability("metal_shears")
	var missing := inventory.tool_max_durability("metal_shears") - durability
	var repair_cost := float(missing) * REPAIR_PRICE_PER_POINT
	var repair := _dialogue_button("NAPRAW NOŻYCE %d/%d — %s" % [durability, inventory.tool_max_durability("metal_shears"), _money(repair_cost)])
	repair.disabled = missing <= 0
	repair.pressed.connect(_repair_shears)
	mirek_choices.add_child(repair)

func _sell_cans_at_scrap() -> void:
	var amount := inventory.item_count("can")
	if amount <= 0: return
	inventory.remove_item("can", amount)
	cash += float(amount) * SCRAP_CAN_PRICE
	_consume_needs(LIGHT_ACTION_COST)
	_update_ui()
	_rebuild_mirek_ui()

func _sell_mesh_at_scrap() -> void:
	var amount := inventory.item_count("mesh")
	if amount <= 0: return
	inventory.remove_item("mesh", amount)
	cash += float(amount) * MESH_PRICE
	_consume_needs(LIGHT_ACTION_COST)
	_update_ui()
	_rebuild_mirek_ui()

func _sell_wire_at_scrap() -> void:
	var amount := inventory.item_count("wire")
	if amount <= 0: return
	inventory.remove_item("wire", amount)
	cash += float(amount) * WIRE_PRICE
	_consume_needs(LIGHT_ACTION_COST)
	_update_ui()
	_rebuild_mirek_ui()

func _buy_container(container_id: String) -> void:
	var price := float(PlayerInventory.CONTAINERS[container_id].price)
	if cash < price:
		_show_message("Nie masz wystarczająco pieniędzy.", true)
		return
	cash -= price
	inventory.add_container(container_id)
	inventory.equip_container(container_id)
	_update_ui()
	_rebuild_mirek_ui()

func _repair_shears() -> void:
	var missing := inventory.tool_max_durability("metal_shears") - inventory.tool_durability("metal_shears")
	var cost := float(missing) * REPAIR_PRICE_PER_POINT
	if missing <= 0: return
	if cash < cost:
		_show_message("Nie masz %s na naprawę." % _money(cost), true)
		return
	cash -= cost
	inventory.repair_tool("metal_shears")
	_update_ui()
	_rebuild_mirek_ui()

func _open_store() -> void:
	if not fab01_bag_picked:
		_show_message("Najpierw podnieś reklamówkę i sprawdź, ile brakuje.", true)
		return
	if not burek_defeated:
		_show_message("Burek pilnuje wejścia do Żuka Gnojarza. Musisz go najpierw pokonać.", true)
		return
	store_open = true
	player.set_physics_process(false)
	store_overlay.visible = true
	store_status_label.text = "Kup tylko to, czego naprawdę potrzebujesz."
	store_status_label.modulate = Color.WHITE
	_update_ui()
	call_deferred("_focus_first_enabled_button", store_overlay)

func _close_store(show_exit_message := true) -> void:
	store_open = false
	store_overlay.visible = false
	player.set_physics_process(true)
	if show_exit_message:
		_show_message("Wychodzisz ze sklepu.")

func _buy_beer() -> void:
	if alcohol_level >= 99.5:
		_set_store_status("Pasek alkoholu jest już pełny.", true); return
	if cash < BEER_COST:
		_set_store_status("Nie wystarczy na oba. Najpierw jeszcze jeden kurs.", true); return
	cash -= BEER_COST
	alcohol_level = minf(100.0, alcohol_level + BEER_RESTORE)
	alcohol_warning_shown = false
	fab01_bought_beer = true
	_set_store_status("Trochę ciszej w głowie. Papierosy jeszcze zostały." if not fab01_bought_cigarettes else "Obie potrzeby zaspokojone.")
	_update_ui()
	_check_fab01_needs()

func _buy_small_vodka() -> void:
	if alcohol_level >= 99.5:
		_set_store_status("Pasek alkoholu jest już pełny.", true); return
	if cash < SMALL_VODKA_COST:
		_set_store_status("Nie masz 7,50 zł na małpkę.", true); return
	cash -= SMALL_VODKA_COST
	alcohol_level = minf(100.0, alcohol_level + SMALL_VODKA_RESTORE)
	alcohol_warning_shown = false
	fab01_bought_beer = true
	_set_store_status("Małpka ucisza głód mocniej, ale kosztuje więcej.")
	_update_ui()
	_check_fab01_needs()

func _buy_cigarettes() -> void:
	if nicotine_level >= 99.5:
		_set_store_status("Pasek nikotyny jest już pełny.", true); return
	if cash < CIGARETTES_COST:
		_set_store_status("Nie wystarczy na oba. Najpierw jeszcze jeden kurs.", true); return
	cash -= CIGARETTES_COST
	nicotine_level = minf(100.0, nicotine_level + CIGARETTES_RESTORE)
	nicotine_warning_shown = false
	fab01_bought_cigarettes = true
	_set_store_status("Dobra, ręce mają zajęcie. Teraz trzeba uspokoić resztę." if not fab01_bought_beer else "Obie potrzeby zaspokojone.")
	_update_ui()
	_check_fab01_needs()

func _open_kiosk() -> void:
	if not fab01_bag_picked:
		_show_message("Najpierw podnieś reklamówkę i sprawdź, ile brakuje.", true)
		return
	kiosk_open = true
	player.set_physics_process(false)
	kiosk_overlay.visible = true
	kiosk_status_label.text = "W kiosku papierosy są tańsze niż w Żuku."
	kiosk_status_label.modulate = Color.WHITE
	_update_ui()
	call_deferred("_focus_first_enabled_button", kiosk_overlay)

func _close_kiosk(show_exit_message := true) -> void:
	kiosk_open = false
	kiosk_overlay.visible = false
	player.set_physics_process(true)
	if show_exit_message:
		_show_message("Odchodzisz od kiosku.")

func _buy_kiosk_cigarettes() -> void:
	if nicotine_level >= 99.5:
		_set_kiosk_status("Pasek nikotyny jest już pełny.", true); return
	if cash < KIOSK_CIGARETTES_COST:
		_set_kiosk_status("Nie masz 5,00 zł na papierosy.", true); return
	cash -= KIOSK_CIGARETTES_COST
	nicotine_level = minf(100.0, nicotine_level + CIGARETTES_RESTORE)
	nicotine_warning_shown = false
	fab01_bought_cigarettes = true
	_set_kiosk_status("Papierosy kupione. W Żuku zostało piwo.")
	_update_ui()
	_check_fab01_needs()

func _check_fab01_needs() -> void:
	if fab01_stage != FAB01_BUY_NEEDS or not fab01_bought_beer or not fab01_bought_cigarettes:
		return
	fab01_stage = FAB01_FIND_MIREK
	if store_open:
		_close_store(false)
	if kiosk_open:
		_close_kiosk(false)
	_show_message("Nie jest dobrze. Jest tylko ciszej. Pora zgłosić się do Mirka — stoi zwykle przy Żuku.")
	_update_ui()

func _complete_fab01() -> void:
	if fab01_stage != FAB01_FIND_MIREK:
		return
	fab01_stage = FAB01_COMPLETED
	_show_message("FAB-01 ukończone. Mirek czeka — zaczyna się FAB-02: Żuk, puszki i siatka.")
	_update_ui()

func _update_ui() -> void:
	if inventory_label == null or inventory == null:
		return
	money_label.text = _money(cash)
	if fab01_bag_picked:
		var quest_item_text := "  •  KLUCZ DO ŻUKA" if inventory.item_count("zuk_key") > 0 else ""
		inventory_label.text = "%s: %d/%d miejsc\n%.2f/%.1f kg  •  puszki: %d  •  siatka: %d  •  drut: %d%s" % [inventory.container_name().to_upper(), inventory.used_space(), inventory.capacity(), inventory.current_weight(), inventory.max_weight(), inventory.item_count("can"), inventory.item_count("mesh"), inventory.item_count("wire"), quest_item_text]
	else:
		inventory_label.text = "BRAK POJEMNIKA\nPodnieś reklamówkę leżącą obok bohatera."
	progression_label.text = "POZIOM %d  •  XP %d/%d  •  PUNKTY: %d" % [player_level, player_xp, _xp_for_next_level(), stat_points]
	health_label.text = "ŻYCIE: %d/%d" % [player_health, player_max_health]
	health_bar.max_value = player_max_health
	health_bar.value = player_health
	alcohol_label.text = "ALKOHOL: %d%%" % roundi(alcohol_level)
	nicotine_label.text = "NIKOTYNA: %d%%" % roundi(nicotine_level)
	alcohol_bar.value = alcohol_level
	nicotine_bar.value = nicotine_level
	if store_money_label != null:
		store_money_label.text = _money(cash)
		store_alcohol_bar.value = alcohol_level
		store_nicotine_bar.value = nicotine_level
	if kiosk_money_label != null:
		kiosk_money_label.text = _money(cash)
		kiosk_nicotine_bar.value = nicotine_level
	_update_fab01_objective()

func _update_fab01_objective() -> void:
	if objective_label == null:
		return
	match fab01_stage:
		FAB01_PICK_UP_BAG:
			objective_label.text = "FAB-01 — PIERWSZY KURS\nCEL: Podnieś reklamówkę."
		FAB01_BUY_NEEDS:
			var beer_mark := "✓" if fab01_bought_beer else "○"
			var cigarettes_mark := "✓" if fab01_bought_cigarettes else "○"
			objective_label.text = "FAB-01 — PIERWSZY KURS\nZbieraj i sprzedawaj puszki.\n%s Piwo 4,00 zł   %s Papierosy od 5,00 zł" % [beer_mark, cigarettes_mark]
		FAB01_FIND_MIREK:
			objective_label.text = "FAB-01 — PIERWSZY KURS\nCEL: Znajdź Mirka przy starym Żuku."
		FAB01_COMPLETED:
			if quest_state != QuestState.COMPLETED:
				match quest_state:
					QuestState.NOT_STARTED:
						objective_label.text = "FAB-02 — ŻUK, PUSZKI I SIATKA\nCEL: Porozmawiaj z Mirkiem."
					QuestState.NEED_CANS:
						objective_label.text = "FAB-02 — ŻUK, PUSZKI I SIATKA\nCEL: Oddaj Mirkowi 4 puszki (%d/4)." % inventory.item_count("can")
					QuestState.HAS_SHEARS:
						objective_label.text = "FAB-02 — ŻUK, PUSZKI I SIATKA\nCEL: Wytnij fragment oznaczonej siatki."
					QuestState.CUT_MESH:
						objective_label.text = "FAB-02 — ŻUK, PUSZKI I SIATKA\nCEL: Oddaj siatkę Mirkowi."
			elif not zul_defeated:
				objective_label.text = "FAB-02 — ŻUK, PUSZKI I SIATKA\nCEL: Pokonaj Żula blokującego Mirka."
			else:
				match heniek_quest_state:
					HeniekQuestState.NOT_STARTED:
						objective_label.text = "FAB-03 — ZAGUBIONY KLUCZ\nCEL: Zapytaj Mirka o nowe zlecenie."
					HeniekQuestState.FIND_HENIEK:
						objective_label.text = "FAB-03 — ZAGUBIONY KLUCZ\nCEL: Znajdź Heńka przy dolnych garażach."
					HeniekQuestState.NEED_WIRE:
						objective_label.text = "FAB-03 — ZAGUBIONY KLUCZ\nCEL: Przynieś Heńkowi 3 druty (%d/3)." % inventory.item_count("wire")
					HeniekQuestState.RETURN_KEY:
						objective_label.text = "FAB-03 — ZAGUBIONY KLUCZ\nCEL: Oddaj klucz Mirkowi."
					HeniekQuestState.COMPLETED:
						objective_label.text = "FAB-03 — ZAGUBIONY KLUCZ\nUKOŃCZONE  •  +15,00 zł  •  +35 XP"

func _show_message(text: String, danger := false) -> void:
	if message_label == null: return
	message_label.text = text
	message_label.modulate = Color("#ef8b67") if danger else Color.WHITE
	var tween := create_tween()
	tween.tween_interval(2.3)
	tween.tween_callback(func() -> void:
		if not _modal_open():
			message_label.text = "Strzałki / WASD — ruch  •  ENTER — akcja  •  I — ekwipunek"
			message_label.modulate = Color.WHITE
	)

func _set_store_status(text: String, danger := false) -> void:
	store_status_label.text = text
	store_status_label.modulate = Color("#ef8b67") if danger else Color("#b9d18e")

func _set_kiosk_status(text: String, danger := false) -> void:
	kiosk_status_label.text = text
	kiosk_status_label.modulate = Color("#ef8b67") if danger else Color("#b9d18e")

func _consume_needs(cost: float) -> void:
	# Zwykłe akcje są zawsze dozwolone, więc oba paski zatrzymują się na zerze.
	alcohol_level = maxf(0.0, alcohol_level - cost)
	nicotine_level = maxf(0.0, nicotine_level - cost)
	alcohol_warning_shown = alcohol_level <= 0.0
	nicotine_warning_shown = nicotine_level <= 0.0
	_update_ui()

func _add_mirek_button(text: String, callback: Callable) -> Button:
	var button := _dialogue_button(text)
	button.pressed.connect(callback)
	mirek_choices.add_child(button)
	return button

func _dialogue_button(text: String) -> Button:
	var button := _menu_button(text)
	button.custom_minimum_size = Vector2(385, 40)
	button.add_theme_font_size_override("font_size", 12)
	return button

func _start_mirek_line(text: String) -> void:
	mirek_dialogue_label.text = text
	mirek_dialogue_label.visible_characters = 0
	mirek_choices.visible = false
	var duration := clampf(float(text.length()) / 42.0, 0.7, 3.6)
	mirek_text_tween = create_tween()
	mirek_text_tween.tween_property(mirek_dialogue_label, "visible_characters", text.length(), duration)
	mirek_text_tween.tween_callback(_finish_mirek_line)

func _finish_mirek_line() -> void:
	if mirek_dialogue_label == null or not is_instance_valid(mirek_dialogue_label):
		return
	if mirek_text_tween != null and mirek_text_tween.is_valid():
		mirek_text_tween.kill()
	mirek_dialogue_label.visible_characters = -1
	if mirek_choices != null and is_instance_valid(mirek_choices):
		mirek_choices.visible = true
		call_deferred("_focus_first_enabled_button", mirek_choices)

func _on_mirek_text_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_mirek_line()

func _classic_dialogue_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#111927f5")
	style.border_color = Color("#d7c38d")
	style.set_border_width_all(4)
	style.set_content_margin_all(14)
	style.shadow_color = Color("#05070acc")
	style.shadow_size = 10
	return style

func _portrait_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#293342")
	style.border_color = Color("#66758a")
	style.set_border_width_all(2)
	style.set_content_margin_all(3)
	return style

func _dialogue_text_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color("#0a101bcc")
	style.border_color = Color("#4f6178")
	style.set_border_width_all(2)
	style.set_content_margin_all(10)
	return style

func _clear_container(container: Container) -> void:
	for child in container.get_children():
		container.remove_child(child)
		child.queue_free()

func _modal_overlay(canvas: CanvasLayer, node_name: String) -> Control:
	var overlay := Control.new()
	overlay.name = node_name
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	overlay.visible = false
	canvas.add_child(overlay)
	var shade := ColorRect.new()
	shade.color = Color("#0b0d0be6")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(shade)
	return overlay

func _modal_panel(overlay: Control, position: Vector2, size: Vector2) -> PanelContainer:
	var panel := PanelContainer.new()
	panel.position = position
	panel.custom_minimum_size = size
	panel.add_theme_stylebox_override("panel", _panel_style(Color("#242822")))
	overlay.add_child(panel)
	return panel

func _money(value: float) -> String:
	return ("%.2f zł" % value).replace(".", ",")

func _label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label

func _wrapped_label(text: String, font_size: int) -> Label:
	var label := _label(text, font_size, Color("#eee6d7"))
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.custom_minimum_size = Vector2(570, 92)
	return label

func _need_bar(fill_color: Color) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 100.0
	bar.show_percentage = false
	bar.custom_minimum_size = Vector2(290, 14)
	var background := StyleBoxFlat.new()
	background.bg_color = Color("#111411")
	background.set_corner_radius_all(2)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(2)
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)
	return bar

func _menu_button(text: String) -> Button:
	var button := Button.new()
	button.text = text
	button.focus_mode = Control.FOCUS_ALL
	button.custom_minimum_size = Vector2(480, 54)
	button.add_theme_font_size_override("font_size", 14)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#343931")
	normal.border_color = Color("#5e6559")
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(3)
	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color("#755f35")
	var focused: StyleBoxFlat = hover.duplicate()
	focused.border_color = Color("#f1cf78")
	focused.set_border_width_all(3)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", focused)
	return button

func _panel_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.border_color = Color("#5b5e55")
	style.set_border_width_all(1)
	style.set_content_margin_all(12)
	style.set_corner_radius_all(3)
	return style

func _show_fab01_intro() -> void:
	var canvas := CanvasLayer.new()
	canvas.name = "WprowadzenieFAB01"
	canvas.layer = 31
	add_child(canvas)
	fab01_intro_overlay = Control.new()
	fab01_intro_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(fab01_intro_overlay)
	var shade := ColorRect.new()
	shade.color = Color("#080908f7")
	shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	fab01_intro_overlay.add_child(shade)
	var panel := PanelContainer.new()
	panel.position = Vector2(235, 125)
	panel.custom_minimum_size = Vector2(810, 470)
	panel.add_theme_stylebox_override("panel", _classic_dialogue_style())
	fab01_intro_overlay.add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 16)
	panel.add_child(box)
	var title := _label("FAB-01 — PIERWSZY KURS", 26, Color("#efb647"))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var ambience := _label("[ autobus za oknem  •  szczekanie psa  •  metaliczny stuk śmietnika ]", 12, Color("#8e968d"))
	ambience.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(ambience)
	box.add_child(HSeparator.new())
	var line := _wrapped_label("Łeb mi pęka. W ustach jakbym spał pod kaloryferem. Najpierw piwo i papierosy, potem będę udawał, że to normalny dzień.", 19)
	line.custom_minimum_size = Vector2(750, 105)
	line.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	line.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	box.add_child(line)
	var tutorial := _wrapped_label("Alkohol i nikotyna spadają za wykonane akcje, nie za czas. Puszki podniesiesz i sprzedasz nawet przy zerze; cięcie siatki wymaga co najmniej 5 punktów obu potrzeb.", 15)
	tutorial.custom_minimum_size = Vector2(750, 80)
	tutorial.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(tutorial)
	var start_button := _menu_button("WSTAŃ I PODNIEŚ REKLAMÓWKĘ")
	start_button.pressed.connect(_begin_fab01_gameplay)
	box.add_child(start_button)
	start_button.grab_focus()

func _begin_fab01_gameplay() -> void:
	if fab01_intro_overlay != null and is_instance_valid(fab01_intro_overlay):
		fab01_intro_overlay.get_parent().queue_free()
		fab01_intro_overlay = null
	gameplay_active = true
	player.set_physics_process(true)
	_show_message("Podejdź do reklamówki i naciśnij Enter.")
	_update_ui()

func _show_loading_screen() -> void:
	player.set_physics_process(false)
	var canvas := CanvasLayer.new()
	canvas.name = "EkranLadowania"
	canvas.layer = 30
	add_child(canvas)
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	var background := ColorRect.new()
	background.color = Color("#171714")
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(background)
	var art := TextureRect.new()
	art.texture = LOADING_ART
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.add_child(art)
	var text := _label("ZBIERAMY GRATY...", 24, Color("#efb647"))
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	text.offset_top = -80
	text.offset_bottom = -36
	overlay.add_child(text)
	await get_tree().create_timer(1.2).timeout
	var tween := create_tween()
	tween.tween_property(overlay, "modulate:a", 0.0, 0.45)
	await tween.finished
	canvas.queue_free()
	_show_fab01_intro()
