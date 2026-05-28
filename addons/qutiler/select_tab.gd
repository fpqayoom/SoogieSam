@tool
extends Control

@onready var zoom_out = %ZoomOut
@onready var zoom_in = %ZoomIn
@onready var zoom_lbl = %ZoomLbl

@onready var btn_undo = %BtnUndo
@onready var btn_redo = %BtnRedo
@onready var btn_move = %BtnMove
@onready var btn_add = %BtnAdd
@onready var btn_del = %BtnDel
@onready var btn_reset = %BtnReset
@onready var btn_clear = %BtnClear

@onready var check_snap = %CheckSnap
@onready var spin_snap = %SpinSnap
@onready var canvas = %Canvas
@onready var scroll_container = %Scroll

var active_touches: Dictionary = {}
var primary_touch_index: int = -1

var tileset: TileSet = null
var current_source: TileSetAtlasSource = null
var tile_size: Vector2i = Vector2i(16, 16)
var undo_redo: UndoRedo = UndoRedo.new()

var selected_tiles: Array[Vector2i] = []
var edit_zoom: float = 16.0
var active_physics_layer: int = 0

# Drag State
var dragged_point_idx: int = -1
var grab_radius: float = 8.0
var points_before_drag: PackedVector2Array = PackedVector2Array()

func _ready():
	set_anchors_preset(PRESET_FULL_RECT) 
	if has_node("VBox"):
		$VBox.set_anchors_preset(PRESET_FULL_RECT)
		
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	scroll_container.follow_focus = false 
	canvas.focus_mode = Control.FOCUS_NONE
	canvas.mouse_filter = Control.MOUSE_FILTER_STOP 

	zoom_out.pressed.connect(func(): _set_zoom(edit_zoom - 2.0))
	zoom_in.pressed.connect(func(): _set_zoom(edit_zoom + 2.0))
	
	btn_undo.pressed.connect(undo_redo.undo)
	btn_redo.pressed.connect(undo_redo.redo)
	
	btn_reset.pressed.connect(_reset_physics_square)
	btn_clear.pressed.connect(_clear_physics)
	
	canvas.gui_input.connect(_on_canvas_gui_input)
	canvas.draw.connect(_on_canvas_draw)
	
	var bg = ButtonGroup.new()
	btn_move.button_group = bg
	btn_add.button_group = bg
	btn_del.button_group = bg
	
	_set_zoom(edit_zoom)

func set_tileset(ts: TileSet):
	tileset = ts
	if tileset:
		tile_size = tileset.tile_size
		if tileset.get_source_count() > 0:
			var source_id = tileset.get_source_id(0)
			current_source = tileset.get_source(source_id) as TileSetAtlasSource

func set_physics_layer(layer_index: int):
	active_physics_layer = layer_index
	canvas.queue_redraw()

func _set_zoom(val: float):
	edit_zoom = clamp(val, 4.0, 64.0)
	zoom_lbl.text = str(round((edit_zoom / 16.0) * 100)) + "%"
	
	if canvas:
		var draw_size = Vector2(tile_size) * edit_zoom
		canvas.custom_minimum_size = draw_size * 1.5 
		canvas.queue_redraw()

func update_selected_tiles(new_tiles: Array[Vector2i]):
	selected_tiles = new_tiles
	canvas.queue_redraw()

func _get_current_polygon() -> PackedVector2Array:
	if selected_tiles.is_empty() or not current_source: return PackedVector2Array()
	var tile_data = current_source.get_tile_data(selected_tiles[0], 0)
	if tile_data and tile_data.get_collision_polygons_count(active_physics_layer) > 0:
		return tile_data.get_collision_polygon_points(active_physics_layer, 0)
	return PackedVector2Array()

func _on_canvas_gui_input(event: InputEvent):
	if selected_tiles.is_empty() or not tileset or tileset.get_physics_layers_count() <= active_physics_layer: return

	canvas.accept_event() 

	if event is InputEventMagnifyGesture or event is InputEventPanGesture:
		return 
		
	# TOUCH LOGIC
	if event is InputEventScreenTouch:
		if event.pressed:
			if primary_touch_index == -1:
				primary_touch_index = event.index
				active_touches[event.index] = event.position
		else:
			if event.index == primary_touch_index:
				primary_touch_index = -1
				if dragged_point_idx != -1:
					_commit_polygon_edit(points_before_drag, _get_current_polygon())
					dragged_point_idx = -1
			active_touches.erase(event.index)

	elif event is InputEventScreenDrag:
		if event.index == primary_touch_index:
			active_touches[event.index] = event.position

	# POLYGON EDITING LOGIC
	var points = _get_current_polygon()
	var center = canvas.custom_minimum_size / 2.0
	var local_pos = (event.position - center) / edit_zoom
	
	if check_snap.button_pressed:
		var snap_val = spin_snap.value
		local_pos = local_pos.snapped(Vector2(snap_val, snap_val))

	var is_press = (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT) or (event is InputEventScreenTouch and event.pressed and event.index == primary_touch_index)
	var is_release = (event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT)
	var is_drag = (event is InputEventMouseMotion) or (event is InputEventScreenDrag and event.index == primary_touch_index)

	if btn_move.button_pressed:
		if is_press:
			dragged_point_idx = _get_closest_point_idx(points, local_pos)
			if dragged_point_idx != -1:
				points_before_drag = points.duplicate()
		elif is_release:
			if dragged_point_idx != -1:
				_commit_polygon_edit(points_before_drag, points)
				dragged_point_idx = -1
		elif is_drag and dragged_point_idx != -1:
			points[dragged_point_idx] = local_pos
			_set_polygon_on_selection(points) 

	elif btn_add.button_pressed:
		if is_press:
			if points.is_empty() or points.size() < 3:
				var hs = Vector2(tile_size) / 2.0
				var new_pts = PackedVector2Array([Vector2(-hs.x, -hs.y), Vector2(hs.x, -hs.y), Vector2(hs.x, hs.y), Vector2(-hs.x, hs.y)])
				_commit_polygon_edit(points, new_pts)
			else:
				var old_pts = points.duplicate()
				points.insert(_get_closest_segment_idx(points, local_pos), local_pos)
				_commit_polygon_edit(old_pts, points)

	elif btn_del.button_pressed:
		if is_press:
			var del_idx = _get_closest_point_idx(points, local_pos)
			if del_idx != -1 and points.size() > 3:
				var old_pts = points.duplicate()
				points.remove_at(del_idx)
				_commit_polygon_edit(old_pts, points)

func _commit_polygon_edit(old_pts: PackedVector2Array, new_pts: PackedVector2Array):
	if old_pts == new_pts: return
	
	undo_redo.create_action("Edit Polygon")
	undo_redo.add_do_method(self._set_polygon_on_selection.bind(new_pts))
	undo_redo.add_undo_method(self._set_polygon_on_selection.bind(old_pts))
	undo_redo.commit_action()

func _set_polygon_on_selection(points: PackedVector2Array):
	if selected_tiles.is_empty(): return
	var target_tile = selected_tiles[0] 
	
	if not current_source.has_tile(target_tile): current_source.create_tile(target_tile)
	var td = current_source.get_tile_data(target_tile, 0)
	
	if points.is_empty():
		td.set_collision_polygons_count(active_physics_layer, 0)
	else:
		td.set_collision_polygons_count(active_physics_layer, 1)
		td.set_collision_polygon_points(active_physics_layer, 0, points)
			
	canvas.queue_redraw()

func _reset_physics_square():
	if selected_tiles.is_empty() or not tileset or tileset.get_physics_layers_count() <= active_physics_layer: return
	var old_pts = _get_current_polygon()
	var hs = Vector2(tile_size) / 2.0
	var new_pts = PackedVector2Array([Vector2(-hs.x, -hs.y), Vector2(hs.x, -hs.y), Vector2(hs.x, hs.y), Vector2(-hs.x, hs.y)])
	_commit_polygon_edit(old_pts, new_pts)

func _clear_physics():
	if selected_tiles.is_empty() or not tileset: return
	var old_pts = _get_current_polygon()
	_commit_polygon_edit(old_pts, PackedVector2Array())

func _on_canvas_draw():
	if selected_tiles.is_empty() or not current_source:
		canvas.draw_string(ThemeDB.fallback_font, Vector2(20, 30), "Select tile(s) in Paint tab.", HORIZONTAL_ALIGNMENT_LEFT, -1, 16)
		return
		
	var primary_tile = selected_tiles[0]
	var center = canvas.custom_minimum_size / 2.0
	var draw_size = Vector2(tile_size) * edit_zoom
	var rect = Rect2(center - draw_size / 2.0, draw_size)
	
	var src_rect = Rect2(Vector2(primary_tile) * Vector2(tile_size), Vector2(tile_size))
	canvas.draw_texture_rect_region(current_source.texture, rect, src_rect)
	
	var grid_color = Color(1, 1, 1, 0.1)
	var snap_val = spin_snap.value if check_snap.button_pressed else 1.0
	
	for x in range(0, tile_size.x + 1, snap_val):
		var px = rect.position.x + (x * edit_zoom)
		canvas.draw_line(Vector2(px, rect.position.y), Vector2(px, rect.position.y + rect.size.y), grid_color)
	for y in range(0, tile_size.y + 1, snap_val):
		var py = rect.position.y + (y * edit_zoom)
		canvas.draw_line(Vector2(rect.position.x, py), Vector2(rect.position.x + rect.size.x, py), grid_color)

	var pts = _get_current_polygon()
	if not pts.is_empty():
		for i in range(pts.size()):
			var p1 = center + (pts[i] * edit_zoom)
			var p2 = center + (pts[(i + 1) % pts.size()] * edit_zoom)
			canvas.draw_line(p1, p2, Color.AQUA, 2.0)
		for pt in pts:
			canvas.draw_circle(center + (pt * edit_zoom), 5.0, Color.WHITE)

func _get_closest_point_idx(points: PackedVector2Array, local_pos: Vector2) -> int:
	var closest_idx = -1
	var min_dist = grab_radius / edit_zoom
	for i in range(points.size()):
		var d = local_pos.distance_to(points[i])
		if d < min_dist: min_dist = d; closest_idx = i
	return closest_idx

func _get_closest_segment_idx(points: PackedVector2Array, local_pos: Vector2) -> int:
	var best_idx = -1
	var min_dist = INF
	for i in range(points.size()):
		var p1 = points[i]; var p2 = points[(i + 1) % points.size()]
		var l2 = p1.distance_squared_to(p2)
		var t = max(0.0, min(1.0, (local_pos - p1).dot(p2 - p1) / l2)) if l2 != 0 else 0
		var proj = p1 + t * (p2 - p1)
		var d = local_pos.distance_to(proj)
		if d < min_dist: min_dist = d; best_idx = i + 1
	return best_idx
