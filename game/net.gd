extends Node

var BASE_URL = "http://127.0.0.1:8000" 
var auth_token = ""

signal auth_success
signal auth_failed(msg)

signal tree_loaded(json_data)
signal history_loaded(history_array)
signal action_updated(response_dict)

func _ready():
	if Profile.has_meta("auth_token"):
		auth_token = Profile.get_meta("auth_token")

func _send_request(url_path: String, method: int, body_dict: Dictionary, callback: Callable):
	if Profile.has_meta("auth_token"):
		auth_token = Profile.get_meta("auth_token")

	var request = HTTPRequest.new()
	add_child(request)
	
	var headers = ["Content-Type: application/json"]
	if auth_token != "":
		headers.append("Authorization: Token " + auth_token)
	
	var body_json = ""
	if body_dict.size() > 0:
		body_json = JSON.stringify(body_dict)
		
	request.request_completed.connect(func(_result, _code, _hdrs, _body):
		callback.call(_code, _body)
		request.queue_free()
	)
	
	request.request(BASE_URL + url_path, headers, method, body_json)

func login(username, password):
	_send_request("/login/", HTTPClient.METHOD_POST, {"username": username, "password": password}, func(code, body):
		if code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			auth_token = data.get("token", "")
			Profile.set_meta("auth_token", auth_token)
			auth_success.emit()
		else:
			auth_failed.emit("Ошибка авторизации")
	)

func fetch_user_tree():
	_send_request("/tree/", HTTPClient.METHOD_GET, {}, func(code, body):
		if code == 200:
			tree_loaded.emit(body.get_string_from_utf8())
	)

func send_action(skill_id: int, added_progress: int = 1):
	_send_request("/tree/action/", HTTPClient.METHOD_POST, {"skill_id": skill_id, "added_progress": added_progress}, func(code, body):
		if code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			action_updated.emit(data)
	)

func fetch_history():
	_send_request("/tree/history/", HTTPClient.METHOD_GET, {}, func(code, body):
		if code == 200:
			var data = JSON.parse_string(body.get_string_from_utf8())
			if typeof(data) == TYPE_ARRAY:
				history_loaded.emit(data)
	)

func create_custom_skill(node_name: String, node_info: String, cooldown: String, duration_sec: int):
	var payload = {
		"node_name": node_name,
		"node_info": node_info,
		"cooldown": cooldown,
		"area": 4,
		"node_type": "A"
	}
	
	if duration_sec > 0:
		payload["duration_sec"] = duration_sec
	else:
		payload["duration_sec"] = null
		
	_send_request("/tree/", HTTPClient.METHOD_POST, payload, func(code, _body):
		if code == 201 or code == 200:
			fetch_user_tree()
)
