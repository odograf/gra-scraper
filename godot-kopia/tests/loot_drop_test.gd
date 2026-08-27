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

	_expect(not PlayerInventory.LIMITS_ENABLED, "Pojemnik jest tymczasowo bez limitu miejsca i wagi")
	for index in range(40):
		_expect(game.inventory.add_item("can"), "Nieograniczony pojemnik przyjmuje puszkę %d" % (index + 1))
	_expect(game.inventory.used_space() > game.inventory.capacity(), "Zawartość może chwilowo przekraczać nominalną pojemność")

	var collar := game._spawn_loot("dog_collar", game.player.global_position) as LootPickup
	_expect(collar != null and collar.is_in_group("keyboard_interactable"), "Drop obroży pojawia się jako interaktywny przedmiot")
	_expect(collar.try_collect(), "Obrożę można podnieść")
	await create_timer(0.35).timeout
	_expect(game.inventory.item_count("dog_collar") == 1, "Obroża trafia do ekwipunku")
	game.player._finish_action()

	var cash_before: float = game.cash
	var coin := game._spawn_loot("one_zloty", game.player.global_position) as LootPickup
	_expect(coin != null and coin.cash_cents == 100, "Złotówka przechowuje nagrodę 100 groszy")
	_expect(coin.try_collect(), "Złotówkę można podnieść")
	await create_timer(0.35).timeout
	_expect(is_equal_approx(game.cash, cash_before + 1.0), "Złotówka zwiększa gotówkę o 1,00 zł")
	game.player._finish_action()

	var pack := game.get_tree().get_nodes_in_group("park_pack_1")
	var drops_before := game.get_tree().get_node_count_in_group("loot_pickup")
	for dog in pack:
		(dog as WildDogEnemy).receive_realtime_hit(999, game.player.global_position)
	await process_frame
	_expect(game.get_tree().get_node_count_in_group("loot_pickup") == drops_before + 1, "Cała wataha zostawia dokładnie jeden drop")
	_expect(game.cleared_loot_groups.has("park_pack_1"), "Wataha nie może ponownie wylosować łupu")

	var group_one := game.get_tree().get_nodes_in_group("sewer_rat_group_1")
	var rat_drops_before := game.get_tree().get_node_count_in_group("loot_pickup")
	for rat in group_one:
		(rat as SewerRatEnemy).receive_realtime_hit(999, game.player.global_position)
	await process_frame
	_expect(game.get_tree().get_node_count_in_group("loot_pickup") == rat_drops_before + 1, "Legowisko Szczórów zostawia dokładnie jeden drop")

	var named_drops_before := game.get_tree().get_node_count_in_group("loot_pickup")
	_expect(not game._spawn_named_loot_once("zul_1", game.player.global_position).is_empty(), "Żul 1 ma własną tabelę łupu")
	_expect(game._spawn_named_loot_once("zul_1", game.player.global_position).is_empty(), "Nazwany przeciwnik nie daje tego samego dropu drugi raz")
	_expect(game.get_tree().get_node_count_in_group("loot_pickup") == named_drops_before + 1, "Nazwany przeciwnik tworzy jeden przedmiot na mapie")

	if failures == 0:
		print("LOOT_DROP_TEST_OK")
	else:
		printerr("LOOT_DROP_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
