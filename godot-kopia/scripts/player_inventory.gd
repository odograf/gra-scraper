class_name PlayerInventory
extends RefCounted

signal changed

const ItemCatalogScript := preload("res://scripts/item_catalog.gd")
const BagWeaponCatalogScript := preload("res://scripts/bag_weapon_catalog.gd")
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
var owned_bag_weapons := {"plastic_bag": true, "black_sack": true}
var equipped_bag_weapon := "plastic_bag"
var bag_weapon_upgrades: Dictionary = {"plastic_bag": [], "black_sack": []}
var tools: Dictionary = {}

func save_snapshot() -> Dictionary:
	return {
		"items": items.duplicate(true),
		"owned_containers": owned_containers.duplicate(true),
		"equipped_container": equipped_container,
		"owned_bag_weapons": owned_bag_weapons.duplicate(true),
		"equipped_bag_weapon": equipped_bag_weapon,
		"bag_weapon_upgrades": bag_weapon_upgrades.duplicate(true),
		"tools": tools.duplicate(true)
	}

func restore_snapshot(data: Dictionary) -> void:
	var saved_items: Dictionary = data.get("items", {})
	for item_id in items:
		items[item_id] = maxi(0, int(saved_items.get(item_id, 0)))
	owned_containers = {"plastic_bag": true}
	var saved_containers: Dictionary = data.get("owned_containers", {})
	for container_id in saved_containers:
		if CONTAINERS.has(container_id) and bool(saved_containers[container_id]):
			owned_containers[container_id] = true
	var requested_container := String(data.get("equipped_container", "plastic_bag"))
	equipped_container = requested_container if owned_containers.has(requested_container) else "plastic_bag"
	owned_bag_weapons = {"plastic_bag": true, "black_sack": true}
	var saved_bag_weapons: Dictionary = data.get("owned_bag_weapons", {})
	for weapon_id in saved_bag_weapons:
		var typed_weapon_id := StringName(weapon_id)
		if BagWeaponCatalogScript.has_weapon(typed_weapon_id) and bool(saved_bag_weapons[weapon_id]):
			owned_bag_weapons[String(typed_weapon_id)] = true
	var requested_weapon := StringName(data.get("equipped_bag_weapon", "plastic_bag"))
	equipped_bag_weapon = String(requested_weapon) if owned_bag_weapons.has(String(requested_weapon)) else "plastic_bag"
	bag_weapon_upgrades = {"plastic_bag": [], "black_sack": []}
	var saved_upgrades: Dictionary = data.get("bag_weapon_upgrades", {})
	for weapon_id in saved_upgrades:
		if owned_bag_weapons.has(String(weapon_id)) and saved_upgrades[weapon_id] is Array:
			bag_weapon_upgrades[String(weapon_id)] = (saved_upgrades[weapon_id] as Array).duplicate()
	tools.clear()
	var saved_tools: Dictionary = data.get("tools", {})
	for tool_id in saved_tools:
		if TOOL_MAX_DURABILITY.has(tool_id):
			tools[tool_id] = clampi(int(saved_tools[tool_id]), 0, int(TOOL_MAX_DURABILITY[tool_id]))
	changed.emit()

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

func equip_bag_weapon(weapon_id: String) -> bool:
	if not owned_bag_weapons.has(weapon_id) or not BagWeaponCatalogScript.has_weapon(StringName(weapon_id)):
		return false
	equipped_bag_weapon = weapon_id
	changed.emit()
	return true

func bag_weapon_name() -> String:
	return BagWeaponCatalogScript.display_name(StringName(equipped_bag_weapon))

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
