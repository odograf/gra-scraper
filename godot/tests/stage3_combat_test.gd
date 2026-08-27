extends SceneTree

const CombatRulesScript := preload("res://scripts/combat_rules.gd")
const CombatantConfigScript := preload("res://scripts/combatant_config.gd")

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var rules = CombatRulesScript.new()
	rules.reset(20260825)
	_expect(rules.player_health == 100 and rules.enemy_health == 46, "Bohater zaczyna walkę ze 100 punktami życia")
	var player_config := CombatantConfigScript.player()
	_expect(player_config.attack == 10 and player_config.defense == 0 and player_config.agility == 10 and player_config.attack_range == 2, "Centralna konfiguracja zawiera bazowe statystyki bohatera")
	var park_dog := CombatantConfigScript.enemy("park_dog")
	_expect(park_dog.level == 1 and park_dog.max_health == 30 and park_dog.attack == 5 and park_dog.attack_range == 1 and park_dog.xp_reward == 50, "Pies z parku ma poziom 1, 30 HP, 5 ataku, zasięg 1 i nagrodę 50 XP")
	var park_dog_rules = CombatRulesScript.new()
	park_dog_rules.configure_enemy_stats(park_dog)
	park_dog_rules.reset(20260825)
	park_dog_rules.forced_enemy_action = "jab"
	var health_before_dog: int = park_dog_rules.player_health
	var dog_health_before_player_attack: int = park_dog_rules.enemy_health
	park_dog_rules.resolve_round("quick")
	_expect(dog_health_before_player_attack - park_dog_rules.enemy_health == 10, "Bazowy atak bohatera odbiera przeciwnikowi 10 HP bez obrony")
	_expect(health_before_dog - park_dog_rules.player_health == 5, "Atak psa z parku odbiera dokładnie 5 HP bohatera bez obrony")
	_expect(CombatRulesScript.PLAYER_ACTIONS == ["quick", "heavy", "guard", "sidestep"], "Gracz ma cztery różne ruchy")
	var dog_rules = CombatRulesScript.new()
	var burek_config := CombatantConfigScript.enemy("burek")
	dog_rules.configure_enemy_stats(burek_config)
	dog_rules.reset(20260825)
	_expect(dog_rules.enemy_health == 20 and dog_rules.enemy_attack == 3 and dog_rules.enemy_attack_range == 1, "Burek korzysta wyłącznie z centralnej konfiguracji")
	var zul_rules = CombatRulesScript.new()
	var zul_config := CombatantConfigScript.enemy("zul_1")
	zul_rules.configure_enemy_stats(zul_config)
	zul_rules.reset(20260825)
	_expect(zul_rules.enemy_health == 64 and zul_rules.enemy_attack == 10 and zul_rules.enemy_agility == 6, "Żul 1 korzysta wyłącznie z centralnej konfiguracji")

	rules.forced_enemy_action = "enemy_heavy"
	var health_before_guard: int = rules.player_health
	var guard_state: Dictionary = rules.resolve_round("guard")
	var guarded_damage: int = health_before_guard - rules.player_health
	_expect(guarded_damage >= 0 and guarded_damage <= 5, "Garda redukuje ciężki atak o 60 procent")
	_expect(not guard_state.events.is_empty(), "Tura jest podzielona na animowane zdarzenia")

	var enemy_before_quick: int = rules.enemy_health
	rules.forced_enemy_action = "enemy_guard"
	rules.resolve_round("quick")
	_expect(rules.enemy_health <= enemy_before_quick, "Szybki cios może uszkodzić przeciwnika")

	var charge_rules = CombatRulesScript.new()
	charge_rules.reset(20260825)
	charge_rules.forced_enemy_action = "enemy_guard"
	var enemy_before_charge: int = charge_rules.enemy_health
	charge_rules.resolve_round("heavy")
	_expect(charge_rules.player_heavy_charged and charge_rules.enemy_health == enemy_before_charge, "Silny atak zużywa pierwszą turę na ładowanie")
	charge_rules.forced_enemy_action = "enemy_guard"
	charge_rules.resolve_round("heavy")
	_expect(not charge_rules.player_heavy_charged and charge_rules.enemy_health < enemy_before_charge, "Naładowany silny atak uderza w następnej turze")

	var sidestep_rules = CombatRulesScript.new()
	sidestep_rules.reset(20260825)
	sidestep_rules.forced_enemy_action = "enemy_guard"
	sidestep_rules.resolve_round("sidestep")
	_expect(sidestep_rules.player_sidestep_turns == 2, "Skakanie na boki działa w turze aktywacji i dwóch kolejnych")

	for index in range(40):
		if rules.finished:
			break
		rules.forced_enemy_action = "enemy_guard"
		rules.resolve_round("heavy")
	_expect(rules.finished and rules.result == "victory", "Seria trafień może zakończyć walkę zwycięstwem")

	var packed: PackedScene = load("res://scenes/main.tscn")
	var game = packed.instantiate()
	root.add_child(game)
	await process_frame
	_expect(game.health_bar != null and game.health_bar.visible, "Pasek zdrowia bohatera jest stale widoczny w HUD-zie")
	_expect(roundi(game.health_bar.max_value) == 100 and roundi(game.health_bar.value) == 100 and game.health_label.text == "ŻYCIE: 100/100", "HUD pokazuje bazowe 100 punktów zdrowia")
	game.gameplay_active = true
	_expect(game.combat_enemy != null and game.combat_enemy.position == Vector2(1160, 580), "Zadymiarz stoi pod kioskiem")
	game.player.position = game.combat_enemy.position
	game._update_interaction_focus()
	_expect(game.focused_interactable == game.combat_enemy, "Zadymiarz jest dostępny jako najbliższa interakcja")
	game.alcohol_level = 0.0
	_expect(game._try_interact_nearby(), "Próba walki przy zerowym alkoholu obsługuje interakcję")
	_expect(not game.combat_open, "Zerowy alkohol blokuje rozpoczęcie walki")
	game.alcohol_level = 20.0
	game.nicotine_level = 0.0
	game._update_interaction_focus()
	_expect(game._try_interact_nearby(), "Próba walki przy zerowej nikotynie obsługuje interakcję")
	_expect(not game.combat_open, "Zerowa nikotyna blokuje rozpoczęcie walki")
	game.nicotine_level = 20.0
	game._update_interaction_focus()
	_expect(game._try_interact_nearby(), "Enter przy zadymiarzu rozpoczyna walkę")
	_expect(game.combat_open and game.combat_overlay.visible, "Interakcja otwiera osobny ekran walki")
	_expect(not game.player.is_physics_processing(), "Ekran walki zatrzymuje ruch na mapie")
	_expect(game.combat_overlay.move_buttons.size() == 4, "Ekran pokazuje cztery przyciski ruchów")
	var quick_button := game.combat_overlay.move_buttons["quick"] as Button
	_expect(quick_button.text == "SZYBKI CIOS", "Pierwszym ruchem jest prawdziwy atak")
	game.combat_overlay.start_fight(20260825)
	game.combat_overlay.rules.forced_enemy_action = "enemy_guard"
	var click_attack := InputEventMouseButton.new()
	click_attack.button_index = MOUSE_BUTTON_LEFT
	click_attack.pressed = true
	click_attack.position = game.combat_overlay._enemy_click_rect().get_center()
	game.combat_overlay._gui_input(click_attack)
	_expect(game.combat_overlay.busy, "Lewy klik w model przeciwnika rozpoczyna atak")
	_expect(game.combat_overlay.rules.enemy_health < CombatRulesScript.ENEMY_MAX_HEALTH, "Szybki cios wylicza obrażenia przeciwnika")
	_expect(game.combat_overlay.enemy_health_bar.value == CombatRulesScript.ENEMY_MAX_HEALTH, "Pasek nie przeskakuje natychmiast do końcowej wartości")
	await create_timer(1.9).timeout
	_expect(roundi(game.combat_overlay.enemy_health_bar.value) == game.combat_overlay.rules.enemy_health, "Pasek płynnie dochodzi do nowego poziomu przed końcem tury")
	game.combat_overlay.start_fight(20260825)
	var sidestep_button := game.combat_overlay.move_buttons["sidestep"] as Button
	_expect(sidestep_button.text == "SKACZ NA BOKI", "Unik zastąpiło trzyturowe skakanie na boki")
	game.combat_overlay.rules.forced_enemy_action = "enemy_guard"
	game.combat_overlay._choose_action("sidestep")
	_expect(game.combat_overlay.busy, "Animowana tura blokuje natychmiastowy wybór kolejnego ruchu")
	await create_timer(1.7).timeout
	_expect(game.combat_overlay.rules.round_number == 2, "Kliknięcie ruchu rozgrywa pełną turę interfejsu")
	_expect(not game.combat_overlay.busy, "Po animacji wyników można wybrać kolejny ruch")
	game.combat_overlay.player_health_changed.emit(73, 100)
	_expect(game.player_health == 73 and roundi(game.health_bar.value) == 73 and game.health_label.text == "ŻYCIE: 73/100", "Walka synchronizuje zdrowie z głównym HUD-em")
	game._close_combat_prototype()
	_expect(not game.combat_open and game.player.is_physics_processing(), "Powrót z walki przywraca sterowanie bohaterem")
	game._open_combat_prototype("zadymiarz")
	_expect(game.combat_overlay.rules.player_health == 73, "Kolejna walka zaczyna się z aktualnym zdrowiem bohatera")
	game._close_combat_prototype()

	var zul_1 := game.get_node("Zul1") as MapResident
	game.quest_state = game.QuestState.COMPLETED
	game._activate_zul_blockade()
	await create_timer(0.7).timeout
	game.player.position = zul_1.position
	game._update_interaction_focus()
	_expect(game.focused_interactable == zul_1, "Żul 1 jest interaktywnym przeciwnikiem na mapie")
	_expect(game.interaction_hint_label.text.contains("ŻULEM 1"), "HUD podpowiada walkę z Żulem 1")
	_expect(game._try_interact_nearby(), "Enter przy Żulu 1 rozpoczyna walkę")
	_expect(game.combat_overlay.enemy_name == "ŻUL 1", "Ekran walki pokazuje nazwę Żula 1")
	_expect(game.combat_overlay.rules.enemy_max_health == 64, "Żul 1 rozpoczyna walkę z 64 punktami życia")
	_expect(game.combat_overlay.enemy_texture == game.ZUL_1_COMBAT_ART, "Walka z Żulem 1 używa jego dużego modelu")
	game._on_combat_resolved("victory")
	await create_timer(0.75).timeout
	_expect(game.zul_defeated and zul_1.position.is_equal_approx(game.ZUL_DEFEATED_POSITION), "Pokonany Żul 1 odsuwa się z jedynego przejścia")
	game._close_combat_prototype()

	var burek := game.get_node("Burek") as MapResident
	game.player.position = burek.position
	game._update_interaction_focus()
	_expect(game.focused_interactable == burek, "Burek jest interaktywnym przeciwnikiem na mapie")
	_expect(game.interaction_hint_label.text.contains("BURKIEM"), "HUD podpowiada walkę z Burkiem")
	_expect(game._try_interact_nearby(), "Enter przy Burku rozpoczyna walkę")
	_expect(game.combat_overlay.enemy_name == "BUREK" and game.combat_overlay.enemy_kind == "dog", "Burek uruchamia psi wariant walki")
	_expect(game.combat_overlay.rules.enemy_max_health == 20, "Burek rozpoczyna walkę z małym paskiem 20 punktów życia")
	_expect(game.combat_overlay.enemy_texture == game.BUREK_COMBAT_ART, "Walka z Burkiem używa jego dużego modelu")
	game.combat_overlay.rules.forced_enemy_action = "enemy_guard"
	var dog_state: Dictionary = game.combat_overlay.rules.resolve_round("guard")
	var dog_guard_message := false
	for event in dog_state.events:
		if String(event.message).contains("sierść"):
			dog_guard_message = true
	_expect(dog_guard_message, "Burek korzysta z psich opisów ruchów")
	game._on_combat_resolved("victory")
	await create_timer(0.75).timeout
	_expect(game.burek_defeated and burek.position.is_equal_approx(game.BUREK_DEFEATED_POSITION), "Pokonany Burek odsuwa się od drzwi sklepu")
	game._close_combat_prototype()
	_finish("STAGE3_COMBAT_TEST")

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)

func _finish(test_name: String) -> void:
	if failures == 0: print(test_name + "_OK")
	else: printerr(test_name + "_FAILED: %d" % failures)
	quit(failures)
