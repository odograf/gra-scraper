extends SceneTree

const MainScene := preload("res://scenes/main.tscn")
const MainMenuScene := preload("res://scenes/main_menu.tscn")
const SaveManagerScript := preload("res://scripts/save_manager.gd")

var failures: Array[String] = []
var save_manager: GameSaveManager

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	save_manager = root.get_node_or_null("SaveManager") as GameSaveManager
	if save_manager == null:
		save_manager = SaveManagerScript.new() as GameSaveManager
		save_manager.name = "SaveManager"
		root.add_child(save_manager)
	var original_prefix: String = save_manager.save_prefix
	save_manager.save_prefix = "/private/tmp/zlomiarz_rpg_test_slot_"
	_cleanup_test_saves()

	var menu := MainMenuScene.instantiate()
	root.add_child(menu)
	await process_frame
	_expect(menu.main_box != null and menu.load_box != null, "Menu główne ma wybór nowej gry i wczytywania")
	_expect(menu.NEW_GAME_SCENE == "res://scenes/melina_prologue_mockup.tscn", "Nowa gra z menu zaczyna się w melinie")
	menu.queue_free()
	await process_frame

	var game := MainScene.instantiate()
	root.add_child(game)
	await process_frame
	game.gameplay_active = true
	game.fab01_bag_picked = true
	game.cash = 37.25
	game.alcohol_level = 61.0
	game.nicotine_level = 42.0
	game.player.global_position = Vector2(1234, 987)
	game.inventory.add_item("dog_collar", 2)
	game.inventory.equip_bag_weapon("black_sack")
	game.player_state.set_health(73)
	var snapshot: Dictionary = game._build_save_data()
	_expect(save_manager.save_game(2, snapshot), "Zapis do wybranego slotu działa")
	_expect(save_manager.has_save(2), "Slot wykrywa istniejący zapis")
	var summary: Dictionary = save_manager.slot_summary(2)
	_expect(bool(summary.get("exists", false)) and int(summary.get("level", 0)) == 1, "Menu potrafi odczytać opis slotu")
	_expect(save_manager.request_load(2), "Wczytanie wybranego slotu działa")
	var loaded: Dictionary = save_manager.consume_pending_load()
	_expect(not loaded.is_empty() and int(loaded.get("version", 0)) == GameSaveManager.SAVE_VERSION, "Zapis jest wersjonowany")

	game.cash = 0.0
	game.inventory.items["dog_collar"] = 0
	game.inventory.equip_bag_weapon("plastic_bag")
	game.player_state.set_health(1)
	game._restore_save_data(loaded)
	_expect(is_equal_approx(game.cash, 37.25), "Gotówka wraca po wczytaniu")
	_expect(game.inventory.item_count("dog_collar") == 2, "Ekwipunek wraca po wczytaniu")
	_expect(game.inventory.equipped_bag_weapon == "black_sack", "Wybrana broń torbowa wraca po wczytaniu")
	_expect(game.player.equipped_bag_weapon == &"black_sack", "Warstwa broni bohatera synchronizuje się z zapisem")
	_expect(game.player_health == 73, "Zdrowie wraca po wczytaniu")
	_expect(game.player.global_position == Vector2(1234, 987), "Pozycja bohatera wraca po wczytaniu")

	game.queue_free()
	await process_frame
	_expect(save_manager.request_load(2), "Slot można przekazać do nowej sceny gry")
	var reloaded_game := MainScene.instantiate()
	root.add_child(reloaded_game)
	await process_frame
	_expect(is_equal_approx(reloaded_game.cash, 37.25), "Scena automatycznie konsumuje wybrany zapis")
	_expect(reloaded_game.inventory.item_count("dog_collar") == 2, "Automatyczne wczytanie odtwarza ekwipunek")
	reloaded_game.gameplay_active = true
	reloaded_game._open_pause_menu()
	_expect(paused and reloaded_game.pause_menu_open and reloaded_game.pause_menu.visible, "Esc może otworzyć aktywne menu pauzy")
	reloaded_game._close_pause_menu()
	_expect(not paused and not reloaded_game.pause_menu_open, "Wznowienie zamyka pauzę")
	reloaded_game.queue_free()
	await process_frame
	_cleanup_test_saves()
	save_manager.save_prefix = original_prefix
	save_manager.start_new_game()
	if failures.is_empty():
		print("SAVE_MENU_TEST_OK")
		quit(0)
	else:
		for failure in failures:
			push_error(failure)
		quit(1)

func _cleanup_test_saves() -> void:
	for slot in range(1, GameSaveManager.SLOT_COUNT + 1):
		for suffix in ["", ".tmp", ".bak"]:
			var path: String = save_manager.slot_path(slot) + suffix
			if FileAccess.file_exists(path):
				DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

func _expect(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
