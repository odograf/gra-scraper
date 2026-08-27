extends SceneTree

const CombatRulesScript := preload("res://scripts/combat_rules.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame

	_expect(game.player_level == 1 and game.player_xp == 0, "Bohater zaczyna na pierwszym poziomie bez XP")
	_expect(game._xp_for_next_level() == 25, "Pierwszy awans wymaga 25 XP")
	game._award_xp(24, "test")
	_expect(game.player_level == 1 and game.player_xp == 24, "XP odkłada się do progu awansu")
	game._award_xp(1, "test")
	_expect(game.player_level == 2 and game.player_xp == 0, "Przekroczenie progu podnosi poziom")
	_expect(game.stat_points == 1, "Każdy awans daje jeden punkt statystyki")
	game._rebuild_inventory_ui()
	var strength_button := game.inventory_box.find_child("Stat_strength", true, false) as Button
	_expect(strength_button != null and not strength_button.disabled, "Ekran ekwipunku pozwala rozdać wolny punkt")
	game._increase_stat("strength")
	_expect(int(game.character_stats.strength) == 1 and game.stat_points == 0, "Punkt można przeznaczyć na Siłę")

	var rules = CombatRulesScript.new()
	rules.reset(20260825, {"strength": 2, "endurance": 2, "agility": 2})
	_expect(rules.player_max_health == 110 and rules.player_health == 110, "Kondycja zwiększa bazowe 100 punktów życia")
	_expect(is_equal_approx(rules.player_evasion_chance(), 0.60), "Zwinność zwiększa szansę skoków na boki")
	rules.forced_enemy_action = "enemy_guard"
	var enemy_before: int = rules.enemy_health
	rules.resolve_round("quick")
	_expect(enemy_before - rules.enemy_health >= 3, "Siła zwiększa obrażenia nawet przeciw gardzie")

	var xp_before_can: int = game.player_xp
	game._on_can_collected()
	_expect(game.player_xp == xp_before_can + game.CAN_XP, "Podniesienie puszki daje doświadczenie")
	var xp_before_fight: int = game.player_xp
	game.active_combat_xp_reward = 20
	game._on_combat_resolved("victory")
	_expect(game.player_xp == xp_before_fight + 20, "Wygrana walka daje doświadczenie z konfiguracji przeciwnika")
	_finish("PROGRESSION_TEST")

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _finish(test_name: String) -> void:
	if failures == 0: print(test_name + "_OK")
	else: printerr(test_name + "_FAILED: %d" % failures)
	quit(failures)
