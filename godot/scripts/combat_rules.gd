class_name CombatRules
extends RefCounted

const CombatantConfigScript := preload("res://scripts/combatant_config.gd")
const PLAYER_MAX_HEALTH := 100
const ENEMY_MAX_HEALTH := 46
const PLAYER_ACTIONS := ["quick", "heavy", "guard", "sidestep"]
const ENEMY_ACTIONS := ["jab", "enemy_heavy", "enemy_guard"]

var player_health := PLAYER_MAX_HEALTH
var player_max_health := PLAYER_MAX_HEALTH
var enemy_health := ENEMY_MAX_HEALTH
var enemy_max_health := ENEMY_MAX_HEALTH
var enemy_damage_bonus := 0
var enemy_accuracy_bonus := 0.0
var player_strength := 0
var player_endurance := 0
var player_agility := 0
var player_attack := 10
var player_defense := 0
var player_attack_range := 2
var enemy_attack := 7
var enemy_defense := 0
var enemy_agility := 0
var enemy_attack_range := 1
var player_advantage := false
var enemy_advantage := false
var player_sidestep_turns := 0
var player_heavy_charged := false
var enemy_guard_active := false
var round_number := 1
var finished := false
var result := ""
var forced_enemy_action := ""
var enemy_name := "Zadymiarz"
var enemy_kind := "human"
var rng := RandomNumberGenerator.new()

func configure_enemy_stats(config: Dictionary) -> void:
	enemy_name = String(config.get("display_name", "Przeciwnik"))
	enemy_kind = String(config.get("kind", "human"))
	enemy_max_health = int(config.get("max_health", ENEMY_MAX_HEALTH))
	enemy_attack = int(config.get("attack", 7))
	enemy_defense = int(config.get("defense", 0))
	enemy_agility = int(config.get("agility", 0))
	enemy_attack_range = int(config.get("attack_range", 1))
	enemy_damage_bonus = 0
	enemy_accuracy_bonus = 0.0

func reset(seed := 0, stats: Dictionary = {}) -> void:
	var player_config := CombatantConfigScript.player()
	player_strength = int(stats.get("strength", 0))
	player_endurance = int(stats.get("endurance", 0))
	player_agility = int(stats.get("agility", player_config.agility))
	player_attack = int(stats.get("attack", player_config.attack))
	player_defense = int(stats.get("defense", player_config.defense))
	player_attack_range = int(stats.get("attack_range", player_config.attack_range))
	player_max_health = int(player_config.max_health) + player_endurance * 5
	player_health = clampi(int(stats.get("current_health", player_max_health)), 0, player_max_health)
	enemy_health = enemy_max_health
	player_advantage = false
	enemy_advantage = false
	player_sidestep_turns = 0
	player_heavy_charged = false
	enemy_guard_active = false
	round_number = 1
	finished = false
	result = ""
	forced_enemy_action = ""
	if seed == 0:
		rng.randomize()
	else:
		rng.seed = seed

func resolve_round(player_action: String) -> Dictionary:
	if finished or player_action not in PLAYER_ACTIONS:
		return snapshot([])

	var events: Array[Dictionary] = []
	var player_guarding := false
	var enemy_action := _choose_enemy_action()

	match player_action:
		"quick":
			_attack(true, false, enemy_guard_active, false, events)
			enemy_guard_active = false
		"heavy":
			if player_heavy_charged:
				player_heavy_charged = false
				_attack(true, true, enemy_guard_active, false, events)
				enemy_guard_active = false
			else:
				player_heavy_charged = true
				_append_event(events, "charge", "player", "Cofasz bark i ładujesz silny atak. Uderzysz w następnej turze.")
		"guard":
			player_guarding = true
			_append_event(events, "guard", "player", "Przyjmujesz gardę i osłaniasz głowę.")
		"sidestep":
			player_sidestep_turns = 3
			_append_event(events, "sidestep", "player", "Zaczynasz skakać na boki. Przez 3 tury masz 50% szansy uniku.")

	if enemy_health <= 0:
		_finish_if_needed(events)
		return _finish_round(events, enemy_action)

	match enemy_action:
		"enemy_guard":
			enemy_guard_active = true
			var guard_text := "%s jeży sierść i cofa łeb. Trudniej go teraz trafić." % enemy_name if enemy_kind == "dog" else "%s unosi ręce. Jego garda zatrzyma część następnego ciosu." % enemy_name
			_append_event(events, "guard", "enemy", guard_text)
		"jab":
			_attack(false, false, player_guarding, player_sidestep_turns > 0, events)
		"enemy_heavy":
			_attack(false, true, player_guarding, player_sidestep_turns > 0, events)

	if player_sidestep_turns > 0:
		player_sidestep_turns -= 1
	_finish_if_needed(events)
	return _finish_round(events, enemy_action)

func snapshot(events: Array[Dictionary] = []) -> Dictionary:
	return {
		"player_health": player_health,
		"player_max_health": player_max_health,
		"enemy_health": enemy_health,
		"enemy_max_health": enemy_max_health,
		"player_state": _player_state_text(),
		"enemy_state": "GARDA" if enemy_guard_active else ("PRZEWAGA" if enemy_advantage else "CZUJNY"),
		"sidestep_turns": player_sidestep_turns,
		"heavy_charged": player_heavy_charged,
		"strength": player_strength,
		"endurance": player_endurance,
		"agility": player_agility,
		"player_attack": player_attack,
		"player_defense": player_defense,
		"player_attack_range": player_attack_range,
		"enemy_attack": enemy_attack,
		"enemy_defense": enemy_defense,
		"enemy_agility": enemy_agility,
		"enemy_attack_range": enemy_attack_range,
		"round": round_number,
		"finished": finished,
		"result": result,
		"events": events,
	}

func _finish_round(events: Array[Dictionary], enemy_action: String) -> Dictionary:
	if not finished:
		round_number += 1
	var state := snapshot(events)
	state["enemy_action"] = enemy_action
	return state

func _finish_if_needed(events: Array[Dictionary]) -> void:
	if enemy_health <= 0:
		finished = true
		result = "victory"
		var victory_text := "%s odskakuje i wycofuje się. Wygrywasz starcie." % enemy_name if enemy_kind == "dog" else "%s pada na ziemię. Wygrywasz walkę." % enemy_name
		_append_event(events, "result", "enemy", victory_text)
	elif player_health <= 0:
		finished = true
		result = "defeat"
		_append_event(events, "result", "player", "Nie masz już siły walczyć. Przegrywasz starcie.")

func _player_state_text() -> String:
	if player_heavy_charged:
		return "ŁADUJE SILNY ATAK"
	if player_sidestep_turns > 0:
		return "SKOKI: %d TURY" % player_sidestep_turns
	return "PRZEWAGA" if player_advantage else "GOTOWY"

func _choose_enemy_action() -> String:
	if forced_enemy_action in ENEMY_ACTIONS:
		var selected := forced_enemy_action
		forced_enemy_action = ""
		return selected
	var roll := rng.randi_range(0, 99)
	if enemy_health <= 14 and roll < 35:
		return "enemy_guard"
	if roll < 55:
		return "jab"
	if roll < 83:
		return "enemy_heavy"
	return "enemy_guard"

func player_evasion_chance() -> float:
	return minf(0.80, 0.50 + float(player_agility) * 0.05)

func _attack(player_is_attacker: bool, is_heavy: bool, defender_guarding: bool, defender_sidestep: bool, events: Array[Dictionary]) -> void:
	var agility_accuracy_bonus := float(player_agility) * (0.01 if is_heavy else 0.02) if player_is_attacker else 0.0
	var base_accuracy := minf(0.98, (0.78 if is_heavy else 0.92) + agility_accuracy_bonus + (0.0 if player_is_attacker else enemy_accuracy_bonus))
	var advantage := player_advantage if player_is_attacker else enemy_advantage
	if advantage:
		base_accuracy = minf(0.98, base_accuracy + 0.08)
		if player_is_attacker: player_advantage = false
		else: enemy_advantage = false

	var enemy_attack_name := ("szarża" if is_heavy else "ugryzienie") if enemy_kind == "dog" else ("ciężkie kopnięcie" if is_heavy else "prosty")
	var attack_name := "silny atak" if player_is_attacker and is_heavy else ("szybki cios" if player_is_attacker else enemy_attack_name)
	if rng.randf() > base_accuracy:
		_append_event(events, "miss", "player" if player_is_attacker else "enemy", "%s nie trafia." % attack_name.capitalize())
		if is_heavy:
			if player_is_attacker: enemy_advantage = true
			else: player_advantage = true
		return

	if defender_sidestep and rng.randf() < player_evasion_chance():
		player_advantage = true
		_append_event(events, "evade", "enemy", "Skaczesz w bok — %s mija cię o włos." % attack_name)
		return

	var damage := 0
	if player_is_attacker:
		damage = player_attack + (8 + player_strength * 2 if is_heavy else player_strength)
		damage = maxi(1, damage - enemy_defense)
	else:
		damage = enemy_attack + (4 if is_heavy else 0)
		damage = maxi(1, damage - player_defense)
	if advantage:
		damage += 3
	var guard_message := ""
	if defender_guarding:
		damage = maxi(1, ceili(float(damage) * 0.4))
		guard_message = " Garda pochłania większość uderzenia."
		if is_heavy:
			if player_is_attacker: enemy_advantage = true
			else: player_advantage = true

	if player_is_attacker:
		enemy_health = maxi(0, enemy_health - damage)
		_append_event(events, "attack", "player", "%s trafia za %d obrażeń.%s" % [attack_name.capitalize(), damage, guard_message], damage)
	else:
		player_health = maxi(0, player_health - damage)
		_append_event(events, "attack", "enemy", "%s trafia cię za %d obrażeń.%s" % [attack_name.capitalize(), damage, guard_message], damage)

func _append_event(events: Array[Dictionary], kind: String, actor: String, message: String, damage := 0) -> void:
	events.append({
		"kind": kind,
		"actor": actor,
		"message": message,
		"damage": damage,
		"player_health": player_health,
		"enemy_health": enemy_health,
	})
