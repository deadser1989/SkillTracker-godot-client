extends Control

@onready var back_btn = $MarginContainer/VBoxContainer/HBoxContainer/BackBtn
@onready var add_skill_btn = $MarginContainer/VBoxContainer/HBoxContainer/AddSkillBtn
@onready var skill_filter_btn = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/SkillFilterBtn
@onready var time_filter_btn = $MarginContainer/VBoxContainer/HBoxContainer/VBoxContainer/TimeFilterBtn

@onready var draw_area = $MarginContainer/VBoxContainer/GraphCard/MarginContainer/GraphDrawArea

@onready var active_list = $MarginContainer/VBoxContainer/BottomSplit/LeftPanel/ActiveTasksCard/MarginContainer/ScrollContainer/ActiveList
@onready var history_list = $MarginContainer/VBoxContainer/BottomSplit/RightPanel/HistoryCard/MarginContainer/ScrollContainer/HistoryList

@onready var skill_window = $SkillWindow
@onready var title_label = $SkillWindow/MarginContainer/MainCol/Header/TitleBox/Title
@onready var lvl_label = $SkillWindow/MarginContainer/MainCol/LvlLabel
@onready var desc_label = $SkillWindow/MarginContainer/MainCol/Description
@onready var extra_info = $SkillWindow/MarginContainer/MainCol/ExtraInfo
@onready var close_btn = $SkillWindow/MarginContainer/MainCol/Header/CloseBtn

@onready var prog_row = $SkillWindow/MarginContainer/MainCol/ProgressRow
@onready var prog_slider = $SkillWindow/MarginContainer/MainCol/ProgressRow/ProgressSlider
@onready var slider_val_label = $SkillWindow/MarginContainer/MainCol/ProgressRow/SliderValLabel

@onready var lvl_up_btn = $SkillWindow/MarginContainer/MainCol/HBoxContainer/LvlUpBtn
@onready var upgrade_btn = $SkillWindow/MarginContainer/MainCol/HBoxContainer/UpgradeBtn

@onready var add_skill_window = $AddSkillWindow
@onready var name_input = $AddSkillWindow/MarginContainer/FormCol/NameInput
@onready var desc_input = $AddSkillWindow/MarginContainer/FormCol/DescInput
@onready var period_btn = $AddSkillWindow/MarginContainer/FormCol/PeriodBtn
@onready var type_btn = $AddSkillWindow/MarginContainer/FormCol/TypeBtn
@onready var duration_row = $AddSkillWindow/MarginContainer/FormCol/DurationRow
@onready var duration_input = $AddSkillWindow/MarginContainer/FormCol/DurationRow/DurationInput
@onready var cancel_btn = $AddSkillWindow/MarginContainer/FormCol/FormButtons/CancelBtn
@onready var save_btn = $AddSkillWindow/MarginContainer/FormCol/FormButtons/SaveBtn

var current_time_mode = 0  
var selected_skill_id = "" 
var selected_skill = null 

var graph_labels = [] 
var line_reading = []
var line_fitness = []
var line_language = []
var line_creative = []
var bar_target = []
var bar_current = []

var server_history_data: Array = []

func _ready():
	back_btn.pressed.connect(func(): get_tree().change_scene_to_file("res://shell.tscn"))
	draw_area.draw.connect(_on_graph_draw)
	draw_area.resized.connect(draw_area.queue_redraw)
	
	skill_window.hide()
	add_skill_window.hide()
	duration_row.hide()
	
	close_btn.pressed.connect(_on_close_btn_pressed)
	prog_slider.value_changed.connect(_on_slider_changed)
	upgrade_btn.pressed.connect(_on_upgrade_btn_pressed)
	lvl_up_btn.pressed.connect(_on_lvl_up_btn_pressed)
	
	add_skill_btn.pressed.connect(_on_add_skill_btn_pressed)
	cancel_btn.pressed.connect(_on_cancel_form_pressed)
	save_btn.pressed.connect(_on_save_form_pressed)
	type_btn.item_selected.connect(_on_type_btn_selected)
	
	GM.obligations_updated.connect(func(): setup_filters(); populate_active_tasks())
	Net.action_updated.connect(func(_res_dict): fetch_history_from_server())
	
	setup_filters()
	populate_active_tasks()
	fetch_history_from_server()

func _process(_delta):
	if skill_window.visible and selected_skill != null:
		if selected_skill.get_task_type() == 1 and selected_skill.has_method("is_timer_active") and selected_skill.is_timer_active():
			upgrade_btn.get_node("Label").text = "Завершить " + format_time(selected_skill.get_current_timer_sec())
			
func format_time(seconds: float) -> String:
	var m = int(seconds / 60.0)
	var s = int(seconds) % 60
	return "%02d:%02d" % [m, s]

func setup_filters():
	skill_filter_btn.clear()
	
	skill_filter_btn.add_item("Общая активность", 0)
	skill_filter_btn.set_item_metadata(0, "")
	skill_filter_btn.add_separator()
	skill_filter_btn.add_item("Чтение", 2)
	skill_filter_btn.set_item_metadata(2, "area_0")
	skill_filter_btn.add_item("Спорт", 3)
	skill_filter_btn.set_item_metadata(3, "area_1")
	skill_filter_btn.add_item("Языки", 4)
	skill_filter_btn.set_item_metadata(4, "area_2")
	skill_filter_btn.add_item("Творчество", 5)
	skill_filter_btn.set_item_metadata(5, "area_3")
	skill_filter_btn.add_separator()
	
	var tasks = GM.get_all_obligations()
	if tasks.size() > 0:
		for task in tasks:
			var prefix = ""
			if task["cd_type"] == 1: prefix = "[ЕЖЕДНЕВНО] "
			elif task["cd_type"] == 2: prefix = "[ЕЖЕНЕДЕЛЬНО] "
			elif task["cd_type"] == 3: prefix = "[ЕЖЕМЯСЯЧНО] "
			
			skill_filter_btn.add_item(" " + prefix + task["name"])
			var last_idx = skill_filter_btn.get_item_count() - 1
			skill_filter_btn.set_item_metadata(last_idx, str(task["id"]))

	if not skill_filter_btn.item_selected.is_connected(_on_skill_filter_changed):
		skill_filter_btn.item_selected.connect(_on_skill_filter_changed)
	
	time_filter_btn.clear()
	time_filter_btn.add_item("За последнюю неделю", 0)
	time_filter_btn.add_item("За этот месяц", 1)
	if not time_filter_btn.item_selected.is_connected(_on_time_filter_changed):
		time_filter_btn.item_selected.connect(_on_time_filter_changed)

func _on_time_filter_changed(index: int):
	current_time_mode = index
	aggregate_data()
	draw_area.queue_redraw()

func _on_skill_filter_changed(index: int):
	var meta = skill_filter_btn.get_item_metadata(index)
	if meta != null: selected_skill_id = str(meta)
	else: selected_skill_id = ""
	aggregate_data()
	draw_area.queue_redraw()

func _on_add_skill_btn_pressed():
	name_input.text = ""
	desc_input.text = ""
	period_btn.selected = 0
	type_btn.selected = 0
	duration_input.text = "10"
	duration_row.hide()
	add_skill_window.show()

func _on_cancel_form_pressed():
	add_skill_window.hide()

func _on_type_btn_selected(index: int):
	if index == 1: duration_row.show()
	else: duration_row.hide()

func _on_save_form_pressed():
	var s_name = name_input.text.strip_edges()
	if s_name == "": return
	
	var cd_str = "D"
	if period_btn.selected == 1: cd_str = "W"
	elif period_btn.selected == 2: cd_str = "M"
	
	var target_val = 1
	var is_timer = false
	
	if type_btn.selected == 1:
		var mins = max(1, int(duration_input.text))
		target_val = mins * 60
		is_timer = true
	
	if Net.has_method("create_custom_skill"):
		Net.create_custom_skill(s_name, desc_input.text.strip_edges(), cd_str, target_val, is_timer)
	add_skill_window.hide()
	
func fetch_history_from_server():
	Net._send_request("/tree/history/", HTTPClient.METHOD_GET, {}, func(code, body):
		if code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_ARRAY:
				server_history_data = data
				populate_history()
				aggregate_data()
				draw_area.queue_redraw()
	)

func aggregate_data():
	graph_labels.clear()
	line_reading.clear()
	line_fitness.clear()
	line_language.clear()
	line_creative.clear()
	bar_target.clear()
	bar_current.clear()
	
	var days_count = 7 if current_time_mode == 0 else 31
	var now = Time.get_unix_time_from_system()
	
	for i in range(days_count):
		line_reading.append(0)
		line_fitness.append(0)
		line_language.append(0)
		line_creative.append(0)
		bar_target.append(0)
		bar_current.append(0)
		
		var day_unix = now - (days_count - 1 - i) * 86400
		var dict = Time.get_date_dict_from_unix_time(day_unix)
		
		if current_time_mode == 0:
			var d_names = ["Вс", "Пн", "Вт", "Ср", "Чт", "Пт", "Сб"]
			graph_labels.append(d_names[dict.weekday])
		else:
			if i == days_count - 1: graph_labels.append(str(dict.day))
			elif (days_count - 1 - i) % 5 == 0: graph_labels.append(str(dict.day))
			else: graph_labels.append("")

	for entry in server_history_data:
		var date_str = entry.get("date", "")
		if date_str == "": continue
		var parts = date_str.split("-")
		if parts.size() < 3: continue
		
		var dict = {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2]), "hour": 12, "minute": 0, "second": 0}
		var entry_time = Time.get_unix_time_from_datetime_dict(dict)
		var diff_days = int((now - entry_time) / 86400)
		
		if diff_days >= 0 and diff_days < days_count:
			var idx = days_count - 1 - diff_days
			var prog = int(entry.get("progress_added", 1))
			var s_id = str(entry.get("skill_id", ""))
			
			if selected_skill_id == "" or selected_skill_id.begins_with("area_"):
				var node_area = -1
				for t in GM.get_all_obligations():
					if str(t["id"]) == s_id:
						node_area = int(t.get("area", -1))
						break
				
				if node_area == -1:
					var n_str = entry.get("node_name", "").to_lower()
					if "чтени" in n_str or "книг" in n_str or "литератур" in n_str: node_area = 0
					elif "спорт" in n_str or "йога" in n_str or "трениров" in n_str or "отжиман" in n_str or "планк" in n_str: node_area = 1
					elif "язык" in n_str or "слов" in n_str or "english" in n_str: node_area = 2
					elif "творчеств" in n_str or "фото" in n_str or "каллиграф" in n_str or "рисун" in n_str: node_area = 3
					else: node_area = 0 

				if node_area == 0: line_reading[idx] += prog
				elif node_area == 1: line_fitness[idx] += prog
				elif node_area == 2: line_language[idx] += prog
				elif node_area == 3: line_creative[idx] += prog
				
			else:
				if s_id == selected_skill_id: bar_current[idx] += prog

	if selected_skill_id != "" and not selected_skill_id.begins_with("area_"):
		var current_target = 10
		for t in GM.get_all_obligations():
			if str(t["id"]) == selected_skill_id:
				current_target = int(t.get("target", 10))
				break
		for i in range(days_count): bar_target[i] = current_target
		
func _on_graph_draw():
	if draw_area.size.x == 0 or draw_area.size.y == 0: return 
	var pad_left = 60.0  
	var pad_bottom = 60.0 
	var pad_right = 30.0
	
	var w = draw_area.size.x
	var h = draw_area.size.y
	var graph_w = w - pad_left - pad_right
	var graph_h = h - pad_bottom - 30.0 
	var base_y = h - pad_bottom 
	var font = ThemeDB.fallback_font

	var max_val = 1
	if selected_skill_id == "" or selected_skill_id.begins_with("area_"):
		var all_lines = line_reading + line_fitness + line_language + line_creative
		for v in all_lines: if v > max_val: max_val = v
	else:
		for v in bar_target: if v > max_val: max_val = v
		for v in bar_current: if v > max_val: max_val = v
	
	max_val = int(max_val * 1.25)
	if max_val == 0: max_val = 1 
	
	for i in range(5):
		var fraction = i / 4.0
		var line_y = base_y - (fraction * graph_h)
		var val_text = str(int(max_val * fraction))
		draw_area.draw_string(font, Vector2(10, line_y + 4), val_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.6, 0.7))
		draw_area.draw_dashed_line(Vector2(pad_left, line_y), Vector2(w - pad_right, line_y), Color(1, 1, 1, 0.1), 1.0, 4.0)

	var step_x = graph_w / float(graph_labels.size() - 1)

	if selected_skill_id == "": _draw_lines_mode(font, step_x, pad_left, base_y, max_val, graph_h, h, -1)
	elif selected_skill_id.begins_with("area_"):
		var area_num = int(selected_skill_id.replace("area_", ""))
		_draw_lines_mode(font, step_x, pad_left, base_y, max_val, graph_h, h, area_num)
	else: _draw_bars_mode(font, step_x, pad_left, base_y, max_val, graph_h, h)

	for i in range(graph_labels.size()):
		if graph_labels[i] != "":
			var x = pad_left + i * step_x
			draw_area.draw_string(font, Vector2(x - 8, base_y + 20), graph_labels[i], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.6, 0.6, 0.7))

func _draw_lines_mode(font, step_x, pad_left, base_y, max_val, graph_h, h, specific_area):
	var cols = [Color(0.2, 0.6, 1.0), Color(1.0, 0.6, 0.2), Color(0.3, 0.9, 0.4), Color(0.8, 0.3, 0.9)]
	var data_arrays = [line_reading, line_fitness, line_language, line_creative]
	var names = ["Чтение", "Спорт", "Языки", "Творчество"]

	for a in range(data_arrays.size()):
		if specific_area != -1 and a != specific_area: continue
		if data_arrays[a].size() == 0: continue
		var arr = data_arrays[a]
		var color = cols[a]
		var points = PackedVector2Array()
		for i in range(arr.size()):
			var x = pad_left + i * step_x
			var y = base_y - ((float(arr[i]) / max_val) * graph_h)
			points.append(Vector2(x, y))
			draw_area.draw_circle(Vector2(x, y), 5.0, color)
			if specific_area != -1 or a == 0: 
				draw_area.draw_dashed_line(Vector2(x, y), Vector2(x, base_y), Color(1, 1, 1, 0.1), 1.0, 6.0)
		draw_area.draw_polyline(points, color, 4.0, true)
		var l_x = pad_left + 150 + (a * 100)
		if specific_area != -1: l_x = pad_left + 200 
		draw_area.draw_rect(Rect2(l_x, h - 25, 12, 12), color)
		draw_area.draw_string(font, Vector2(l_x + 20, h - 15), names[a], HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color.WHITE)

func _draw_bars_mode(font, step_x, pad_left, base_y, max_val, graph_h, h):
	var bar_width = step_x * 0.6 
	if bar_width > 40.0: bar_width = 40.0 
	var target_col = Color(0.4, 0.4, 0.4, 0.4)  
	var current_col = Color(0.6, 0.2, 1.0, 0.8) 
	var success_col = Color(1.0, 0.8, 0.2, 0.85)

	for i in range(bar_target.size()):
		var x = pad_left + i * step_x
		var t_h = (float(bar_target[i]) / max_val) * graph_h
		var c_h = (float(bar_current[i]) / max_val) * graph_h
		draw_area.draw_rect(Rect2(x - bar_width/2, base_y - t_h, bar_width, t_h), target_col)
		var final_col = success_col if bar_current[i] >= bar_target[i] else current_col
		draw_area.draw_rect(Rect2(x - bar_width/2, base_y - c_h, bar_width, c_h), final_col)

	var legend_y = h - 25
	draw_area.draw_rect(Rect2(pad_left + 150, legend_y - 12, 12, 12), current_col)
	draw_area.draw_string(font, Vector2(pad_left + 170, legend_y - 2), "Сделано", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)
	draw_area.draw_rect(Rect2(pad_left + 260, legend_y - 12, 12, 12), target_col)
	draw_area.draw_string(font, Vector2(pad_left + 280, legend_y - 2), "Цель", HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color.WHITE)

func populate_active_tasks():
	for child in active_list.get_children(): child.queue_free()
	
	var tasks = GM.get_all_obligations()
	var active_t = []
	var done_t = []

	for task in tasks:
		if task["current"] >= task["target"]: done_t.append(task)
		else: active_t.append(task)

	for t in active_t: create_stat_todo_item(t, false)
	for t in done_t: create_stat_todo_item(t, true)

func create_stat_todo_item(task, is_done):
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(0, 45)
	btn.alignment = HORIZONTAL_ALIGNMENT_LEFT
	
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 12; sb.corner_radius_top_right = 12
	sb.corner_radius_bottom_left = 12; sb.corner_radius_bottom_right = 12
	
	if is_done:
		btn.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5)) 
		sb.bg_color = Color(0.1, 0.1, 0.15, 0.5) 
	else:
		sb.bg_color = Color(0.25, 0.15, 0.4, 0.85) 
		
	btn.add_theme_stylebox_override("normal", sb)
	btn.add_theme_stylebox_override("hover", sb)
	btn.add_theme_stylebox_override("focus", sb)
	
	var prefix = ""
	if task["cd_type"] == 1: prefix = "[ЕЖЕДНЕВНО] "
	elif task["cd_type"] == 2: prefix = "[ЕЖЕНЕДЕЛЬНО] "
	elif task["cd_type"] == 3: prefix = "[ЕЖЕМЕСЯЧНО] "
	
	var progress_txt = str(task["current"]) + " / " + str(task["target"])
	if task["task_type"] == 1: progress_txt =  "Таймер"
	
	btn.text = "   " + prefix + task["name"] + "  (" + progress_txt + ")"
	
	btn.pressed.connect(func(): recreate_and_open_skill(task["id"]))
	active_list.add_child(btn)

func populate_history():
	for child in history_list.get_children(): child.queue_free()
	if server_history_data.size() == 0:
		var lbl = Label.new()
		lbl.text = "   Вы пока не совершали никаких действий   "
		lbl.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
		history_list.add_child(lbl)
		return

	for act in server_history_data:
		var lbl = Label.new()
		lbl.custom_minimum_size = Vector2(0, 30)
		var skill_name = act.get("node_name", "Навык ID: " + str(act.get("skill_id", "")))
		lbl.text = "  " + act["date"] + ": " + skill_name + " (+" + str(act["progress_added"]) + ")"
		history_list.add_child(lbl)

func recreate_and_open_skill(task_id):
	selected_skill = SkillNode.new()
	selected_skill.set_skill_id(task_id)
	
	var t_name = "Неизвестный навык"
	var t_lvl = 1
	var t_cur = 0
	var t_target = 1
	var cd_type = 0
	var t_type = 0
	var t_time = -1
	
	for t in GM.get_all_obligations():
		if str(t["id"]) == str(task_id):
			t_name = t["name"]
			t_lvl = t["level"]
			t_cur = t["current"]
			t_target = t["target"]
			cd_type = t["cd_type"]
			t_type = t["task_type"]
			
			if t.has("duration_sec"): t_time = int(t["duration_sec"])
			elif t.has("skill_time"): t_time = int(t["skill_time"])
			break
			
	selected_skill.set_skill_name(t_name)
	selected_skill.set_skill_title("Задание из вашего списка.")
	selected_skill.set_skill_level(t_lvl)
	selected_skill.set_skill_cur_prog(t_cur)
	selected_skill.set_skill_nes_prog(t_target)
	
	var base = max(1, int(t_target / max(1, t_lvl)))
	selected_skill.set_base_progress(base)
	
	selected_skill.set_cooldown_type(cd_type)
	selected_skill.set_task_type(t_type)
	
	if t_type == 1: t_time = t_target
	
	selected_skill.set_skill_time(t_time)
	selected_skill.set_skill_state(2) 
	
	open_skill_window(selected_skill)
	
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
	if state == 2: 
		if node.get_task_type() == 1: 
			var t_time = node.get_skill_time()
			if t_time <= 0: t_time = node.get_skill_nes_prog()
			extra_info.text = period_text + "\nНа время: " + str(int(t_time / 60.0)) + " мин."
			if node.has_method("is_timer_active") and node.is_timer_active(): 
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
				upgrade_btn.get_node("Label").text = "Выполнить (+1)"
			
		upgrade_btn.show()
		upgrade_btn.disabled = false
		
	skill_window.show()
	
func _on_close_btn_pressed():
	skill_window.hide()
	selected_skill = null

func _on_slider_changed(value):
	slider_val_label.text = "+" + str(value)
	upgrade_btn.get_node("Label").text = "Добавить (+" + str(value) + ")"

func _on_upgrade_btn_pressed():
	if selected_skill == null: return
	
	var add_amount = 0 
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
		add_amount = 1
		if prog_row.visible:
			add_amount = int(prog_slider.value)
		
		selected_skill.add_progress(add_amount)
		GM.add_obligation(selected_skill) 
		
	if add_amount > 0:
		var raw_id = selected_skill.get_skill_id()
		Net.send_action(int(raw_id), add_amount)
		recreate_and_open_skill(raw_id)
	else:
		open_skill_window(selected_skill)
		
func _on_lvl_up_btn_pressed():
	if selected_skill == null: return
	var lvl = selected_skill.get_skill_level()
	selected_skill.set_skill_level(lvl + 1)
	selected_skill.refresh_target_by_level()
	GM.add_obligation(selected_skill) 
	recreate_and_open_skill(selected_skill.get_skill_id())
