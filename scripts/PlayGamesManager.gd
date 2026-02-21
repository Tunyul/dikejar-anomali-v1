extends Node

# Signal
signal login_success(player_data) # Dictionary: {id, display_name, avatar_url}
signal login_failed(error_code)
signal achievement_unlocked(achievement_id)

var play_games = null
var is_authenticated = false

func _ready():
	if Engine.has_singleton("GodotPlayGamesServices"):
		play_games = Engine.get_singleton("GodotPlayGamesServices")

		# Setup callback
		play_games.connect("sign_in_success", _on_sign_in_success)
		play_games.connect("sign_in_failed", _on_sign_in_failed)

		# Auto-login saat start
		# Note: Google menyarankan silent sign-in dulu
		sign_in(true)
	else:
		print("PlayGamesManager: Plugin not found!")

func sign_in(silent: bool = false):
	if play_games:
		if silent:
			# Login tanpa UI pop-up (jika user pernah login sebelumnya)
			# Implementasi tergantung plugin, biasanya otomatis handle di init
			play_games.signIn()
		else:
			# Login dengan UI pop-up (jika silent gagal atau tombol login ditekan)
			play_games.signIn()

func _on_sign_in_success(account_id: String):
	print("PlayGamesManager: Login Success! ID: ", account_id)
	is_authenticated = true

	# Ambil detail player
	# (Tergantung plugin, kadang perlu panggil fungsi getPlayer())
	var player_info = {
		"id": account_id,
		"display_name": "Player" # Placeholder, update jika plugin support getDisplayName
	}
	emit_signal("login_success", player_info)

func _on_sign_in_failed(error_code: int):
	print("PlayGamesManager: Login Failed. Code: ", error_code)
	is_authenticated = false
	emit_signal("login_failed", error_code)

func unlock_achievement(achievement_id: String):
	if play_games and is_authenticated:
		play_games.unlockAchievement(achievement_id)
		# emit_signal("achievement_unlocked", achievement_id) # Opsional

func show_achievements():
	if play_games and is_authenticated:
		play_games.showAchievements()

func show_leaderboard(leaderboard_id: String):
	if play_games and is_authenticated:
		play_games.showLeaderboard(leaderboard_id)
