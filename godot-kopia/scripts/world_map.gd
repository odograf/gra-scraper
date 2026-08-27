@tool
class_name WorldMap
extends Node2D

@export var editable_scene := false

const WORLD_SIZE := Vector2(2800, 1600)
const FENCE_SHEET := preload("res://assets/props/fence_segments_v1.png")
const FENCE_FRAME_SIZE := Vector2i(724, 724)
const KIOSK_TEXTURE := preload("res://assets/buildings/kiosk_v1.png")
const ZUK_GNOJARZ_TEXTURE := preload("res://assets/buildings/zuk_gnojarz_v1.png")
const MIREK_ZUK_TEXTURE := preload("res://assets/props/mirek_zuk_front_v1.png")
const CRATE_CANS_TEXTURE := preload("res://assets/props/crate_cans_v1.png")
const CRATE_SCRAP_TEXTURE := preload("res://assets/props/crate_scrap_v1.png")
const TERRAIN_TILESET := preload("res://assets/terrain/terrain_tileset_v1.tres")
const TERRAIN_TILE_SIZE := Vector2i(128, 128)
const TERRAIN_SOURCE_ID := 0

const GRASS_TILES := [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0)]
const SIDEWALK_TILES := [Vector2i(3, 0), Vector2i(4, 0)]
const ASPHALT_TILES := [Vector2i(5, 0), Vector2i(6, 0), Vector2i(7, 0)]

func _ready() -> void:
	# W world_map.tscn teren, grafiki i kolizje są zapisanymi węzłami,
	# dzięki czemu widać je i można edytować w widoku 2D Godota.
	if editable_scene:
		queue_redraw()
		return
	_create_terrain()
	_create_collisions()
	_create_building_art()
	_create_fence_art()
	queue_redraw()

func _create_collisions() -> void:
	_add_rect_collision(Rect2(-30, -30, WORLD_SIZE.x + 60, 45), "GranicaGora")
	_add_rect_collision(Rect2(-30, WORLD_SIZE.y - 15, WORLD_SIZE.x + 60, 45), "GranicaDol")
	_add_rect_collision(Rect2(-30, 0, 45, WORLD_SIZE.y), "GranicaLewa")
	_add_rect_collision(Rect2(WORLD_SIZE.x - 15, 0, 45, WORLD_SIZE.y), "GranicaPrawa")
	_add_rect_collision(Rect2(2140, 70, 620, 350), "Sklep")
	_add_rect_collision(Rect2(895, 270, 290, 225), "KolizjaKiosku")
	_add_rect_collision(Rect2(170, 474, 225, 118), "Kosze")
	_add_rect_collision(Rect2(1900, 520, 240, 130), "KonteneryZaUlica")
	_add_rect_collision(Rect2(2260, 1095, 240, 130), "KonteneryPrzyGarazach")
	_add_rect_collision(Rect2(1420, 1305, 240, 130), "KonteneryNaPustymPlacu")
	_add_rect_collision(Rect2(1220, 300, 280, 108), "Lawka")
	_add_rect_collision(Rect2(1050, 700, 180, 105), "StarySamochod")
	# Żuk i skrzynki zamykają Mirka z trzech stron. Przejście od dołu ma 74 px.
	_add_rect_collision(Rect2(1320, 430, 280, 105), "ZukMirka")
	_add_rect_collision(Rect2(1305, 535, 118, 205), "SkrzynkiMirkaLewe")
	_add_rect_collision(Rect2(1497, 535, 118, 205), "SkrzynkiMirkaPrawe")
	_add_rect_collision(Rect2(2350, 780, 330, 155), "MagazynWschodni")
	_add_rect_collision(Rect2(650, 1260, 470, 170), "GarazeDolne")
	_add_rect_collision(Rect2(90, 855, 338, 28), "PlotLewyA")
	_add_rect_collision(Rect2(552, 855, 108, 28), "PlotLewyB")
	_add_rect_collision(Rect2(790, 855, 440, 28), "PlotPrawy")
	_add_circle_collision(Vector2(1597, 212), 28.0, "Slup")
	_add_circle_collision(Vector2(865, 165), 48.0, "Drzewo1")
	_add_circle_collision(Vector2(1750, 760), 52.0, "Drzewo2")
	_add_circle_collision(Vector2(2090, 830), 48.0, "Drzewo3")
	_add_circle_collision(Vector2(2700, 1050), 55.0, "Drzewo4")
	# Zaniedbany park w lewym dolnym narożniku. Drzewa zostawiają szeroką,
	# wydeptaną trasę od przerwy w płocie do wszystkich trzech polan.
	for park_tree in [
		[Vector2(72, 965), 30.0], [Vector2(250, 960), 32.0], [Vector2(575, 970), 31.0],
		[Vector2(82, 1160), 29.0], [Vector2(565, 1260), 34.0],
		[Vector2(72, 1510), 31.0], [Vector2(430, 1530), 34.0]
	]:
		_add_circle_collision(park_tree[0], park_tree[1], "DrzewoParkowe")
	_add_rect_collision(Rect2(92, 1218, 120, 30), "LawkaParkowaA")
	_add_rect_collision(Rect2(425, 1435, 120, 30), "LawkaParkowaB")

func _add_rect_collision(rect: Rect2, node_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	var collision := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = rect.size
	collision.shape = shape
	collision.position = rect.get_center()
	body.add_child(collision)
	add_child(body)

func _add_circle_collision(center: Vector2, radius: float, node_name: String) -> void:
	var body := StaticBody2D.new()
	body.name = node_name
	var collision := CollisionShape2D.new()
	var shape := CircleShape2D.new()
	shape.radius = radius
	collision.shape = shape
	collision.position = center
	body.add_child(collision)
	add_child(body)

func _draw() -> void:
	_draw_ground()
	_draw_bench()
	_draw_car()
	_draw_scrap_corner()
	_draw_extended_district()
	_draw_park()
	_draw_small_props()

func _create_building_art() -> void:
	_add_building_sprite("ZukGnojarz", ZUK_GNOJARZ_TEXTURE, Vector2(2450, 245), Vector2(0.40, 0.40))
	_add_building_sprite("Kiosk", KIOSK_TEXTURE, Vector2(1040, 350), Vector2(0.25, 0.25))
	_add_prop_sprite("ZukMirkaSprite", MIREK_ZUK_TEXTURE, Vector2(1460, 425), Vector2(0.19, 0.19), 4)
	_add_prop_sprite("SkrzynkaPuszekMirkaA", CRATE_CANS_TEXTURE, Vector2(1364, 585), Vector2(0.115, 0.115), 7)
	_add_prop_sprite("SkrzynkaPuszekMirkaB", CRATE_CANS_TEXTURE, Vector2(1364, 686), Vector2(0.115, 0.115), 7)
	_add_prop_sprite("SkrzynkaZlomuMirkaA", CRATE_SCRAP_TEXTURE, Vector2(1556, 585), Vector2(0.108, 0.108), 7)
	_add_prop_sprite("SkrzynkaZlomuMirkaB", CRATE_SCRAP_TEXTURE, Vector2(1556, 686), Vector2(0.108, 0.108), 7)

func _add_building_sprite(node_name: String, texture: Texture2D, sprite_position: Vector2, sprite_scale: Vector2) -> void:
	_add_prop_sprite(node_name, texture, sprite_position, sprite_scale, 3)

func _add_prop_sprite(node_name: String, texture: Texture2D, sprite_position: Vector2, sprite_scale: Vector2, layer: int) -> void:
	var sprite := Sprite2D.new()
	sprite.name = node_name
	sprite.texture = texture
	sprite.position = sprite_position
	sprite.scale = sprite_scale
	sprite.z_index = layer
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(sprite)

func _draw_ground() -> void:
	# Drobne detale są rysowane nad kaflami: pęknięcia placu i starte linie jezdni.
	for i in range(28):
		var point := Vector2(85 + (i * 193) % 790, 445 + (i * 127) % 430)
		draw_line(point, point + Vector2(22, 8), Color("#555650"), 2)
		draw_line(point + Vector2(22, 8), point + Vector2(13, 25), Color("#555650"), 2)
	for y in range(15, int(WORLD_SIZE.y), 100):
		draw_rect(Rect2(1773, y, 7, 48), Color("#d4bd72"))
	for x in range(20, int(WORLD_SIZE.x), 120):
		draw_rect(Rect2(x, 1126, 62, 6), Color("#d4bd72"))

func _create_terrain() -> void:
	var terrain := TileMapLayer.new()
	terrain.name = "TerenBazowy"
	terrain.tile_set = TERRAIN_TILESET
	terrain.z_index = -10
	terrain.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(terrain)

	var map_size := Vector2i(
		ceili(WORLD_SIZE.x / TERRAIN_TILE_SIZE.x),
		ceili(WORLD_SIZE.y / TERRAIN_TILE_SIZE.y)
	)
	for y in range(map_size.y):
		for x in range(map_size.x):
			_set_terrain_cell(terrain, Vector2i(x, y), GRASS_TILES, x * 17 + y * 31)

	# Stary asfaltowy plac przy kontenerach.
	_paint_area_with_grass_edges(terrain, Rect2i(0, 3, 8, 4), ASPHALT_TILES, 2)
	# Wydeptany chodnik i plac przed kioskiem.
	_paint_area_with_grass_edges(terrain, Rect2i(6, 1, 4, 3), SIDEWALK_TILES, 1)

	# Główna ulica i poprzeczny dojazd do garaży.
	_paint_rect(terrain, Rect2i(13, 0, 2, map_size.y), ASPHALT_TILES)
	_paint_rect(terrain, Rect2i(0, 8, map_size.x, 2), ASPHALT_TILES)

	# Betonowe chodniki po obu stronach dróg. Przy skrzyżowaniu asfalt ma
	# pierwszeństwo, żeby nie powstawały zamknięte pasy przez środek jezdni.
	_paint_rect(terrain, Rect2i(12, 0, 1, map_size.y), SIDEWALK_TILES)
	_paint_rect(terrain, Rect2i(15, 0, 1, map_size.y), SIDEWALK_TILES)
	_paint_rect(terrain, Rect2i(0, 7, map_size.x, 1), SIDEWALK_TILES)
	_paint_rect(terrain, Rect2i(0, 10, map_size.x, 1), SIDEWALK_TILES)
	_paint_rect(terrain, Rect2i(12, 7, 4, 4), ASPHALT_TILES)
	_paint_rect(terrain, Rect2i(13, 0, 2, map_size.y), ASPHALT_TILES)
	_paint_rect(terrain, Rect2i(0, 8, map_size.x, 2), ASPHALT_TILES)

func _paint_rect(layer: TileMapLayer, rect: Rect2i, tiles: Array) -> void:
	for y in range(rect.position.y, rect.end.y):
		for x in range(rect.position.x, rect.end.x):
			_set_terrain_cell(layer, Vector2i(x, y), tiles, x * 13 + y * 29)

func _paint_area_with_grass_edges(layer: TileMapLayer, rect: Rect2i, tiles: Array, transition_row: int) -> void:
	_paint_rect(layer, rect, tiles)
	if rect.size.x < 2 or rect.size.y < 2:
		return
	for x in range(rect.position.x + 1, rect.end.x - 1):
		layer.set_cell(Vector2i(x, rect.position.y), TERRAIN_SOURCE_ID, Vector2i(2, transition_row))
		layer.set_cell(Vector2i(x, rect.end.y - 1), TERRAIN_SOURCE_ID, Vector2i(0, transition_row))
	for y in range(rect.position.y + 1, rect.end.y - 1):
		layer.set_cell(Vector2i(rect.position.x, y), TERRAIN_SOURCE_ID, Vector2i(1, transition_row))
		layer.set_cell(Vector2i(rect.end.x - 1, y), TERRAIN_SOURCE_ID, Vector2i(3, transition_row))
	layer.set_cell(rect.position, TERRAIN_SOURCE_ID, Vector2i(6, transition_row))
	layer.set_cell(Vector2i(rect.end.x - 1, rect.position.y), TERRAIN_SOURCE_ID, Vector2i(7, transition_row))
	layer.set_cell(Vector2i(rect.end.x - 1, rect.end.y - 1), TERRAIN_SOURCE_ID, Vector2i(4, transition_row))
	layer.set_cell(Vector2i(rect.position.x, rect.end.y - 1), TERRAIN_SOURCE_ID, Vector2i(5, transition_row))

func _set_terrain_cell(layer: TileMapLayer, cell: Vector2i, choices: Array, seed_value: int) -> void:
	var atlas_coords: Vector2i = choices[abs(seed_value) % choices.size()]
	layer.set_cell(cell, TERRAIN_SOURCE_ID, atlas_coords)

func _draw_extended_district() -> void:
	# Magazyn i pusty plac z porzuconymi elementami.
	draw_rect(Rect2(2350, 780, 330, 155), Color("#5d5b51"))
	draw_colored_polygon(PackedVector2Array([Vector2(2325, 800), Vector2(2390, 735), Vector2(2630, 735), Vector2(2700, 800)]), Color("#41413c"))
	draw_rect(Rect2(2410, 825, 110, 110), Color("#353b39"))
	draw_rect(Rect2(650, 1260, 470, 170), Color("#5b5c53"))
	for x in range(670, 1100, 105):
		draw_rect(Rect2(x, 1290, 82, 115), Color("#3d4540"))
	# Złom rozsiany po nowej części mapy.
	for pos in [Vector2(2020, 690), Vector2(2180, 930), Vector2(2590, 620), Vector2(1300, 1390), Vector2(1860, 1450), Vector2(2520, 1320)]:
		draw_line(pos, pos + Vector2(55, -13), Color("#6b4836"), 9)
		draw_line(pos + Vector2(8, 18), pos + Vector2(63, 3), Color("#777b70"), 5)
		draw_circle(pos + Vector2(70, 7), 13, Color("#343735"), false, 5)
	_draw_tree(Vector2(2090, 830), 52)
	_draw_tree(Vector2(2700, 1050), 60)

func _draw_park() -> void:
	# Ciemniejsza, nierówno wydeptana murawa odcina park od reszty osiedla.
	draw_rect(Rect2(28, 910, 590, 650), Color("#33432d99"))
	draw_rect(Rect2(28, 910, 590, 650), Color("#687053"), false, 5.0)
	var path := PackedVector2Array([
		Vector2(700, 905), Vector2(590, 960), Vector2(485, 1050),
		Vector2(405, 1190), Vector2(330, 1345), Vector2(270, 1560)
	])
	draw_polyline(path, Color("#77705b"), 72.0, true)
	draw_polyline(path, Color("#9a8e70aa"), 4.0, true)
	# Boczne ścieżki prowadzą do polan watah i puszek.
	draw_polyline(PackedVector2Array([Vector2(500, 1040), Vector2(555, 1080)]), Color("#77705b"), 42.0, true)
	draw_polyline(PackedVector2Array([Vector2(390, 1210), Vector2(300, 1260)]), Color("#77705b"), 38.0, true)
	draw_polyline(PackedVector2Array([Vector2(320, 1370), Vector2(175, 1450)]), Color("#77705b"), 42.0, true)

	for park_tree in [
		[Vector2(72, 965), 38.0], [Vector2(250, 960), 42.0], [Vector2(575, 970), 40.0],
		[Vector2(82, 1160), 38.0], [Vector2(565, 1260), 45.0],
		[Vector2(72, 1510), 40.0], [Vector2(430, 1530), 45.0]
	]:
		_draw_tree(park_tree[0], park_tree[1])

	_draw_park_bench(Vector2(92, 1218))
	_draw_park_bench(Vector2(425, 1435))
	for shrub_position in [Vector2(155, 1015), Vector2(520, 1140), Vector2(125, 1310), Vector2(500, 1360), Vector2(355, 1500)]:
		draw_circle(shrub_position, 17.0, Color("#3c4d34"))
		draw_circle(shrub_position + Vector2(12, -5), 13.0, Color("#485a3b"))
	draw_string(ThemeDB.fallback_font, Vector2(45, 940), "STARY PARK", HORIZONTAL_ALIGNMENT_LEFT, 180, 17, Color("#cfc79a"))

func _draw_park_bench(position: Vector2) -> void:
	draw_rect(Rect2(position + Vector2(4, 7), Vector2(120, 28)), Color("#14161255"))
	for y in [0.0, 11.0]:
		draw_rect(Rect2(position + Vector2(0, y), Vector2(120, 8)), Color("#654832"))
		draw_line(position + Vector2(5, y + 2), position + Vector2(114, y + 2), Color("#8a6747"), 1.5)
	for x in [12.0, 100.0]:
		draw_rect(Rect2(position + Vector2(x, 18), Vector2(7, 13)), Color("#3e413a"))

func _draw_shop() -> void:
	draw_rect(Rect2(145, 96, 660, 360), Color(0, 0, 0, 0.25))
	draw_rect(Rect2(120, 70, 660, 360), Color("#c8b995"))
	draw_colored_polygon(PackedVector2Array([Vector2(95, 92), Vector2(165, 30), Vector2(735, 30), Vector2(805, 92)]), Color("#4d4a43"))
	for x in range(140, 760, 80):
		draw_line(Vector2(x, 72), Vector2(x + 35, 37), Color("#333632"), 4)
	# Witryna, drzwi i markiza.
	draw_rect(Rect2(350, 195, 350, 145), Color("#313a3a"))
	draw_rect(Rect2(360, 205, 160, 125), Color("#647575"))
	draw_rect(Rect2(530, 205, 160, 125), Color("#596a6a"))
	var stripe := 0
	for x in range(330, 720, 46):
		var stripe_color := Color("#994b3b") if stripe % 2 == 0 else Color("#d1bf94")
		draw_colored_polygon(PackedVector2Array([Vector2(x, 170), Vector2(x + 40, 170), Vector2(x + 30, 205), Vector2(x - 8, 205)]), stripe_color)
		stripe += 1
	draw_rect(Rect2(170, 205, 120, 225), Color("#35483e"))
	draw_rect(Rect2(193, 235, 74, 62), Color("#758987"))
	draw_circle(Vector2(269, 330), 6, Color("#d6b863"))
	draw_rect(Rect2(260, 103, 380, 55), Color("#ded3b9"))
	draw_rect(Rect2(260, 103, 380, 55), Color("#6e6758"), false, 5)
	for point in [Vector2(155, 135), Vector2(722, 122), Vector2(320, 374), Vector2(660, 380)]:
		draw_line(point, point + Vector2(14, 8), Color("#8f826c"), 2)
		draw_line(point + Vector2(14, 8), point + Vector2(8, 24), Color("#8f826c"), 2)

func _draw_bins() -> void:
	_draw_bin(Vector2(190, 480), Color("#5d6460"), 88)
	_draw_bin(Vector2(285, 492), Color("#686d66"), 92)
	_draw_bin(Vector2(365, 505), Color("#405745"), 72)

func _draw_bin(position: Vector2, color: Color, width: float) -> void:
	draw_rect(Rect2(position + Vector2(7, 8), Vector2(width, 92)), Color(0, 0, 0, 0.22))
	draw_colored_polygon(PackedVector2Array([position + Vector2(8, 10), position + Vector2(width - 8, 10), position + Vector2(width - 15, 92), position + Vector2(15, 92)]), color)
	draw_rect(Rect2(position, Vector2(width, 18)), color.lightened(0.13))
	draw_line(position + Vector2(24, 30), position + Vector2(20, 78), color.darkened(0.2), 3)
	draw_circle(position + Vector2(18, 98), 8, Color("#2b2e2c"))
	draw_circle(position + Vector2(width - 18, 98), 8, Color("#2b2e2c"))

func _draw_bench() -> void:
	var pos := Vector2(1220, 300)
	draw_rect(Rect2(pos + Vector2(18, 80), Vector2(265, 30)), Color(0, 0, 0, 0.2))
	for y in [8, 35, 62]:
		draw_rect(Rect2(pos + Vector2(0, y), Vector2(280, 19)), Color("#6f4935"))
		draw_line(pos + Vector2(8, y + 5), pos + Vector2(265, y + 2), Color("#9a6847"), 2)
	for x in [30, 244]:
		draw_rect(Rect2(pos + Vector2(x, 75), Vector2(16, 32)), Color("#454743"))

func _draw_fences() -> void:
	_draw_fence_segment(Vector2(90, 855), Vector2(660, 855))
	_draw_fence_segment(Vector2(790, 855), Vector2(1230, 855))
	draw_circle(Vector2(660, 855), 9, Color("#bbb29e"))
	draw_circle(Vector2(790, 855), 9, Color("#bbb29e"))

func _draw_fence_segment(from: Vector2, to: Vector2) -> void:
	draw_line(from, to, Color("#8d8d82"), 5)
	for x in range(int(from.x), int(to.x) + 1, 42):
		draw_line(Vector2(x, from.y - 38), Vector2(x, from.y + 10), Color("#a6a397"), 5)
		draw_line(Vector2(x, from.y - 30), Vector2(x + 35, from.y), Color("#6f746d"), 2)

func _create_fence_art() -> void:
	# Zwykłe przęsła omijają środkowy fragment obsługiwany przez ScrapFence.
	var panel_centers := [146.0, 258.0, 370.0, 606.0, 845.0, 955.0, 1065.0, 1175.0]
	for x in panel_centers:
		var sprite := Sprite2D.new()
		sprite.name = "PlotZwykly"
		sprite.texture = _fence_frame(0)
		sprite.position = Vector2(x, 809)
		sprite.scale = Vector2(0.18, 0.18)
		sprite.z_index = 4
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(sprite)

func _fence_frame(column: int) -> AtlasTexture:
	var frame := AtlasTexture.new()
	frame.atlas = FENCE_SHEET
	frame.region = Rect2(Vector2(column * FENCE_FRAME_SIZE.x, 0), Vector2(FENCE_FRAME_SIZE))
	return frame

func _draw_car() -> void:
	var pos := Vector2(1050, 700)
	draw_rect(Rect2(pos + Vector2(8, 14), Vector2(180, 95)), Color(0, 0, 0, 0.25))
	draw_colored_polygon(PackedVector2Array([pos + Vector2(8, 35), pos + Vector2(40, 6), pos + Vector2(140, 6), pos + Vector2(178, 38), pos + Vector2(170, 90), pos + Vector2(12, 90)]), Color("#764a36"))
	draw_rect(Rect2(pos + Vector2(48, 14), Vector2(80, 33)), Color("#526365"))
	draw_circle(pos + Vector2(35, 91), 18, Color("#282b29"))
	draw_circle(pos + Vector2(150, 91), 18, Color("#282b29"))

func _draw_scrap_corner() -> void:
	# Mały punkt skupu Mirka przy ulicy.
	draw_rect(Rect2(1320, 485, 245, 210), Color("#56594f"))
	for x in range(1330, 1560, 28):
		draw_line(Vector2(x, 490), Vector2(x, 688), Color("#696d62"), 2)
	draw_rect(Rect2(1340, 455, 205, 48), Color("#b6aa87"))
	draw_rect(Rect2(1340, 455, 205, 48), Color("#554e42"), false, 4)
	draw_string(ThemeDB.fallback_font, Vector2(1360, 487), "SKUP ZLOMU", HORIZONTAL_ALIGNMENT_CENTER, 165, 18, Color("#3a3933"))
	draw_rect(Rect2(1375, 625, 145, 40), Color("#454842"))
	draw_rect(Rect2(1390, 632, 115, 22), Color("#777b70"))

func _draw_small_props() -> void:
	draw_colored_polygon(PackedVector2Array([Vector2(650, 695), Vector2(735, 674), Vector2(830, 708), Vector2(800, 755), Vector2(688, 746)]), Color("#596d6c88"))
	draw_line(Vector2(680, 765), Vector2(805, 723), Color("#6c3f2d"), 9)
	draw_line(Vector2(682, 763), Vector2(808, 721), Color("#a0653f"), 2)
	draw_rect(Rect2(1570, 180, 54, 82), Color("#5a493a"))
	draw_line(Vector2(1597, 180), Vector2(1597, 20), Color("#493a30"), 18)
	draw_line(Vector2(1597, 30), Vector2(1820, 92), Color("#323430"), 4)
	_draw_tree(Vector2(865, 165), 52)
	_draw_tree(Vector2(1750, 760), 58)
	for pos in [Vector2(900, 580), Vector2(1500, 620), Vector2(460, 980), Vector2(1390, 920)]:
		draw_line(pos, pos + Vector2(-8, -15), Color("#4b563d"), 3)
		draw_line(pos, pos + Vector2(5, -18), Color("#4b563d"), 3)

func _draw_tree(position: Vector2, radius: float) -> void:
	draw_circle(position + Vector2(8, 16), radius, Color(0, 0, 0, 0.2))
	draw_circle(position, radius, Color("#34452f"))
	draw_circle(position - Vector2(15, 10), radius * 0.65, Color("#45563a"))
	draw_circle(position + Vector2(22, -9), radius * 0.58, Color("#3d5036"))
	draw_rect(Rect2(position + Vector2(-8, 32), Vector2(16, 40)), Color("#574433"))
