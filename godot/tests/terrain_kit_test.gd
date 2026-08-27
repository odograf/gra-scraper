extends SceneTree

var failures := 0

func _init() -> void:
	var tile_set := load("res://assets/terrain/terrain_tileset_v1.tres") as TileSet
	_expect(tile_set != null, "Zestaw terenu można wczytać jako TileSet")
	if tile_set != null:
		_expect(tile_set.tile_size == Vector2i(128, 128), "TileSet używa siatki 128x128")
		_expect(tile_set.get_source_count() == 1, "TileSet ma jedno źródło atlasowe")
		var source := tile_set.get_source(0) as TileSetAtlasSource
		_expect(source != null, "Źródłem kafli jest atlas")
		if source != null:
			_expect(source.get_tiles_count() == 32, "Atlas zawiera 32 gotowe kafle")
			_expect(source.texture_region_size == Vector2i(128, 128), "Region atlasu odpowiada rozmiarowi kafla")

	var atlas := load("res://assets/terrain/terrain_atlas_v1.png") as Texture2D
	_expect(atlas != null, "Tekstura atlasu jest zaimportowana")
	if atlas != null:
		_expect(atlas.get_size() == Vector2(1024, 512), "Atlas ma regularną siatkę 8x4")

	for material_name in ["grass", "sidewalk", "asphalt"]:
		var texture := load("res://assets/terrain/%s_base_v1.png" % material_name) as Texture2D
		_expect(texture != null, "Materiał %s istnieje" % material_name)
		if texture != null:
			_expect(texture.get_size() == Vector2(128, 128), "Materiał %s ma rozmiar jednego kafla" % material_name)

	var world := WorldMap.new()
	root.add_child(world)
	await process_frame
	var terrain := world.get_node_or_null("TerenBazowy") as TileMapLayer
	_expect(terrain != null, "Mapa tworzy warstwę kafli terenu")
	if terrain != null:
		_expect(terrain.tile_set == tile_set, "Mapa korzysta z przygotowanego TileSetu")
		_expect(terrain.get_used_cells().size() == 22 * 13, "Kafle pokrywają cały świat 2800x1600")
		_expect(terrain.get_cell_atlas_coords(Vector2i(0, 0)).y == 0, "Północno-zachodnia część mapy ma podłoże bazowe")
		_expect(terrain.get_cell_atlas_coords(Vector2i(13, 0)).x >= 5, "Pionowa ulica korzysta z asfaltu")
		_expect(terrain.get_cell_atlas_coords(Vector2i(0, 8)).x >= 5, "Droga do garaży korzysta z asfaltu")

	if failures == 0:
		print("TERRAIN_KIT_TEST_OK")
	else:
		printerr("TERRAIN_KIT_TEST_FAILED: %d" % failures)
	quit(failures)

func _expect(condition: bool, description: String) -> void:
	if not condition:
		failures += 1
		printerr("FAIL: " + description)
