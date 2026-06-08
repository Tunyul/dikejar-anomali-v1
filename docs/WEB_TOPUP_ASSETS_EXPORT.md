# Visual Assets Export List for Web Portal

**Version**: 1.3.57-beta
**Date**: 2026-04-12
**Purpose**: Essential visual assets from Anomaly Rush game for web portal UI consistency

---

## Asset Export Table

| Asset Name                          | Godot Path                                                          | Web Usage                                     | Export Note                                                                                                   |
| ----------------------------------- | ------------------------------------------------------------------- | --------------------------------------------- | ------------------------------------------------------------------------------------------------------------- |
| **Character Sprites**               |                                                                     |                                               |                                                                                                               |
| Izan Run Sprite                     | `res://assets/mc/run/idle_run.png`                                  | Landing page animation, character showcase    | 512x512 spritesheet (4x4 grid). Slice to 16 frames or use CSS sprite animation. PNG with transparency.        |
| Izan Jump Sprite                    | `res://assets/mc/jump/sprite-jump-256px-16-v2.png`                  | Action poses, product page dynamics           | Likely 1024x1024 (4x4 grid). Extract first frame for static display. PNG with transparency.                   |
| Izan Attack Sprite                  | `res://assets/mc/attack/sprite-attack-256px-36-3.png`               | Dynamic action scenes, promotional banners    | Check actual dimensions. Use first frame for static icons. PNG with transparency.                             |
| **Character Skins (Profile Icons)** |                                                                     |                                               |                                                                                                               |
| Basic Skin                          | `res://assets/profile/profile_basic.png`                            | Default avatar in profile/shop preview        | ~256x256. Resize to 128x128 for thumbnails. PNG with transparency.                                            |
| Premium Skin                        | `res://assets/profile/profile_premium.png`                          | Premium tier indicator, shop preview          | ~256x256. Maintain aspect ratio. PNG with transparency.                                                       |
| Chef Skin                           | `res://assets/profile/profile_chef.png`                             | Cosmetic shop item preview                    | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Firefighter Skin                    | `res://assets/profile/profile_firefighter.png`                      | Cosmetic shop item preview                    | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Caveman Skin                        | `res://assets/profile/profile_caveman.png`                          | Cosmetic shop item preview                    | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Cat Explorer Skin                   | `res://assets/profile/profile_cat_explorer.png`                     | Bundle preview (Explorer Collection)          | ~256x256. Featured in bundle products. PNG with transparency.                                                 |
| Doctor Skin                         | `res://assets/profile/profile_doctor.png`                           | Cosmetic shop item preview                    | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Robot Skin                          | `res://assets/profile/profile_robot.png`                            | Cosmetic shop item preview                    | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Knight Skin                         | `res://assets/profile/profile_knight.png`                           | Cosmetic shop item preview                    | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Neon Skin                           | `res://assets/profile/profile_neon.png`                             | Premium cosmetic showcase                     | ~256x256. Highlight with glow effect. PNG with transparency.                                                  |
| Shadow/Ninja Skin                   | `res://assets/profile/profile_ninja.png`                            | Premium cosmetic showcase                     | ~256x256. Dark theme compatibility. PNG with transparency.                                                    |
| Astro White Skin                    | `res://assets/profile/profile_astro_white.png`                      | Space-themed cosmetic preview                 | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Astro Blue Skin                     | `res://assets/profile/profile_astro_blue.png`                       | Space-themed cosmetic preview                 | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Pirate Skin                         | `res://assets/profile/profile_pirate.png`                           | Adventure-themed cosmetic preview             | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Wizard Skin                         | `res://assets/profile/profile_wizard.png`                           | Fantasy bundle preview                        | ~256x256. Featured in Fantasy Legends Pack. PNG with transparency.                                            |
| Dragon Skin                         | `res://assets/profile/profile_dragon.png`                           | Fantasy bundle preview                        | ~256x256. Featured in Fantasy Legends Pack. PNG with transparency.                                            |
| Superhero Skin                      | `res://assets/profile/profile_superhero.png`                        | Hero bundle preview                           | ~256x256. Legacy version. PNG with transparency.                                                              |
| Green Dragon Skin                   | `res://assets/profile/profile_green_dragon.png`                     | Alternative dragon variant                    | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Superhero Male Skin                 | `res://assets/profile/profile_superhero_male.png`                   | Hero bundle (male variant)                    | ~256x256. Featured in Hero Collection. PNG with transparency.                                                 |
| Superhero Female Skin               | `res://assets/profile/profile_superhero_female.png`                 | Hero bundle (female variant)                  | ~256x256. Featured in Hero Collection. PNG with transparency.                                                 |
| Witch Skin                          | `res://assets/profile/profile_witch.png`                            | Fantasy bundle preview                        | ~256x256. Featured in Fantasy Legends Pack. PNG with transparency.                                            |
| Pirate V2 Skin                      | `res://assets/profile/profile_pirate_v2.png`                        | Updated pirate variant                        | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| Orc Skin                            | `res://assets/profile/profile_orc.png`                              | Monster-themed cosmetic                       | ~256x256. Optimize to <50KB. PNG with transparency.                                                           |
| **Currency Icons**                  |                                                                     |                                               |                                                                                                               |
| Gem/Diamond Icon                    | `res://assets/diamond_animation/diamond-1024x1024.png`              | Product catalog gem prices, balance display   | 1024x1024. May be animation spritesheet - extract first frame. Resize to 64x64 for UI. PNG with transparency. |
| Coin Icon                           | `res://assets/coin_animation/coin-1024x1024.png`                    | Product catalog coin prices, balance display  | 1024x1024. May be animation spritesheet - extract first frame. Resize to 64x64 for UI. PNG with transparency. |
| Heart Icon                          | `res://assets/icon/icon_heart_96x96.png`                            | Health upgrade indicators, max heart products | 96x96. Resize to 48x48 for compact UI. PNG with transparency.                                                 |
| **Power-Up Icons**                  |                                                                     |                                               |                                                                                                               |
| Magnet Icon                         | `res://assets/icon/icon_magnet_v1_96x96.png`                        | Magnet power-up product cards                 | 96x96. Resize to 64x64 for product cards. PNG with transparency.                                              |
| Magnet Timer Icon                   | `res://assets/icon/icon_magnet_timer_96x96.png`                     | Duration upgrade indicators                   | 96x96. Shows timer overlay. PNG with transparency.                                                            |
| Shield Icon                         | `res://assets/icon/icon_shield.png`                                 | Shield protection product cards               | Check dimensions (~96x96). Resize proportionally. PNG with transparency.                                      |
| Double Coins Icon                   | `res://assets/icon/icon_coinduble_96x96.png`                        | Double coins product cards                    | 96x96. Resize to 64x64 for product cards. PNG with transparency.                                              |
| Coin Multiplier Icon                | `res://assets/icon/icon_coin_multiplier_96x96.png`                  | Gain multiplier upgrade cards                 | 96x96. Resize to 64x64 for product cards. PNG with transparency.                                              |
| Speed Boost Icon                    | `res://assets/icon/icon_boost_96x96.png`                            | Speed boost product cards                     | 96x96. Resize to 64x64 for product cards. PNG with transparency.                                              |
| Gift Box Icon                       | `res://assets/icon/icon_gift_box_96x96.png`                         | Bundle product indicators, special offers     | 96x96. Use for all bundle types. PNG with transparency.                                                       |
| **Border Frames**                   |                                                                     |                                               |                                                                                                               |
| Gold Premium Border                 | `res://assets/border/border_gold_premium.png`                       | Premium avatar frame, rarity indicator        | Overlay image. Apply 5px padding over avatar. PNG with transparency.                                          |
| Silver Premium Border               | `res://assets/border/border_silver_premium.png`                     | Silver tier avatar frame                      | Overlay image. Apply 5px padding over avatar. PNG with transparency.                                          |
| Neon V2 Border                      | `res://assets/border/border_neon_v2.png`                            | Neon-themed avatar frame                      | Overlay image. Apply 5px padding. Glowing effect. PNG with transparency.                                      |
| Shadow V2 Border                    | `res://assets/border/border_shadow_v2.png`                          | Shadow-themed avatar frame                    | Overlay image. Apply 5px padding. Dark aesthetic. PNG with transparency.                                      |
| Fire Border                         | `res://assets/border/border_fire.png`                               | Fire-themed avatar frame                      | Overlay image. Apply 22px padding (larger flame effects). PNG with transparency.                              |
| Kraken Border                       | `res://assets/border/border_kraken.png`                             | Sea monster-themed frame                      | Overlay image. Apply 14px padding. PNG with transparency.                                                     |
| Nature Border                       | `res://assets/border/border_nature.png`                             | Nature-themed avatar frame                    | Overlay image. Apply 14px padding. PNG with transparency.                                                     |
| Cyber Border                        | `res://assets/border/border_cyber.png`                              | Cyberpunk-themed frame                        | Overlay image. Apply 14px padding. PNG with transparency.                                                     |
| **Background Layers (Parallax)**    |                                                                     |                                               |                                                                                                               |
| Sky Background                      | `res://assets/bg/` (browse for sky\*.png)                           | Landing page parallax layer 1 (topmost)       | Wide format (min 2048px width). Seamless horizontal repeat. PNG or WebP for compression.                      |
| Cloud Layer                         | `res://assets/Background/png/` (browse for cloud\*.png)             | Parallax layer 2                              | Wide format with transparency. Slower scroll than sky. PNG with transparency.                                 |
| Mountain Layer                      | `res://assets/Background/png/` (browse for mountain\*.png)          | Parallax layer 3                              | Wide format. Medium scroll speed. PNG or WebP.                                                                |
| Hills Layer                         | `res://assets/Background/png/` (browse for hill\*.png)              | Parallax layer 4                              | Wide format. Faster scroll than mountains. PNG or WebP.                                                       |
| Ground Tile                         | `res://assets/Tiles/` (browse terrain tiles)                        | Bottom parallax layer, decorative             | Tile size (64x64 or 128x128). Repeat pattern. PNG with transparency.                                          |
| **UI Elements**                     |                                                                     |                                               |                                                                                                               |
| Play Button Texture                 | `res://assets/tombol/` (screenshot from MainMenu)                   | CTA button styling reference                  | ~300x80. Green gradient style. Use as CSS reference, not direct image.                                        |
| Shop Button Texture                 | `res://assets/tombol/` (screenshot from MainMenu)                   | Shop link styling reference                   | ~300x80. Blue gradient style. Use as CSS reference.                                                           |
| Settings Button Texture             | `res://assets/tombol/` (screenshot from MainMenu)                   | Settings link styling reference               | ~300x80. Purple gradient style. Use as CSS reference.                                                         |
| Indonesian Flag                     | `res://assets/icon/icon_flag_INA.png`                               | Language switcher (ID)                        | Small icon (~48x48). Resize to 32x32 for UI. PNG with transparency.                                           |
| English Flag                        | `res://assets/icon/icon_flag_US.png`                                | Language switcher (EN)                        | Small icon (~48x48). Resize to 32x32 for UI. PNG with transparency.                                           |
| Chinese Flag                        | `res://assets/icon/icon_flag_CN.png`                                | Language switcher (ZH)                        | Small icon (~48x48). Resize to 32x32 for UI. PNG with transparency.                                           |
| **Fonts**                           |                                                                     |                                               |                                                                                                               |
| Fredoka Bold                        | `res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf`  | Headings, titles, large text                  | TTF format. Convert to WOFF2 for web optimization. License: SIL OFL (free commercial use).                    |
| Nunito Regular                      | `res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf` | Body text, labels, descriptions               | TTF format. Convert to WOFF2 for web optimization. License: SIL OFL (free commercial use).                    |
| **Branding**                        |                                                                     |                                               |                                                                                                               |
| Game Logo                           | `res://logo.png`                                                    | Header logo, favicon, social media            | High resolution (1024px+ width). Create SVG version if possible. PNG with transparency.                       |
| App Icon                            | `res://assets/icon/icon_apk.png`                                    | Favicon, app store links                      | 192x192. Also export 32x32 and 16x16 for favicon.ico. PNG with transparency.                                  |

---

## Export Priority Levels

### P0 - Critical (Must Have)

- Gem Icon, Coin Icon
- Izan Run Sprite (first frame)
- Fredoka Bold, Nunito Regular fonts
- Game Logo
- All currency/power-up icons used in products

### P1 - Important (Should Have)

- All 24 character skins
- All 12 border frames
- Background layers (at least sky + hills)
- Language flags

### P2 - Nice to Have

- Full animation spritesheets
- All button textures
- Effect particles

---

## Export Automation Script

Create `tools/export_web_assets.gd` in Godot project:

```gdscript
extends EditorScript

func _run():
    var export_dir = "res://../web-portal/public/assets/"

    # Create directory structure
    var dirs = [
        "characters",
        "icons/currency",
        "icons/powerups",
        "icons/skins",
        "icons/ui",
        "borders",
        "backgrounds",
        "fonts",
        "ui",
        "branding"
    ]

    for dir in dirs:
        var path = export_dir + dir
        if not DirAccess.dir_exists_absolute(path):
            DirAccess.make_dir_recursive_absolute(path)
            print("Created: ", path)

    # Export critical assets
    export_asset("res://assets/diamond_animation/diamond-1024x1024.png",
                 export_dir + "icons/currency/gem_icon.png")

    export_asset("res://assets/coin_animation/coin-1024x1024.png",
                 export_dir + "icons/currency/coin_icon.png")

    export_asset("res://assets/mc/run/idle_run.png",
                 export_dir + "characters/izan_run_spritesheet.png")

    export_asset("res://logo.png",
                 export_dir + "branding/logo.png")

    # Export fonts
    export_asset("res://assets/font/Fredoka Nunito/Fredoka/static/Fredoka-Bold.ttf",
                 export_dir + "fonts/Fredoka-Bold.ttf")

    export_asset("res://assets/font/Fredoka Nunito/Nunito/static/Nunito-Regular.ttf",
                 export_dir + "fonts/Nunito-Regular.ttf")

    # Export all skins
    var skin_files = [
        "profile_basic.png", "profile_premium.png", "profile_chef.png",
        "profile_firefighter.png", "profile_caveman.png", "profile_cat_explorer.png",
        "profile_doctor.png", "profile_robot.png", "profile_knight.png",
        "profile_neon.png", "profile_ninja.png", "profile_astro_white.png",
        "profile_astro_blue.png", "profile_pirate.png", "profile_wizard.png",
        "profile_dragon.png", "profile_superhero.png", "profile_green_dragon.png",
        "profile_superhero_male.png", "profile_superhero_female.png",
        "profile_witch.png", "profile_pirate_v2.png", "profile_orc.png"
    ]

    for skin_file in skin_files:
        var source = "res://assets/profile/" + skin_file
        var dest = export_dir + "icons/skins/" + skin_file
        export_asset(source, dest)

    # Export all borders
    var border_files = [
        "border_gold_premium.png", "border_silver_premium.png",
        "border_neon_v2.png", "border_shadow_v2.png", "border_fire.png",
        "border_kraken.png", "border_nature.png", "border_cyber.png"
    ]

    for border_file in border_files:
        var source = "res://assets/border/" + border_file
        var dest = export_dir + "borders/" + border_file
        export_asset(source, dest)

    # Export power-up icons
    var powerup_icons = [
        ["icon_magnet_v1_96x96.png", "magnet.png"],
        ["icon_magnet_timer_96x96.png", "magnet_timer.png"],
        ["icon_shield.png", "shield.png"],
        ["icon_coinduble_96x96.png", "double_coins.png"],
        ["icon_coin_multiplier_96x96.png", "coin_multiplier.png"],
        ["icon_boost_96x96.png", "speed_boost.png"],
        ["icon_heart_96x96.png", "heart.png"],
        ["icon_gift_box_96x96.png", "gift_box.png"]
    ]

    for icon_pair in powerup_icons:
        var source = "res://assets/icon/" + icon_pair[0]
        var dest = export_dir + "icons/powerups/" + icon_pair[1]
        export_asset(source, dest)

    # Export flags
    var flags = [
        ["icon_flag_INA.png", "id.png"],
        ["icon_flag_US.png", "en.png"],
        ["icon_flag_CN.png", "zh.png"]
    ]

    for flag_pair in flags:
        var source = "res://assets/icon/" + flag_pair[0]
        var dest = export_dir + "ui/flags/" + flag_pair[1]
        export_asset(source, dest)

    print("\n✅ Web assets exported to: ", export_dir)
    print("Next step: Optimize images with TinyPNG/ImageOptim")

func export_asset(source: String, dest: String):
    if not ResourceLoader.exists(source):
        print("⚠️  Source not found: ", source)
        return

    var file = FileAccess.open(source, FileAccess.READ)
    if not file:
        print("❌ Cannot read: ", source)
        return

    var data = file.get_buffer(file.get_length())
    file.close()

    var dest_file = FileAccess.open(dest, FileAccess.WRITE)
    if not dest_file:
        print("❌ Cannot write to: ", dest)
        return

    dest_file.store_buffer(data)
    dest_file.close()
    print("✓ Exported: ", source.get_file(), " -> ", dest)
```

**Run from Godot Editor**: Open script → File → Run

---

## Optimization Guidelines

### Image Compression

- Use **TinyPNG.com** or **ImageOptim** (Mac) / **FileOptimizer** (Windows)
- Target sizes:
  - Icons: < 20KB each
  - Skins: < 50KB each
  - Borders: < 30KB each
  - Backgrounds: < 200KB each (use WebP)
  - Spritesheets: < 100KB each

### Format Selection

- **PNG**: Icons, skins, borders (transparency required)
- **WebP**: Background layers (better compression, modern browsers)
- **WOFF2**: Fonts (smaller than TTF)
- **SVG**: Simple shapes (if converting from PNG)

### Responsive Images

Create multiple sizes for key assets:

```
icons/currency/
├── gem_icon@1x.png   (64x64)
├── gem_icon@2x.png   (128x128)
└── gem_icon@3x.png   (192x192)
```

### Lazy Loading Strategy

- Load immediately: Logo, currency icons, primary CTA buttons
- Load on scroll: Character skins, border previews
- Load on interaction: Full spritesheets, background layers

---

## CSS Integration Tokens

```css
:root {
  /* Colors from game */
  --color-primary: #ffcc00;
  --color-secondary: #00aeef;
  --color-accent: #ff5722;
  --color-text: #333333;
  --color-border: #000000;

  /* Fonts */
  --font-heading: "Fredoka", sans-serif;
  --font-body: "Nunito", sans-serif;
}

/* Font imports */
@font-face {
  font-family: "Fredoka";
  src: url("/assets/fonts/Fredoka-Bold.woff2") format("woff2");
  font-weight: bold;
}

@font-face {
  font-family: "Nunito";
  src: url("/assets/fonts/Nunito-Regular.woff2") format("woff2");
  font-weight: normal;
}
```

---

## Missing Assets - Manual Check Required

Browse these directories in Godot editor and note exact filenames:

1. **Background layers**: `res://assets/Background/png/` and `res://assets/bg/`
   - Look for: sky, clouds, mountains, hills
   - Update table with exact paths

2. **Ground tiles**: `res://assets/Tiles/`
   - Find main terrain tile used in gameplay

3. **Button textures**: `res://assets/tombol/`
   - Screenshot actual buttons from MainMenu scene if PNGs unavailable

---

**End of Asset Export Documentation**
