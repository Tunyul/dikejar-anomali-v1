extends CanvasLayer

signal language_changed(locale: String)
signal bgm_track_changed(track_name: String)
signal bgm_index_changed(index: int)

var _overlay: ColorRect
var _tween_active: bool = false
var _cloud_layer: Control
var _rng := RandomNumberGenerator.new()
var _sfx_player: AudioStreamPlayer = null
var _sfx_poly: AudioStreamPolyphonic = null
var _sfx_playback: AudioStreamPlaybackPolyphonic = null
var _sfx_streams: Dictionary = {}
var _sfx_rng := RandomNumberGenerator.new()
var _sfx_volume: float = 0.8
var _sfx_muted: bool = false
var _sfx_base_db: float = 0.0
var _sfx_pool: Array[AudioStreamPlayer] = []
var _sfx_pool_cursor: int = 0
var _bgm_player: AudioStreamPlayer = null
var _bgm_volume: float = 0.8
var _bgm_muted: bool = false
var _bgm_paths: Array[String] = []
var _bgm_index: int = -1
@export var transition_duration: float = 1.2
@export var cloud_count: int = 18
@export var row_height_px: float = 96.0
@export var col_width_px: float = 160.0
@export var min_rows: int = 6
@export var min_cols: int = 8
@export var scale_min: float = 0.8
@export var scale_max: float = 1.4
@export var margin_min: float = 100.0
@export var margin_max: float = 400.0
@export var delay_factor: float = 0.35
@export var direction_mode: int = 0
@export var preview_in_editor: bool = false: set = _set_preview_enabled
@export var preview_use_sprite: bool = true
@export var live_update_in_editor: bool = false
@export var transition_mode: int = 1
var _last_preview_sig: String = ""
var _cloud_textures: Array[Texture2D] = []

const _I18N_TRANSLATIONS: Array[String] = [
    "res://i18n/translations.id.translation",
    "res://i18n/translations.en.translation",
    "res://i18n/translations.zh.translation",
]
const _I18N_FALLBACK: Dictionary = {
    "en": {
        "Backsound": "Backsound",
        "Settings": "Settings",
        "Language": "Language",
        "Bahasa Indonesia": "Indonesian",
        "English": "English",
        "中文": "Chinese",
        "BGM Volume": "BGM Volume",
        "SFX Volume": "SFX Volume",
        "Mute BGM": "Mute BGM",
        "Mute SFX": "Mute SFX",
        "Loading": "Loading",
        "Checking content": "Checking content",
        "Downloading assets": "Downloading assets",
        "Mounting assets": "Mounting assets",
        "Manifest download failed": "Manifest download failed",
        "Manifest invalid": "Manifest invalid",
        "Content download failed": "Content download failed",
        "Content mount failed": "Content mount failed",
        "Shop": "Shop",
        "Owned": "Owned",
        "Coming Soon": "Coming Soon",
        "Buy": "Buy",
        "Coins": "Coins",
        "Gems": "Gems",
        "Money": "Money",
        "Already owned.": "Already owned.",
        "Not enough coins.": "Not enough coins.",
        "Not enough gems.": "Not enough gems.",
        "Not supported.": "Not supported.",
        "Purchase processed.": "Purchase processed.",
        "Purchase successful: %s": "Purchase successful: %s",
        "Buy %s\nfor %d %s?": "Buy %s\nfor %d %s?",
        "[Error] Groups container (HBox) not found": "[Error] Groups container (HBox) not found",
        "Skills & Power-ups (Coins)": "Skills & Power-ups (Coins)",
        "Upgrades (Coins)": "Upgrades (Coins)",
        "Upgrades (Gems)": "Upgrades (Gems)",
        "Cosmetics (Coins)": "Cosmetics (Coins)",
        "Cosmetics (Gems)": "Cosmetics (Gems)",
        "Gem Packs (Real)": "Gem Packs (Real)",
        "Bundles (Real)": "Bundles (Real)",
        "Magnet 30s": "Magnet 30s",
        "Perisai 1 Hit": "Shield 1 Hit",
        "Double Coins (1 Run)": "Double Coins (1 Run)",
        "Speed Boost (1 Run)": "Speed Boost (1 Run)",
        "Upgrade Nyawa Maks +1": "Max Life Upgrade +1",
        "Upgrade Durasi Magnet +10%": "Magnet Duration Upgrade +10%",
        "Upgrade Durasi Shield +10%": "Shield Duration Upgrade +10%",
        "Upgrade Durasi Double Coins +10%": "Double Coins Duration Upgrade +10%",
        "Upgrade Multiplier Double Coins +0.25x": "Double Coins Multiplier Upgrade +0.25x",
        "Upgrade Durasi Speed Boost +10%": "Speed Boost Duration Upgrade +10%",
        "Skin Basic": "Basic Skin",
        "Skin Premium": "Premium Skin",
        "Skin Neon": "Neon Skin",
        "Skin Shadow": "Shadow Skin",
        "Small Gem Pack (100)": "Small Gem Pack (100)",
        "Standard Gem Pack (300 +30)": "Standard Gem Pack (300 +30)",
        "Big Gem Pack (800 +150)": "Big Gem Pack (800 +150)",
        "Mega Gem Pack (2000 +500)": "Mega Gem Pack (2000 +500)",
        "Starter Pack": "Starter Pack",
        "Progress Pack": "Progress Pack",
        "Cosmetic Starter": "Cosmetic Starter",
        "Menarik koin otomatis selama 30 detik.": "Automatically attracts coins for 30 seconds.",
        "Melindungi dari satu kali tabrakan.": "Protects you from one collision.",
        "Mendapatkan koin 2x lipat selama satu sesi lari.": "Earn 2x coins for one run.",
        "Meningkatkan kecepatan lari dasar sebesar 50%.": "Increases base running speed by 50%.",
        "Meningkatkan kapasitas nyawa maksimal secara permanen.": "Permanently increases maximum life capacity.",
        "Menambah durasi efek magnet secara permanen.": "Permanently increases magnet effect duration.",
        "Menambah durasi perlindungan perisai secara permanen.": "Permanently increases shield protection duration.",
        "Menambah durasi efek double coins secara permanen.": "Permanently increases double coins effect duration.",
        "Menambah multiplier gain koin saat double coins aktif.": "Increases coin gain multiplier while double coins is active.",
        "Menambah durasi efek speed boost secara permanen.": "Permanently increases speed boost effect duration.",
        "Skin standar untuk petualang pemula.": "Standard skin for new adventurers.",
        "Skin dengan detail emas yang elegan.": "Elegant skin with golden details.",
        "Skin futuristik yang menyala dalam gelap.": "Futuristic skin that glows in the dark.",
        "Skin misterius yang terbuat dari bayangan.": "Mysterious skin made of shadows.",
        "Paket kecil gems untuk kebutuhan mendesak.": "Small gem pack for urgent needs.",
        "Paket standar dengan bonus gems 10%.": "Standard pack with a 10% gem bonus.",
        "Paket besar dengan bonus gems melimpah.": "Big pack with lots of bonus gems.",
        "Pilihan terbaik untuk kolektor sejati.": "Best choice for true collectors.",
        "Koin, Gems, dan Power-ups untuk memulai.": "Coins, Gems, and Power-ups to get started.",
        "Boost kemajuanmu dengan koin dan power-ups.": "Boost your progress with coins and power-ups.",
        "Paket hemat koin dan gems untuk beli skin.": "Value pack of coins and gems for buying skins.",
        "Kembali ke menu utama?\nRun ini akan diakhiri.": "Return to main menu?\nThis run will end.",
        "Lanjut dengan bonus?\nTonton iklan untuk lanjut run ini.": "Continue with bonus?\nWatch ad to continue this run.",
        "MISSIONS": "MISSIONS",
        "DAILY": "DAILY",
        "MISSION": "MISSION",
        "WEEKLY": "WEEKLY",
        "MONTHLY": "MONTHLY",
        "CHALLENGE": "CHALLENGE",
        "BACK": "BACK",
        "Kalahkan {n} musuh": "Defeat {n} enemies",
        "Capai jarak {n}m": "Reach {n}m distance",
        "Kumpulkan {n} koin": "Collect {n} coins",
        "Dapatkan {n} skill": "Get {n} skills",
        "Lompat {n} kali": "Jump {n} times",
        "Mainkan {n} run": "Play {n} runs",
        "Dapatkan Shield {n} kali": "Get Shield {n} times",
        "Dapatkan DoubleCoins {n} kali": "Get DoubleCoins {n} times",
        "Reward Ready!": "Reward Ready!",
        "Done: %s": "Done: %s",
        "Collect {n} coins": "Collect {n} coins",
        "Defeat {n} enemies": "Defeat {n} enemies",
        "Jump {n} times": "Jump {n} times",
        "Get {n} skills": "Get {n} skills",
        "Reach {n}m distance": "Reach {n}m distance",
        "Reset misi harian?\nTonton iklan untuk reset.": "Reset daily missions?\nWatch ad to reset.",
        "SEASON_REWARDS_TITLE": "SEASON REWARDS",
        "CLAIM_ALL": "CLAIM ALL",
        "TIME_REMAINING_HINT": "SEASON ENDS SOON"
    },
    "id": {
        "Backsound": "Musik",
        "Settings": "Pengaturan",
        "Language": "Bahasa",
        "Bahasa Indonesia": "Bahasa Indonesia",
        "English": "English",
        "中文": "中文",
        "BGM Volume": "Volume BGM",
        "SFX Volume": "Volume SFX",
        "Mute BGM": "Bisukan BGM",
        "Mute SFX": "Bisukan SFX",
        "Loading": "Memuat",
        "Checking content": "Memeriksa konten",
        "Downloading assets": "Mengunduh aset",
        "Mounting assets": "Memasang aset",
        "Manifest download failed": "Unduhan manifest gagal",
        "Manifest invalid": "Manifest tidak valid",
        "Content download failed": "Unduhan konten gagal",
        "Content mount failed": "Gagal memasang konten",
        "Shop": "Toko",
        "Owned": "Dimiliki",
        "Coming Soon": "Segera Hadir",
        "Buy": "Beli",
        "Coins": "Koin",
        "Gems": "Permata",
        "Money": "Uang",
        "Already owned.": "Sudah dimiliki.",
        "Not enough coins.": "Koin tidak cukup.",
        "Not enough gems.": "Permata tidak cukup.",
        "Not supported.": "Tidak didukung.",
        "Purchase processed.": "Pembelian diproses.",
        "Purchase successful: %s": "Pembelian berhasil: %s",
        "Buy %s\nfor %d %s?": "Beli %s\nseharga %d %s?",
        "[Error] Groups container (HBox) not found": "[Error] Wadah grup (HBox) tidak ditemukan",
        "Skills & Power-ups (Coins)": "Skill & Power-up (Koin)",
        "Upgrades (Coins)": "Upgrade (Koin)",
        "Upgrades (Gems)": "Upgrade (Permata)",
        "Cosmetics (Coins)": "Kosmetik (Koin)",
        "Cosmetics (Gems)": "Kosmetik (Permata)",
        "Gem Packs (Real)": "Paket Permata (Uang)",
        "Bundles (Real)": "Bundel (Uang)",
        "Magnet 30s": "Magnet 30 Detik",
        "Perisai 1 Hit": "Perisai 1 Hit",
        "Double Coins (1 Run)": "Koin 2x (1 Lari)",
        "Speed Boost (1 Run)": "Speed Boost (1 Lari)",
        "Upgrade Nyawa Maks +1": "Upgrade Nyawa Maks +1",
        "Upgrade Durasi Magnet +10%": "Upgrade Durasi Magnet +10%",
        "Upgrade Durasi Shield +10%": "Upgrade Durasi Shield +10%",
        "Upgrade Durasi Double Coins +10%": "Upgrade Durasi Double Coins +10%",
        "Upgrade Multiplier Double Coins +0.25x": "Upgrade Multiplier Double Coins +0.25x",
        "Upgrade Durasi Speed Boost +10%": "Upgrade Durasi Speed Boost +10%",
        "Skin Basic": "Skin Dasar",
        "Skin Premium": "Skin Premium",
        "Skin Neon": "Skin Neon",
        "Skin Shadow": "Skin Bayangan",
        "Small Gem Pack (100)": "Paket Permata Kecil (100)",
        "Standard Gem Pack (300 +30)": "Paket Permata Standar (300 +30)",
        "Big Gem Pack (800 +150)": "Paket Permata Besar (800 +150)",
        "Mega Gem Pack (2000 +500)": "Paket Permata Mega (2000 +500)",
        "Starter Pack": "Paket Pemula",
        "Progress Pack": "Paket Progres",
        "Cosmetic Starter": "Kosmetik Pemula",
        "Menarik koin otomatis selama 30 detik.": "Menarik koin otomatis selama 30 detik.",
        "Melindungi dari satu kali tabrakan.": "Melindungi dari satu kali tabrakan.",
        "Mendapatkan koin 2x lipat selama satu sesi lari.": "Mendapatkan koin 2x lipat selama satu sesi lari.",
        "Meningkatkan kecepatan lari dasar sebesar 50%.": "Meningkatkan kecepatan lari dasar sebesar 50%.",
        "Meningkatkan kapasitas nyawa maksimal secara permanen.": "Meningkatkan kapasitas nyawa maksimal secara permanen.",
        "Menambah durasi efek magnet secara permanen.": "Menambah durasi efek magnet secara permanen.",
        "Menambah durasi perlindungan perisai secara permanen.": "Menambah durasi perlindungan perisai secara permanen.",
        "Menambah durasi efek double coins secara permanen.": "Menambah durasi efek double coins secara permanen.",
        "Menambah multiplier gain koin saat double coins aktif.": "Menambah multiplier gain koin saat double coins aktif.",
        "Menambah durasi efek speed boost secara permanen.": "Menambah durasi efek speed boost secara permanen.",
        "Skin standar untuk petualang pemula.": "Skin standar untuk petualang pemula.",
        "Skin dengan detail emas yang elegan.": "Skin dengan detail emas yang elegan.",
        "Skin futuristik yang menyala dalam gelap.": "Skin futuristik yang menyala dalam gelap.",
        "Skin misterius yang terbuat dari bayangan.": "Skin misterius yang terbuat dari bayangan.",
        "Paket kecil gems untuk kebutuhan mendesak.": "Paket kecil gems untuk kebutuhan mendesak.",
        "Paket standar dengan bonus gems 10%.": "Paket standar dengan bonus gems 10%.",
        "Paket besar dengan bonus gems melimpah.": "Paket besar dengan bonus gems melimpah.",
        "Pilihan terbaik untuk kolektor sejati.": "Pilihan terbaik untuk kolektor sejati.",
        "Koin, Gems, dan Power-ups untuk memulai.": "Koin, Gems, dan Power-ups untuk memulai.",
        "Boost kemajuanmu dengan koin dan power-ups.": "Boost kemajuanmu dengan koin dan power-ups.",
        "Paket hemat koin dan gems untuk beli skin.": "Paket hemat koin dan gems untuk beli skin.",
        "Kembali ke menu utama?\nRun ini akan diakhiri.": "Kembali ke menu utama?\nRun ini akan diakhiri.",
        "Lanjut dengan bonus?\nTonton iklan untuk lanjut run ini.": "Lanjut dengan bonus?\nTonton iklan untuk lanjut run ini.",
        "MISSIONS": "MISI",
        "DAILY": "HARIAN",
        "MISSION": "MISI",
        "WEEKLY": "MINGGUAN",
        "MONTHLY": "BULANAN",
        "CHALLENGE": "TANTANGAN",
        "BACK": "KEMBALI",
        "Kalahkan {n} musuh": "Kalahkan {n} musuh",
        "Capai jarak {n}m": "Capai jarak {n}m",
        "Kumpulkan {n} koin": "Kumpulkan {n} koin",
        "Dapatkan {n} skill": "Dapatkan {n} skill",
        "Lompat {n} kali": "Lompat {n} kali",
        "Mainkan {n} run": "Mainkan {n} run",
        "Dapatkan Shield {n} kali": "Dapatkan Shield {n} kali",
        "Dapatkan DoubleCoins {n} kali": "Dapatkan DoubleCoins {n} kali",
        "Reward Ready!": "Hadiah Siap!",
        "Done: %s": "Selesai: %s",
        "Collect {n} coins": "Kumpulkan {n} koin",
        "Defeat {n} enemies": "Kalahkan {n} musuh",
        "Jump {n} times": "Lompat {n} kali",
        "Get {n} skills": "Dapatkan {n} skill",
        "Reach {n}m distance": "Capai jarak {n}m",
        "Reset misi harian?\nTonton iklan untuk reset.": "Reset misi harian?\nTonton iklan untuk reset.",
        "SEASON_REWARDS_TITLE": "HADIAH SEASON",
        "CLAIM_ALL": "AMBIL SEMUA",
        "TIME_REMAINING_HINT": "SEASON SEGERA BERAKHIR"
    },
    "zh": {
        "Backsound": "音乐",
        "Settings": "设置",
        "Language": "语言",
        "Bahasa Indonesia": "印尼语",
        "English": "英语",
        "中文": "中文",
        "BGM Volume": "背景音乐音量",
        "SFX Volume": "音效音量",
        "Mute BGM": "静音BGM",
        "Mute SFX": "静音音效",
        "Loading": "加载中",
        "Checking content": "检查内容",
        "Downloading assets": "正在下载资源",
        "Mounting assets": "正在挂载资源",
        "Manifest download failed": "清单下载失败",
        "Manifest invalid": "清单无效",
        "Content download failed": "内容下载失败",
        "Content mount failed": "内容挂载失败",
        "Shop": "商店",
        "Owned": "已拥有",
        "Coming Soon": "即将推出",
        "Buy": "购买",
        "Coins": "金币",
        "Gems": "宝石",
        "Money": "现金",
        "Already owned.": "已拥有。",
        "Not enough coins.": "金币不足。",
        "Not enough gems.": "宝石不足。",
        "Not supported.": "不支持。",
        "Purchase processed.": "购买已处理。",
        "Purchase successful: %s": "购买成功：%s",
        "Buy %s\nfor %d %s?": "购买%s\n花费%d%s？",
        "[Error] Groups container (HBox) not found": "[错误] 未找到分组容器(HBox)",
        "Skills & Power-ups (Coins)": "技能与道具（金币）",
        "Upgrades (Coins)": "升级（金币）",
        "Upgrades (Gems)": "升级（宝石）",
        "Cosmetics (Coins)": "外观（金币）",
        "Cosmetics (Gems)": "外观（宝石）",
        "Gem Packs (Real)": "宝石包（现金）",
        "Bundles (Real)": "礼包（现金）",
        "Magnet 30s": "磁铁30秒",
        "Perisai 1 Hit": "护盾（1次）",
        "Double Coins (1 Run)": "双倍金币（1局）",
        "Speed Boost (1 Run)": "速度提升（1局）",
        "Upgrade Nyawa Maks +1": "最大生命升级+1",
        "Upgrade Durasi Magnet +10%": "磁铁持续时间升级+10%",
        "Upgrade Durasi Shield +10%": "护盾持续时间升级+10%",
        "Upgrade Durasi Double Coins +10%": "双倍金币持续时间升级+10%",
        "Upgrade Multiplier Double Coins +0.25x": "双倍金币倍率升级+0.25x",
        "Upgrade Durasi Speed Boost +10%": "加速持续时间升级+10%",
        "Skin Basic": "基础皮肤",
        "Skin Premium": "高级皮肤",
        "Skin Neon": "霓虹皮肤",
        "Skin Shadow": "暗影皮肤",
        "Small Gem Pack (100)": "小宝石包（100）",
        "Standard Gem Pack (300 +30)": "标准宝石包（300+30）",
        "Big Gem Pack (800 +150)": "大宝石包（800+150）",
        "Mega Gem Pack (2000 +500)": "超大宝石包（2000+500）",
        "Starter Pack": "新手礼包",
        "Progress Pack": "进度礼包",
        "Cosmetic Starter": "外观新手包",
        "Menarik koin otomatis selama 30 detik.": "自动吸引金币30秒。",
        "Melindungi dari satu kali tabrakan.": "抵挡一次碰撞。",
        "Mendapatkan koin 2x lipat selama satu sesi lari.": "一局内获得2倍金币。",
        "Meningkatkan kecepatan lari dasar sebesar 50%.": "基础跑速提升50%。",
        "Meningkatkan kapasitas nyawa maksimal secara permanen.": "永久提升最大生命值。",
        "Menambah durasi efek magnet secara permanen.": "永久增加磁铁效果持续时间。",
        "Menambah durasi perlindungan perisai secara permanen.": "永久增加护盾效果持续时间。",
        "Menambah durasi efek double coins secara permanen.": "永久增加双倍金币效果持续时间。",
        "Menambah multiplier gain koin saat double coins aktif.": "双倍金币生效时提高金币倍率。",
        "Menambah durasi efek speed boost secara permanen.": "永久增加加速效果持续时间。",
        "Skin standar para petualang pemula.": "适合新手冒险者的标准皮肤。",
        "Skin dengan detail emas yang elegan.": "带有优雅金色细节的皮肤。",
        "Skin futuristik yang menyala dalam gelap.": "在黑暗中发光的未来风皮肤。",
        "Skin misterius yang terbuat dari bayangan.": "由阴影构成的神秘皮肤。",
        "Paket kecil gems untuk kebutuhan mendesak.": "适合紧急需求的小宝石包。",
        "Paket standar dengan bonus gems 10%.": "标准包，附赠10%宝石。",
        "Paket besar dengan bonus gems melimpah.": "大包，赠送大量宝石。",
        "Pilihan terbaik untuk kolektor sejati.": "真正收藏家的最佳选择。",
        "Koin, Gems, dan Power-ups untuk memulai.": "包含金币、宝石与道具，助你起步。",
        "Boost kemajuanmu dengan koin dan power-ups.": "用金币与道具加速进度。",
        "Paket hemat koin dan gems untuk beli skin.": "金币与宝石优惠包，用于购买皮肤。",
        "Kembali ke menu utama?\nRun ini akan diakhiri.": "返回主菜单？\n本次跑酷将结束。",
        "Lanjut dengan bonus?\nTonton iklan untuk lanjut run ini.": "使用奖励继续？\n观看广告以继续本次跑酷。",
        "MISSIONS": "任务",
        "DAILY": "每日",
        "MISSION": "任务",
        "WEEKLY": "每周",
        "MONTHLY": "每月",
        "CHALLENGE": "挑战",
        "BACK": "返回",
        "Kalahkan {n} musuh": "击败 {n} 个敌人",
        "Capai jarak {n}m": "达到 {n} 米距离",
        "Kumpulkan {n} koin": "收集 {n} 金币",
        "Dapatkan {n} skill": "获得 {n} 个技能",
        "Lompat {n} kali": "跳跃 {n} 次",
        "Mainkan {n} run": "进行 {n} 次跑酷",
        "Dapatkan Shield {n} kali": "获得护盾 {n} 次",
        "Dapatkan DoubleCoins {n} kali": "获得双倍金币 {n} 次",
        "Reward Ready!": "奖励已就绪！",
        "Done: %s": "完成：%s",
        "Collect {n} coins": "收集 {n} 金币",
        "Defeat {n} enemies": "击败 {n} 个敌人",
        "Jump {n} times": "跳跃 {n} 次",
        "Get {n} skills": "获得 {n} 个技能",
        "Reach {n}m distance": "达到 {n} 米距离",
        "Reset misi harian?\nTonton iklan untuk reset.": "重置每日任务？\n观看广告以重置。",
        "SEASON_REWARDS_TITLE": "赛季奖励",
        "CLAIM_ALL": "全部领取",
        "TIME_REMAINING_HINT": "赛季即将结束"
    }
}
const _I18N_SAVE_SECTION := "settings"
const _I18N_SAVE_KEY := "language"
const _I18N_DEFAULT := "en"
var _i18n_loaded: bool = false
var _i18n_loaded_locales: Dictionary = {}

func _ensure_cloud_textures_loaded() -> void:
    if not _cloud_textures.is_empty():
        return
    if DisplayServer.get_name() == "headless":
        return
    _cloud_textures = [
        load("res://assets/Background/png/Clouds/512x512/Cloud_1.png") as Texture2D,
        load("res://assets/Background/png/Clouds/512x512/Cloud_2.png") as Texture2D,
        load("res://assets/Background/png/Clouds/512x512/Cloud_1.png") as Texture2D,
        load("res://assets/Background/png/Clouds/512x512/Cloud_2.png") as Texture2D,
        load("res://assets/Background/png/Clouds/512x512/Cloud_1.png") as Texture2D,
        load("res://assets/Background/png/Clouds/512x512/Cloud_2.png") as Texture2D
    ]

func _ready() -> void:
    layer = 1000
    _overlay = ColorRect.new()
    _overlay.color = Color(0, 0, 0, 1)
    _overlay.modulate.a = 0.0
    _overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
    _overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
    add_child(_overlay)
    _init_sfx()
    _load_sfx_settings_from_save()
    _init_i18n()
    if Engine.is_editor_hint() and preview_in_editor and _is_transition_scene_open():
        _spawn_preview_clouds()
        _last_preview_sig = _make_preview_signature()


func _init_i18n() -> void:
    _ensure_i18n_loaded()
    var saved := _load_language_from_save()
    if saved == "":
        saved = _I18N_DEFAULT
    set_language(saved, false)


func _ensure_i18n_loaded() -> void:
    if _i18n_loaded:
        return
    _i18n_loaded = true
    if DisplayServer.get_name() == "headless":
        _ensure_i18n_json_fallback()
        return
    var ver := Engine.get_version_info()
    if int(ver.get("minor", 0)) >= 6:
        _ensure_i18n_json_fallback()
        return
    for p in _I18N_TRANSLATIONS:
        var t := load(p) as Translation
        if t:
            TranslationServer.add_translation(t)
            var loc := str(t.locale).strip_edges().to_lower()
            if loc != "":
                _i18n_loaded_locales[loc] = true
    _ensure_i18n_json_fallback()


func _ensure_i18n_json_fallback() -> void:
    for locale in _I18N_FALLBACK.keys():
        var loc := str(locale).strip_edges().to_lower()
        if _i18n_loaded_locales.has(loc):
            continue
        var dict_value: Variant = _I18N_FALLBACK[locale]
        if typeof(dict_value) != TYPE_DICTIONARY:
            continue
        var dict: Dictionary = dict_value
        var t := _translation_from_dict(loc, dict)
        if t:
            TranslationServer.add_translation(t)
            _i18n_loaded_locales[loc] = true


func _translation_from_dict(locale: String, dict: Dictionary) -> Translation:
    var t := Translation.new()
    t.locale = locale
    for k in dict.keys():
        var src := str(k)
        var dst := str(dict[k])
        t.add_message(src, dst)
    return t


func _pick_default_locale() -> String:
    var sys := ""
    if OS.has_method("get_locale_language"):
        sys = str(OS.get_locale_language())
    if sys == "":
        sys = str(TranslationServer.get_locale())
    sys = sys.strip_edges().to_lower()
    if sys.begins_with("en"):
        return "en"
    if sys.begins_with("id"):
        return "id"
    if sys.begins_with("zh"):
        return "zh"
    return _I18N_DEFAULT


func _normalize_locale(locale: String) -> String:
    var lc := locale.strip_edges().to_lower()
    if lc.begins_with("en"):
        return "en"
    if lc.begins_with("id"):
        return "id"
    if lc.begins_with("zh"):
        return "zh"
    return _I18N_DEFAULT


func set_language(locale: String, save: bool = true) -> void:
    _ensure_i18n_loaded()
    var lc := _normalize_locale(locale)
    TranslationServer.set_locale(lc)
    if save:
        _save_language_to_save(lc)
    emit_signal("language_changed", lc)


func get_language() -> String:
    return _normalize_locale(str(TranslationServer.get_locale()))


func _load_language_from_save() -> String:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        return ""
    return str(cfg.get_value(_I18N_SAVE_SECTION, _I18N_SAVE_KEY, ""))


func _save_language_to_save(locale: String) -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        cfg = ConfigFile.new()
    cfg.set_value(_I18N_SAVE_SECTION, _I18N_SAVE_KEY, locale)
    cfg.save("user://save.cfg")

func fade_out(duration: float = 0.5) -> void:
    var t := create_tween()
    _tween_active = true
    t.tween_property(_overlay, "modulate:a", 1.0, duration)
    await t.finished
    if not is_inside_tree():
        return
    _tween_active = false

func fade_in(duration: float = 0.5) -> void:
    var t := create_tween()
    _tween_active = true
    t.tween_property(_overlay, "modulate:a", 0.0, duration)
    await t.finished
    if not is_inside_tree():
        return
    _tween_active = false

func fade_to_scene(scene_path: String, duration: float = 0.5) -> void:
    var packed_scene: PackedScene = null
    if Engine.has_singleton("Preloader"):
        var p := Preloader
        if p and p.has_method("get_packed"):
            packed_scene = p.get_packed(scene_path)
    if packed_scene == null:
        var res := load(scene_path)
        if res is PackedScene:
            packed_scene = res
    await fade_out(duration)
    if not is_inside_tree():
        return
    if packed_scene != null:
        var err := get_tree().change_scene_to_packed(packed_scene)
        if err != OK:
            get_tree().change_scene_to_file(scene_path)
    else:
        get_tree().change_scene_to_file(scene_path)
    await fade_in(duration)

func cloud_sweep_to_scene(scene_path: String, duration: float = -1.0, count: int = -1) -> void:
    _rng.randomize()
    _ensure_cloud_textures_loaded()
    if _cloud_textures.is_empty():
        await fade_to_scene(scene_path, 0.4)
        return
    var vs := get_viewport().get_visible_rect().size
    _cloud_layer = Control.new()
    _cloud_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    _cloud_layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
    _cloud_layer.modulate.a = 1.0
    add_child(_cloud_layer)
    var packed_scene: PackedScene = null
    if Engine.has_singleton("Preloader"):
        var p := Preloader
        if p and p.has_method("get_packed"):
            packed_scene = p.get_packed(scene_path)
    if packed_scene == null:
        var res := load(scene_path)
        if res is PackedScene:
            packed_scene = res
    var dur: float = (transition_duration if duration <= 0.0 else duration)
    var base_count: int = (cloud_count if count <= 0 else count)
    var rows: int = max(min_rows, int(ceil(vs.y / row_height_px)))
    var cols: int = max(min_cols, int(ceil(vs.x / col_width_px)))
    var grid_total: int = rows * cols
    var total: int = min(base_count, grid_total)
    total = int(clamp(total, 16.0, 48.0))
    for i in range(total):
        var tx: Texture2D = _cloud_textures[_rng.randi_range(0, _cloud_textures.size() - 1)]
        var cloud_rect := TextureRect.new()
        cloud_rect.texture = tx
        cloud_rect.stretch_mode = TextureRect.STRETCH_SCALE
        var base_w := tx.get_width()
        var base_h := tx.get_height()
        var scale_factor: float = _rng.randf_range(scale_min, scale_max)
        cloud_rect.custom_minimum_size = Vector2(base_w * scale_factor, base_h * scale_factor)
        var dir_rand := (_rng.randi() % 2) == 0
        var start_left := (direction_mode == 0 and dir_rand) or (direction_mode == 1)
        var start_x := -base_w * scale_factor - _rng.randf_range(margin_min, margin_max)
        var end_x := vs.x + base_w * scale_factor + _rng.randf_range(margin_min, margin_max)
        if not start_left:
            start_x = vs.x + base_w * scale_factor + _rng.randf_range(margin_min, margin_max)
            end_x = -base_w * scale_factor - _rng.randf_range(margin_min, margin_max)
        var row_index: int = i % rows
        var row_h: float = vs.y / float(rows)
        var y: float = clamp(row_h * row_index + _rng.randf_range(0.0, row_h - base_h * scale_factor), 0.0, vs.y - base_h * scale_factor)
        cloud_rect.position = Vector2(start_x, y)
        _cloud_layer.add_child(cloud_rect)
        var delay: float = _rng.randf_range(0.0, dur * delay_factor)
        var t := create_tween()
        t.tween_property(cloud_rect, "position:x", end_x, dur).set_delay(delay)
    await get_tree().create_timer(dur + 0.4).timeout
    if not is_inside_tree():
        return
    await fade_out(0.2)
    if not is_inside_tree():
        return
    if is_instance_valid(_cloud_layer):
        _cloud_layer.queue_free()
    if packed_scene != null:
        get_tree().change_scene_to_packed(packed_scene)
    else:
        get_tree().change_scene_to_file(scene_path)
    await get_tree().create_timer(0.01).timeout
    if not is_inside_tree():
        return
    await fade_in(0.2)

func play_transition_to_scene(scene_path: String) -> void:
    # Keep transition deterministic across devices and avoid mixed transition states.
    await fade_to_scene(scene_path, 0.4)

func _spawn_preview_clouds() -> void:
    _rng.randomize()
    _ensure_cloud_textures_loaded()
    if _cloud_textures.is_empty():
        return
    var vs: Vector2 = get_viewport().get_visible_rect().size
    if vs.x <= 1.0 or vs.y <= 1.0:
        var vw := int(ProjectSettings.get_setting("display/window/size/viewport_width"))
        var vh := int(ProjectSettings.get_setting("display/window/size/viewport_height"))
        vs = Vector2(float(vw), float(vh))
    if is_instance_valid(_cloud_layer):
        _cloud_layer.queue_free()
    _cloud_layer = Control.new()
    _cloud_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
    add_child(_cloud_layer)
    var rows: int = max(min_rows, int(ceil(vs.y / row_height_px)))
    var cols: int = max(min_cols, int(ceil(vs.x / col_width_px)))
    var total: int = min(64, rows * cols)
    for i in range(total):
        var tx: Texture2D = _cloud_textures[_rng.randi_range(0, _cloud_textures.size() - 1)]
        var base_w := tx.get_width()
        var base_h := tx.get_height()
        var scale_factor: float = _rng.randf_range(scale_min, scale_max)
        if preview_use_sprite:
            var spr := Sprite2D.new()
            spr.texture = tx
            spr.centered = false
            spr.scale = Vector2(scale_factor, scale_factor)
            var row_index: int = i % rows
            var row_h: float = vs.y / float(rows)
            var y: float = clamp(row_h * row_index + _rng.randf_range(0.0, row_h - base_h * scale_factor), 0.0, vs.y - base_h * scale_factor)
            var x: float = _rng.randf_range(0.0, vs.x - base_w * scale_factor)
            spr.position = Vector2(x, y)
            _cloud_layer.add_child(spr)
        else:
            var cloud_rect := TextureRect.new()
            cloud_rect.texture = tx
            cloud_rect.stretch_mode = TextureRect.STRETCH_SCALE
            cloud_rect.custom_minimum_size = Vector2(base_w * scale_factor, base_h * scale_factor)
            var row_index2: int = i % rows
            var row_h2: float = vs.y / float(rows)
            var y2: float = clamp(row_h2 * row_index2 + _rng.randf_range(0.0, row_h2 - base_h * scale_factor), 0.0, vs.y - base_h * scale_factor)
            var x2: float = _rng.randf_range(0.0, vs.x - base_w * scale_factor)
            cloud_rect.position = Vector2(x2, y2)
            _cloud_layer.add_child(cloud_rect)

func _clear_preview_clouds() -> void:
    if is_instance_valid(_cloud_layer):
        _cloud_layer.queue_free()
        _cloud_layer = null

func _set_preview_enabled(v: bool) -> void:
    preview_in_editor = v
    if Engine.is_editor_hint():
        if preview_in_editor and _is_transition_scene_open():
            _spawn_preview_clouds()
            _last_preview_sig = _make_preview_signature()
        else:
            _clear_preview_clouds()

func _make_preview_signature() -> String:
    return str(transition_duration) + ":" + str(cloud_count) + ":" + str(row_height_px) + ":" + str(col_width_px) + ":" + str(min_rows) + ":" + str(min_cols) + ":" + str(scale_min) + ":" + str(scale_max) + ":" + str(margin_min) + ":" + str(margin_max) + ":" + str(delay_factor) + ":" + str(direction_mode) + ":" + str(preview_use_sprite)

func _process(_delta: float) -> void:
    if Engine.is_editor_hint() and preview_in_editor and live_update_in_editor and _is_transition_scene_open():
        var sig := _make_preview_signature()
        if sig != _last_preview_sig:
            _clear_preview_clouds()
            _spawn_preview_clouds()
            _last_preview_sig = sig

func _is_transition_scene_open() -> bool:
    var cs := get_tree().get_current_scene()
    if cs == null:
        return false
    var path := cs.get_scene_file_path()
    return path.ends_with("/scenes/TransitionManager.tscn")

func set_sfx_volume(v: float) -> void:
    _sfx_volume = clampf(v, 0.0, 1.0)
    _apply_sfx_mix()

func set_sfx_muted(m: bool) -> void:
    _sfx_muted = m
    _apply_sfx_mix()

func play_sfx(id: StringName, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
    if _sfx_muted:
        return
    if _sfx_pool.is_empty():
        _init_sfx()
        if _sfx_pool.is_empty():
            return
    var stream := _get_sfx_stream(id)
    if stream == null:
        return
    var p := _sfx_pool[_sfx_pool_cursor]
    _sfx_pool_cursor = (_sfx_pool_cursor + 1) % _sfx_pool.size()
    if p.playing:
        p.stop()
    p.stream = stream
    p.pitch_scale = pitch_scale * _pitch_variation(id)
    p.volume_db = _sfx_base_db + volume_db
    p.play()
    _request_bgm_duck(id)

func _request_bgm_duck(id: StringName) -> void:
    var db: float = 0.0
    var dur: float = 0.0
    match String(id):
        "player_hit":
            db = 7.0
            dur = 0.26
        "enemy_kill":
            db = 5.0
            dur = 0.20
        "speed_boost_start":
            db = 4.0
            dur = 0.18
        "game_over":
            db = 8.0
            dur = 0.35
        _:
            return
    duck_bgm(db, dur)

func _init_sfx() -> void:
    _sfx_rng.randomize()
    if not _sfx_pool.is_empty():
        return
    _sfx_player = null
    _sfx_poly = null
    _sfx_playback = null
    _sfx_pool_cursor = 0
    var pool_size := 10
    for i in range(pool_size):
        var p := AudioStreamPlayer.new()
        p.name = "SFX_%d" % i
        p.process_mode = Node.PROCESS_MODE_ALWAYS
        add_child(p)
        _sfx_pool.append(p)
    _sfx_player = _sfx_pool[0]
    _apply_sfx_mix()

func _apply_sfx_mix() -> void:
    _sfx_base_db = (-60.0 if _sfx_muted else _lin_to_db(_sfx_volume))
    if _sfx_pool.is_empty():
        return
    for p in _sfx_pool:
        if is_instance_valid(p):
            p.volume_db = _sfx_base_db

var _bgm_duck_db: float = 0.0
var _bgm_duck_tween: Tween = null

func _lin_to_db(v: float) -> float:
    return -60.0 if v <= 0.0 else 20.0 * log(v) / log(10.0)

func set_bgm_volume(v: float) -> void:
    _bgm_volume = clampf(v, 0.0, 1.0)
    _apply_bgm_mix()

func set_bgm_muted(m: bool) -> void:
    _bgm_muted = m
    _apply_bgm_mix()

func duck_bgm(reduction_db: float = 6.0, duration_sec: float = 0.22) -> void:
    if _bgm_muted:
        return
    var d := -absf(reduction_db)
    _bgm_duck_db = minf(_bgm_duck_db, d)
    _apply_bgm_mix()
    if _bgm_duck_tween and _bgm_duck_tween.is_running():
        _bgm_duck_tween.kill()
    var dur: float = maxf(duration_sec, 0.02)
    _bgm_duck_tween = create_tween()
    _bgm_duck_tween.tween_method(func(v2: float) -> void:
        _bgm_duck_db = v2
        _apply_bgm_mix()
    , _bgm_duck_db, 0.0, dur)

func _apply_bgm_mix() -> void:
    if _bgm_player == null:
        return
    _bgm_player.volume_db = (-60.0 if _bgm_muted else (_lin_to_db(_bgm_volume) + _bgm_duck_db))

func ensure_bgm_player() -> void:
    if _bgm_player != null and is_instance_valid(_bgm_player):
        return
    _bgm_player = AudioStreamPlayer.new()
    _bgm_player.name = "BGMPlayer"
    _bgm_player.process_mode = Node.PROCESS_MODE_ALWAYS
    _bgm_player.finished.connect(_on_bgm_finished)
    add_child(_bgm_player)
    _apply_bgm_mix()

func play_bgm(stream_or_path: Variant, volume: float = -1.0) -> void:
    var stream: AudioStream = null
    if typeof(stream_or_path) == TYPE_STRING:
        var path = str(stream_or_path)
        if ResourceLoader.exists(path):
            stream = load(path) as AudioStream
        else:
            push_error("BGM file not found: " + path)
    elif stream_or_path is AudioStream:
        stream = stream_or_path

    if stream == null:
        return

    _bgm_paths = [] # Reset playlist if playing single stream
    _bgm_index = -1
    ensure_bgm_player()
    if volume >= 0.0:
        _bgm_volume = volume
        _apply_bgm_mix()

    if _bgm_player.stream == stream and _bgm_player.playing:
        return

    _bgm_player.stream = stream
    _bgm_player.play()

func play_playlist(paths: Array[String], start_index: int = 0) -> void:
    if paths.is_empty():
        return

    # Filter paths that actually exist
    var valid_paths: Array[String] = []
    for p in paths:
        if ResourceLoader.exists(p):
            valid_paths.append(p)
        else:
            push_error("Playlist BGM file not found: " + p)

    if valid_paths.is_empty():
        return

    _bgm_paths = valid_paths
    _bgm_index = clampi(start_index, 0, _bgm_paths.size() - 1)
    _play_current_playlist_item()

func _play_current_playlist_item() -> void:
    if _bgm_index < 0 or _bgm_index >= _bgm_paths.size():
        return
    var path := _bgm_paths[_bgm_index]

    if not ResourceLoader.exists(path):
        push_error("BGM item not found during playback: " + path)
        # Try next one if available
        if _bgm_paths.size() > 1:
            _on_bgm_finished()
        return

    var stream := load(path) as AudioStream
    if stream:
        ensure_bgm_player()
        if _bgm_player.stream != stream or not _bgm_player.playing:
            _bgm_player.stream = stream
            _bgm_player.play()

        var raw_name := path.get_file().get_basename().replace("backsound-mainmenu-", "").replace("backsound-", "").replace("-", " ").strip_edges()
        var track_name := ""
        if raw_name.is_valid_int():
            track_name = "Track " + raw_name
        elif raw_name == "":
            track_name = "Main Theme"
        else:
            track_name = raw_name.capitalize()

        bgm_track_changed.emit(track_name)
        bgm_index_changed.emit(_bgm_index)

func _on_bgm_finished() -> void:
    if _bgm_paths.is_empty():
        return
    _bgm_index = (_bgm_index + 1) % _bgm_paths.size()
    _play_current_playlist_item()

func stop_bgm() -> void:
    if _bgm_player and is_instance_valid(_bgm_player) and _bgm_player.playing:
        _bgm_player.stop()

func is_bgm_playing() -> bool:
    return _bgm_player != null and is_instance_valid(_bgm_player) and _bgm_player.playing

func get_bgm_player() -> AudioStreamPlayer:
    ensure_bgm_player()
    return _bgm_player

func _load_sfx_settings_from_save() -> void:
    var cfg := ConfigFile.new()
    var err := cfg.load("user://save.cfg")
    if err != OK:
        _apply_sfx_mix()
        return
    set_sfx_volume(float(cfg.get_value("settings", "sfx_volume", _sfx_volume)))
    set_sfx_muted(bool(cfg.get_value("settings", "sfx_muted", _sfx_muted)))

func _pitch_variation(id: StringName) -> float:
    match String(id):
        "jump":
            return _sfx_rng.randf_range(0.97, 1.05)
        "coin":
            return _sfx_rng.randf_range(0.98, 1.02)
        "mission_claim":
            return _sfx_rng.randf_range(0.985, 1.015)
        "click":
            return _sfx_rng.randf_range(0.98, 1.03)
        "enemy_kill":
            return _sfx_rng.randf_range(0.96, 1.04)
        "game_over":
            return 1.0
        "magnet_pickup", "shield_pickup", "double_coins_pickup", "speed_boost_pickup":
            return _sfx_rng.randf_range(0.98, 1.03)
        "heart_pickup":
            return _sfx_rng.randf_range(0.985, 1.02)
        "player_hit":
            return _sfx_rng.randf_range(0.98, 1.02)
        "speed_boost_start":
            return _sfx_rng.randf_range(0.97, 1.03)
        _:
            return _sfx_rng.randf_range(0.98, 1.04)

func _get_sfx_stream(id: StringName) -> AudioStream:
    var key := String(id)
    if _sfx_streams.has(key):
        var cached: Variant = _sfx_streams[key]
        if cached is Array:
            var arr := cached as Array
            if arr.is_empty():
                return null
            return arr[_sfx_rng.randi_range(0, arr.size() - 1)] as AudioStream
        return cached as AudioStream

    # Try loading from assets first
    var asset_path := "res://assets/audio/sfx/" + key + ".mp3"

    # Map special keys to actual filenames if they differ
    var actual_path := asset_path
    match key:
        "coin":
            actual_path = "res://assets/audio/sfx/audio-SFX-only-not-a-song-Coin-pickup-two-quick-pings-90.mp3"
        "mission_claim":
            actual_path = "res://assets/audio/sfx/audio-One-shot-SFX-only-not-music-Coin-pickup-chain-3-mi.mp3"

    if ResourceLoader.exists(actual_path):
        var s_res = load(actual_path) as AudioStream
        if s_res:
            _sfx_streams[key] = s_res
            return s_res

    # Fallback to default asset path if not mapped
    if actual_path != asset_path and ResourceLoader.exists(asset_path):
        var s_res = load(asset_path) as AudioStream
        if s_res:
            _sfx_streams[key] = s_res
            return s_res

    var s: Variant = null
    match key:
        "jump":
            s = _gen_jump_wav()
        "coin":
            var arr: Array = []
            for i in range(10):
                arr.append(_gen_coin_wav_variant(i))
            s = arr
        "mission_claim":
            s = _gen_coin_wav_variant(99)
        "click":
            s = _gen_click_wav()
        "enemy_kill":
            var arr2: Array = []
            for i in range(6):
                arr2.append(_gen_enemy_kill_wav_variant(i))
            s = arr2
        "game_over":
            s = _gen_game_over_wav()
        "magnet_pickup":
            s = _gen_powerup_pickup_wav_variant(0, 980.0)
        "shield_pickup":
            s = _gen_powerup_pickup_wav_variant(1, 720.0)
        "double_coins_pickup":
            s = _gen_powerup_pickup_wav_variant(2, 1120.0)
        "speed_boost_pickup":
            s = _gen_powerup_pickup_wav_variant(3, 860.0)
        "heart_pickup":
            var arr3: Array = []
            for i in range(4):
                arr3.append(_gen_heart_pickup_wav_variant(i))
            s = arr3
        "player_hit":
            var arr4: Array = []
            for i in range(5):
                arr4.append(_gen_player_hit_wav_variant(i))
            s = arr4
        "speed_boost_start":
            var arr5: Array = []
            for i in range(4):
                arr5.append(_gen_speed_boost_start_wav_variant(i))
            s = arr5
        _:
            s = _gen_click_wav()
    _sfx_streams[key] = s
    if s is Array:
        var a := s as Array
        if a.is_empty():
            return null
        return a[0] as AudioStream
    return s as AudioStream

func _gen_click_wav() -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.055
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)
    var phase := 0.0
    var freq := 1000.0
    var attack := 0.002
    var release := 0.04
    for i in range(count):
        var t := float(i) / float(sr)
        phase += TAU * freq / float(sr)
        var a := clampf(t / attack, 0.0, 1.0)
        var r := clampf((dur - t) / release, 0.0, 1.0)
        var env := a * r
        var sample := sin(phase) * env * 0.45
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _gen_jump_wav() -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.14
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)
    var phase := 0.0
    var phase2 := 0.0
    var attack := 0.006
    var release := 0.09
    for i in range(count):
        var t := float(i) / float(sr)
        var k := clampf(t / dur, 0.0, 1.0)
        var freq := lerpf(360.0, 980.0, k)
        var freq2 := freq * 2.0
        phase += TAU * freq / float(sr)
        phase2 += TAU * freq2 / float(sr)
        var a := clampf(t / attack, 0.0, 1.0)
        var r := clampf((dur - t) / release, 0.0, 1.0)
        var env := a * r
        var tone := (sin(phase) * 0.55 + sin(phase2) * 0.18)
        var sample := tone * env * 0.55
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _gen_coin_wav_variant(variant_seed: int) -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.16
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)

    var rng := RandomNumberGenerator.new()
    rng.seed = 9001 + variant_seed
    var detune := rng.randf_range(0.986, 1.014)
    var base_f1 := 1800.0 * detune
    var base_f2 := base_f1 * 1.25

    var split := int(round(0.07 * float(sr)))
    split = clampi(split, 1, count - 1)

    var phase1 := 0.0
    var phase2 := 0.0
    var phase3 := 0.0
    var mod_phase := 0.0
    var mod_freq := rng.randf_range(34.0, 52.0)
    var mod_depth := rng.randf_range(0.006, 0.014)

    var attack := 0.0016
    var decay1 := 0.032
    var decay2 := 0.038
    for i in range(count):
        var t := float(i) / float(sr)

        var f := base_f1
        var ti := t
        var tau := decay1
        if i >= split:
            f = base_f2
            ti = float(i - split) / float(sr)
            tau = decay2

        mod_phase += TAU * mod_freq / float(sr)
        var fm := 1.0 + sin(mod_phase) * mod_depth
        var freq := f * fm
        phase1 += TAU * freq / float(sr)
        phase2 += TAU * (freq * 2.0) / float(sr)
        phase3 += TAU * (freq * 2.74) / float(sr)

        var a := clampf(ti / attack, 0.0, 1.0)
        var env := a * exp(-ti / max(tau, 0.0001))

        var tone := sin(phase1) * 0.70 + sin(phase2) * 0.20 + sin(phase3) * 0.10
        var click := (rng.randf_range(-1.0, 1.0) * exp(-t / 0.008)) * 0.14
        var sample := (tone * env * 0.62) + click
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _gen_enemy_kill_wav_variant(variant_seed: int) -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.16
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)

    var rng := RandomNumberGenerator.new()
    rng.seed = 4242 + variant_seed

    var phase1 := 0.0
    var phase2 := 0.0
    var mod_phase := 0.0
    var mod_freq := rng.randf_range(18.0, 46.0)
    var attack := 0.0018
    for i in range(count):
        var t := float(i) / float(sr)
        var k := clampf(t / dur, 0.0, 1.0)
        var sweep := pow(k, 0.55)
        var f := lerpf(1350.0, 220.0, sweep)
        mod_phase += TAU * mod_freq / float(sr)
        f *= 1.0 + sin(mod_phase) * 0.018
        phase1 += TAU * f / float(sr)
        phase2 += TAU * (f * 2.12) / float(sr)

        var a := clampf(t / attack, 0.0, 1.0)
        var env := a * exp(-t / 0.045)
        var grit := rng.randf_range(-1.0, 1.0) * exp(-t / 0.010) * 0.22
        var tone := sin(phase1) * 0.62 + sin(phase2) * 0.15
        var sample := (tone + grit) * env * 0.95
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _gen_game_over_wav() -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.70
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)
    var phase1 := 0.0
    var phase2 := 0.0
    var attack := 0.02
    for i in range(count):
        var t := float(i) / float(sr)
        var k := clampf(t / dur, 0.0, 1.0)
        var sweep := pow(k, 0.75)
        var f := lerpf(240.0, 70.0, sweep)
        phase1 += TAU * f / float(sr)
        phase2 += TAU * (f * 1.98) / float(sr)
        var a := clampf(t / attack, 0.0, 1.0)
        var env := a * exp(-t / 0.55)
        var trem := 1.0 + sin(TAU * 5.5 * t) * 0.07
        var tone := sin(phase1) * 0.62 + sin(phase2) * 0.14
        var sample := tone * env * trem * 0.62
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _gen_powerup_pickup_wav_variant(variant_seed: int, base_freq: float) -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.22
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)

    var rng := RandomNumberGenerator.new()
    rng.seed = 90000 + variant_seed

    var phase1 := 0.0
    var phase2 := 0.0
    var phase3 := 0.0
    var mod_phase := 0.0
    var mod_freq := rng.randf_range(24.0, 46.0)
    var mod_depth := rng.randf_range(0.006, 0.014)
    var attack := 0.0026
    for i in range(count):
        var t := float(i) / float(sr)
        var k := clampf(t / dur, 0.0, 1.0)
        var f := lerpf(base_freq * 0.92, base_freq * 1.65, pow(k, 0.75))
        mod_phase += TAU * mod_freq / float(sr)
        f *= 1.0 + sin(mod_phase) * mod_depth
        phase1 += TAU * f / float(sr)
        phase2 += TAU * (f * 2.0) / float(sr)
        phase3 += TAU * (f * 2.92) / float(sr)
        var a := clampf(t / attack, 0.0, 1.0)
        var env := a * exp(-t / 0.080)
        var sparkle := rng.randf_range(-1.0, 1.0) * exp(-t / 0.010) * 0.16
        var tone := sin(phase1) * 0.60 + sin(phase2) * 0.20 + sin(phase3) * 0.08
        var sample := (tone * 0.78 + sparkle) * env * 0.78
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _gen_heart_pickup_wav_variant(variant_seed: int) -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.26
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)
    var rng := RandomNumberGenerator.new()
    rng.seed = 7777 + variant_seed
    var detune := rng.randf_range(0.992, 1.008)
    var f1 := 520.0 * detune
    var f2 := 660.0 * detune
    var phase1 := 0.0
    var phase2 := 0.0
    var attack := 0.008
    for i in range(count):
        var t := float(i) / float(sr)
        phase1 += TAU * f1 / float(sr)
        phase2 += TAU * f2 / float(sr)
        var a := clampf(t / attack, 0.0, 1.0)
        var env := a * exp(-t / 0.14)
        var breath := rng.randf_range(-1.0, 1.0) * exp(-t / 0.020) * 0.04
        var tone := sin(phase1) * 0.56 + sin(phase2) * 0.34
        var sample := (tone + breath) * env * 0.60
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _gen_player_hit_wav_variant(variant_seed: int) -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.12
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)

    var rng := RandomNumberGenerator.new()
    rng.seed = 1337 + variant_seed
    var detune := rng.randf_range(0.985, 1.015)
    var f1 := 160.0 * detune
    var f2 := 92.0 * detune
    var phase1 := 0.0
    var phase2 := 0.0
    var attack := 0.0015
    for i in range(count):
        var t := float(i) / float(sr)
        phase1 += TAU * f1 / float(sr)
        phase2 += TAU * f2 / float(sr)
        var a := clampf(t / attack, 0.0, 1.0)
        var env := a * exp(-t / 0.040)
        var thud := (sin(phase1) * 0.55 + sin(phase2) * 0.30) * env
        var grit := rng.randf_range(-1.0, 1.0) * exp(-t / 0.010) * 0.20
        var sample := (thud + grit) * 0.78
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _gen_speed_boost_start_wav_variant(variant_seed: int) -> AudioStreamWAV:
    var sr := 44100
    var dur := 0.28
    var count := int(ceil(dur * float(sr)))
    var data := PackedByteArray()
    data.resize(count * 2)

    var rng := RandomNumberGenerator.new()
    rng.seed = 24680 + variant_seed
    var phase := 0.0
    var mod_phase := 0.0
    var mod_freq := rng.randf_range(9.0, 15.0)
    var attack := 0.004
    for i in range(count):
        var t := float(i) / float(sr)
        var k := clampf(t / dur, 0.0, 1.0)
        var f := lerpf(280.0, 1400.0, pow(k, 0.65))
        mod_phase += TAU * mod_freq / float(sr)
        f *= 1.0 + sin(mod_phase) * 0.015
        phase += TAU * f / float(sr)
        var a := clampf(t / attack, 0.0, 1.0)
        var env := a * exp(-t / 0.18)
        var noise := rng.randf_range(-1.0, 1.0) * 0.55
        var tone := sin(phase) * 0.35
        var hiss := noise * (0.35 + 0.65 * pow(k, 0.85))
        var sample := (tone + hiss) * env * 0.72
        _write_pcm16_mono_sample(data, i, sample)
    return _make_wav(sr, data)

func _make_wav(sample_rate: int, data: PackedByteArray) -> AudioStreamWAV:
    var wav := AudioStreamWAV.new()
    wav.format = AudioStreamWAV.FORMAT_16_BITS
    wav.stereo = false
    wav.mix_rate = sample_rate
    wav.data = data
    return wav

func _write_pcm16_mono_sample(dst: PackedByteArray, index: int, v: float) -> void:
    var s := int(clampf(v, -1.0, 1.0) * 32767.0)
    var u := (s + 65536) % 65536
    dst[index * 2] = u & 0xFF
    dst[index * 2 + 1] = (u >> 8) & 0xFF
