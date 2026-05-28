@tool
extends EditorPlugin

var main_panel: VBoxContainer
var search_bar: LineEdit
var prop_list: VBoxContainer
var current_node: Node
var update_timer: Timer

func _enter_tree():
	main_panel = VBoxContainer.new()
	main_panel.name = "Pro Inspector"
	
	# Header with manual refresh
	var header = HBoxContainer.new()
	main_panel.add_child(header)
	
	var btn_refresh = Button.new()
	btn_refresh.text = "Refresh"
	btn_refresh.custom_minimum_size = Vector2(100, 50)
	btn_refresh.pressed.connect(_refresh_properties)
	header.add_child(btn_refresh)
	
	search_bar = LineEdit.new()
	search_bar.placeholder_text = "Search properties..."
	search_bar.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	search_bar.text_changed.connect(_refresh_properties)
	header.add_child(search_bar)
	
	# Protected Scroll Area
	var scroll = ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	main_panel.add_child(scroll)
	
	prop_list = VBoxContainer.new()
	prop_list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Force a minimum height so it can't be hidden easily
	#prop_list.custom_minimum_size = Vector2(0, 800) 
	scroll.add_child(prop_list)

	add_control_to_dock(EditorPlugin.DOCK_SLOT_RIGHT_BR, main_panel)

	# --- THE PERSISTENCE ENGINE ---
	# We use a timer to "poll" the selection because signals are being blocked
	update_timer = Timer.new()
	update_timer.wait_time = 0.5
	update_timer.autostart = true
	update_timer.timeout.connect(_check_for_selection_change)
	add_child(update_timer)

func _exit_tree():
	if is_instance_valid(update_timer):
		update_timer.stop()
		update_timer.queue_free()
	if main_panel:
		remove_control_from_docks(main_panel)
		main_panel.queue_free()

func _check_for_selection_change():
	var nodes = EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() > 0:
		if nodes[0] != current_node:
			_refresh_properties()

func _refresh_properties(filter_text: String = ""):
	if not is_instance_valid(prop_list): return
	
	var nodes = EditorInterface.get_selection().get_selected_nodes()
	if nodes.size() == 0:
		current_node = null
		return
		
	current_node = nodes[0]
	
	# Clear list
	for child in prop_list.get_children():
		child.queue_free()
	
	var filter = filter_text.to_lower() if filter_text != "" else search_bar.text.to_lower()
	var current_group = "General"
	
	for p in current_node.get_property_list():
		# Handle Headers
		if p.usage & PROPERTY_USAGE_CATEGORY or p.usage & PROPERTY_USAGE_GROUP:
			current_group = p.name.capitalize()
			var g_panel = PanelContainer.new()
			var style = StyleBoxFlat.new()
			style.bg_color = Color(0.2, 0.25, 0.35)
			g_panel.add_theme_stylebox_override("panel", style)
			var g_lbl = Label.new()
			g_lbl.text = " " + current_group
			g_panel.add_child(g_lbl)
			prop_list.add_child(g_panel)
			continue
			
		# Filter
		if not (p.usage & PROPERTY_USAGE_EDITOR): continue
		if filter != "" and not filter in p.name.to_lower(): continue
		
		# Row
		var hbox = HBoxContainer.new()
		var name_lbl = Label.new()
		name_lbl.text = " " + p.name
		name_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		hbox.add_child(name_lbl)
		
		var val = current_node.get(p.name)
		var ui = _create_ui(p, val)
		if ui:
			ui.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			ui.stretch_ratio = 1.5
			hbox.add_child(ui)
		
		prop_list.add_child(hbox)

func _create_ui(p, val) -> Control:
	if p.type == TYPE_BOOL:
		var cb = CheckBox.new()
		cb.button_pressed = val if val != null else false
		cb.toggled.connect(func(v): current_node.set(p.name, v))
		return cb
	if p.type == TYPE_COLOR:
		var cp = ColorPickerButton.new()
		cp.color = val if val != null else Color.WHITE
		cp.color_changed.connect(func(c): current_node.set(p.name, c))
		return cp
	if p.type == TYPE_INT or p.type == TYPE_FLOAT:
		var sb = SpinBox.new()
		sb.min = -100000; sb.max = 100000
		sb.value = float(val) if val != null else 0.0
		sb.step = 0.01 if p.type == TYPE_FLOAT else 1.0
		sb.value_changed.connect(func(v): current_node.set(p.name, v))
		return sb
	
	var le = LineEdit.new()
	le.text = str(val)
	le.text_submitted.connect(func(t): current_node.set(p.name, t))
	return le
