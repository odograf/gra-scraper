class_name GameSaveManager
extends Node

signal game_saved(slot: int)
signal game_loaded(slot: int)
signal save_failed(slot: int, reason: String)

const SAVE_VERSION := 1
const SLOT_COUNT := 3
const GAME_SCENE := "res://scenes/main.tscn"
const MENU_SCENE := "res://scenes/main_menu.tscn"

var save_prefix := "user://zlomiarz_slot_"
var current_slot := 0
var pending_load_data: Dictionary = {}

func slot_path(slot: int) -> String:
	return "%s%d.save" % [save_prefix, slot]

func has_save(slot: int) -> bool:
	return _valid_slot(slot) and FileAccess.file_exists(slot_path(slot))

func save_game(slot: int, game_data: Dictionary) -> bool:
	if not _valid_slot(slot):
		save_failed.emit(slot, "Nieprawidłowy slot zapisu.")
		return false
	var payload := game_data.duplicate(true)
	payload["version"] = SAVE_VERSION
	payload["saved_at"] = Time.get_datetime_string_from_system(false, true)
	var path := slot_path(slot)
	var temporary_path := path + ".tmp"
	var backup_path := path + ".bak"
	var file := FileAccess.open(temporary_path, FileAccess.WRITE)
	if file == null:
		save_failed.emit(slot, "Nie udało się otworzyć pliku zapisu.")
		return false
	file.store_var(payload, false)
	file.close()
	var absolute_path := ProjectSettings.globalize_path(path)
	var absolute_temporary := ProjectSettings.globalize_path(temporary_path)
	var absolute_backup := ProjectSettings.globalize_path(backup_path)
	if FileAccess.file_exists(path):
		DirAccess.copy_absolute(absolute_path, absolute_backup)
		DirAccess.remove_absolute(absolute_path)
	var rename_error := DirAccess.rename_absolute(absolute_temporary, absolute_path)
	if rename_error != OK:
		if FileAccess.file_exists(backup_path):
			DirAccess.copy_absolute(absolute_backup, absolute_path)
		save_failed.emit(slot, "Nie udało się zatwierdzić pliku zapisu.")
		return false
	current_slot = slot
	game_saved.emit(slot)
	return true

func load_game(slot: int) -> Dictionary:
	if not _valid_slot(slot):
		return {}
	var data := _read_save(slot_path(slot))
	if data.is_empty():
		data = _read_save(slot_path(slot) + ".bak")
	if data.is_empty():
		return {}
	var version := int(data.get("version", 0))
	if version > SAVE_VERSION:
		return {}
	if version < SAVE_VERSION:
		data = _migrate_save(data, version)
	return data

func request_load(slot: int) -> bool:
	var data := load_game(slot)
	if data.is_empty():
		return false
	current_slot = slot
	pending_load_data = data
	game_loaded.emit(slot)
	return true

func start_new_game() -> void:
	current_slot = 0
	pending_load_data.clear()

func consume_pending_load() -> Dictionary:
	var data := pending_load_data.duplicate(true)
	pending_load_data.clear()
	return data

func slot_summary(slot: int) -> Dictionary:
	var data := load_game(slot)
	if data.is_empty():
		return {"exists": false, "slot": slot}
	var progress: Dictionary = data.get("progress", {})
	var fab: Dictionary = data.get("fab01", {})
	return {
		"exists": true,
		"slot": slot,
		"saved_at": String(data.get("saved_at", "brak daty")).replace("T", " "),
		"level": clampi(int(progress.get("level", 1)), 1, 999),
		"stage": String(fab.get("stage", "pick_up_bag"))
	}

func _read_save(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var value: Variant = file.get_var(false)
	file.close()
	return value as Dictionary if value is Dictionary else {}

func _migrate_save(data: Dictionary, from_version: int) -> Dictionary:
	var migrated := data.duplicate(true)
	if from_version <= 0:
		migrated["version"] = 1
	return migrated

func _valid_slot(slot: int) -> bool:
	return slot >= 1 and slot <= SLOT_COUNT
