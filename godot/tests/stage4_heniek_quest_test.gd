extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	game.gameplay_active = true
	game.fab01_bag_picked = true
	game.fab01_stage = game.FAB01_COMPLETED
	game.quest_state = game.QuestState.COMPLETED
	game.zul_defeated = true
	game.zul_npc.set_fight_enabled(false)
	game._update_ui()

	var heniek := game.get_node("Heniek") as MapResident
	_expect(heniek != null and heniek.talkable, "Heniek Mechanik jest rozmownym NPC na mapie")
	_expect(heniek.position == Vector2(1210, 1335), "Heniek stoi przy dolnych garażach")
	var sprite := heniek.get_node("MapaSprite") as AnimatedSprite2D
	_expect(sprite.sprite_frames.get_frame_count("idle") == 4, "Heniek ma cztery klatki animacji bezczynności")
	_expect(sprite.is_playing(), "Animacja Heńka odtwarza się na mapie")
	var heniek_image := (sprite.sprite_frames.get_frame_texture("idle", 0) as AtlasTexture).atlas.get_image()
	_expect(heniek_image.get_used_rect().size.x < heniek_image.get_width(), "Sprite Heńka ma prawdziwe przezroczyste tło")
	var guaranteed_wire_bins := 0
	for trash in game.trash_bins:
		if trash.guaranteed_wire:
			guaranteed_wire_bins += 1
	_expect(guaranteed_wire_bins == 3, "Trzy dalsze kontenery gwarantują drut potrzebny do zlecenia")

	game._open_mirek()
	game._start_heniek_quest()
	_expect(game.heniek_quest_state == game.HeniekQuestState.FIND_HENIEK, "Mirek uruchamia FAB-03 — Zagubiony klucz")
	_expect(game.objective_label.text.contains("Znajdź Heńka"), "HUD prowadzi gracza do Heńka")
	game._close_mirek()

	game.player.position = heniek.position
	game._update_interaction_focus()
	_expect(game.focused_interactable == heniek, "Heniek jest dostępny przez Enter")
	_expect(game.interaction_hint_label.text.contains("HEŃKIEM"), "HUD pokazuje rozmowę z Heńkiem")
	_expect(game._try_interact_nearby(), "Enter otwiera rozmowę z Heńkiem")
	_expect(game.heniek_open and game.heniek_overlay.visible, "Heniek ma osobny ekran rozmowy")
	game._accept_heniek_deal()
	_expect(game.heniek_quest_state == game.HeniekQuestState.NEED_WIRE, "Heniek prosi o trzy kawałki drutu")
	for _index in range(3):
		_expect(game.inventory.add_item("wire"), "Drut mieści się w początkowej reklamówce")
	game._give_wire_to_heniek()
	_expect(game.heniek_quest_state == game.HeniekQuestState.RETURN_KEY, "Oddanie drutu odblokowuje powrót do Mirka")
	_expect(game.inventory.item_count("wire") == 0 and game.inventory.item_count("zuk_key") == 1, "Heniek wymienia trzy druty na klucz do Żuka")
	_expect(game.inventory.used_space() == 0 and is_zero_approx(game.inventory.current_weight()), "Klucz jest przedmiotem fabularnym bez miejsca i wagi")
	game._close_heniek()

	var cash_before: float = game.cash
	game._open_mirek()
	game._return_zuk_key()
	_expect(game.heniek_quest_state == game.HeniekQuestState.COMPLETED, "Oddanie klucza kończy FAB-03")
	_expect(is_equal_approx(game.cash, cash_before + 15.0), "Mirek płaci 15 zł za odzyskanie klucza")
	_expect(game.player_level == 2 and game.player_xp == 10, "Nagroda 35 XP daje pierwszy awans i zachowuje nadwyżkę")
	_expect(game.inventory.item_count("zuk_key") == 0, "Klucz znika z ekwipunku po oddaniu")
	_expect(game.objective_label.text.contains("UKOŃCZONE"), "HUD oznacza FAB-03 jako ukończone")
	_finish("STAGE4_HENIEK_QUEST_TEST")

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _finish(test_name: String) -> void:
	if failures == 0:
		print(test_name + "_OK")
	else:
		printerr(test_name + "_FAILED: %d" % failures)
	quit(failures)
