class_name BagWeaponCatalog
extends RefCounted

const DEFAULT_WEAPON_ID := &"plastic_bag"

const PLASTIC_BAG_TEXTURE := preload("res://assets/weapons/plastic_bag_attack_overlay_v1.png")
const BLACK_SACK_TEXTURE := preload("res://assets/weapons/black_sack_attack_overlay_v1.png")

# Broń torbowa jest osobnym wyposażeniem od pojemnika na łupy. Dzięki temu
# zmiana wiadra lub plecaka nie podmienia ataku, a ulepszenia (np. taśma)
# można później dopisać do konkretnej broni bez ruszania animacji ciała.
const WEAPONS := {
	&"plastic_bag": {
		"name": "Reklamówka",
		"texture": PLASTIC_BAG_TEXTURE,
		"columns": 4,
		"rows": 2,
		"background_key": &"none",
		"damage_bonus": 0,
		"upgrade_slots": 2
	},
	&"black_sack": {
		"name": "Czarny worek",
		"texture": BLACK_SACK_TEXTURE,
		"columns": 4,
		"rows": 2,
		"background_key": &"light_checkerboard",
		"damage_bonus": 0,
		"upgrade_slots": 2
	}
}

static func has_weapon(weapon_id: StringName) -> bool:
	return WEAPONS.has(weapon_id)

static func definition(weapon_id: StringName) -> Dictionary:
	return WEAPONS.get(weapon_id, WEAPONS[DEFAULT_WEAPON_ID])

static func display_name(weapon_id: StringName) -> String:
	return String(definition(weapon_id).name)

static func frame_size(weapon_id: StringName) -> Vector2i:
	var data := definition(weapon_id)
	var texture := data.texture as Texture2D
	return Vector2i(texture.get_width() / int(data.columns), texture.get_height() / int(data.rows))

