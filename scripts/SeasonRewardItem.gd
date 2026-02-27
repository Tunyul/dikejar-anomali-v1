extends PanelContainer

@onready var _level_label: Label = %LevelLabel
@onready var _reward_label: Label = %RewardLabel
@onready var _status_label: Label = %StatusLabel
@onready var _claim_button: Button = %ClaimButton
@onready var _icon_rect: TextureRect = %IconRect

const COIN_ICON = preload("res://assets/coin_animation/png/2x/Coin.png")
const GEM_ICON = preload("res://assets/diamond_animation/diamond-sprite-256px-36.png")

var _level: int = 0
var _reward_data: Dictionary = {}

signal claim_requested(level)

func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_PASS
    if _claim_button and not _claim_button.pressed.is_connected(_on_claim_button_pressed):
        _claim_button.pressed.connect(_on_claim_button_pressed)

func setup(lvl: int, data: Dictionary, is_unlocked: bool, is_claimed: bool) -> void:
    _level = lvl
    _reward_data = data

    if _level_label:
        _level_label.text = str(_level)

    if _reward_label:
        var type = data.get("type", "coins")
        var amount = data.get("amount", 0)
        _reward_label.text = "+%d %s" % [amount, tr(type.to_upper())]

        if _icon_rect:
            if type == "gems":
                _icon_rect.texture = GEM_ICON
                # Since it's an atlas, we might want to just show the first frame or use an AtlasTexture
                if _icon_rect.texture is Texture2D and not _icon_rect.texture is AtlasTexture:
                    var atlas = AtlasTexture.new()
                    atlas.atlas = GEM_ICON
                    atlas.region = Rect2(0, 0, 263, 223)
                    _icon_rect.texture = atlas
            else:
                _icon_rect.texture = COIN_ICON

    if is_claimed:
        _status_label.text = tr("CLAIMED")
        _status_label.modulate = Color.GREEN
        _claim_button.visible = false
        modulate.a = 0.6
    elif is_unlocked:
        _status_label.text = tr("READY")
        _status_label.modulate = Color.YELLOW
        _claim_button.visible = true
        _claim_button.disabled = false
        _claim_button.text = tr("CLAIM")
        modulate.a = 1.0
    else:
        _status_label.text = tr("LOCKED")
        _status_label.modulate = Color.GRAY
        _claim_button.visible = true
        _claim_button.disabled = true
        _claim_button.text = tr("CLAIM")
        modulate.a = 0.8

func _on_claim_button_pressed() -> void:
    TransitionManager.play_sfx(&"click")
    claim_requested.emit(_level)
