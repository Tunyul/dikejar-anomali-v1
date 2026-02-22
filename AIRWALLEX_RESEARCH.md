# Riset Integrasi Airwallex vs Google Play Billing

**Dokumen Persiapan Teknis & Policy**

## 1. Masalah Utama: Policy Google Play Store

Google memiliki aturan **mutlak** untuk penjualan barang digital (Coins, Gems, Skins, VIP, Remove Ads) di dalam aplikasi Android.

- **Aturan:** Wajib menggunakan **Google Play Billing System**.
- **Larangan:** Dilarang menggunakan metode pembayaran pihak ketiga (seperti Airwallex, Xendit, Midtrans, Transfer Bank langsung) di dalam aplikasi.
- **Resiko:** Jika nekat memasang Airwallex SDK atau WebView payment di dalam game untuk beli Coin:
  - App akan **DITOLAK** saat review rilis.
  - Jika lolos review awal, bisa kena **BANNED** sewaktu-waktu (Suspend App atau Suspend Akun Developer).
  - _Pengecualian:_ Barang fisik (baju, tiket konser) boleh pakai 3rd party. Tapi game kita menjual Coin (digital).

**Referensi:** [Google Play Payments Policy](https://support.google.com/googleplay/android-developer/answer/9858738)

---

## 2. Jika Manager Memaksa (Skenario "Web Payment")

Jika manager tetap ingin menggunakan Airwallex untuk menghindari potongan 30% Google, satu-satunya cara "abu-abu" (masih beresiko tapi sering dipakai game besar) adalah **Web Top-up Center**.

**Flow:**

1.  User tidak beli di dalam App.
2.  User login ke **Website Official** game (di browser Chrome/Safari, bukan di dalam game).
3.  Di Website, user beli Coin pakai Airwallex.
4.  Coin masuk ke akun player (Backend Server mengupdate database player).
5.  Saat user buka game, Coin sudah bertambah.

**Di dalam Godot (Client), persiapan kamu:**

- Tidak ada SDK Airwallex di Godot.
- Hanya tombol "Top Up" yang melempar user ke browser (`OS.shell_open("https://website-game.com/topup")`).

---

## 3. Persiapan Teknis (Integrasi API Airwallex)

Jika akhirnya diputuskan untuk integrasi Airwallex (entah untuk versi Web atau nekat di Android), ini yang perlu kamu pelajari:

### A. Arsitektur

Godot **TIDAK BOLEH** menyimpan `Secret Key` Airwallex.

- **SALAH:** Godot -> Airwallex API.
- **BENAR:** Godot -> Backend Server Kamu (PHP/NodeJS/Python) -> Airwallex API.

### B. Node Godot yang Wajib Dikuasai

Kamu harus menguasai komunikasi HTTP di Godot.

**1. HTTPRequest Node**
Digunakan untuk menembak API Backend kamu (yang nanti nyambung ke Airwallex).

```gdscript
# Contoh Request Link Pembayaran
func request_payment_url(amount: int):
    var url = "https://api.game-kamu.com/create-payment"
    var headers = ["Content-Type: application/json"]
    var body = JSON.stringify({"amount": amount, "user_id": "player_123"})
    $HTTPRequest.request(url, headers, HTTPClient.METHOD_POST, body)
```

**2. JSON Parsing**
Mengolah balasan dari server.

```gdscript
func _on_request_completed(result, response_code, headers, body):
    var json = JSON.parse_string(body.get_string_from_utf8())
    var payment_url = json["payment_link"]
    OS.shell_open(payment_url) # Buka browser untuk bayar
```

**3. Deep Linking (Opsional tapi Penting)**
Agar setelah bayar di browser, user otomatis kembali ke Game.

- Perlu setting di `Export > Android > Intent Filter`.
- Scheme: `anomalyrush://payment_success`

---

## 4. Materi Belajar (Keyword Search)

Untuk mempersiapkan diri, cari tutorial/dokumentasi berikut:

1.  **Godot HTTPRequest Tutorial:** Belajar cara GET/POST data.
2.  **REST API Concepts:** Pahami apa itu Endpoint, Header, Body, JSON.
3.  **Airwallex Payment Intents API:** Baca docs Airwallex bagian "Accept Payments -> Online Payments".
4.  **Backend Basics (Opsional):** Jika kamu solo dev fullstack, pelajari cara buat endpoint sederhana (misal pakai Firebase Functions atau ExpressJS) untuk jembatan ke Airwallex.

## 5. Kesimpulan Strategi

Saat meeting nanti:

1.  Sampaikan dulu **Resiko Banned Google**.
2.  Saran solusi aman: **Google Play Billing** di dalam App, **Airwallex** hanya di Website (Web Top-up).
