@tool
extends EditorPlugin

var main_ui: TabContainer

func _enter_tree():
	main_ui = TabContainer.new()
	main_ui.name = "MobileTileStation"
	main_ui.custom_minimum_size = Vector2(0, 320)
	main_ui.tab_alignment = TabBar.ALIGNMENT_LEFT
	
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.18, 0.2, 0.25)
	main_ui.add_theme_stylebox_override("panel", style)

	_build_ui()
	
	call_deferred("add_control_to_bottom_panel", main_ui, "Tile Station")

func _exit_tree():
	if main_ui:
		remove_control_from_bottom_panel(main_ui)
		main_ui.queue_free()

func _build_ui():
	# --- TILEMAP TAB ---
	var map_tab = MarginContainer.new()
	map_tab.name = "TileMap"
	map_tab.add_theme_constant_override("margin_top", 10)
	map_tab.add_theme_constant_override("margin_left", 10)
	map_tab.add_theme_constant_override("margin_right", 10)
	main_ui.add_child(map_tab)
	
	var map_grid = GridContainer.new()
	map_grid.columns = 3
	map_grid.add_theme_constant_override("h_separation", 8)
	map_grid.add_theme_constant_override("v_separation", 8)
	map_tab.add_child(map_grid)
	
	map_grid.add_child(_make_btn("PAINT", Color(0.05, 0.3, 0.05), "paint"))
	map_grid.add_child(_make_btn("ERASE", Color(0.4, 0.05, 0.05), "erase"))
	map_grid.add_child(_make_btn("PICK", Color(0.0, 0.35, 0.35), "pick"))
	map_grid.add_child(_make_btn("RECT", Color(0.5, 0.4, 0.05), "rect"))
	map_grid.add_child(_make_btn("BUCKET", Color(0.35, 0.0, 0.35), "bucket"))

	# --- TILESET TAB ---
	var set_tab = MarginContainer.new()
	set_tab.name = "TileSet"
	set_tab.add_theme_constant_override("margin_top", 10)
	set_tab.add_theme_constant_override("margin_left", 10)
	main_ui.add_child(set_tab)
	
	var set_grid = GridContainer.new()
	set_grid.columns = 2
	set_tab.add_child(set_grid)
	set_grid.add_child(_make_btn("COLLISION", Color(0.2, 0.2, 0.4), "collision"))
	set_grid.add_child(_make_btn("ATLAS", Color(0.2, 0.4, 0.4), "atlas"))

	# --- SETUP TAB ---
	var setup_tab = MarginContainer.new()
	setup_tab.name = "Setup"
	setup_tab.add_theme_constant_override("margin_top", 10)
	setup_tab.add_theme_constant_override("margin_left", 10)
	main_ui.add_child(setup_tab)
	
	var clean_btn = _make_btn("CLEAN NATIVE UI", Color(0.25, 0.25, 0.25), "clean")
	setup_tab.add_child(clean_btn)

func _make_btn(txt: String, col: Color, action: String) -> Button:
	var btn = Button.new()
	btn.text = txt
	btn.custom_minimum_size = Vector2(0, 80)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style = StyleBoxFlat.new()
	style.bg_color = col
	style.border_width_bottom = 2
	style.border_color = col.lightened(0.2)
	btn.add_theme_stylebox_override("normal", style)
	btn.add_theme_stylebox_override("hover", style)
	btn.add_theme_stylebox_override("pressed", style)
	
	btn.pressed.connect(_on_button_pressed.bind(action))
	
	return btn

func _on_button_pressed(action: String):
	if action == "clean":
		_clean_ui()
	print("Tile Station Action: ", action)

func _clean_ui():
	var base = EditorInterface.get_base_control()
	# Renamed variables below to avoid keyword conflicts
	_hide_nodes_by_type(base, "TileMapEditor")
	_hide_nodes_by_type(base, "TileSetEditor")

func _hide_nodes_by_type(node: Node, target_class: String):
	for child in node.get_children():
		if target_class in child.get_class():
			child.visible = false
		_hide_nodes_by_type(child, target_class)
