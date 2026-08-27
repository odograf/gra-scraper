class_name CombatantConfig
extends RefCounted

# Jedno miejsce do ustawiania bazowych parametrów bohatera i przeciwników.
# Zasięg jest liczony w polach przyszłej mapy taktycznej.
const PLAYER := {
	"max_health": 100,
	"attack": 10,
	"defense": 0,
	"agility": 10,
	"attack_range": 2,
	"strength": 0,
	"endurance": 0,
}

const ENEMIES := {
	"zadymiarz": {
		"display_name": "Osiedlowy zadymiarz",
		"kind": "human",
		"level": 1,
		"max_health": 46,
		"attack": 7,
		"defense": 0,
		"agility": 4,
		"attack_range": 1,
		"xp_reward": 20,
		"location": "WALKA POD KIOSKIEM",
		"intro": "Osiedlowy zadymiarz zagradza ci drogę. Kliknij przeciwnika, aby zaatakować.",
	},
	"burek": {
		"display_name": "Burek",
		"kind": "dog",
		"level": 1,
		"max_health": 20,
		"attack": 3,
		"defense": 0,
		"agility": 3,
		"attack_range": 1,
		"xp_reward": 20,
		"location": "WALKA PRZED ŻUKIEM GNOJARZEM",
		"intro": "Burek pilnuje wejścia do Żuka Gnojarza. Kliknij psa, aby zaatakować.",
	},
	"zul_1": {
		"display_name": "Żul 1",
		"kind": "human",
		"level": 3,
		"max_health": 64,
		"attack": 10,
		"defense": 0,
		"agility": 6,
		"attack_range": 1,
		"xp_reward": 20,
		"location": "WALKA O DOSTĘP DO MIRKA",
		"intro": "Żul 1 nie chce odczepić się od Mirka. To mocny przeciwnik — zalecany poziom 3.",
	},
	"park_dog": {
		"display_name": "Pies z parku",
		"kind": "dog",
		"level": 1,
		"max_health": 30,
		"attack": 5,
		"defense": 0,
		"agility": 5,
		"attack_range": 1,
		"xp_reward": 50,
		"location": "PARK",
		"intro": "Bezpański pies broni swojego kawałka parku.",
	},
}

static func player() -> Dictionary:
	return PLAYER.duplicate(true)

static func enemy(enemy_id: String) -> Dictionary:
	assert(ENEMIES.has(enemy_id), "Brak konfiguracji przeciwnika: %s" % enemy_id)
	var config: Dictionary = ENEMIES[enemy_id]
	for required_key in ["display_name", "kind", "level", "max_health", "attack", "defense", "agility", "attack_range", "xp_reward"]:
		assert(config.has(required_key), "Przeciwnik %s nie ma pola %s" % [enemy_id, required_key])
	return config.duplicate(true)

static func has_enemy(enemy_id: String) -> bool:
	return ENEMIES.has(enemy_id)
