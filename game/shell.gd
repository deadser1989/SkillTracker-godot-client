extends Node

@onready var content_container = $MainContent

@onready var btn_stats = $MainContent/ShellUI/NavBackground/TopNav/BtnStats
@onready var btn_tree = $MainContent/ShellUI/NavBackground/TopNav/BtnTree
@onready var btn_profile = $MainContent/ShellUI/NavBackground/TopNav/BtnProfile

var scene_stats = preload("res://stats.tscn")
var scene_tree = preload("res://main.tscn")
var scene_profile = preload("res://profile.tscn")

var current_scene_node = null

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
	
	if current_scene_node != null:
		current_scene_node.queue_free()
		
	current_scene_node = scene_resource.instantiate()
	content_container.add_child(current_scene_node)

	if current_scene_node is Control:
		current_scene_node.set_anchors_preset(Control.PRESET_FULL_RECT)
		current_scene_node.offset_left = 0
		current_scene_node.offset_top = 0
		current_scene_node.offset_right = 0
		current_scene_node.offset_bottom = 0
