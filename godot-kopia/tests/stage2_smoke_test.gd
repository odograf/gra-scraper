extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.fab01_bag_picked = true
	game.fab01_stage = game.FAB01_COMPLETED
	# Bohater używa kanonicznego arkusza chodu 3 na 4.
	_expect(game.player.sprite.sprite_frames.get_frame_count("idle_down") == 1, "Bezruch bohatera używa środkowej klatki")
	_expect(game.player.sprite.sprite_frames.get_frame_count("walk_down") == 4, "Chód bohatera używa cyklu 0-1-2-1")
	_expect(game.player.sprite.sprite_frames.get_animation_speed("pickup_down") >= 9.0, "Podnoszenie puszki jest szybkie")
	_expect(game.player.sprite.sprite_frames.get_animation_speed("walk_down") >= 9.0, "Cykl chodu pozostaje płynny")
	game.player.sprite.play("walk_down")
	game.player.sprite.frame = 3
	game.player._update_animation(Vector2.RIGHT)
	_expect(game.player.sprite.animation == "walk_right" and game.player.sprite.frame == 3, "Zmiana kierunku nie restartuje fazy kroku")
	_expect(game.player.LOCOMOTION_SHEET.get_size() == Vector2(1287, 1220), "Kanoniczny arkusz dokładnie mieści siatkę 3 na 4")
	_expect(game.player.LOCOMOTION_FRAME_SIZE == Vector2i(429, 305), "Arkusz jest dzielony na 3 kolumny i 4 kierunki")
	_expect(game.player.LOCOMOTION_SHEET.resource_path.ends_with("collector_walk_sheet_v3_canonical.png"), "Bohater używa wyrównanego arkusza kanonicznego")
	var locomotion_image: Image = game.player.LOCOMOTION_SHEET.get_image()
	_expect(locomotion_image.get_pixel(0, 0).a == 0.0, "Arkusz ma prawdziwe przezroczyste tło")
	for row in range(4):
		var frame_hashes := {}
		for column in range(3):
			var frame_region := locomotion_image.get_region(Rect2i(column * 429, row * 305, 429, 305))
			frame_hashes[hash(frame_region.get_data())] = true
		_expect(frame_hashes.size() == 3, "Każdy kierunek zachowuje 3 oryginalne pozy")
	for direction in game.player.DIRECTIONS:
		game.player.sprite.play("walk_" + direction)
		game.player._apply_frame_alignment()
		_expect(game.player.sprite.scale == Vector2(0.37, 0.37), "Skala postaci nie zmienia się między kierunkami")
	_expect(game.player.sprite.sprite_frames.get_frame_count("rummage_down") == 4, "Grzebanie w koszu ma 4 klatki")
	_expect(game.player.sprite.sprite_frames.get_frame_count("pickup_down") == 4, "Podnoszenie puszki ma 4 klatki")
	_expect(game.player.play_action("pickup", game.player.global_position + Vector2.DOWN), "Można uruchomić animację podnoszenia")
	_expect(game.player.is_action_busy(), "Animacja akcji chwilowo blokuje ruch")
	game.player._finish_action()
	_expect(not game.player.is_action_busy(), "Po animacji bohater odzyskuje ruch")
	# Każda klatka Mirka musi zachować ten sam punkt stóp i środka głowy.
	var mirek = game.get_node("Mirek")
	_expect(mirek.sprite.sprite_frames.get_animation_speed("idle") >= 3.4, "Animacja bezruchu Mirka jest szybsza")
	_expect(mirek.sprite.sprite_frames.get_animation_speed("smoke") >= 4.8, "Animacja palenia Mirka jest szybsza")
	var frame_center := Vector2(mirek.FRAME_SIZE) * 0.5
	for animation_name in ["idle", "smoke"]:
		mirek.sprite.animation = animation_name
		var row := 1 if animation_name == "smoke" else 0
		for frame_index in range(4):
			mirek.sprite.frame = frame_index
			mirek._apply_frame_alignment()
			var anchor: Vector2 = mirek.frame_anchors[Vector2i(frame_index, row)]
			var anchored_position: Vector2 = mirek.sprite.position + (anchor - frame_center + mirek.sprite.offset) * mirek.sprite.scale
			_expect(anchored_position.length() < 0.01, "Mirek nie przesuwa się między klatkami animacji")
	# Drop: zawsze 1–3 puszki i około 25% szansy na drut.
	var rng := RandomNumberGenerator.new()
	rng.seed = 20260824
	var wire_hits := 0
	for i in range(1000):
		var loot := TrashSearch.generate_loot(rng)
		_expect(int(loot.can) >= 1 and int(loot.can) <= 3, "Kosz losuje od 1 do 3 puszek")
		wire_hits += int(loot.wire)
	_expect(wire_hits >= 180 and wire_hits <= 320, "Szansa na drut wynosi około 25 procent")
	game.trash_bin.set_test_loot(3, 1)
	game._search_trash(game.trash_bin)
	_expect(game.inventory.item_count("can") == 3, "Przeszukanie kosza dodaje puszki")
	_expect(game.inventory.item_count("wire") == 1, "Przeszukanie kosza może dodać drut")
	game.inventory.items = {"can": 0, "mesh": 0, "wire": 0}
	# Prawdziwe kliknięcie nie może zamykać ani wygaszać okna Mirka.
	game._open_mirek()
	var accept_button := _find_button(game.mirek_content, "PRZYJMIJ ZADANIE")
	_expect(accept_button != null, "Przycisk przyjęcia zadania istnieje")
	if accept_button != null:
		accept_button.pressed.emit()
		await process_frame
		_expect(game.mirek_overlay.visible, "Okno Mirka pozostaje widoczne po kliknięciu")
		_expect(_find_button(game.mirek_content, "ODDAJ 4 PUSZKI") != null, "Treść rozmowy jest przebudowana po kliknięciu")
	game._close_mirek()
	game.quest_state = game.QuestState.NOT_STARTED
	var space_before: int = game.inventory.used_space()
	var weight_before: float = game.inventory.current_weight()
	game.inventory.add_tool("metal_shears", 6)
	_expect(game.inventory.used_space() == space_before, "Nożyce nie zajmują miejsca")
	_expect(is_equal_approx(game.inventory.current_weight(), weight_before), "Nożyce nie zwiększają wagi")
	game.inventory.tools.clear()
	for i in range(4): game.inventory.add_item("can")
	game._start_mirek_quest()
	game._deliver_quest_cans()
	_expect(game.quest_state == game.QuestState.HAS_SHEARS, "Mirek wydaje nożyce po oddaniu puszek")
	_expect(game.inventory.has_tool("metal_shears"), "Nożyce trafiają do osobnego wyposażenia")
	_expect(game.inventory.used_space() == 0, "Oddane puszki zwalniają reklamówkę")
	game.zul_defeated = false
	game._open_mirek()
	_expect(game.mirek_open, "Żul 1 nie blokuje zadania zaraz po otrzymaniu nożyc")
	game._close_mirek()
	var fence = game.get_node("SiatkaDoWyciecia")
	game.alcohol_level = 4.0
	game.nicotine_level = 100.0
	game._start_cutting(fence)
	_expect(game.active_fence == null, "Cięcie jest zablokowane, gdy choć jeden pasek ma mniej niż 5 punktów")
	game.alcohol_level = 10.0
	game.nicotine_level = 10.0
	game._start_cutting(fence)
	game._complete_cutting()
	_expect(game.inventory.item_count("mesh") == 1, "Wycinanie dodaje fragment siatki")
	_expect(game.alcohol_level == 5.0 and game.nicotine_level == 5.0, "Udane cięcie kosztuje po 5 punktów obu potrzeb")
	_expect(game.inventory.tool_durability("metal_shears") == 5, "Nożyce tracą 1 trwałości")
	_expect(game.quest_state == game.QuestState.CUT_MESH, "Zadanie przechodzi do oddania siatki")
	game.cash = 5.0
	game._finish_mirek_quest()
	_expect(game.quest_state == game.QuestState.COMPLETED, "Oddanie siatki kończy zadanie")
	_expect(is_equal_approx(game.cash, 13.0), "Mirek płaci 8 zł za pierwszą siatkę")
	_expect(game.zul_npc.fightable, "Po oddaniu siatki Żul 1 staje się przeciwnikiem blokującym handel drutem")
	await create_timer(0.7).timeout
	_expect(game.zul_npc.position.is_equal_approx(game._map_marker_position("StanyNPC/ZulBlokuje", game.ZUL_BLOCK_POSITION)), "Żul 1 wchodzi w jedyne przejście do Mirka")
	game._open_mirek()
	_expect(not game.mirek_open, "Nie można oddać drutu, dopóki Żul 1 blokuje Mirka")
	game.zul_defeated = true
	game.zul_npc.set_fight_enabled(false)
	game._open_mirek()
	_expect(game.mirek_open, "Po pokonaniu Żula 1 można handlować z Mirkiem")
	game._close_mirek()
	game.cash = 30.0
	game._buy_container("large_bag")
	_expect(game.inventory.owned_containers.has("large_bag"), "Duża torba zostaje kupiona")
	_expect(game.inventory.equipped_container == "large_bag", "Kupiony pojemnik jest zakładany")
	_expect(game.inventory.capacity() == 12, "Duża torba ma 12 miejsc")
	game._repair_shears()
	_expect(game.inventory.tool_durability("metal_shears") == 6, "Mirek naprawia nożyce")
	_finish("STAGE2_TEST")

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _find_button(node: Node, text: String) -> Button:
	if node is Button and node.text == text:
		return node
	for child in node.get_children():
		var result := _find_button(child, text)
		if result != null:
			return result
	return null

func _finish(test_name: String) -> void:
	if failures == 0: print(test_name + "_OK")
	else: printerr(test_name + "_FAILED: %d" % failures)
	quit(failures)
