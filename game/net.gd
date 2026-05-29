extends Node

var BASE_URL = "http://localhost:8000"  #var BASE_URL = "http://127.0.0.1:8000" 
var auth_token = ""

signal auth_success
signal auth_failed(msg)
signal catalog_loaded(json_data)
signal tree_loaded(json_data)
signal history_loaded(history_array)
signal action_updated(response_dict)
signal node_activated(response_dict) 

signal strava_connected_success
signal strava_connected_error
signal strava_activities_loaded(activities)

func _ready():
	if Profile.has_meta("auth_token"):
		auth_token = Profile.get_meta("auth_token")

func _send_request(url_path: String, method: int, body_dict: Dictionary, callback: Callable):
	if Profile.has_meta("auth_token"):
		auth_token = Profile.get_meta("auth_token")
	var request = HTTPRequest.new()
	add_child(request)
	var headers = ["Content-Type: application/json"]
	if auth_token != "": headers.append("Authorization: Token " + auth_token)
	var body_json = ""
	if body_dict.size() > 0: body_json = JSON.stringify(body_dict)
	request.request_completed.connect(func(_result, _code, _hdrs, _body):
		callback.call(_code, _body)
		request.queue_free()
	)
	request.request(BASE_URL + url_path, headers, method, body_json)

func login(username, password):
	_send_request("/login/", HTTPClient.METHOD_POST, {"username": username, "password": password}, func(code, body):
		if code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			Profile.set_meta("auth_token", data.get("token", ""))
			auth_success.emit()
		else: auth_failed.emit("Ошибка")
	)

func fetch_user_tree():
	_send_request("/tree/", HTTPClient.METHOD_GET, {}, func(code, body):
		if code == 200: tree_loaded.emit(body.get_string_from_utf8())
	)

func fetch_catalog():
	_send_request("/catalog/", HTTPClient.METHOD_GET, {}, func(code, body):
		if code == 200: catalog_loaded.emit(body.get_string_from_utf8())
	)

func fetch_history():
	_send_request("/tree/history/", HTTPClient.METHOD_GET, {}, func(code, body):
		if code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_ARRAY: history_loaded.emit(data)
	)

func activate_skill(skill_id: int):
	_send_request("/tree/activate_node/", HTTPClient.METHOD_POST, {"skill_id": skill_id}, func(code, body):
		if code == 200: node_activated.emit(JSON.parse_string(body.get_string_from_utf8()))
	)

func send_action(skill_id: int, added_progress: int = 1):
	_send_request("/tree/action/", HTTPClient.METHOD_POST, {"skill_id": skill_id, "added_progress": added_progress}, func(code, body):
		if code == 200: action_updated.emit(JSON.parse_string(body.get_string_from_utf8()))
	)

func send_levelup(skill_id: int, new_target: int):
	var payload = {"skill_id": skill_id, "is_levelup": true, "new_target": new_target}
	_send_request("/tree/action/", HTTPClient.METHOD_POST, payload, func(code, body):
		if code == 200: action_updated.emit(JSON.parse_string(body.get_string_from_utf8()))
	)


func add_node_to_server(parent_id: int, p_name: String, info: String, rarity: int, xp: int, target: int, cooldown_str: String, local_node: Node):
	var payload = {
		"parent_id": parent_id, "node_name": p_name, "node_info": info, 
		"node_rarity": rarity, "xp_reward": xp, "target_progress": target,
		"cooldown": cooldown_str
	}
	_send_request("/tree/add_node/", HTTPClient.METHOD_POST, payload, func(code, body):
		if code == 201:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_DICTIONARY and data.has("new_node_id"):
				if is_instance_valid(local_node) and local_node.has_method("set_skill_id"):
					local_node.set_skill_id(str(data["new_node_id"]))
					var p = local_node.get_parent()
					if p and p.has_method("registerNode"):
						p.registerNode(local_node) 
						if p.has_method("queue_redraw"): p.queue_redraw() 
	)
	
func send_strava_code(code: String):
	_send_request("/integrations/auth/strava-callback", HTTPClient.METHOD_POST, {"code": code}, func(http_code, _body):
		if http_code == 200 or http_code == 201: strava_connected_success.emit()
		else: strava_connected_error.emit()
	)

func fetch_strava_activities():
	_send_request("/integrations/activities/", HTTPClient.METHOD_GET, {}, func(http_code, body):
		if http_code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_ARRAY: strava_activities_loaded.emit(data)
	)
	
func create_custom_skill(node_name: String, node_info: String, cooldown: String, target_val: int, is_timer: bool):
	var new_node = SkillNode.new()
	new_node.set_skill_id("custom_" + str(randi() % 100000))
	new_node.set_skill_name(node_name)
	new_node.set_skill_title(node_info)
	new_node.set_skill_state(2)
	new_node.set_base_progress(target_val)
	new_node.set_skill_nes_prog(target_val)
	
	if cooldown == "D": new_node.set_cooldown_type(1)
	elif cooldown == "W": new_node.set_cooldown_type(2)
	elif cooldown == "M": new_node.set_cooldown_type(3)
	
	if is_timer:
		new_node.set_task_type(1)
		new_node.set_skill_time(target_val)
	else:
		new_node.set_task_type(0)
		
	GM.add_obligation(new_node)
	action_updated.emit({})
