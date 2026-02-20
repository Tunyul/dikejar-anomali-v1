# Panduan Penggunaan AdMob (Anomaly Rush!)

Dokumen ini menjelaskan cara menggunakan sistem iklan AdMob yang telah diintegrasikan ke dalam game menggunakan `AdManager`.

## 1. Konsep Dasar

Semua fungsi iklan dikelola secara terpusat oleh **Autoload** bernama `AdManager`. Anda dapat memanggil fungsi-fungsi ini dari script manapun di dalam game.

### Jenis Iklan yang Tersedia:

1.  **Banner**: Iklan kecil di bagian bawah layar (selalu muncul di menu utama/gameplay jika diinginkan).
2.  **Interstitial**: Iklan layar penuh yang bisa di-skip (cocok untuk jeda antar level atau Game Over).
3.  **Rewarded**: Iklan video pendek yang **tidak bisa di-skip** dan memberikan hadiah kepada pemain (Koin ganda, Nyawa tambahan).

---

## 2. Banner Ads (Iklan Spanduk)

Banner otomatis dimuat saat game dimulai jika Anda memanggilnya di `MainMenu`.

**Cara Menampilkan Banner:**

```gdscript
AdManager.show_banner()
```

**Cara Menyembunyikan Banner:**

```gdscript
AdManager.hide_banner()
```

> **Catatan:** Banner sudah dikonfigurasi menggunakan ukuran standar `320x50` agar otomatis berada di posisi tengah bawah (Bottom Center) dan tidak menutupi tombol kontrol.

---

## 3. Interstitial Ads (Iklan Jeda/Game Over)

Gunakan ini saat momen perpindahan scene atau saat Game Over, di mana pemain tidak mengharapkan hadiah khusus.

**Contoh Implementasi: Saat Game Over (Ingin Lanjut / Restart)**

Di dalam script `GameManager.gd` atau `GameOverMenu.gd`:

```gdscript
func _on_restart_button_pressed():
    # Cek apakah iklan interstitial siap
    if AdManager.is_interstitial_ready():
        # Tampilkan iklan, lalu restart game setelah iklan ditutup
        AdManager.show_interstitial()

        # Opsional: Hubungkan signal untuk restart setelah iklan ditutup
        # (Jika Anda ingin restart HANYA setelah iklan selesai)
        # Namun biasanya langsung restart di background juga tidak masalah untuk interstitial
        get_tree().reload_current_scene()
    else:
        # Jika iklan belum siap/gagal load, langsung restart
        get_tree().reload_current_scene()
```

Atau cara yang lebih rapi menggunakan `await`:

```gdscript
func _on_restart_button_pressed():
    if AdManager.is_interstitial_ready():
        AdManager.show_interstitial()
        # Tunggu sampai iklan ditutup (perlu implementasi signal tambahan di AdManager jika ingin strict)
        # Untuk simplifikasi, interstitial biasanya bersifat "fire and forget" visual

    get_tree().reload_current_scene()
```

---

## 4. Rewarded Ads (Iklan Berhadiah)

Gunakan ini untuk memberikan item premium atau koin ganda.

**Contoh Implementasi: Klaim 2x Reward Coin**

Di dalam script `GameOverMenu.gd` atau `LevelComplete.gd`:

1.  **Hubungkan Signal di `_ready()`**:
    Anda perlu mendengarkan signal `reward_granted` dari `AdManager` untuk tahu kapan harus memberikan hadiah.

    ```gdscript
    func _ready():
        # Hubungkan signal reward_granted ke fungsi lokal _on_reward_received
        AdManager.reward_granted.connect(_on_reward_received)
    ```

2.  **Tombol Klaim 2x Coin**:

    ```gdscript
    func _on_double_coin_button_pressed():
        if AdManager.is_rewarded_ready():
            # Panggil iklan dengan "reason" tertentu agar kita tahu hadiah apa yang harus diberi
            AdManager.show_rewarded("double_coins")
        else:
            # Beritahu user iklan belum siap
            print("Iklan belum siap, coba lagi nanti!")
    ```

3.  **Fungsi Penerima Hadiah**:

    ```gdscript
    func _on_reward_received(reason: String):
        if reason == "double_coins":
            # Logika penggandaan koin
            var current_coins = GameManager.current_level_coins
            GameManager.add_coins(current_coins) # Tambah lagi sejumlah yang didapat (jadi 2x)

            print("Selamat! Koin Anda menjadi: ", GameManager.current_level_coins)

            # Update UI koin di sini (jika ada label)
            $CoinLabel.text = str(GameManager.current_level_coins)

            # Matikan tombol agar tidak bisa klaim 2x lagi
            $DoubleCoinButton.disabled = true
    ```

---

## 5. Troubleshooting (Masalah Umum)

- **Iklan Tidak Muncul di Editor:**
  Hanya **Dummy Banner** yang akan muncul di editor PC. Iklan asli (Interstitial/Rewarded) hanya muncul di perangkat Android/iOS asli.

- **"Unable to obtain JavascriptEngine" di Android:**
  Ini biasanya terjadi jika versi library AdMob terlalu baru untuk WebView HP lama, atau jika ada AdBlocker (seperti AdAway).
  - **Solusi:** Pastikan AdBlocker mati. Versi library sudah diset ke `23.0.0` yang stabil.

- **Banner Menutupi Tombol:**
  Pastikan `AdManager.gd` menggunakan `AdSize.BANNER` (bukan ukuran custom). Ini akan memaksa ukuran 320x50 yang aman untuk layout mobile landscape.
