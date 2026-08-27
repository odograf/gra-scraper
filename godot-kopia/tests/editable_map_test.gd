extends SceneTree

var failures := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var map_scene: PackedScene = load("res://scenes/world_map.tscn")
	var editable_map := map_scene.instantiate() as WorldMap
	root.add_child(editable_map)
	await process_frame
	_expect(editable_map.editable_scene, "Mapa jest zapisana jako edytowalna scena")
	var terrain := editable_map.get_node_or_null("TerenBazowy") as TileMapLayer
	_expect(terrain != null, "Scena zawiera widoczną warstwę TileMapLayer")
	_expect(terrain != null and terrain.get_used_cells().size() > 200, "Kafelki podłoża są zapisane w scenie, a nie tworzone dopiero po starcie")
	_expect(editable_map.get_node_or_null("ZukGnojarz") is Sprite2D, "Budynki są osobnymi węzłami Sprite2D")
	_expect(editable_map.get_node_or_null("KolizjaKiosku") is StaticBody2D, "Kolizje są osobnymi węzłami edytora")
	_expect(editable_map.get_node_or_null("PunktyRozgrywki/Puszki").get_child_count() == 30, "Trzydzieści puszek ma przesuwalne markery")
	_expect(editable_map.get_node_or_null("PunktyRozgrywki/WatahyPsow/Wataha1").get_child_count() == 2, "Pierwsza wataha ma markery w scenie")
	_expect(editable_map.get_node_or_null("PunktyRozgrywki/WatahyPsow/Wataha2").get_child_count() == 3, "Druga wataha ma markery w scenie")
	_expect(editable_map.get_node_or_null("PunktyRozgrywki/WatahyPsow/Wataha3").get_child_count() == 4, "Trzecia wataha ma markery w scenie")
	editable_map.queue_free()
	await process_frame

	var main_scene: PackedScene = load("res://scenes/main.tscn")
	var game = main_scene.instantiate()
	root.add_child(game)
	await process_frame
	var world := game.get_node_or_null("Osiedle") as WorldMap
	_expect(world != null, "Main zawiera instancję edytowalnej mapy")
	var player_marker := world.get_node("PunktyRozgrywki/Start/Bohater") as Marker2D
	_expect(game.player.global_position == player_marker.global_position, "Pozycja bohatera pochodzi z markera sceny")
	var can_marker := world.get_node("PunktyRozgrywki/Puszki/Puszka01") as Marker2D
	_expect(game.get_node("Puszka1").global_position == can_marker.global_position, "Pozycja puszki pochodzi z markera sceny")
	var dog_marker := world.get_node("PunktyRozgrywki/WatahyPsow/Wataha1/Pies1") as Marker2D
	_expect(game.get_node("DzikiWychudzonyPies").global_position == dog_marker.global_position, "Pozycja psa pochodzi z markera sceny")
	_expect(not world.get_node("PunktyRozgrywki").visible, "Podglądy markerów są ukryte podczas gry")

	if failures == 0:
		print("EDITABLE_MAP_TEST_OK")
	else:
		printerr("EDITABLE_MAP_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
