extends Node2D

@onready var tree_request = $TreeRequest
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

@onready var bottom_buttons = $UI/SkillWindow/MarginContainer/MainCol/HBoxContainer
@onready var lvl_up_btn = $UI/SkillWindow/MarginContainer/MainCol/HBoxContainer/LvlUpBtn
@onready var upgrade_btn = $UI/SkillWindow/MarginContainer/MainCol/HBoxContainer/UpgradeBtn

@onready var tooltip = $UI/Tooltip
@onready var tooltip_name = $UI/Tooltip/VBoxContainer/NameLabel
@onready var tooltip_info = $UI/Tooltip/VBoxContainer/InfoLabel

@onready var lvl_display = $UI/HUD/TopLeft/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer/LevelLabel
@onready var xp_bar = $UI/HUD/TopLeft/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/XPBar
@onready var xp_text_label = $UI/HUD/TopLeft/VBoxContainer/HBoxContainer/MarginContainer/HBoxContainer/VBoxContainer2/XPText

@onready var energy_text = $UI/HUD/TopRight/HBoxContainer/EnergyText
@onready var cooldown_text = $UI/HUD/TopRight/HBoxContainer/CooldownText

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

	Net.tree_loaded.connect(_on_server_tree_downloaded)
	Net.action_updated.connect(_on_server_action_processed)
	Net.fetch_user_tree()

func _on_server_tree_downloaded(parsed_json_string: String):
	for child in tree.get_children():
		if child.has_method("get_skill_state"):
			child.queue_free()

	var parsed_nodes = GM.parse_user_tree(parsed_json_string)

	for node in parsed_nodes:
		tree.add_child(node)
		tree.registerNode(node)
		setup_node_graphics(node)

		if node.get_required_prev_skills().size() == 0:
			var area = node.get_subject_area()
			if area == 0: node.position = Vector2(0, -150)
			elif area == 1: node.position = Vector2(150, 0)
			elif area == 2: node.position = Vector2(0, 150)
			elif area == 3: node.position = Vector2(-150, 0)
			node.set_tree_depth(0)
			node.set_layer_index(0)
		else:
			var parent = tree.find_skill_node(node.get_required_prev_skills()[0])
			if parent:
				tree.place_node_on_map(node, parent, 0) 
			
		if node.get_skill_state() >= 2:
			GM.add_obligation(node)
			
	var all_nodes_in_tree = tree.get_children()
	for child in all_nodes_in_tree:
		if child.has_method("get_skill_state"):
			if child.get_skill_state() >= 2:
				spawn_branches_for_node(child)
	
	refresh_todo_list()

func _on_server_action_processed(response: Dictionary):
	var s_id = str(response.get("node_id", ""))
	var node = tree.find_skill_node(s_id)
	if node:
		node.setSkillCurProg(response.get("current_progress", 0))
		node.set_base_progress(response.get("target_progress", 1))
		node.setSkillState(response.get("node_state", 2))
		
		if response.get("node_just_finished", false):
			tree.reveal_successors(node)
			spawn_branches_for_node(node)
			if selected_skill == node:
				skill_window.hide()
				selected_skill = null
				
		var server_level = response.get("profile_level", Profile.get_level())
		if server_level != Profile.get_level():
			Profile.set_level(server_level)
			
		if selected_skill == node:
			open_skill_window(node)
			
	Net.fetch_user_tree()

func spawn_branches_for_node(parent_node):
	if parent_node.get_tree_depth() >= 6: return
	
	var existing_children = 0
	for child in tree.get_children():
		if child != parent_node and child.has_method("get_skill_state"):
			var reqs = child.get_required_prev_skills()
			if reqs.size() > 0 and reqs[0] == parent_node.get_skill_id():
				existing_children += 1
				
	if existing_children == 0:
		spawn_new_random_skill(0, parent_node)
		spawn_new_random_skill(1, parent_node)
	elif existing_children == 1:
		spawn_new_random_skill(1, parent_node)
		
	tree.reveal_successors(parent_node)
	
func _process(_delta):
	check_hover()
	update_fog()
	
	if skill_window.visible and selected_skill != null:
		if selected_skill.is_timer_active():
			upgrade_btn.get_node("Label").text = "Завершить досрочно [" + format_time(selected_skill.get_current_timer_sec()) + "]"
			
	if not GM.can_start_new_skill():
		cooldown_text.text = format_time(GM.get_cooldown_time_left())
	else:
		cooldown_text.text = "MAX"

func update_fog():
	var lines_array = PackedVector4Array()
	for child in tree.get_children():
		if not child.has_method("get_skill_state"): continue
		if child.get_skill_state() >= 1: 
			var parents = child.get_required_prev_skills()
			if parents.size() > 0:
				for p_id in parents:
					var pt = tree.find_skill_node(p_id)
					if pt and pt.get_skill_state() >= 1:
						lines_array.append(Vector4(child.global_position.x, child.global_position.y, pt.global_position.x, pt.global_position.y))
			else:
				var c_p = child.global_position
				lines_array.append(Vector4(c_p.x, c_p.y, c_p.x, c_p.y))
	fog.material.set_shader_parameter("lines_pos", lines_array)
	fog.material.set_shader_parameter("lines_count", lines_array.size())
		
func check_hover():
	var mp = get_global_mouse_position()
	var found = null
	for child in tree.get_children():
		if not child.has_method("get_skill_state"): continue
		if child.get_skill_state() == 0: continue 
		if child.global_position.distance_to(mp) < 45.0:
			found = child
			break
	if found != null: show_tooltip(found)
	else: tooltip.hide()

func show_tooltip(node):
	if skill_window.visible:
		tooltip.hide()
		return
	tooltip_name.text = node.get_skill_name()
	if node.get_skill_state() == 1: tooltip_info.text = "Скрытый навык"
	else: 
		if node.get_skill_level() == 0: tooltip_info.text = "Таргет фиксирован" 
		else: tooltip_info.text = "Уровень: " + str(node.get_skill_level())
	tooltip.global_position = get_viewport().get_mouse_position() + Vector2(20, -50)
	tooltip.show()

func _unhandled_input(event):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_RIGHT or event.button_index == MOUSE_BUTTON_MIDDLE:
			is_dragging_camera = event.pressed
	elif event is InputEventMouseMotion and is_dragging_camera:
		if camera: camera.position -= event.relative * camera.zoom.x
	
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var click_pos = get_global_mouse_position()
		for child in tree.get_children():
			if not child.has_method("get_skill_state"): continue
			if child.get_skill_state() == 0: continue 
			if child.global_position.distance_to(click_pos) < 45.0:
				open_skill_window(child)
				break

func _on_close_btn_pressed():
	skill_window.hide()
	selected_skill = null

func open_skill_window(node):
	selected_skill = node
	title_label.text = node.get_skill_name()
	desc_label.text = node.get_skill_title()
	prog_row.hide()
	
	if node.get_skill_level() == 0:
		lvl_label.text = "Разовый навык"
		lvl_up_btn.hide()
	else:
		lvl_label.text = "Уровень: " + str(node.get_skill_level())
		if node.get_skill_state() >= 2: lvl_up_btn.show()
		else: lvl_up_btn.hide()
	
	var period_text = ""
	var cd = node.get_cooldown_type()
	if cd == 1: period_text = "[Ежедневно]"
	elif cd == 2: period_text = "[Еженедельно]"
	elif cd == 3: period_text = "[Ежемесячно]"
	
	var state = node.get_skill_state()
	
	if state == 1:
		extra_info.text = period_text + "\nТребует энергии для разблокировки."
		upgrade_btn.get_node("Label").text = "ИЗУЧИТЬ"
		upgrade_btn.show()
		upgrade_btn.disabled = false
		
	elif state == 2: 
		if node.get_task_type() == 1: 
			extra_info.text = period_text + "\nНа время: " + str(node.get_skill_time() / 60) + " мин."
			if node.is_timer_active(): 
				upgrade_btn.get_node("Label").text = "Завершить " + format_time(node.get_current_timer_sec())
			else: 
				upgrade_btn.get_node("Label").text = "Старт"
		else: 
			var c = node.get_skill_cur_prog()
			var n = node.get_skill_nes_prog()
			extra_info.text = period_text + "\nЦель: " + str(c) + " / " + str(n)
			
			var diff = n - c
			if diff > 1:
				prog_row.show()
				prog_slider.min_value = 1
				prog_slider.max_value = diff
				prog_slider.value = 1
				slider_val_label.text = "+1"
				upgrade_btn.get_node("Label").text = "Добавить"
			else:
				upgrade_btn.get_node("Label").text = "Выполнить"
			
		upgrade_btn.show()
		upgrade_btn.disabled = false
		
	elif state == 3:
		extra_info.text = period_text + "\nЗавершено!"
		upgrade_btn.hide() 
		
	tooltip.hide() 
	skill_window.show()

func _on_slider_changed(value):
	slider_val_label.text = "+" + str(value)
	upgrade_btn.get_node("Label").text = "Добавить (+" + str(value) + ")"

func _on_upgrade_btn_pressed():
	if selected_skill == null: return
	var state = selected_skill.get_skill_state()
	
	if state == 1: 
		if GM.request_start_skill():
			selected_skill.set_skill_state(2) 
			GM.add_obligation(selected_skill)
			spawn_branches_for_node(selected_skill) 
			open_skill_window(selected_skill)
			Net.send_action(int(selected_skill.get_skill_id()), 0)
			return 
			
	if state == 2: 
		var add_amount = 0
		if selected_skill.get_task_type() == 1: 
			if selected_skill.is_timer_active():
				if selected_skill.has_method("force_finish_timer"):
					selected_skill.force_finish_timer() 
					add_amount = 1
			else:
				selected_skill.start_progress_time() 
			GM.add_obligation(selected_skill) 
		else: 
			add_amount = 1
			if prog_row.visible:
				add_amount = int(prog_slider.value)
			
			selected_skill.add_progress(add_amount)
			GM.add_obligation(selected_skill) 
			
		if add_amount > 0:
			Net.send_action(int(selected_skill.get_skill_id()), add_amount)
		else:
			open_skill_window(selected_skill)

func _on_lvl_up_btn_pressed():
	if selected_skill == null: return
	var lvl = selected_skill.get_skill_level()
	selected_skill.set_skill_level(lvl + 1)
	selected_skill.refresh_target_by_level()
	
	if selected_skill.get_skill_state() == 3:
		selected_skill.set_skill_state(2)
		
	GM.add_obligation(selected_skill) 
	open_skill_window(selected_skill)
	
func _on_todo_toggle():
	is_todo_open = !is_todo_open
	var tw = create_tween()
	var target_y = 0
	
	if is_todo_open:
		target_y = get_viewport_rect().size.y - todo_panel.size.y
		todo_toggle_btn.text = "Свернуть"
	else:
		target_y = get_viewport_rect().size.y - 40
		todo_toggle_btn.text = "Задачи ^"
		
	tw.tween_property(todo_panel, "position:y", target_y, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	
func refresh_todo_list():
	for child in task_list_container.get_children(): child.queue_free()
	var tasks = GM.get_all_obligations()
	var active_tasks = []
	var done_tasks = []
	
	for t in tasks:
		if t["current"] >= t["target"]: done_tasks.append(t)
		else: active_tasks.append(t)
		
	for t in active_tasks: create_todo_item(t, false)
	for t in done_tasks: create_todo_item(t, true)

func create_todo_item(task, is_done):
	var btn = Button.new()
	btn.flat = true
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	btn.custom_minimum_size = Vector2(280, 35)
	
	var prefix = ""
	if task["cd_type"] == 1: prefix = "[ДЕНЬ] "
	elif task["cd_type"] == 2: prefix = "[НЕДЕЛЯ] "
	elif task["cd_type"] == 3: prefix = "[МЕСЯЦ] "
	
	var progress_txt = str(task["current"]) + "/" + str(task["target"])
	if task["task_type"] == 1: progress_txt = "Таймер"
	
	btn.text = prefix + task["name"] + " (" + progress_txt + ")"
	
	var item_bg = ColorRect.new()
	item_bg.custom_minimum_size = Vector2(0, 35)
	
	if is_done:
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		item_bg.color = Color(0.1, 0.1, 0.15, 0.8) 
	else:
		item_bg.color = Color(0.2, 0.2, 0.3, 0.8)  
		
	var t_id = task["id"]
	btn.pressed.connect(func():
		var target_node = tree.find_skill_node(t_id)
		if target_node:
			var tw = create_tween()
			tw.tween_property(camera, "position", target_node.position, 0.4).set_trans(Tween.TRANS_QUAD)
			open_skill_window(target_node)
	)
	item_bg.add_child(btn)
	task_list_container.add_child(item_bg)

func update_player_hud():
	var level_val = Profile.get_level() if Profile.has_method("get_level") else 1
	var xp_val = Profile.get_xp() if Profile.has_method("get_xp") else 0
	var max_xp_val = Profile.get_max_xp() if Profile.has_method("get_max_xp") else 100
	
	lvl_display.text = "Level " + str(level_val)
	xp_bar.max_value = max_xp_val
	var tw = create_tween()
	tw.tween_property(xp_bar, "value", xp_val, 0.4).set_trans(Tween.TRANS_QUAD)
	xp_text_label.text = str(xp_val) + " / " + str(max_xp_val) + " XP"

func update_energy_hud():
	if GM.can_start_new_skill(): energy_text.text = "Энергия: ГОТОВО"
	else: energy_text.text = "Восстановление..."

func _on_global_level_up(new_level):
	print("ИГРОК ПОЛУЧИЛ УРОВЕНЬ: ", new_level)

func format_time(seconds: float) -> String:
	var m = int(seconds / 60.0)
	var s = int(seconds) % 60
	return "%02d:%02d" % [m, s]
	
func spawn_new_random_skill(child_index: int, parent_node: SkillNode):  
	var new_id_base = GM.roll_new_skill(parent_node.get_subject_area())
	if new_id_base == "error": return 
	
	var data = GM.get_skill_data(new_id_base)
	var unique_id = str(new_id_base) + "_" + str(randi() % 10000)
	
	var new_node = SkillNode.new()
	new_node.set_skill_id(unique_id)
	
	if not data.is_empty():
		new_node.set_skill_name(data["node_name"])
		new_node.set_skill_title(data["node_info"])
		new_node.set_skill_rarity(int(data.get("node_rarity", 0)))
		new_node.set_skill_xp(int(data.get("xp_reward", 10)))
		
		if data.has("cooldown"):
			var cd = data["cooldown"]
			if cd == "daily" or cd == "D": new_node.set_cooldown_type(1)
			elif cd == "weekly" or cd == "W": new_node.set_cooldown_type(2)
			elif cd == "monthly" or cd == "M": new_node.set_cooldown_type(3)
			else: new_node.set_cooldown_type(0) 
			
		if data.has("duration_sec") and data["duration_sec"] != null:
			new_node.set_task_type(1) 
			new_node.set_skill_time(int(data["duration_sec"]))
		else:
			new_node.set_task_type(0) 
			new_node.set_skill_time(-1)
			
		new_node.set_base_progress(int(data.get("base_progress", 1)))
	else:
		new_node.set_skill_name("Секрет")
		new_node.set_base_progress(1)
	
	new_node.set_skill_state(0) 
	new_node.set_skill_subject_area(parent_node.get_subject_area())
	new_node.set_skill_level(1) 
	new_node.refresh_target_by_level() 
	
	var reqs = PackedStringArray()
	reqs.append(parent_node.get_skill_id())
	new_node.set_required_prev_skills(reqs)
	
	tree.add_child(new_node)
	tree.registerNode(new_node)
	setup_node_graphics(new_node)
	tree.place_node_on_map(new_node, parent_node, child_index)
	
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
