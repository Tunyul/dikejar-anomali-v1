extends Node

# AdMob Plugin
# https://github.com/Poing-Studios/godot-admob-android
# https://github.com/Poing-Studios/godot-admob-ios

signal banner_loaded
signal banner_failed_to_load(error_code: int)
signal interstitial_loaded
signal interstitial_failed_to_load(error_code: int)
signal interstitial_closed
signal reward_granted(reason: String)
signal rewarded_ad_loaded
signal rewarded_ad_failed_to_load(error_code: int)
signal rewarded_ad_closed

var _ad_view : AdView
var _interstitial_ad : InterstitialAd
var _rewarded_ad : RewardedAd
var _pending_reward_reason: String = ""
var _banner_locks: Dictionary = {}

# Ad Unit IDs (Test IDs)
# Ganti dengan ID asli saat rilis
const BANNER_ID_ANDROID = "ca-app-pub-3940256099942544/6300978111"
const INTERSTITIAL_ID_ANDROID = "ca-app-pub-3940256099942544/1033173712"
const REWARDED_ID_ANDROID = "ca-app-pub-3940256099942544/5224354917"

const BANNER_ID_IOS = "ca-app-pub-3940256099942544/2934735716"
const INTERSTITIAL_ID_IOS = "ca-app-pub-3940256099942544/4411468910"
const REWARDED_ID_IOS = "ca-app-pub-3940256099942544/1712485313"

func _ready() -> void:
    if OS.get_name() == "Android" or OS.get_name() == "iOS":
        MobileAds.initialize()
        load_banner()
        load_interstitial()
        load_rewarded()
    else:
        print("AdManager: Running on non-mobile platform (Dummy Mode)")

func load_banner() -> void:
    if _ad_view:
        _ad_view.destroy()
        _ad_view = null

    var unit_id = BANNER_ID_ANDROID if OS.get_name() == "Android" else BANNER_ID_IOS
    var ad_size = AdSize.BANNER
    _ad_view = AdView.new(unit_id, ad_size, AdPosition.Values.BOTTOM)

    _ad_view.ad_listener.on_ad_loaded = func() -> void:
        print("Banner loaded")
        banner_loaded.emit()
        if not _is_banner_locked():
            _ad_view.show() # Show immediately when loaded

    _ad_view.ad_listener.on_ad_failed_to_load = func(load_ad_error : LoadAdError) -> void:
        print("Banner failed to load: " + load_ad_error.message)
        banner_failed_to_load.emit(load_ad_error.code)

    _ad_view.load_ad(AdRequest.new())

func show_banner() -> void:
    if _is_banner_locked():
        return
    if _ad_view:
        _ad_view.show()

func hide_banner() -> void:
    if _ad_view:
        _ad_view.hide()

func move_banner(to_top: bool) -> void:
    if _ad_view:
        # Hancurkan banner lama
        _ad_view.destroy()
        _ad_view = null

    var unit_id = BANNER_ID_ANDROID if OS.get_name() == "Android" else BANNER_ID_IOS
    var ad_size = AdSize.BANNER
    # Tentukan posisi baru
    var position = AdPosition.Values.TOP if to_top else AdPosition.Values.BOTTOM

    _ad_view = AdView.new(unit_id, ad_size, position)

    _ad_view.ad_listener.on_ad_loaded = func() -> void:
        print("Banner reloaded at ", "TOP" if to_top else "BOTTOM")
        banner_loaded.emit()
        if not _is_banner_locked():
            _ad_view.show()

    _ad_view.ad_listener.on_ad_failed_to_load = func(load_ad_error : LoadAdError) -> void:
        print("Banner failed to reload: " + load_ad_error.message)
        banner_failed_to_load.emit(load_ad_error.code)

    _ad_view.load_ad(AdRequest.new())

func load_interstitial() -> void:
    var unit_id = INTERSTITIAL_ID_ANDROID if OS.get_name() == "Android" else INTERSTITIAL_ID_IOS
    var ad_request := AdRequest.new()
    var callback := InterstitialAdLoadCallback.new()

    callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
        print("Interstitial loaded")
        _interstitial_ad = ad
        interstitial_loaded.emit()

        var full_screen_callback := FullScreenContentCallback.new()
        full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
            print("Interstitial dismissed")
            interstitial_closed.emit()
            load_interstitial() # Preload next

        _interstitial_ad.full_screen_content_callback = full_screen_callback

    callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
        print("Interstitial failed to load: ", error.message)
        interstitial_failed_to_load.emit(error.code)

    InterstitialAdLoader.new().load(unit_id, ad_request, callback)

func show_interstitial() -> void:
    if _interstitial_ad:
        _interstitial_ad.show()
    else:
        print("Interstitial not ready")
        load_interstitial() # Try loading again

func load_rewarded() -> void:
    var unit_id = REWARDED_ID_ANDROID if OS.get_name() == "Android" else REWARDED_ID_IOS
    var ad_request := AdRequest.new()
    var callback := RewardedAdLoadCallback.new()

    callback.on_ad_loaded = func(ad: RewardedAd) -> void:
        print("Rewarded Ad loaded")
        _rewarded_ad = ad
        rewarded_ad_loaded.emit()

        var full_screen_callback := FullScreenContentCallback.new()
        full_screen_callback.on_ad_dismissed_full_screen_content = func() -> void:
            print("Rewarded Ad dismissed")
            rewarded_ad_closed.emit()
            load_rewarded() # Preload next

        full_screen_callback.on_ad_failed_to_show_full_screen_content = func(error: AdError) -> void:
            print("Rewarded Ad failed to show: ", error.message)
            load_rewarded()

        _rewarded_ad.full_screen_content_callback = full_screen_callback

    callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
        print("Rewarded Ad failed to load: ", error.message)
        rewarded_ad_failed_to_load.emit(error.code)

    RewardedAdLoader.new().load(unit_id, ad_request, callback)

func show_rewarded(reason: String) -> void:
    _pending_reward_reason = reason

    if OS.get_name() != "Android" and OS.get_name() != "iOS":
        # Dummy implementation for PC/Editor
        print("[Dummy] Show Rewarded Ad: ", reason)
        var timer := get_tree().create_timer(1.0)
        await timer.timeout
        print("[Dummy] Reward Granted")
        reward_granted.emit(reason)
        return

    if _rewarded_ad:
        var listener := OnUserEarnedRewardListener.new()
        var current_reason = _pending_reward_reason
        listener.on_user_earned_reward = func(item: RewardedItem) -> void:
            print("Reward Earned: " + item.type)
            print("AdManager: Emitting reward_granted for reason: ", current_reason)
            # Call deferred to ensure signal is emitted safely
            call_deferred("emit_reward_granted", current_reason)

        _rewarded_ad.show(listener)
    else:
        print("Rewarded ad not ready")

func emit_reward_granted(reason: String) -> void:
    reward_granted.emit(reason)

func is_rewarded_available() -> bool:
    if OS.get_name() != "Android" and OS.get_name() != "iOS":
        return true
    return _rewarded_ad != null


func _is_banner_locked() -> bool:
    return _banner_locks.size() > 0


func acquire_banner_lock(lock_id: String) -> void:
    var id := lock_id.strip_edges()
    if id.is_empty():
        return
    _banner_locks[id] = true
    hide_banner()


func release_banner_lock(lock_id: String) -> void:
    var id := lock_id.strip_edges()
    if id.is_empty():
        return
    var had_lock := false
    if _banner_locks.has(id):
        _banner_locks.erase(id)
        had_lock = true
    if had_lock and not _is_banner_locked():
        show_banner()
