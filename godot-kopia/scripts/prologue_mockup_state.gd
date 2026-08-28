class_name PrologueMockupState
extends RefCounted

# Proste dane przejściowe mockupu. Statyczny RefCounted wystarcza, ponieważ
# stan nie potrzebuje drzewa scen ani sygnałów.
static var run_started := false
static var has_bag := false
static var cans_collected := 0
static var current_health := -1
static var maximum_health := -1
static var main_entry_pending := false
static var equipped_bag_weapon := "plastic_bag"

static func begin_new_run() -> void:
	run_started = true
	has_bag = false
	cans_collected = 0
	current_health = -1
	maximum_health = -1
	main_entry_pending = false
	equipped_bag_weapon = "plastic_bag"

static func prepare_outside_preview() -> void:
	if run_started:
		return
	run_started = true
	has_bag = true
	cans_collected = 6

static func capture_health(current: int, maximum: int) -> void:
	current_health = current
	maximum_health = maximum

static func prepare_main_entry(current: int, maximum: int) -> void:
	capture_health(current, maximum)
	main_entry_pending = true

static func consume_main_entry() -> bool:
	var pending := main_entry_pending
	main_entry_pending = false
	return pending
