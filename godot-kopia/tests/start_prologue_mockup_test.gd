extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/melina_prologue_mockup.tscn")
	_expect(packed != null, "Osobna scena meliny istnieje")
	_expect(load("res://scenes/start_suburb_mockup.tscn") != null, "Osobna scena przedmieścia istnieje")
	var mockup = packed.instantiate()
	root.add_child(mockup)
	current_scene = mockup
	await process_frame
	_expect(mockup.active_cans.size() == 6, "Melina zawiera dokładnie sześć puszek")
	_expect(is_equal_approx(mockup.MELINA_RECT.size.x, mockup.TILE_SIZE * 3.0), "Melina ma dokładnie trzy kratki szerokości")
	_expect(mockup.dialogue_overlay.visible, "Prolog zaczyna się klikanym dialogiem")
	for index in range(3):
		mockup._advance_dialogue()
	_expect(mockup.stage == mockup.Stage.TAKE_BAG, "Po pierwszym dialogu celem jest reklamówka")
	mockup.player.global_position = mockup.starter_bag.global_position
	_expect(mockup.starter_bag.try_collect(), "Reklamówkę można podnieść")
	_expect(mockup.dialogue_overlay.visible, "Podniesienie reklamówki uruchamia drugi dialog")
	for index in range(2):
		mockup._advance_dialogue()
	_expect(mockup.stage == mockup.Stage.COLLECT_CANS, "Po drugim dialogu można zbierać puszki")
	for index in range(6):
		mockup._register_mock_can()
	_expect(mockup.cans_collected == 6 and mockup.dialogue_overlay.visible, "Szósta puszka uruchamia dialog o automacie i psach")
	for index in range(2):
		mockup._advance_dialogue()
	_expect(mockup.stage == mockup.Stage.EXIT_MELINA, "Drzwi odblokowują się dopiero po sześciu puszkach")
	mockup.player.global_position = mockup.EXIT_POSITION
	# Regresja błędu z wejścia: viewport musi zostać użyty przed zwolnieniem
	# sceny przez change_scene_to_file().
	_expect(mockup.get_viewport() != null, "Melina ma aktywny viewport przed przejściem")
	_expect(mockup._handle_exit_click(), "Kliknięcie odblokowanych drzwi przenosi na przedmieście")
	await process_frame
	await process_frame
	var suburb = current_scene
	_expect(suburb != null and suburb.name == "StartSuburbMockup", "Wyjście naprawdę zmienia aktywną scenę")
	_expect(suburb.location_mode == suburb.Location.SUBURB, "Nowa scena jest przedmieściem")
	_expect(suburb.cans_collected == 6, "Liczba puszek przechodzi między scenami")
	_expect(suburb.enemies.size() == 7, "Na zewnątrz jest 3 psy i 4 szczury")
	var active_enemy_count := 0
	for enemy in suburb.enemies:
		if enemy.active:
			active_enemy_count += 1
	_expect(active_enemy_count == 7, "Zagrożenia aktywują się po wyjściu z meliny")
	# Kilka klatek stabilizuje kamerę i pozwala użyć testu również do podglądu
	# końcowego układu mapy w trybie Movie Maker Godota.
	for frame in range(5):
		await process_frame
	_finish()

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _finish() -> void:
	if failures == 0:
		print("START_PROLOGUE_MOCKUP_TEST_OK")
	else:
		printerr("START_PROLOGUE_MOCKUP_TEST_FAILED: %d" % failures)
	quit(failures)
