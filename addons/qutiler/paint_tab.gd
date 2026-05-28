@tool
extends Control

signal selection_changed(tiles: Array[Vector2i])

@onready var property_select = %PropertySelect
@onready var atlas_texture = %AtlasTexture
@onready var zoom_out = %ZoomOut
@onready var zoom_in = %ZoomIn
@onready var zoom_lbl = %ZoomLbl
@onready var scroll_container = %Scroll

var tileset: TileSet = null
var current_source: TileSetAtlasSource = null
var tile_size: Vector2i = Vector2i(16, 16)

var is_painting: bool = false
var current_property: String = "select"
var selected_tiles: Array[Vector2i] = []
var paint_zoom: float = 1.0
var active_physics_layer: int = 0

func _ready():	
	set_anchors_preset(PRESET_FULL_RECT) 
	if has_node("VBox"):
		$VBox.set_anchors_preset(PRESET_FULL_RECT)
		
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	atlas_texture.focus_mode = Control.FOCUS_NONE
	atlas_texture.mouse_filter = Control.MOUSE_FILTER_STOP
	
	zoom_out.pressed.connect(func(): _set_zoom(paint_zoom - 0.25))
	zoom_in.pressed.connect(func(): _set_zoom(paint_zoom + 0.25))
	
	property_select.item_selected.connect(_on_property_selected)
	atlas_texture.texture_filter = TEXTURE_FILTER_NEAREST
	atlas_texture.gui_input.connect(_on_atlas_gui_input)
	atlas_texture.draw.connect(_on_atlas_draw)

func set_tileset(ts: TileSet):
	tileset = ts
	if tileset:
		tile_size = tileset.tile_size
		if tileset.get_source_count() > 0:
			var source_id = tileset.get_source_id(0)
			current_source = tileset.get_source(source_id) as TileSetAtlasSource
			if current_source and current_source.texture:
				atlas_texture.texture = current_source.texture
				_set_zoom(1.0)

func set_physics_layer(layer_index: int):
	active_physics_layer = layer_index
	atlas_texture.queue_redraw()

func _set_zoom(val: float):
	paint_zoom = clamp(val, 0.5, 5.0)
	zoom_lbl.text = str(round(paint_zoom * 100)) + "%"
	if current_source and current_source.texture:
		atlas_texture.custom_minimum_size = current_source.texture.get_size() * paint_zoom
	atlas_texture.queue_redraw()

func _on_property_selected(idx: int):
	current_property = ["select", "physics_add", "physics_clear"][idx]
	atlas_texture.queue_redraw()

func _on_atlas_gui_input(event: InputEvent):
	if not current_source: return
	
	atlas_texture.accept_event()
	
	if event is InputEventMagnifyGesture or event is InputEventPanGesture:
		return 
	
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event is InputEventMouseButton and event.button_index != MOUSE_BUTTON_LEFT:
			return
			
		is_painting = event.pressed
		if is_painting:
			if current_property == "select" and not Input.is_key_pressed(KEY_SHIFT):
				selected_tiles.clear()
			_paint_data_at(event.position)
			
	elif (event is InputEventScreenDrag or event is InputEventMouseMotion) and is_painting:
		_paint_data_at(event.position)

func _paint_data_at(pos: Vector2):
	var unzoomed_pos = pos / paint_zoom
	var coords = Vector2i(unzoomed_pos.x / tile_size.x, unzoomed_pos.y / tile_size.y)
	
	if not current_source.texture: return
	var tex_size = current_source.texture.get_size()
	if unzoomed_pos.x < 0 or unzoomed_pos.y < 0 or unzoomed_pos.x >= tex_size.x or unzoomed_pos.y >= tex_size.y: return
	
	if not current_source.has_tile(coords): current_source.create_tile(coords)
	var tile_data = current_source.get_tile_data(coords, 0)
	
	match current_property:
		"select":
			if not selected_tiles.has(coords):
				selected_tiles.append(coords)
				selection_changed.emit(selected_tiles)
		"physics_add":
			if tileset.get_physics_layers_count() > active_physics_layer:
				tile_data.set_collision_polygons_count(active_physics_layer, 1)
				var hs = Vector2(tile_size) / 2.0
				var pts = PackedVector2Array([Vector2(-hs.x, -hs.y), Vector2(hs.x, -hs.y), Vector2(hs.x, hs.y), Vector2(-hs.x, hs.y)])
				tile_data.set_collision_polygon_points(active_physics_layer, 0, pts)
		"physics_clear":
			if tileset.get_physics_layers_count() > active_physics_layer:
				tile_data.set_collision_polygons_count(active_physics_layer, 0)
				
	atlas_texture.queue_redraw()

func _on_atlas_draw():
	if not current_source or not atlas_texture.texture: return
	var tex_size = atlas_texture.texture.get_size()
	var grid_color = Color(1.0, 1.0, 1.0, 0.2)
	
	for x in range(0, int(tex_size.x) + 1, tile_size.x): atlas_texture.draw_line(Vector2(x, 0) * paint_zoom, Vector2(x, tex_size.y) * paint_zoom, grid_color)
	for y in range(0, int(tex_size.y) + 1, tile_size.y): atlas_texture.draw_line(Vector2(0, y) * paint_zoom, Vector2(tex_size.x, y) * paint_zoom, grid_color)

	for i in range(current_source.get_tiles_count()):
		var coords = current_source.get_tile_id(i)
		var tile_data = current_source.get_tile_data(coords, 0)
		if not tile_data: continue
		
		var rect = Rect2((Vector2(coords) * Vector2(tile_size)) * paint_zoom, Vector2(tile_size) * paint_zoom)
		if tileset.get_physics_layers_count() > active_physics_layer and tile_data.get_collision_polygons_count(active_physics_layer) > 0:
			atlas_texture.draw_rect(rect, Color(0.2, 0.5, 0.9, 0.3), true)

	for t in selected_tiles:
		var rect = Rect2((Vector2(t) * Vector2(tile_size)) * paint_zoom, Vector2(tile_size) * paint_zoom)
		atlas_texture.draw_rect(rect, Color.YELLOW, false, 2.0)
