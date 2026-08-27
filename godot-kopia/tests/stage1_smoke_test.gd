extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	_expect(game.fab01_stage == game.FAB01_PICK_UP_BAG, "FAB-01 zaczyna się od podniesienia reklamówki")
	var guaranteed_cans := 0
	for child in game.get_children():
		if child.name.begins_with("Puszka"):
			guaranteed_cans += 1
	_expect(guaranteed_cans >= 24, "Powiększona mapa ma co najmniej 24 puszki")
	_expect(game.trash_bins.size() >= 4, "Na mapie są co najmniej 4 grupy kontenerów")
	_expect(WorldMap.WORLD_SIZE == Vector2(2800, 1600), "Mapa została powiększona do 2800 na 1600")
	_expect(game.get_node("Osiedle/ZukGnojarz") is Sprite2D, "Żuk Gnojarz jest osobnym budynkiem na mapie")
	_expect(game.get_node("Osiedle/Kiosk") is Sprite2D, "Kiosk jest osobnym budynkiem na mapie")
	_expect(game.get_node("Osiedle/ZukMirkaSprite") is Sprite2D, "Za Mirkiem stoi osobny sprite starego Żuka")
	_expect(game.get_node("Osiedle/SkrzynkaPuszekMirkaA") is Sprite2D, "Przy Mirku stoi osobna skrzynka puszek")
	_expect(game.get_node("Osiedle/SkrzynkaZlomuMirkaA") is Sprite2D, "Przy Mirku stoi osobna skrzynka złomu")
	_expect(game.get_node("Osiedle/ZukMirka") is StaticBody2D, "Żuk za Mirkiem ma kolizję")
	_expect(game.get_node("Osiedle/SkrzynkiMirkaLewe") is StaticBody2D and game.get_node("Osiedle/SkrzynkiMirkaPrawe") is StaticBody2D, "Skrzynki tworzą dwa boki jedynego dojścia do Mirka")
	_expect(game.get_node("OkienkoKiosku") is Area2D, "Kiosk ma interaktywne okienko")
	var zul_1 := game.get_node("Zul1") as MapResident
	var burek := game.get_node("Burek") as MapResident
	_expect(game.y_sort_enabled, "Główna scena sortuje postacie według pozycji na osi Y")
	_expect(game.player.z_index == zul_1.z_index and game.player.z_index == burek.z_index, "Bohater, Żul 1 i Burek dzielą warstwę potrzebną do sortowania Y")
	_expect(zul_1.position == game._map_marker_position("StanyNPC/ZulCzeka", game.ZUL_WAIT_POSITION) and not zul_1.fightable, "Żul 1 czeka z boku do zakończenia zlecenia z siatką")
	_expect(burek.position == game._map_marker_position("StanyNPC/BurekStart", game.BUREK_DOOR_POSITION), "Burek stoi dokładnie w świetle drzwi Żuka Gnojarza")
	_expect(zul_1.get_node("MapaSprite") is AnimatedSprite2D and burek.get_node("MapaSprite") is AnimatedSprite2D, "Obie nowe postacie korzystają z animowanych sprite'ów")
	var zul_sprite := zul_1.get_node("MapaSprite") as AnimatedSprite2D
	var burek_sprite := burek.get_node("MapaSprite") as AnimatedSprite2D
	_expect(zul_sprite.sprite_frames.get_frame_count("idle") == 4, "Żul 1 ma cztery klatki animacji bezczynności")
	_expect(burek_sprite.sprite_frames.get_frame_count("idle") == 4, "Burek ma cztery klatki animacji bezczynności")
	_expect(zul_sprite.is_playing() and burek_sprite.is_playing(), "Animacje Żula 1 i Burka odtwarzają się na mapie")
	_expect(zul_1.sprite_scale > burek.sprite_scale, "Burek ma mniejszą skalę mapową niż Żul 1")
	_expect(zul_1.frame_anchors.size() == 4 and burek.frame_anchors.size() == 4, "Każda klatka obu NPC ma osobną kotwicę")
	for resident in [zul_1, burek]:
		var resident_sprite := resident.get_node("MapaSprite") as AnimatedSprite2D
		var resident_frame_size: Vector2i = resident._frame_size()
		for frame_index in range(4):
			resident_sprite.frame = frame_index
			resident._apply_frame_alignment(resident_sprite)
			var anchor: Vector2 = resident.frame_anchors[frame_index]
			var aligned_anchor := resident_sprite.offset + anchor - Vector2(resident_frame_size) * 0.5
			_expect(aligned_anchor.length() < 0.01, "%s: klatka %d trzyma środek głowy i podstawę w punkcie mapy" % [resident.name, frame_index])
	var zul_image := (zul_sprite.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture).atlas.get_image()
	var burek_image := (burek_sprite.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture).atlas.get_image()
	_expect(zul_image.get_used_rect().size.x < zul_image.get_width(), "Sprite Żula 1 ma prawdziwe przezroczyste tło")
	_expect(burek_image.get_used_rect().size.x < burek_image.get_width(), "Sprite Burka ma prawdziwe przezroczyste tło")
	for prop_name in ["ZukMirkaSprite", "SkrzynkaPuszekMirkaA", "SkrzynkaZlomuMirkaA"]:
		var prop := game.get_node("Osiedle/" + prop_name) as Sprite2D
		var prop_image := prop.texture.get_image()
		_expect(prop_image.get_used_rect().size.x < prop_image.get_width(), "%s ma prawdziwe przezroczyste tło" % prop_name)
	var camera := game.player.get_node("Kamera") as Camera2D
	_expect(camera.limit_right == 2800 and camera.limit_bottom == 1600, "Kamera obejmuje całą powiększoną mapę")
	game.gameplay_active = true
	game._update_pickup_focus()
	_expect(game.starter_bag.interaction_focused, "Najbliższa reklamówka podświetla się, gdy bohater jest obok")
	_expect(game.interaction_hint_label.visible, "HUD pokazuje nierotującą się podpowiedź klawisza Enter")
	_expect(game._try_pick_up_nearby_item(), "Enter może podnieść najbliższą reklamówkę")
	await process_frame
	_expect(game.fab01_bag_picked and game.fab01_stage == game.FAB01_BUY_NEEDS, "Podniesienie reklamówki uruchamia cel zakupów")
	var nearby_can = game.get_node("Puszka3")
	game._update_pickup_focus()
	_expect(nearby_can.interaction_focused, "Tylko najbliższa puszka otrzymuje podświetlenie")
	var focused_count := 0
	for pickup in game.get_tree().get_nodes_in_group("pickup_item"):
		if pickup.interaction_focused:
			focused_count += 1
	_expect(focused_count == 1, "Jednocześnie podświetlony jest dokładnie jeden przedmiot")
	var player_position: Vector2 = game.player.position
	game.player.position = Vector2(50, 50)
	game._update_pickup_focus()
	_expect(not nearby_can.interaction_focused, "Podświetlenie znika po odejściu od puszki")
	_expect(not game.interaction_hint_label.visible, "Podpowiedź Enter znika poza zasięgiem przedmiotów")
	game.player.position = player_position
	var alcohol_before_wait: float = game.alcohol_level
	var nicotine_before_wait: float = game.nicotine_level
	game._process(20.0)
	_expect(is_equal_approx(game.alcohol_level, alcohol_before_wait) and is_equal_approx(game.nicotine_level, nicotine_before_wait), "Potrzeby nie spadają od samego upływu czasu")
	_expect(game._try_pick_up_nearby_item(), "Enter rozpoczyna podnoszenie najbliższej puszki")
	await create_timer(0.35).timeout
	_expect(game.inventory.item_count("can") == 1, "Puszka podniesiona Enterem trafia do ekwipunku")
	_expect(is_equal_approx(game.alcohol_level, alcohol_before_wait - 1.0) and is_equal_approx(game.nicotine_level, nicotine_before_wait - 1.0), "Podniesienie puszki kosztuje po 1 punkcie obu potrzeb")
	game.inventory.remove_item("can", 1)
	game.player._finish_action()
	for i in range(6):
		_expect(game.inventory.add_item("can"), "Puszka %d mieści się w reklamówce" % (i + 1))
	_expect(not game.inventory.can_add("can"), "Pełna reklamówka blokuje siódmą puszkę")
	game.cash = 5.0
	game.alcohol_level = 0.0
	game.nicotine_level = 0.0
	game._on_machine_sell_requested()
	_expect(game.inventory.item_count("can") == 0, "Automat opróżnia reklamówkę")
	_expect(is_equal_approx(game.cash, 8.6), "Automat wypłaca 0,60 zł za puszkę")
	_expect(game.alcohol_level == 0.0 and game.nicotine_level == 0.0, "Puszki można sprzedać przy zerowych paskach potrzeb")
	game.alcohol_level = 40.0
	game._buy_beer()
	_expect(is_equal_approx(game.cash, 4.6), "Piwo kosztuje 4,00 zł")
	_expect(is_equal_approx(game.alcohol_level, 75.0), "Piwo uzupełnia alkohol o 35")
	game.cash = 10.0
	game.nicotine_level = 30.0
	game._open_store()
	game._buy_cigarettes()
	_expect(is_equal_approx(game.cash, 4.5), "Papierosy kosztują 5,50 zł")
	_expect(is_equal_approx(game.nicotine_level, 72.0), "Papierosy uzupełniają nikotynę o 42")
	_expect(game.fab01_stage == game.FAB01_FIND_MIREK, "Kupienie obu używek kieruje gracza do Mirka")
	_expect(not game.store_open, "Po zaspokojeniu obu potrzeb bohater automatycznie wychodzi ze sklepu")
	var mirek = game.get_node("Mirek")
	game.player.position = mirek.position
	game._update_interaction_focus()
	_expect(game.focused_interactable == mirek, "Mirek staje się najbliższą akcją klawiaturową")
	_expect(game.interaction_hint_label.text.contains("POROZMAWIAJ"), "HUD podpowiada rozmowę klawiszem Enter")
	_expect(game._try_interact_nearby(), "Enter rozpoczyna rozmowę z Mirkiem")
	_expect(game.fab01_stage == game.FAB01_COMPLETED, "Pierwsza rozmowa z Mirkiem kończy FAB-01")
	_expect(game.mirek_open, "Po zakupach Enter przy Mirku od razu otwiera rozmowę")
	game._finish_mirek_line()
	await process_frame
	_expect(game.get_viewport().gui_get_focus_owner() is Button, "Opcje dialogowe otrzymują fokus klawiatury")
	game._close_mirek()
	var door = game.get_node("WejscieDoSklepu")
	game.player.position = door.position
	game._update_interaction_focus()
	_expect(game.focused_interactable == door, "Drzwi sklepu są dostępne jako akcja Enter")
	_expect(game._try_interact_nearby(), "Enter wykonuje próbę wejścia do sklepu")
	_expect(not game.store_open, "Burek blokuje sklep przed pierwszym zwycięstwem")
	game.burek_defeated = true
	game._update_interaction_focus()
	_expect(game._try_interact_nearby(), "Po pokonaniu Burka Enter otwiera sklep")
	await process_frame
	_expect(game.store_open and not game.player.is_physics_processing(), "Sklep zatrzymuje ruch")
	var first_focus := game.get_viewport().gui_get_focus_owner()
	_expect(first_focus is Button, "Pierwsza opcja sklepu otrzymuje fokus klawiatury")
	game._move_menu_focus(1)
	_expect(game.get_viewport().gui_get_focus_owner() != first_focus, "W menu można zmieniać opcje klawiaturą")
	game._close_store()
	_expect(not game.store_open and game.player.is_physics_processing(), "Wyjście przywraca ruch")
	var kiosk = game.get_node("OkienkoKiosku")
	game.player.position = kiosk.position
	game._update_interaction_focus()
	_expect(game.focused_interactable == kiosk, "Okienko kiosku jest dostępne jako akcja Enter")
	_expect(game._try_interact_nearby(), "Enter otwiera kiosk")
	_expect(game.kiosk_open and not game.player.is_physics_processing(), "Kiosk zatrzymuje ruch")
	game.cash = 5.0
	game.nicotine_level = 20.0
	game._buy_kiosk_cigarettes()
	_expect(is_equal_approx(game.cash, 0.0) and is_equal_approx(game.nicotine_level, 62.0), "Kiosk sprzedaje tańsze papierosy za 5,00 zł")
	game._close_kiosk()
	_finish("STAGE1_TEST")

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _finish(test_name: String) -> void:
	if failures == 0: print(test_name + "_OK")
	else: printerr(test_name + "_FAILED: %d" % failures)
	quit(failures)
