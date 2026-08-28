extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	_expect(game.bottom_hud_panel != null, "Dolna konsola HUD istnieje")
	_expect(is_equal_approx(game.bottom_hud_panel.anchor_bottom, 1.0), "HUD jest zakotwiczony do dołu ekranu")
	_expect(game.bottom_hud_panel.anchor_left > 0.0 and game.bottom_hud_panel.anchor_right < 1.0, "HUD używa proporcjonalnych marginesów zamiast sztywnej pozycji")
	_expect(game.bottom_hud_panel.is_ancestor_of(game.health_bar), "Pasek życia znajduje się w dolnym HUD-zie")
	_expect(game.bottom_hud_panel.is_ancestor_of(game.alcohol_bar), "Pasek alkoholu znajduje się w dolnym HUD-zie")
	_expect(game.bottom_hud_panel.is_ancestor_of(game.nicotine_bar), "Pasek nikotyny znajduje się w dolnym HUD-zie")
	_expect(game.bottom_hud_panel.offset_bottom - game.bottom_hud_panel.offset_top <= 64.0, "Dolny HUD jest kompaktowy i nie zasłania mapy")
	var camera := game.player.get_node("Kamera") as Camera2D
	_expect(camera.limit_bottom > int(WorldMap.WORLD_SIZE.y), "Kamera zostawia dolny margines mapy nad HUD-em")
	_expect(game.health_bar.custom_minimum_size.y > game.alcohol_bar.custom_minimum_size.y, "Pasek życia jest większy od pasków potrzeb")
	_expect(game.health_bar.custom_minimum_size.y > game.nicotine_bar.custom_minimum_size.y, "Życie pozostaje dominującym paskiem")
	_expect(game.bag_hud_button.custom_minimum_size.x <= 52.0, "Przycisk torby ma kompaktowy rozmiar")
	_expect(game.bag_hud_button != null and game.bag_hud_button.icon != null, "HUD ma przycisk z ikoną torby")
	_expect(game.health_bar.value == 100.0 and game.alcohol_bar.value == 28.0 and game.nicotine_bar.value == 24.0, "Dolne paski pokazują aktualne wartości zasobów")
	_expect(game.store_overlay.find_child("WycentrowanyPanel", true, false) is CenterContainer, "Okna modalne są centrowane przez kontener")
	_expect(is_equal_approx(game.action_panel.anchor_left, 0.5) and is_equal_approx(game.action_panel.anchor_bottom, 1.0), "Pasek czynności jest zakotwiczony względem środka i dołu")

	game.fab01_bag_picked = true
	game._on_hud_bag_pressed()
	_expect(game.inventory_open, "Przycisk torby otwiera ten sam ekwipunek co klawisz I")
	game._close_inventory()

	if failures == 0:
		print("HUD_LAYOUT_TEST_OK")
	else:
		printerr("HUD_LAYOUT_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
