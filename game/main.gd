extends Node2D

@onready var tree = $Tree
@onready var camera = $Tree/Camera2D 
@onready var fog = $Tree/FogOfWar
@onready var skill_window = $UI/SkillWindow
@onready var title_label = $UI/SkillWindow/MarginContainer/MainCol/Header/TitleBox/Title
@onready var lvl_label = $UI/SkillWindow/MarginContainer/MainCol/LvlLabel
@onready var close_btn = $UI/SkillWindow/MarginContainer/MainCol/Header/CloseBtn
@onready var desc_label = $UI/SkillWindow/MarginContainer/MainCol/Description
@onready var extra_info = $UI/SkillWindow/MarginContainer/MainCol/ExtraInfo
@onready var prog_row = $UI/SkillWindow/MarginContainer/MainCol/ProgressRow
@onready var prog_slider = $UI/SkillWindow/MarginContainer/MainCol/ProgressRow/ProgressSlider
@onready var slider_val_label = $UI/SkillWindow/MarginContainer/MainCol/ProgressRow/SliderValLabel
@onready var upgrade_btn = $UI/SkillWindow/MarginContainer/MainCol/HBoxContainer/UpgradeBtn
@onready var lvl_up_btn = $UI/SkillWindow/MarginContainer/MainCol/HBoxContainer/LvlUpBtn
@onready var tooltip = $UI/Tooltip
@onready var tooltip_name = $UI/Tooltip/VBoxContainer/NameLabel
@onready var tooltip_info = $UI/Tooltip/VBoxContainer/InfoLabel
@onready var cooldown_text = $UI/HUD/TopRight/HBoxContainer/CooldownText
@onready var xp_bar = $UI/HUD/TopLeft/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/XPBar
@onready var xp_text_label = $UI/HUD/TopLeft/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/XPText
@onready var lvl_display = $UI/HUD/TopLeft/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/LevelLabel
@onready var todo_panel = $UI/HUD/ToDoPanel
@onready var todo_toggle_btn = $UI/HUD/ToDoPanel/VBoxContainer/ToggleBtn
@onready var task_list_container = $UI/HUD/ToDoPanel/VBoxContainer/ScrollContainer/TaskList

var selected_skill = null 
var is_dragging_camera = false 
var is_todo_open = false

func _ready():
	skill_window.hide()
	tooltip.hide()
	
	Profile.level_up_achieved.connect(_on_global_level_up)
	Profile.profile_updated.connect(update_player_hud)
	
	prog_slider.value_changed.connect(_on_slider_changed)
	upgrade_btn.pressed.connect(_on_upgrade_btn_pressed)
	close_btn.pressed.connect(_on_close_btn_pressed)
	lvl_up_btn.pressed.connect(_on_lvl_up_btn_pressed)
	todo_toggle_btn.pressed.connect(_on_todo_toggle)
	
	GM.obligations_updated.connect(refresh_todo_list)
	GM.cooldown_started.connect(update_energy_hud)
	GM.cooldown_finished.connect(update_energy_hud)
	
	update_player_hud()
	update_energy_hud()

	Net.tree_loaded.connect(_on_server_tree_downloaded)
	Net.action_updated.connect(_on_server_action_processed)
		
	if not Net.catalog_loaded.is_connected(_on_catalog_ready):
		Net.catalog_loaded.connect(_on_catalog_ready)
	Net.fetch_catalog()

func _on_catalog_ready(json_str):
	GM.load_catalog_from_json(json_str)
	Net.fetch_user_tree()

func update_energy_hud():
	if GM.can_start_new_skill():
		cooldown_text.text = "MAX"
	else:
		cooldown_text.text = format_time(GM.get_cooldown_time_left())

func _on_server_tree_downloaded(parsed_json_string: String):
	var data = JSON.parse_string(parsed_json_string)
	if typeof(data) == TYPE_ARRAY:
		for item in data:
			if item.has("nodes"): 
				for n in item["nodes"]: _fix_cpp_types(n)
			else: 
				_fix_cpp_types(item)
	var safe_json = JSON.stringify(data)

	if tree.has_method("clear_nodes"): tree.clear_nodes()
	for child in tree.get_children():
		if child.has_method("get_skill_state"):
			tree.remove_child(child)
			child.queue_free()

	var parsed_nodes = GM.parse_user_tree(safe_json)
	var node_dict = {}

	for node in parsed_nodes:
		if node.get_base_progress() >= 60:
			node.set_task_type(1)
			node.set_skill_time(node.get_base_progress())
		var n_id = str(node.get_skill_id()).replace(".0", "").split("_")[0]
		node_dict[n_id] = node
		tree.add_child(node)
		if tree.has_method("registerNode"): tree.registerNode(node)
		setup_node_graphics(node)

	var placed_ids = []
	var parent_child_counts = {}

	for node in parsed_nodes:
		if node.get_required_prev_skills().size() == 0:
			var area = node.get_subject_area()
			if area == 0: node.position = Vector2(0, -150)
			elif area == 1: node.position = Vector2(150, 0)
			elif area == 2: node.position = Vector2(0, 150)
			elif area == 3: node.position = Vector2(-150, 0)
			node.set_tree_depth(0)
			node.set_layer_index(0)
			node.force_update_transform()
			
			var r_id = str(node.get_skill_id()).replace(".0", "").split("_")[0]
			placed_ids.append(r_id)
			if node.get_skill_state() >= 2: GM.add_obligation(node)

	var max_iterations = 100 
	var iters = 0
	var placed_this_round = true
	
	while placed_this_round and iters < max_iterations:
		placed_this_round = false
		iters += 1
		for node in parsed_nodes:
			var n_id = str(node.get_skill_id()).replace(".0", "").split("_")[0]
			if not placed_ids.has(n_id) and node.get_required_prev_skills().size() > 0:
				var p_id_str = str(node.get_required_prev_skills()[0]).replace(".0", "").split("_")[0]
				if placed_ids.has(p_id_str): 
					var parent = node_dict.get(p_id_str)
					if parent:
						if not parent_child_counts.has(p_id_str): parent_child_counts[p_id_str] = 0
						var c_index = parent_child_counts[p_id_str]
						
						parent.force_update_transform()
						if tree.has_method("place_node_on_map"): tree.place_node_on_map(node, parent, c_index) 
						node.force_update_transform()
						
						parent_child_counts[p_id_str] += 1
					placed_ids.append(n_id)
					placed_this_round = true
					if node.get_skill_state() >= 2: GM.add_obligation(node)
	
	if tree.has_method("queue_redraw"): tree.queue_redraw()
	refresh_todo_list()

func _fix_cpp_types(n: Dictionary):
	if n.has("node_state"):
		var st = int(n["node_state"])
		if st == 0: n["node_state"] = "hidden"
		elif st == 1: n["node_state"] = "revealed"
		elif st == 2: n["node_state"] = "active"
		elif st == 3: n["node_state"] = "finished"
		
func _on_server_action_processed(response: Dictionary):
	var s_id = str(int(response.get("node_id", 0)))
	var node = tree.find_skill_node(s_id)
	if node == null: node = tree.find_skill_node(s_id + ".0")
		
	if node:
		node.set_skill_cur_prog(response.get("current_progress", 0))
		node.set_skill_state(response.get("node_state", 2))
		
		if response.get("node_state") == 3:
			node.set_skill_state(3)
			
		var server_level = response.get("profile_level", Profile.get_level())
		if server_level != Profile.get_level(): Profile.set_level(server_level)
			
		if selected_skill == node:
			open_skill_window(node)

func spawn_branches_for_node(parent_node):
	var existing_children = 0
	var p_id_str = str(parent_node.get_skill_id()).replace(".0", "").split("_")[0]
	for child in tree.get_children():
		if child != parent_node and child.has_method("get_skill_state"):
			var reqs = child.get_required_prev_skills()
			if reqs.size() > 0:
				var child_req_id = str(reqs[0]).replace(".0", "").split("_")[0]
				if child_req_id == p_id_str: existing_children += 1
				
	if existing_children == 0:
		spawn_new_random_skill(0, parent_node)
		spawn_new_random_skill(1, parent_node)
	elif existing_children == 1:
		spawn_new_random_skill(1, parent_node)
		
	tree.reveal_successors(parent_node)

func spawn_new_random_skill(child_index: int, parent_node: SkillNode):  
	var new_id_base = GM.roll_new_skill(parent_node.get_subject_area())
	if new_id_base == "error": return 
	
	var data = GM.get_skill_data(new_id_base)
	var new_node = SkillNode.new()
	new_node.set_skill_id("temp_" + str(randi() % 100000))
	
	var target_val = 1
	var cd_str = "D"
	
	if not data.is_empty():
		new_node.set_skill_name(data["node_name"])
		new_node.set_skill_title(data["node_info"])
		new_node.set_skill_rarity(int(data.get("node_rarity", 0)))
		new_node.set_skill_xp(int(data.get("xp_reward", 10)))
		
		if data.has("duration_sec"): target_val = int(data["duration_sec"])
		else: target_val = int(data.get("base_progress", 1))
		
		if data.has("cooldown"): cd_str = str(data["cooldown"])
	else:
		new_node.set_skill_name("Секрет")
	
	new_node.set_base_progress(target_val)
	new_node.set_skill_level(1) 
	new_node.refresh_target_by_level() 
	
	if target_val >= 60:
		new_node.set_task_type(1)
		new_node.set_skill_time(target_val)
		
	var cd_upper = cd_str.to_upper()
	if cd_upper == "D" or cd_upper == "DAILY": new_node.set_cooldown_type(1)
	elif cd_upper == "W" or cd_upper == "WEEKLY": new_node.set_cooldown_type(2)
	elif cd_upper == "M" or cd_upper == "MONTHLY": new_node.set_cooldown_type(3)
	
	new_node.set_skill_state(1)
	new_node.set_skill_subject_area(parent_node.get_subject_area())
	
	var reqs = PackedStringArray()
	reqs.append(str(parent_node.get_skill_id()))
	new_node.set_required_prev_skills(reqs)
	
	tree.add_child(new_node)
	if tree.has_method("registerNode"): tree.registerNode(new_node)
	setup_node_graphics(new_node)
	
	parent_node.force_update_transform()
	if tree.has_method("place_node_on_map"): tree.place_node_on_map(new_node, parent_node, child_index)
	new_node.force_update_transform()
	
	var parent_raw = str(parent_node.get_skill_id()).replace(".0", "").split("_")[0]
	if parent_raw.is_valid_int() and int(parent_raw) > 0:
		Net.add_node_to_server(int(parent_raw), new_node.get_skill_name(), new_node.get_skill_title(), new_node.get_skill_rarity(), new_node.get_skill_xp(), new_node.get_base_progress(), cd_str, new_node)
		
func _on_upgrade_btn_pressed():
	if selected_skill == null: return
	var state = selected_skill.get_skill_state()
	
	#ищучить
	if state == 1: 
		if GM.request_start_skill():
			selected_skill.set_skill_state(2) 
			GM.add_obligation(selected_skill)
			
			spawn_branches_for_node(selected_skill)
			open_skill_window(selected_skill)
			
			var raw_id_str = str(selected_skill.get_skill_id())
			var base_id = int(raw_id_str.replace(".0", "").split("_")[0])
			if base_id > 0: Net.activate_skill(base_id)
		return 
			
	# прокачать
	if state == 2: 
		var add_amount = 1
		
		if selected_skill.get_task_type() == 1: 
			if selected_skill.is_timer_active():
				if selected_skill.has_method("force_finish_timer"):
					selected_skill.force_finish_timer() 
				add_amount = selected_skill.get_skill_nes_prog() - selected_skill.get_skill_cur_prog()
				if add_amount <= 0: add_amount = 1
			else:
				selected_skill.start_progress_time() 
				GM.add_obligation(selected_skill) 
				open_skill_window(selected_skill)
				return 
		else: 
			if prog_row.visible: add_amount = int(prog_slider.value)
		
		selected_skill.add_progress(add_amount)
		GM.add_obligation(selected_skill) 
		
		var raw_id_str = str(selected_skill.get_skill_id())
		var base_id = int(raw_id_str.replace(".0", "").split("_")[0])
		if base_id > 0: Net.send_action(base_id, add_amount) 
		
		open_skill_window(selected_skill)
		
func _on_lvl_up_btn_pressed():
	if selected_skill == null: return
	var lvl = selected_skill.get_skill_level()
	selected_skill.set_skill_level(lvl + 1)
	selected_skill.refresh_target_by_level()
	selected_skill.set_skill_cur_prog(0)
	selected_skill.set_skill_state(2) 
	
	GM.add_obligation(selected_skill) 
	open_skill_window(selected_skill)
	
	var raw_id_str = str(selected_skill.get_skill_id())
	var base_id = int(raw_id_str.replace(".0", "").split("_")[0])
	if base_id > 0: Net.send_levelup(base_id, selected_skill.get_skill_nes_prog())

func _process(_delta):
	check_hover()
	update_fog()
	
	if not GM.can_start_new_skill():
		cooldown_text.text = format_time(GM.get_cooldown_time_left())
	else:
		cooldown_text.text = "MAX ENERGY"
		
	if skill_window.visible and selected_skill != null:
		if selected_skill.get_task_type() == 1 and selected_skill.has_method("is_timer_active") and selected_skill.is_timer_active():
			upgrade_btn.get_node("Label").text = "Завершить " + format_time(selected_skill.get_current_timer_sec())
			
func update_fog():
	var lines_array = PackedVector4Array()
	for child in tree.get_children():
		if not child.has_method("get_skill_state"): continue
		if child.get_skill_state() >= 1: 
			var parents = child.get_required_prev_skills()
			if parents.size() > 0:
				for p_id in parents:
					var pt = tree.find_skill_node(p_id)
					if pt and pt.get_skill_state() >= 1: lines_array.append(Vector4(child.global_position.x, child.global_position.y, pt.global_position.x, pt.global_position.y))
			else: lines_array.append(Vector4(child.global_position.x, child.global_position.y, child.global_position.x, child.global_position.y))
	fog.material.set_shader_parameter("lines_pos", lines_array)
	fog.material.set_shader_parameter("lines_count", lines_array.size())

func check_hover():
	var mp = get_global_mouse_position()
	var found = null
	for child in tree.get_children():
		if not child.has_method("get_skill_state"): continue
		if child.get_skill_state() == 0: continue 
		if child.global_position.distance_to(mp) < 45.0: found = child; break
	if found != null: show_tooltip(found)
	else: tooltip.hide()

func show_tooltip(node):
	if skill_window.visible: tooltip.hide(); return
	tooltip_name.text = node.get_skill_name()
	if node.get_skill_state() == 1: tooltip_info.text = "Скрытый навык"
	else: tooltip_info.text = "Уровень: " + str(node.get_skill_level())
	tooltip.global_position = get_viewport().get_mouse_position() + Vector2(20, -50)
	tooltip.show()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE: is_dragging_camera = event.pressed
	elif event is InputEventMouseMotion and is_dragging_camera:
		if camera: camera.position -= event.relative * camera.zoom.x
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		for child in tree.get_children():
			if not child.has_method("get_skill_state"): continue
			if child.get_skill_state() == 0: continue 
			if child.global_position.distance_to(click_pos) < 45.0: open_skill_window(child); break

func _on_close_btn_pressed():
	skill_window.hide(); selected_skill = null

func open_skill_window(node):
	selected_skill = node
	title_label.text = node.get_skill_name()
	desc_label.text = node.get_skill_title()
	extra_info.text = "" 
	upgrade_btn.hide(); prog_row.hide(); lvl_up_btn.hide()
	lvl_label.text = "Уровень: " + str(node.get_skill_level())
	
	var state = node.get_skill_state()
	if state == 1:
		extra_info.text = "\nТребует энергии для разблокировки."
		upgrade_btn.get_node("Label").text = "ИЗУЧИТЬ"
		upgrade_btn.show()
	elif state == 2: 
		if node.get_task_type() == 1:
			var t_time = node.get_skill_time()
			if t_time <= 0: t_time = node.get_skill_nes_prog()
			extra_info.text = "\nНа время: " + str(int(t_time / 60.0)) + " мин."
			if node.has_method("is_timer_active") and node.is_timer_active(): 
				upgrade_btn.get_node("Label").text = "Завершить " + format_time(node.get_current_timer_sec())
			else: 
				upgrade_btn.get_node("Label").text = "Старт"
		else:
			var c = node.get_skill_cur_prog()
			var n = node.get_skill_nes_prog()
			extra_info.text = "\nЦель: " + str(c) + " / " + str(n)
			if n - c > 1:
				prog_row.show()
				prog_slider.min_value = 1; prog_slider.max_value = n - c; prog_slider.value = 1
				slider_val_label.text = "+1"
				upgrade_btn.get_node("Label").text = "Добавить"
			else: upgrade_btn.get_node("Label").text = "Выполнить (+1)"
		upgrade_btn.show()
	elif state == 3: 
		extra_info.text = "\nПрогресс заполнен!"
		lvl_up_btn.show()
	skill_window.show()
	
func _on_slider_changed(value):
	slider_val_label.text = "+" + str(value)
	upgrade_btn.get_node("Label").text = "Добавить (+" + str(value) + ")"

func update_player_hud():
	var level_val = Profile.get_level() if Profile.has_method("get_level") else 1
	var xp_val = Profile.get_xp() if Profile.has_method("get_xp") else 0
	var max_xp_val = Profile.get_max_xp() if Profile.has_method("get_max_xp") else 100
	lvl_display.text = "Level " + str(level_val)
	xp_bar.max_value = max_xp_val
	xp_bar.value = xp_val
	xp_text_label.text = str(xp_val) + " / " + str(max_xp_val) + " XP"

func format_time(seconds: float) -> String:
	var m = int(seconds / 60.0); var s = int(seconds) % 60
	return "%02d:%02d" % [m, s]

func setup_node_graphics(node: SkillNode):
	node.set_tex_border(load("res://assets/icons/skill-node-5.png"))
	node.set_icon_fit_on(load("res://assets/icons/gantelya.png"))
	node.set_icon_fit_off(load("res://assets/icons/gantelya.png")) 
	node.set_icon_read_on(load("res://assets/icons/book_skill_tree.png"))
	node.set_icon_read_off(load("res://assets/icons/book_skill_tree.png"))
	node.set_icon_creativity_on(load("res://assets/icons/lampochka.png"))
	node.set_icon_creativity_off(load("res://assets/icons/lampochka.png"))
	node.set_icon_language_on(load("res://assets/icons/language.png"))
	node.set_icon_language_off(load("res://assets/icons/language.png"))
	node.set_tex_flash(load("res://assets/icons/svet.png"))
	node.set_tex_star(load("res://assets/icons/mini-star.png"))

func _notification(what):
	if what == NOTIFICATION_VISIBILITY_CHANGED:
		if has_node("UI"): $UI.visible = visible
		if has_node("Tree/FogOfWar"): $Tree/FogOfWar.visible = visible
		if has_node("Tree/Camera2D"): $Tree/Camera2D.enabled = visible
		var bg = get_node_or_null("ParallaxBackground")
		if bg: bg.visible = visible

func _on_global_level_up(_new_level): pass

func _on_todo_toggle():
	is_todo_open = !is_todo_open
	var tw = create_tween()
	var target_y = get_viewport_rect().size.y - todo_panel.size.y if is_todo_open else get_viewport_rect().size.y - 40
	todo_toggle_btn.text = "Свернуть" if is_todo_open else "Задачи ^"
	tw.tween_property(todo_panel, "position:y", target_y, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func refresh_todo_list():
	for child in task_list_container.get_children(): child.queue_free()
	var tasks = GM.get_all_obligations()
	for t in tasks: create_todo_item(t, t["current"] >= t["target"])

func create_todo_item(task, is_done):
	var btn = Button.new()
	btn.flat = true; btn.alignment = HORIZONTAL_ALIGNMENT_LEFT; btn.custom_minimum_size = Vector2(280, 35)
	btn.text = task["name"] + " (" + (str(task["current"]) + "/" + str(task["target"]) if task["task_type"] != 1 else "Таймер") + ")"
	var item_bg = ColorRect.new()
	item_bg.custom_minimum_size = Vector2(0, 35)
	if is_done:
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		item_bg.color = Color(0.1, 0.1, 0.15, 0.8) 
	else: item_bg.color = Color(0.2, 0.2, 0.3, 0.8)  
	btn.pressed.connect(func():
		var target_node = tree.find_skill_node(str(task["id"]))
		if target_node:
			var tw = create_tween()
			tw.tween_property(camera, "position", target_node.position, 0.4).set_trans(Tween.TRANS_QUAD)
			open_skill_window(target_node)
	)
	item_bg.add_child(btn); task_list_container.add_child(item_bg)
