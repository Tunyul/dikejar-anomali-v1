# Panduan Implementasi Google Play Billing

Untuk mengaktifkan fitur pembayaran (In-App Purchase), ikuti langkah-langkah berikut:

## 1. Install Plugin

Karena fitur ini butuh library Android asli, Anda harus menginstall plugin **Godot Google Play Billing**.

1. Buka Godot Editor.
2. Klik menu **AssetLib** di bagian atas.
3. Cari **"Godot Google Play Billing"**.
4. Download dan Install.
5. Masuk ke **Project > Project Settings > Plugins**, centang **Enable** pada plugin tersebut.

## 2. Konfigurasi Export

1. Buka **Project > Export**.
2. Pilih preset **Android**.
3. Di tab **Options**, scroll ke bawah cari bagian **Gradle Build**.
4. Pastikan **Use Gradle Build** dicentang (aktif).
5. (Opsional) Jika ada opsi untuk memilih plugin di export settings, pastikan `GodotGooglePlayBilling` terpilih.

## 3. Setup Produk di Google Play Console

Agar `BillingManager.gd` bisa mengambil data harga, produk harus dibuat dulu di console.

1. Masuk ke **Google Play Console**.
2. Pilih aplikasi **Anomaly Rush!**.
3. Di menu kiri, scroll ke bawah ke bagian **Monetize > Products > In-app products**.
4. Klik **Create product**.
5. Masukkan **Product ID** yang SAMA PERSIS dengan yang ada di script `BillingManager.gd`.

   Daftar Product ID saat ini (bisa diedit di script):
   - `remove_ads` (Non-consumable / Sekali beli)
   - `coin_pack_small` (Consumable / Bisa beli berulang)
   - `coin_pack_medium`
   - `coin_pack_large`

6. Isi Nama, Deskripsi, dan Harga.
7. Klik **Save** dan **Activate**.

## 4. Cara Pakai di Game Code

Script `BillingManager` sudah otomatis jalan (Autoload). Anda tinggal panggil fungsinya dari menu toko.

**Contoh di tombol Beli Koin:**

```gdscript
func _on_buy_button_pressed():
    BillingManager.purchase("coin_pack_small")
```

**Mendengarkan Hasil Pembelian:**

```gdscript
func _ready():
    BillingManager.purchase_successful.connect(_on_purchase_success)
    BillingManager.purchase_failed.connect(_on_purchase_fail)

func _on_purchase_success(product_id):
    if product_id == "coin_pack_small":
        Global.add_coins(100)
    elif product_id == "remove_ads":
        AdManager.remove_ads()

func _on_purchase_fail(error):
    print("Gagal beli: ", error)
```

---

**Catatan Penting:**
Fitur ini **HANYA BERJALAN DI HP ANDROID** yang installasinya ditandatangani dengan keystore yang sama dengan yang diupload ke Play Console, dan akun testnya sudah terdaftar di License Testing. Tidak akan jalan di Editor.
