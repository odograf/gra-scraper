class_name RealtimeEnemyDirector
extends Node

var enemies: Array[RealtimeEnemy] = []

func register_enemy(enemy: RealtimeEnemy) -> void:
	if enemy != null and not enemies.has(enemy):
		enemies.append(enemy)

func set_combat_active(enabled: bool) -> void:
	for index in range(enemies.size() - 1, -1, -1):
		var enemy := enemies[index]
		if enemy == null or not is_instance_valid(enemy):
			enemies.remove_at(index)
			continue
		enemy.active = enabled

func enemy_at_position(world_position: Vector2, selection_radius := 64.0) -> RealtimeEnemy:
	var selected: RealtimeEnemy
	var closest_distance := selection_radius
	for enemy in enemies:
		if enemy == null or not is_instance_valid(enemy) or enemy.dead:
			continue
		var distance := enemy.global_position.distance_to(world_position)
		if distance <= closest_distance:
			closest_distance = distance
			selected = enemy
	return selected
