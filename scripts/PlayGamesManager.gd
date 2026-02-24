extends Node

# Signal
signal login_success(player_data) # Dictionary: {id, display_name, avatar_url}
signal login_failed(error_code)
# signal achievement_unlocked(achievement_id)

var sign_in_client: PlayGamesSignInClient
var achievements_client: PlayGamesAchievementsClient
var leaderboards_client: PlayGamesLeaderboardsClient
var players_client: PlayGamesPlayersClient

var is_authenticated = false

func _ready():
    # Initialize the plugin first
    # Note: Autoload 'GodotPlayGameServices' is available globally
    var init_status = GodotPlayGameServices.initialize()
    if init_status != GodotPlayGameServices.PlayGamesPluginError.OK:
        print("PlayGamesManager: Failed to initialize GodotPlayGameServices or plugin not found.")
        return

    # Initialize Clients
    sign_in_client = PlayGamesSignInClient.new()
    add_child(sign_in_client)

    achievements_client = PlayGamesAchievementsClient.new()
    add_child(achievements_client)

    leaderboards_client = PlayGamesLeaderboardsClient.new()
    add_child(leaderboards_client)

    players_client = PlayGamesPlayersClient.new()
    add_child(players_client)

    # Connect Signals
    sign_in_client.user_authenticated.connect(_on_user_authenticated)
    players_client.current_player_loaded.connect(_on_current_player_loaded)

    # Auto-login check (Silent sign-in is handled by plugin at startup usually)
    # But we can explicitly check authentication
    check_authentication()

func check_authentication():
    if sign_in_client:
        sign_in_client.is_authenticated()

func sign_in(silent: bool = false):
    if sign_in_client:
        if silent:
            # The new plugin's sign_in() triggers the interactive flow.
            # Silent sign-in is usually automatic or via is_authenticated() check.
            sign_in_client.is_authenticated()
        else:
            sign_in_client.sign_in()

func _on_user_authenticated(is_auth: bool):
    if is_auth:
        print("PlayGamesManager: User Authenticated!")
        is_authenticated = true
        if players_client:
            players_client.load_current_player(true)
    else:
        print("PlayGamesManager: User NOT Authenticated.")
        is_authenticated = false
        emit_signal("login_failed", -1)

func _on_current_player_loaded(player: PlayGamesPlayer):
    if player:
        var player_data = {
            "id": player.player_id,
            "display_name": player.display_name,
            "hi_res_image_url": player.hi_res_image_url,
            "icon_image_url": player.icon_image_url
        }
        print("PlayGamesManager: Player data loaded: ", player_data.display_name)
        emit_signal("login_success", player_data)
    else:
        emit_signal("login_success", {"id": "unknown", "display_name": "Player"})

func unlock_achievement(achievement_id: String):
    if achievements_client and is_authenticated:
        achievements_client.unlock_achievement(achievement_id)
        # emit_signal("achievement_unlocked", achievement_id) # Optional

func show_achievements():
    if achievements_client and is_authenticated:
        achievements_client.show_achievements()

func show_leaderboard(leaderboard_id: String):
    if leaderboards_client and is_authenticated:
        leaderboards_client.show_leaderboard(leaderboard_id)

func submit_score(leaderboard_id: String, score: int):
    if leaderboards_client and is_authenticated:
        leaderboards_client.submit_score(leaderboard_id, score)
