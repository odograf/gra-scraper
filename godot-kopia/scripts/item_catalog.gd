class_name ItemCatalog
extends RefCounted

const ITEMS := {
	"can": {"name": "Puszka", "space": 1, "weight": 0.03},
	"mesh": {"name": "Fragment siatki", "space": 4, "weight": 4.0},
	"wire": {"name": "Kawałek drutu", "space": 1, "weight": 0.20},
	"zuk_key": {"name": "Klucz do Żuka", "space": 0, "weight": 0.0},
	"empty_beer_bottle": {
		"name": "Pusta butelka po piwie", "space": 2, "weight": 0.35,
		"texture": preload("res://assets/items/empty_beer_bottle.png")
	},
	"empty_vodka_bottle": {
		"name": "Pusta małpka", "space": 1, "weight": 0.18,
		"texture": preload("res://assets/items/empty_vodka_bottle.png")
	},
	"bottle_caps": {
		"name": "Garść kapsli", "space": 1, "weight": 0.05,
		"texture": preload("res://assets/items/bottle_caps.png")
	},
	"grosz_coins": {
		"name": "Garść groszy", "space": 0, "weight": 0.0,
		"texture": preload("res://assets/items/grosz_coins.png"),
		"cash_min_cents": 5, "cash_max_cents": 30
	},
	"one_zloty": {
		"name": "Złotówka", "space": 0, "weight": 0.0,
		"texture": preload("res://assets/items/one_zloty.png"),
		"cash_min_cents": 100, "cash_max_cents": 100
	},
	"dog_collar": {
		"name": "Stara obroża", "space": 2, "weight": 0.15,
		"texture": preload("res://assets/items/dog_collar.png")
	},
	"dog_tag": {
		"name": "Adresówka psa", "space": 1, "weight": 0.03,
		"texture": preload("res://assets/items/dog_tag.png")
	},
	"coin_pouch": {
		"name": "Sakiewka z drobnymi", "space": 1, "weight": 0.10,
		"texture": preload("res://assets/items/coin_pouch.png")
	}
}

# Jeden rzut na pokonaną grupę. Każda tabela ma gwarantowany czytelny drop,
# ale liczba rzutów na mapie jest mała: trzy watahy i dwa legowiska Szczórów.
const LOOT_TABLES := {
	"park_dog_pack": [
		{"item_id": "dog_collar", "weight": 65},
		{"item_id": "dog_tag", "weight": 35}
	],
	"sewer_rat_nest": [
		{"item_id": "bottle_caps", "weight": 55},
		{"item_id": "grosz_coins", "weight": 35},
		{"item_id": "one_zloty", "weight": 10}
	],
	"zadymiarz": [
		{"item_id": "empty_beer_bottle", "weight": 70},
		{"item_id": "empty_vodka_bottle", "weight": 30}
	],
	"burek": [
		{"item_id": "dog_collar", "weight": 50},
		{"item_id": "dog_tag", "weight": 50}
	],
	"zul_1": [
		{"item_id": "coin_pouch", "weight": 70},
		{"item_id": "empty_vodka_bottle", "weight": 30}
	]
}

static func definition(item_id: String) -> Dictionary:
	return ITEMS.get(item_id, {})

static func display_name(item_id: String) -> String:
	return String(definition(item_id).get("name", item_id))

static func is_direct_cash(item_id: String) -> bool:
	return int(definition(item_id).get("cash_max_cents", 0)) > 0

static func roll_cash_cents(item_id: String, rng: RandomNumberGenerator) -> int:
	var item := definition(item_id)
	var minimum := int(item.get("cash_min_cents", 0))
	var maximum := int(item.get("cash_max_cents", minimum))
	return rng.randi_range(minimum, maximum)

static func roll(table_id: String, rng: RandomNumberGenerator) -> String:
	var table: Array = LOOT_TABLES.get(table_id, [])
	var total_weight := 0
	for entry: Dictionary in table:
		total_weight += maxi(0, int(entry.get("weight", 0)))
	if total_weight <= 0:
		return ""
	var result := rng.randi_range(1, total_weight)
	for entry: Dictionary in table:
		result -= maxi(0, int(entry.get("weight", 0)))
		if result <= 0:
			return String(entry.get("item_id", ""))
	return ""
