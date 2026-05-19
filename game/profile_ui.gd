extends Control

@onready var top_bar = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/TopBar
@onready var settings_btn = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/TopBar/Control3/SettingsBtn
@onready var avatar_btn = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/TopBar/Avatar

@onready var nick_label = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/Nickname
@onready var nick_edit = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/NickEdit
@onready var status_label = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/Status

@onready var lvl_label = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/LvlLabel
@onready var xp_bar = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/XPBar
@onready var xp_text = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/XPText

@onready var logout_btn = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/LogoutBtn
@onready var save_btn = $MarginContainer/MainSplit/VBoxContainer/PlayerCard/MarginContainer/VBoxContainer/SaveBtn

@onready var streak_label = $MarginContainer/MainSplit/VBoxContainer/SummaryCard/MarginContainer/VBoxContainer/StreakLb
@onready var sum_tasks_label = $MarginContainer/MainSplit/VBoxContainer/SummaryCard/MarginContainer/VBoxContainer/SumTasksLb
@onready var dom_area_label = $MarginContainer/MainSplit/VBoxContainer/SummaryCard/MarginContainer/VBoxContainer/Label2
@onready var achiev_grid = $MarginContainer/MainSplit/AchievCard/MarginContainer/VBoxContainer/ScrollContainer/AchievGrid

var is_editing = false
var file_dialog: FileDialog

var avatar_list = [
	preload("res://assets/bg/avatar2.png"),
	preload("res://assets/bg/p0.png"),
	preload("res://assets/bg/p1.png"),
	preload("res://assets/bg/p2.png")
]
var current_avatar_id = 0

func _ready():
	Profile.profile_updated.connect(update_ui)
	
	logout_btn.pressed.connect(_on_logout)
	settings_btn.pressed.connect(toggle_edit_mode)
	save_btn.pressed.connect(save_profile)
	avatar_btn.pressed.connect(_on_avatar_clicked)
	
	nick_edit.hide()
	save_btn.hide()
	
	_setup_file_dialog()
	
	Net.history_loaded.connect(_on_server_history_loaded)
	Net.tree_loaded.connect(_on_server_tree_loaded)
	
	update_ui()
	populate_achievements([])
	
	Net.fetch_history()
	Net.fetch_user_tree()

func _setup_file_dialog():
	file_dialog = FileDialog.new()
	file_dialog.title = "Выберите изображение для аватарки"
	file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	file_dialog.access = FileDialog.ACCESS_FILESYSTEM
	file_dialog.filters = PackedStringArray(["*.png ; PNG Images", "*.jpg,*.jpeg ; JPEG Images"])
	file_dialog.file_selected.connect(_on_avatar_file_selected)
	add_child(file_dialog)

func update_ui():
	var p_name = Profile.get_player_name()
	if p_name == "": p_name = "Player"
	nick_label.text = p_name
	
	current_avatar_id = Profile.get_avatar_id()
	if current_avatar_id == -1:
		_load_custom_avatar()
	elif current_avatar_id >= 0 and current_avatar_id < avatar_list.size():
		avatar_btn.texture_normal = avatar_list[current_avatar_id]
	
	var lvl = Profile.get_level()
	lvl_label.text = "Уровень " + str(lvl)
	
	if lvl <= 3: status_label.text = "Начинающий пользователь"
	elif lvl <= 7: status_label.text = "Опытный пользователь"
	elif lvl <= 15: status_label.text = "Мастер"
	else: status_label.text = "Легенда"
	
	xp_bar.max_value = Profile.get_max_xp()
	var tw = create_tween()
	tw.tween_property(xp_bar, "value", Profile.get_xp(), 0.5).set_trans(Tween.TRANS_QUAD)
	xp_text.text = str(Profile.get_xp()) + " / " + str(Profile.get_max_xp()) + " XP"

func _load_custom_avatar():
	if FileAccess.file_exists("user://custom_avatar.png"):
		var img = Image.load_from_file("user://custom_avatar.png")
		if img:
			var tex = ImageTexture.create_from_image(img)
			avatar_btn.texture_normal = tex

func _on_avatar_clicked():
	if is_editing:
		file_dialog.popup_centered(Vector2i(800, 600))

func _on_avatar_file_selected(path: String):
	var img = Image.load_from_file(path)
	if img:
		var error = img.save_png("user://custom_avatar.png")
		if error == OK:
			current_avatar_id = -1
			_load_custom_avatar()
		else:
			print("ошибка")
	else:
		print("ее удалось загрузить файл")
		
func _on_server_history_loaded(history_array: Array):
	populate_summary(history_array)
	populate_achievements(history_array)

func _on_server_tree_loaded(_json_string: String):
	Net.fetch_history()

func populate_summary(history: Array):
	var streak = _calculate_streak(history)
	streak_label.text = "Серия: " + str(streak) + " дней"
	sum_tasks_label.text = "Выполнено действий: " + str(history.size())
	
	if history.size() > 0:
		var last_action = history[0]
		dom_area_label.text = "Последний активный: " + str(last_action.get("node_name", "Нет данных"))
	else:
		dom_area_label.text = "Лучший навык: Нет данных"

func _calculate_streak(history: Array) -> int:
	if history.is_empty(): return 0
	var unique_days = []
	for entry in history:
		var d = entry.get("date", "")
		if d != "" and not unique_days.has(d):
			unique_days.append(d)
	unique_days.sort()
	unique_days.reverse()
	
	var dict = Time.get_date_dict_from_system()
	var today = "%04d-%02d-%02d" % [dict.year, dict.month, dict.day]
	
	var yesterday_unix = Time.get_unix_time_from_system() - 86400
	var y_dict = Time.get_date_dict_from_unix_time(yesterday_unix)
	var yesterday = "%04d-%02d-%02d" % [y_dict.year, y_dict.month, y_dict.day]
	
	if not unique_days.has(today) and not unique_days.has(yesterday):
		return 0
		
	var streak = 0
	var check_unix = Time.get_unix_time_from_system()
	if not unique_days.has(today) and unique_days.has(yesterday):
		check_unix = yesterday_unix
		
	while true:
		var c_dict = Time.get_date_dict_from_unix_time(check_unix)
		var c_str = "%04d-%02d-%02d" % [c_dict.year, c_dict.month, c_dict.day]
		if unique_days.has(c_str):
			streak += 1
			check_unix -= 86400
		else:
			break
	return streak

func toggle_edit_mode():
	is_editing = !is_editing
	if is_editing:
		nick_label.hide()
		nick_edit.show()
		nick_edit.text = Profile.get_player_name()
		
		logout_btn.hide()
		save_btn.show()
		settings_btn.modulate = Color(1.5, 1.5, 2.0)
	else:
		save_profile()

func save_profile():
	is_editing = false
	var new_name = nick_edit.text.strip_edges()
	if new_name != "":
		Profile.set_player_name(new_name)
		
	Profile.set_avatar_id(current_avatar_id)
	
	nick_edit.hide()
	nick_label.show()
	save_btn.hide()
	logout_btn.show()
	settings_btn.modulate = Color(1.0, 1.0, 1.0)

func populate_achievements(history: Array):
	for child in achiev_grid.get_children(): 
		child.queue_free()
	
	if not FileAccess.file_exists("res://achievements.json"):
		return
		
	var file = FileAccess.open("res://achievements.json", FileAccess.READ)
	var json_text = file.get_as_text()
	var achievs_base = JSON.parse_string(json_text)
	
	if achievs_base == null or typeof(achievs_base) != TYPE_ARRAY:
		return

	var streak = _calculate_streak(history)
	var total_actions = history.size()
	var area_stats = {0: 0, 1: 0, 2: 0, 3: 0}
	
	for entry in history:
		var s_id = str(entry.get("skill_id", ""))
		var node_area = -1
		
		for t in GM.get_all_obligations():
			var t_id = ""
			if typeof(t) == TYPE_DICTIONARY:
				t_id = str(t.get("id", ""))
			elif typeof(t) == TYPE_OBJECT and t != null:
				if t.has_method("get_skill_id"):
					t_id = str(t.get_skill_id())
				elif "id" in t:
					t_id = str(t.id)
					
			if t_id == s_id:
				if typeof(t) == TYPE_DICTIONARY:
					node_area = int(t.get("area", -1))
				elif typeof(t) == TYPE_OBJECT:
					if t.has_method("get_subject_area"):
						node_area = t.get_subject_area()
				break
				
		if node_area == -1:
			var name_str = entry.get("node_name", "").to_lower()
			if "чтение" in name_str or "книг" in name_str: node_area = 0
			elif "отжимания" in name_str or "спорт" in name_str or "трениров" in name_str or "планка" in name_str: node_area = 1
			elif "слов" in name_str or "язык" in name_str or "аудиров" in name_str: node_area = 2
			elif "скетч" in name_str or "идеи" in name_str or "музык" in name_str or "писател" in name_str: node_area = 3

		if area_stats.has(node_area):
			area_stats[node_area] += 1

	for ach in achievs_base:
		var is_unlocked = false
		var type = ach.get("type", "")
		var target = int(ach.get("target", 1))
		
		match type:
			"total":
				is_unlocked = (total_actions >= target)
			"streak":
				is_unlocked = (streak >= target)
			"area":
				var a_id = int(ach.get("area_id", -1))
				if area_stats.has(a_id):
					is_unlocked = (area_stats[a_id] >= target)

		create_achiev_card(ach.get("name", ""), ach.get("desc", ""), is_unlocked)

func create_achiev_card(a_name: String, a_desc: String, is_unlocked: bool):
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(250, 120) 
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var sb = StyleBoxFlat.new()
	sb.corner_radius_top_left = 15; sb.corner_radius_top_right = 15
	sb.corner_radius_bottom_left = 15; sb.corner_radius_bottom_right = 15
	
	if is_unlocked:
		sb.bg_color = Color(0.25, 0.15, 0.4, 0.85) 
		sb.border_width_left = 2; sb.border_width_right = 2; sb.border_width_top = 2; sb.border_width_bottom = 2
		sb.border_color = Color(0.6, 0.3, 0.9, 0.6) 
	else:
		sb.bg_color = Color(0.1, 0.1, 0.12, 0.8)
		sb.border_width_left = 1; sb.border_width_right = 1; sb.border_width_top = 1; sb.border_width_bottom = 1
		sb.border_color = Color(0.2, 0.2, 0.25, 0.5)
		
	card.add_theme_stylebox_override("panel", sb)
	
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 15)
	margin.add_theme_constant_override("margin_bottom", 15)
	card.add_child(margin)
	
	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	margin.add_child(vbox)
	
	var title = Label.new()
	if is_unlocked:
		title.text = a_name
	else:
		title.text =  a_name
		
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 18) 
	if not is_unlocked: 
		title.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = a_desc
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	desc.add_theme_font_size_override("font_size", 13) 
	desc.add_theme_color_override("font_color", Color(0.9, 0.9, 1.0) if is_unlocked else Color(0.3, 0.3, 0.33))
	vbox.add_child(desc)
	
	achiev_grid.add_child(card)

func _on_logout():
	Profile.set_player_name("") 
	Profile.set_meta("auth_token", "")
	get_tree().change_scene_to_file("res://login.tscn")
