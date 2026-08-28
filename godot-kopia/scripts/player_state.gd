class_name PlayerState
extends Node

signal health_changed(current: int, maximum: int)
signal stats_changed(stats: Dictionary)

const CombatantConfigScript := preload("res://scripts/combatant_config.gd")

var stats: Dictionary = {}
var current_health := 1
var maximum_health := 1

func _init(initial_stats: Dictionary = {}) -> void:
	configure(initial_stats if not initial_stats.is_empty() else CombatantConfigScript.player())

func configure(initial_stats: Dictionary) -> void:
	stats = initial_stats.duplicate(true)
	_recalculate_maximum_health(false)
	current_health = clampi(int(initial_stats.get("current_health", maximum_health)), 0, maximum_health)

func combat_snapshot() -> Dictionary:
	var snapshot := stats.duplicate(true)
	snapshot["current_health"] = current_health
	return snapshot

func save_snapshot() -> Dictionary:
	return {
		"stats": stats.duplicate(true),
		"current_health": current_health
	}

func restore_snapshot(data: Dictionary) -> void:
	var restored_stats: Dictionary = data.get("stats", CombatantConfigScript.player())
	configure(restored_stats)
	set_health(clampi(int(data.get("current_health", maximum_health)), 0, maximum_health))
	stats_changed.emit(stats.duplicate(true))
	health_changed.emit(current_health, maximum_health)

func apply_damage(raw_damage: int) -> int:
	if current_health <= 0 or raw_damage <= 0:
		return 0
	var defense := int(stats.get("defense", 0))
	var applied := maxi(1, raw_damage - defense)
	set_health(current_health - applied)
	return applied

func set_health(value: int) -> void:
	var next_health := clampi(value, 0, maximum_health)
	if next_health == current_health:
		return
	current_health = next_health
	health_changed.emit(current_health, maximum_health)

func synchronize_health(value: int, reported_maximum: int = -1) -> void:
	if reported_maximum >= 1 and reported_maximum != maximum_health:
		maximum_health = reported_maximum
	current_health = clampi(value, 0, maximum_health)
	health_changed.emit(current_health, maximum_health)

func increase_stat(stat_id: StringName) -> bool:
	if not stats.has(stat_id):
		return false
	stats[stat_id] = int(stats[stat_id]) + 1
	if stat_id == &"endurance":
		_recalculate_maximum_health(true)
	stats_changed.emit(stats.duplicate(true))
	return true

func realtime_attack_damage() -> int:
	return int(stats.get("attack", 0)) + int(stats.get("strength", 0))

func _recalculate_maximum_health(emit_signal: bool) -> void:
	var base_maximum := int(stats.get("max_health", CombatantConfigScript.PLAYER.max_health))
	maximum_health = maxi(1, base_maximum + int(stats.get("endurance", 0)) * 5)
	current_health = mini(current_health, maximum_health)
	if emit_signal:
		health_changed.emit(current_health, maximum_health)
