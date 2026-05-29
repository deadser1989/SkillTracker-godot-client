extends Node

@onready var content_container = $MainContent

@onready var btn_stats = $MainContent/ShellUI/NavBackground/TopNav/BtnStats
@onready var btn_tree = $MainContent/ShellUI/NavBackground/TopNav/BtnTree
@onready var btn_profile = $MainContent/ShellUI/NavBackground/TopNav/BtnProfile

var scene_stats = preload("res://stats.tscn")
var scene_tree = preload("res://main.tscn")
var scene_profile = preload("res://profile.tscn")

var current_scene_node = null
var cached_scenes = {} 

func _ready():
	btn_stats.pressed.connect(func(): load_tab(scene_stats, btn_stats))
	btn_tree.pressed.connect(func(): load_tab(scene_tree, btn_tree))
	btn_profile.pressed.connect(func(): load_tab(scene_profile, btn_profile))
	
	load_tab(scene_tree, btn_tree)

func load_tab(scene_resource, active_btn):
	var dim_color = Color(0.5, 0.5, 0.7, 0.7)
	btn_stats.modulate = dim_color
	btn_tree.modulate = dim_color
	btn_profile.modulate = dim_color
	
	active_btn.modulate = Color(1.0, 1.0, 1.0, 1.0)
	
	get_viewport().canvas_transform = Transform2D()
	
	if current_scene_node != null:
		current_scene_node.hide() 
		
	if not cached_scenes.has(scene_resource):
		var inst = scene_resource.instantiate()
		content_container.add_child(inst)
		if inst is Control:
			inst.set_anchors_preset(Control.PRESET_FULL_RECT)
			inst.offset_left = 0
			inst.offset_top = 0
			inst.offset_right = 0
			inst.offset_bottom = 0
		cached_scenes[scene_resource] = inst

	current_scene_node = cached_scenes[scene_resource]
	current_scene_node.show()
	
	if current_scene_node.name == "Stats" or current_scene_node.name == "StatsPanel":
		Net.fetch_history()

	if current_scene_node.has_method("fetch_history_from_server"):
		current_scene_node.fetch_history_from_server()
	if current_scene_node.has_method("update_ui"):
		current_scene_node.update_ui()
