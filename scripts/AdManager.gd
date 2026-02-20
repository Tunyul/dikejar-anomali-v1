extends Node

signal reward_granted(reason: String)

# Test IDs (Replace with Real IDs in Production or Project Settings)
const TEST_BANNER_ID = "ca-app-pub-3940256099942544/6300978111"
const TEST_INTERSTITIAL_ID = "ca-app-pub-3940256099942544/1033173712"
const TEST_REWARDED_ID = "ca-app-pub-3940256099942544/5224354917"

var _banner_id: String = TEST_BANNER_ID
var _interstitial_id: String = TEST_INTERSTITIAL_ID
var _rewarded_id: String = TEST_REWARDED_ID

var _ad_view: AdView
var _interstitial_ad: InterstitialAd
var _rewarded_ad: RewardedAd
var _pending_reward_reason: String = ""
var _is_initialized: bool = false
var _dummy_banner: CanvasLayer = null

func _ready() -> void:
    _load_ad_config()
    if not _is_initialized:
        var on_init_listener := OnInitializationCompleteListener.new()
        on_init_listener.on_initialization_complete = _on_initialization_complete
        MobileAds.initialize(on_init_listener)

func _load_ad_config() -> void:
    _banner_id = ProjectSettings.get_setting("admob/config/banner_id", TEST_BANNER_ID)
    _interstitial_id = ProjectSettings.get_setting("admob/config/interstitial_id", TEST_INTERSTITIAL_ID)
    _rewarded_id = ProjectSettings.get_setting("admob/config/rewarded_id", TEST_REWARDED_ID)

    # Clean up empty strings if user cleared them
    if _banner_id.is_empty(): _banner_id = TEST_BANNER_ID
    if _interstitial_id.is_empty(): _interstitial_id = TEST_INTERSTITIAL_ID
    if _rewarded_id.is_empty(): _rewarded_id = TEST_REWARDED_ID

func _on_initialization_complete(_status: InitializationStatus) -> void:
    print("AdMob Initialized")
    _is_initialized = true
    load_banner()
    load_interstitial()
    load_rewarded()

#region Banner
func load_banner() -> void:
    if OS.get_name() != "Android" and OS.get_name() != "iOS":
        return

    if _ad_view:
        _ad_view.destroy()

    var ad_size := AdSize.BANNER # Use standard AdMob Banner constant
    _ad_view = AdView.new(_banner_id, ad_size, AdPosition.Values.BOTTOM)
    _ad_view.load_ad(AdRequest.new())

func show_banner() -> void:
    if OS.get_name() != "Android" and OS.get_name() != "iOS":
        _show_dummy_banner()
        return

    if _ad_view:
        _ad_view.show()
    elif _is_initialized:
        load_banner()

func hide_banner() -> void:
    if OS.get_name() != "Android" and OS.get_name() != "iOS":
        if _dummy_banner: _dummy_banner.hide()
        return

    if _ad_view:
        _ad_view.hide()

func _show_dummy_banner() -> void:
    if _dummy_banner == null:
        _dummy_banner = CanvasLayer.new()
        _dummy_banner.layer = 100
        add_child(_dummy_banner)

        var rect = ColorRect.new()
        rect.color = Color(0, 0, 0, 0.0) # Transparent background
        rect.custom_minimum_size = Vector2(0, 50)
        rect.mouse_filter = Control.MOUSE_FILTER_IGNORE # Don't block clicks
        rect.size_flags_horizontal = Control.SIZE_EXPAND_FILL
        rect.size_flags_vertical = Control.SIZE_EXPAND_FILL

        var label = Label.new()
        label.text = "BANNER AD AREA (TEST MODE)"
        label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
        label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
        label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
        rect.add_child(label)

        # Position at bottom
        var screen_size = DisplayServer.window_get_size()
        rect.size = Vector2(screen_size.x, 50)
        rect.position = Vector2(0, screen_size.y - 50)

        _dummy_banner.add_child(rect)

    _dummy_banner.show()
#endregion

#region Interstitial
func load_interstitial() -> void:
    var callback := InterstitialAdLoadCallback.new()
    callback.on_ad_loaded = func(ad: InterstitialAd) -> void:
        _interstitial_ad = ad
        _interstitial_ad.full_screen_content_callback = _create_content_callback("interstitial")
        print("Interstitial Loaded")

    callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
        print("Interstitial Failed: " + error.message)
        # Retry after delay? For now just log

    InterstitialAdLoader.new().load(_interstitial_id, AdRequest.new(), callback)

func show_interstitial() -> void:
    if _interstitial_ad:
        _interstitial_ad.show()
    else:
        print("Interstitial Not Ready")
        load_interstitial()

func is_interstitial_available() -> bool:
    return _interstitial_ad != null
#endregion

#region Rewarded
func load_rewarded() -> void:
    var callback := RewardedAdLoadCallback.new()
    callback.on_ad_loaded = func(ad: RewardedAd) -> void:
        _rewarded_ad = ad
        _rewarded_ad.full_screen_content_callback = _create_content_callback("rewarded")
        print("Rewarded Loaded")

    callback.on_ad_failed_to_load = func(error: LoadAdError) -> void:
        print("Rewarded Failed: " + error.message)

    RewardedAdLoader.new().load(_rewarded_id, AdRequest.new(), callback)

func show_rewarded(reason: String) -> void:
    _pending_reward_reason = reason
    if _rewarded_ad:
        var listener := OnUserEarnedRewardListener.new()
        listener.on_user_earned_reward = func(item: RewardedItem) -> void:
            print("Reward Earned: " + item.type)
            reward_granted.emit(_pending_reward_reason)

        _rewarded_ad.show(listener)
    else:
        print("Rewarded Not Ready")
        load_rewarded()

func is_rewarded_available() -> bool:
    return _rewarded_ad != null
#endregion

func _create_content_callback(type: String) -> FullScreenContentCallback:
    var callback := FullScreenContentCallback.new()
    callback.on_ad_dismissed_full_screen_content = func() -> void:
        print(type + " dismissed")
        if type == "interstitial":
            _interstitial_ad = null
            load_interstitial()
        elif type == "rewarded":
            _rewarded_ad = null
            load_rewarded()

    callback.on_ad_failed_to_show_full_screen_content = func(_err: AdError) -> void:
        print(type + " failed to show")
        if type == "interstitial":
            _interstitial_ad = null
            load_interstitial()
        elif type == "rewarded":
            _rewarded_ad = null
            load_rewarded()

    return callback
