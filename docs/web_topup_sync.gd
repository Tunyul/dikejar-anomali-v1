extends Node

signal sync_completed(success: bool, coins: int, gems: int)

const API_BASE_URL: String = "https://api.anomalyrush.com/v1"
var http_request: HTTPRequest
var auth_token: String = ""

func _ready() -> void:
	http_request = HTTPRequest.new()
	add_child(http_request)
	http_request.request_completed.connect(_on_request_completed)

func set_token(token: String) -> void:
	auth_token = token

func sync_balance() -> void:
	if auth_token.is_empty():
		sync_completed.emit(false, 0, 0)
		return

	var url: String = API_BASE_URL + "/wallet/balance"
	var headers: PackedStringArray = ["Authorization: Bearer " + auth_token]
	var err: int = http_request.request(url, headers, HTTPClient.METHOD_GET)

	if err != OK:
		sync_completed.emit(false, 0, 0)

func _on_request_completed(result: int, response_code: int, _headers: PackedStringArray, body: PackedByteArray) -> void:
	if result == HTTPRequest.RESULT_SUCCESS and response_code == 200:
		var json: JSON = JSON.new()
		var parse_err: int = json.parse(body.get_string_from_utf8())
		if parse_err == OK:
			var data = json.get_data()
			if typeof(data) == TYPE_DICTIONARY and data.has("coins") and data.has("gems"):
				var coins: int = data.get("coins", 0)
				var gems: int = data.get("gems", 0)
				_apply_grants(coins, gems)
				sync_completed.emit(true, coins, gems)
				return

	sync_completed.emit(false, 0, 0)

func _apply_grants(coins: int, gems: int) -> void:
	if Engine.has_singleton("GameManager"):
		Engine.get_singleton("GameManager").set("server_coins", coins)
		Engine.get_singleton("GameManager").set("server_gems", gems)