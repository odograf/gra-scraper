class_name CombatantDefinition
extends Resource

@export var id: StringName
@export var display_name := "Przeciwnik"
@export var kind: StringName = &"human"
@export_range(1, 99, 1) var level := 1
@export_range(1, 9999, 1) var max_health := 1
@export_range(0, 999, 1) var attack := 0
@export_range(0, 999, 1) var defense := 0
@export_range(0, 999, 1) var agility := 0
@export_range(0, 20, 1) var attack_range := 1
@export_range(0, 99999, 1) var xp_reward := 0
@export var location := ""
@export_multiline var intro := ""

static func from_dictionary(combatant_id: StringName, values: Dictionary) -> CombatantDefinition:
	var definition := CombatantDefinition.new()
	definition.id = combatant_id
	definition.display_name = String(values.get("display_name", "Przeciwnik"))
	definition.kind = StringName(values.get("kind", &"human"))
	definition.level = maxi(1, int(values.get("level", 1)))
	definition.max_health = maxi(1, int(values.get("max_health", 1)))
	definition.attack = maxi(0, int(values.get("attack", 0)))
	definition.defense = maxi(0, int(values.get("defense", 0)))
	definition.agility = maxi(0, int(values.get("agility", 0)))
	definition.attack_range = maxi(0, int(values.get("attack_range", 1)))
	definition.xp_reward = maxi(0, int(values.get("xp_reward", 0)))
	definition.location = String(values.get("location", ""))
	definition.intro = String(values.get("intro", ""))
	return definition

func to_dictionary() -> Dictionary:
	return {
		"id": id,
		"display_name": display_name,
		"kind": kind,
		"level": level,
		"max_health": max_health,
		"attack": attack,
		"defense": defense,
		"agility": agility,
		"attack_range": attack_range,
		"xp_reward": xp_reward,
		"location": location,
		"intro": intro,
	}
