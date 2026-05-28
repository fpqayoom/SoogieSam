@tool
extends Control

@onready var tabs = %Tabs
@onready var paint_tab = %"Paint Tab"
@onready var select_tab = %"Select Tab"
@onready var layer_spin = %LayerSpin

var tileset: TileSet = null

func _ready():
	if paint_tab and select_tab:
		paint_tab.selection_changed.connect(select_tab.update_selected_tiles)
		
	# Wire the new UI SpinBox to trigger the layer change
	if layer_spin:
		layer_spin.value_changed.connect(_on_layer_changed)

func _on_layer_changed(value: float):
	var layer_idx = int(value)
	
	# Push the new layer index to both tabs
	if paint_tab and paint_tab.has_method("set_physics_layer"):
		paint_tab.set_physics_layer(layer_idx)
		
	if select_tab and select_tab.has_method("set_physics_layer"):
		select_tab.set_physics_layer(layer_idx)

func set_tileset(ts: TileSet):
	tileset = ts
	if paint_tab and paint_tab.has_method("set_tileset"):
		paint_tab.set_tileset(tileset)
	if select_tab and select_tab.has_method("set_tileset"):
		select_tab.set_tileset(tileset)
