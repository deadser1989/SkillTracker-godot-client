extends Control

@onready var auth_request = $AuthRequest

@onready var title_label = $VBoxContainer/TitleLabel
@onready var nick_input = $VBoxContainer/NickInput
@onready var email_input = $VBoxContainer/EmailInput
@onready var pwd_input = $VBoxContainer/PasswordInput
@onready var login_btn = $VBoxContainer/LoginBtn
@onready var switch_mode_btn = $VBoxContainer/SwitchModeBtn 

var is_register_mode = true

func _ready():
	login_btn.pressed.connect(_on_login_pressed)
	switch_mode_btn.pressed.connect(_on_switch_mode)
	auth_request.request_completed.connect(_on_login_completed)

func _on_switch_mode():
	is_register_mode = !is_register_mode
	if is_register_mode:
		if title_label: title_label.text = "РЕГИСТРАЦИЯ"
		email_input.show()
		login_btn.text = "Зарегистрироваться"
		switch_mode_btn.text = "Уже есть аккаунт? Войти"
	else:
		if title_label: title_label.text = "ВХОД"
		email_input.hide()
		login_btn.text = "Войти в игру"
		switch_mode_btn.text = "Нет аккаунта? Создать"

func _on_login_pressed():
	var nick = nick_input.text.strip_edges()
	var email = email_input.text.strip_edges()
	var pwd = pwd_input.text.strip_edges()


	if nick == "1" and pwd == "1":		#для тестов пароль 1 ник 1
		Profile.set_player_name("Dev_Tester")
		get_tree().change_scene_to_file("res://shell.tscn")
		return

	if is_register_mode:
		if nick != "" and email != "" and pwd != "":
			_send_auth("http://127.0.0.1:8000/register/", {"username": nick, "email": email, "password": pwd})
		else: _shake_error()
	else:
		if nick != "" and pwd != "":
			_send_auth("http://127.0.0.1:8000/login/", {"username": nick, "password": pwd})
		else: _shake_error()

func _send_auth(url, data):
	login_btn.text = "Подключение..."
	login_btn.disabled = true
	var body = JSON.stringify(data)
	var headers = ["Content-Type: application/json"]
	auth_request.request(url, headers, HTTPClient.METHOD_POST, body)

func _shake_error():
	var tw = create_tween()
	tw.tween_property(login_btn, "position:x", login_btn.position.x + 10, 0.05)
	tw.tween_property(login_btn, "position:x", login_btn.position.x - 10, 0.05)
	tw.tween_property(login_btn, "position:x", login_btn.position.x, 0.05)
	
	if nick_input.text == " ": nick_input.placeholder_text = "ЗАПОЛНИТЕ ВСЕ ПОЛЯ!"
	if pwd_input.text == " ": pwd_input.placeholder_text = "ПАРОЛЬ ОБЯЗАТЕЛЕН!"

func _on_login_completed(_result, response_code, _headers, body):
	login_btn.disabled = false
	if is_register_mode: login_btn.text = "Зарегистрироваться"
	else: login_btn.text = "Войти в игру"
	
	if response_code == 200 or response_code == 201:
		var data = JSON.parse_string(body.get_string_from_utf8())
		if data and typeof(data) == TYPE_DICTIONARY and data.has("token"):
			Profile.set_meta("auth_token", data["token"])
			
		Profile.set_player_name(nick_input.text)
		get_tree().change_scene_to_file("res://shell.tscn")
	else:
		pwd_input.text = ""
		pwd_input.placeholder_text = "ОШИБКА СЕРВЕРА!"
