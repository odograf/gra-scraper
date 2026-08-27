class_name PlayerInventory
extends RefCounted

signal changed

const ItemCatalogScript := preload("res://scripts/item_catalog.gd")
const ITEMS := ItemCatalogScript.ITEMS

# Tymczasowy przełącznik prototypowy. Definicje pojemników pozostają zachowane,
# aby późniejsze przywrócenie limitów nie wymagało migracji ekwipunku.
const LIMITS_ENABLED := false

const CONTAINERS := {
	"plastic_bag": {"name": "Reklamówka", "capacity": 6, "max_weight": 4.0, "price": 0.0},
	"large_bag": {"name": "Duża torba", "capacity": 12, "max_weight": 8.0, "price": 12.0},
	"bucket": {"name": "Wiadro", "capacity": 10, "max_weight": 12.0, "price": 18.0}
}

const TOOL_MAX_DURABILITY := {"metal_shears": 6}

var items := {
	"can": 0, "mesh": 0, "wire": 0, "zuk_key": 0,
	"empty_beer_bottle": 0, "empty_vodka_bottle": 0, "bottle_caps": 0,
	"dog_collar": 0, "dog_tag": 0, "coin_pouch": 0
}
var owned_containers := {"plastic_bag": true}
var equipped_container := "plastic_bag"
var tools: Dictionary = {}

func item_count(item_id: String) -> int:
	return int(items.get(item_id, 0))

func used_space() -> int:
	var result := 0
	for item_id in items:
		var definition: Dictionary = ITEMS.get(item_id, {})
		result += int(definition.get("space", 0)) * item_count(item_id)
	return result

func current_weight() -> float:
	var result := 0.0
	for item_id in items:
		var definition: Dictionary = ITEMS.get(item_id, {})
		result += float(definition.get("weight", 0.0)) * item_count(item_id)
	return result

func capacity() -> int:
	return int(CONTAINERS[equipped_container].capacity)

func max_weight() -> float:
	return float(CONTAINERS[equipped_container].max_weight)

func container_name() -> String:
	return String(CONTAINERS[equipped_container].name)

func can_add(item_id: String, amount := 1) -> bool:
	if not ITEMS.has(item_id) or amount <= 0:
		return false
	if not LIMITS_ENABLED:
		return true
	var definition: Dictionary = ITEMS[item_id]
	var next_space := used_space() + int(definition.space) * amount
	var next_weight := current_weight() + float(definition.weight) * amount
	return next_space <= capacity() and next_weight <= max_weight()

func add_item(item_id: String, amount := 1) -> bool:
	if not can_add(item_id, amount):
		return false
	items[item_id] = item_count(item_id) + amount
	changed.emit()
	return true

func remove_item(item_id: String, amount := 1) -> bool:
	if item_count(item_id) < amount or amount <= 0:
		return false
	items[item_id] = item_count(item_id) - amount
	changed.emit()
	return true

func add_container(container_id: String) -> bool:
	if not CONTAINERS.has(container_id) or owned_containers.has(container_id):
		return false
	owned_containers[container_id] = true
	changed.emit()
	return true

func can_equip_container(container_id: String) -> bool:
	if not owned_containers.has(container_id):
		return false
	if not LIMITS_ENABLED:
		return true
	var definition: Dictionary = CONTAINERS[container_id]
	return used_space() <= int(definition.capacity) and current_weight() <= float(definition.max_weight)

func equip_container(container_id: String) -> bool:
	if not can_equip_container(container_id):
		return false
	equipped_container = container_id
	changed.emit()
	return true

# Narzędzia są osobnym wyposażeniem. Nie są uwzględniane w used_space() ani current_weight().
func add_tool(tool_id: String, durability: int) -> void:
	var maximum := int(TOOL_MAX_DURABILITY.get(tool_id, durability))
	tools[tool_id] = clampi(durability, 0, maximum)
	changed.emit()

func has_tool(tool_id: String) -> bool:
	return int(tools.get(tool_id, 0)) > 0

func tool_durability(tool_id: String) -> int:
	return int(tools.get(tool_id, 0))

func tool_max_durability(tool_id: String) -> int:
	return int(TOOL_MAX_DURABILITY.get(tool_id, 0))

func damage_tool(tool_id: String, amount := 1) -> bool:
	if not tools.has(tool_id) or amount <= 0:
		return false
	tools[tool_id] = maxi(0, tool_durability(tool_id) - amount)
	changed.emit()
	return true

func repair_tool(tool_id: String) -> int:
	if not tools.has(tool_id):
		return 0
	var missing := tool_max_durability(tool_id) - tool_durability(tool_id)
	tools[tool_id] = tool_max_durability(tool_id)
	changed.emit()
	return missing
