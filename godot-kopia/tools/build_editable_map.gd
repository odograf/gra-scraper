extends SceneTree

const WorldMapScript := preload("res://scripts/world_map.gd")
const CAN_TEXTURE := preload("res://assets/items/crushed_can.png")
const DOG_TEXTURE := preload("res://assets/animals/wild_emaciated_dog_sheet_v2_packed.png")
const OUTPUT_PATH := "res://scenes/world_map.tscn"

func _init() -> void:
	call_deferred("_build")

func _build() -> void:
	var world := WorldMapScript.new() as WorldMap
	world.name = "Osiedle"
	world.editable_scene = true
	world.y_sort_enabled = true
	world.editor_description = "Edytowalna mapa. Podłoże maluj na warstwie TerenBazowy; pozycje obiektów zmieniaj w PunktyRozgrywki."
	root.add_child(world)
	await process_frame

	# Te metody tworzą tę samą geometrię co dotychczasowa mapa runtime,
	# ale wynik zostaje zapisany jako zwykłe, edytowalne węzły sceny.
	world._create_terrain()
	world._create_collisions()
	world._create_building_art()
	world._create_fence_art()
	_create_gameplay_markers(world)

	root.remove_child(world)
	_set_scene_owner_recursive(world, world)
	var packed := PackedScene.new()
	var pack_error := packed.pack(world)
	if pack_error != OK:
		printerr("Nie udało się spakować mapy: %s" % error_string(pack_error))
		quit(1)
		return
	var save_error := ResourceSaver.save(packed, OUTPUT_PATH)
	if save_error != OK:
		printerr("Nie udało się zapisać mapy: %s" % error_string(save_error))
		quit(1)
		return
	print("EDITABLE_MAP_BUILT_OK")
	quit()

func _create_gameplay_markers(world: WorldMap) -> void:
	var markers := Node2D.new()
	markers.name = "PunktyRozgrywki"
	markers.editor_description = "Przesuwaj te markery w widoku 2D. Gra odczytuje ich pozycje podczas uruchamiania."
	world.add_child(markers)

	var starts := _folder(markers, "Start")
	_marker(starts, "Bohater", Vector2(850, 600), "Pozycja startowa bohatera")

	var interactions := _folder(markers, "Interakcje")
	_marker(interactions, "ReklamowkaStartowa", Vector2(815, 625), "Startowa reklamówka")
	_marker(interactions, "AutomatNaPuszki", Vector2(835, 430), "Automat na puszki")
	_marker(interactions, "WejscieDoSklepu", Vector2(2450, 450), "Drzwi Żuka Gnojarza")
	_marker(interactions, "OkienkoKiosku", Vector2(1040, 520), "Okienko kiosku")
	_marker(interactions, "ZadymiarzPodKioskiem", Vector2(1160, 580), "Przeciwnik walki turowej")
	_marker(interactions, "Mirek", Vector2(1460, 610), "Mirek")
	_marker(interactions, "Heniek", Vector2(1210, 1335), "Heniek Mechanik")
	_marker(interactions, "SiatkaDoWyciecia", Vector2(490, 855), "Fragment płotu do wycięcia")

	var npc_states := _folder(markers, "StanyNPC")
	_marker(npc_states, "BurekStart", Vector2(2450, 470), "Burek blokujący drzwi")
	_marker(npc_states, "BurekPoWalce", Vector2(2310, 520), "Burek po przegranej")
	_marker(npc_states, "ZulCzeka", Vector2(1660, 690), "Żul przed aktywacją blokady")
	_marker(npc_states, "ZulBlokuje", Vector2(1460, 750), "Żul blokujący przejście")
	_marker(npc_states, "ZulPoWalce", Vector2(1660, 760), "Żul po przegranej")

	var trash := _folder(markers, "Kontenery")
	_marker(trash, "KonteneryStartowe", Vector2(300, 535), "Kontenery startowe", {"guaranteed_wire": false})
	_marker(trash, "KonteneryZaUlica", Vector2(2020, 585), "Kontenery za ulicą", {"guaranteed_wire": true})
	_marker(trash, "KonteneryPrzyGarazach", Vector2(2380, 1160), "Kontenery przy garażach", {"guaranteed_wire": true})
	_marker(trash, "KonteneryNaPustymPlacu", Vector2(1540, 1370), "Kontenery na pustym placu", {"guaranteed_wire": true})

	var dog_positions := [
		[Vector2(470, 1020), Vector2(550, 1080)],
		[Vector2(315, 1190), Vector2(400, 1230), Vector2(330, 1280)],
		[Vector2(140, 1370), Vector2(230, 1400), Vector2(175, 1470), Vector2(285, 1490)]
	]
	var packs := _folder(markers, "WatahyPsow")
	for pack_index in range(dog_positions.size()):
		var pack := _folder(packs, "Wataha%d" % (pack_index + 1))
		for dog_index in range(dog_positions[pack_index].size()):
			var dog_marker := _marker(pack, "Pies%d" % (dog_index + 1), dog_positions[pack_index][dog_index], "Dziki pies — wataha %d" % (pack_index + 1), {
				"pack_id": pack_index + 1,
				"dog_index": dog_index + 1
			})
			_add_dog_preview(dog_marker)

	var can_positions := [
		Vector2(620, 560), Vector2(770, 720), Vector2(960, 670), Vector2(1260, 610),
		Vector2(1480, 800), Vector2(520, 785), Vector2(1030, 610), Vector2(1260, 870),
		Vector2(1880, 280), Vector2(2010, 610), Vector2(2030, 720), Vector2(2310, 710),
		Vector2(2650, 600), Vector2(2680, 820), Vector2(2070, 980), Vector2(2250, 1260),
		Vector2(2510, 1370), Vector2(1790, 1240), Vector2(1450, 1460), Vector2(1090, 1320),
		Vector2(720, 1210), Vector2(390, 1390), Vector2(2650, 1510), Vector2(1900, 1490),
		Vector2(430, 1070), Vector2(590, 1025), Vector2(270, 1245), Vector2(450, 1180),
		Vector2(115, 1430), Vector2(335, 1435)
	]
	var cans := _folder(markers, "Puszki")
	for index in range(can_positions.size()):
		var can_marker := _marker(cans, "Puszka%02d" % (index + 1), can_positions[index], "Puszka nr %d" % (index + 1), {
			"spawn_index": index,
			"rotation": float(index % 3 - 1) * 0.35
		}, false)
		_add_can_preview(can_marker)

func _folder(parent: Node, node_name: String) -> Node2D:
	var folder := Node2D.new()
	folder.name = node_name
	parent.add_child(folder)
	return folder

func _marker(parent: Node, node_name: String, marker_position: Vector2, description: String, metadata := {}, show_label := true) -> Marker2D:
	var marker := Marker2D.new()
	marker.name = node_name
	marker.position = marker_position
	marker.editor_description = description
	for key in metadata:
		marker.set_meta(key, metadata[key])
	parent.add_child(marker)
	if show_label:
		var label := Label.new()
		label.name = "Opis"
		label.text = description
		label.position = Vector2(10, -22)
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color("#ffe29a"))
		label.add_theme_color_override("font_shadow_color", Color("#111111"))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		marker.add_child(label)
	return marker

func _add_can_preview(marker: Marker2D) -> void:
	var sprite := Sprite2D.new()
	sprite.name = "PodgladPuszki"
	sprite.texture = CAN_TEXTURE
	sprite.scale = Vector2(0.055, 0.055)
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	marker.add_child(sprite)

func _add_dog_preview(marker: Marker2D) -> void:
	var atlas := AtlasTexture.new()
	atlas.atlas = DOG_TEXTURE
	atlas.region = Rect2(0, 0, 512, 384)
	var sprite := Sprite2D.new()
	sprite.name = "PodgladPsa"
	sprite.texture = atlas
	sprite.offset = Vector2(512, 384) * 0.5 - Vector2(230, 330)
	sprite.scale = Vector2.ONE * 0.29
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	marker.add_child(sprite)

func _set_scene_owner_recursive(node: Node, scene_root: Node) -> void:
	for child in node.get_children():
		child.owner = scene_root
		_set_scene_owner_recursive(child, scene_root)
