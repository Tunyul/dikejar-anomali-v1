# Web Top-Up & Profile - Frontend Specification

Dokumen ini berisi spesifikasi teknis dan desain untuk pengembangan frontend website top-up game "Dikejar Anomali".

## 1. Konsep & Identitas Visual (UI/UX)

### Tema
- **Fantasy & Adventure**: Nuansa petualangan seru dengan elemen fantasi (Naga, Penyihir, Bajak Laut).
- **Playful & Friendly**: Menggunakan font bulat (Fredoka) dan warna cerah sesuai target audiens game runner.
- **Mobile-First**: Desain harus diutamakan untuk layar HP (vertical scroll), baru kemudian desktop.

### Palet Warna (Sesuai Aset Game)
| Tipe | Kode Warna | Penggunaan |
| :--- | :--- | :--- |
| **Primary** | `#FFCC00` (Yellow) | Tombol aksi utama (Beli, Top Up) - sesuai tombol Shop di game |
| **Secondary** | `#00AEEF` (Sky Blue) | Background halaman utama / Header |
| **Accent** | `#FF5722` (Orange) | Badge promo, notifikasi, highlight |
| **Text** | `#333333` (Dark Gray) | Teks utama agar mudah dibaca (kontras dengan background cerah) |
| **Border** | `#000000` (Black) | Outline tebal pada card/tombol (style kartun) |

### Tipografi
- **Headings**: `Fredoka` atau `Nunito` (Rounded, Bold, Playful).
- **Body**: `Nunito` atau `Poppins` (Clean, rounded sans-serif).

### Komponen UI Utama
- **Card Paket**: Box dengan outline hitam tebal, background cerah, dan rounded corner besar.
- **Button**: Style tombol 3D kartun (ada shadow bawah), warna kuning/oranye.
- **Avatar Frame**: Support tampilan frame unik (Fire, Neon, Kraken, Gold) di halaman profil.

---

## 2. User Flow & Journey

### A. Login (Entry Point)
1. User masuk ke halaman utama.
2. Input form: `Player ID` atau `Email`.
3. Tombol "Masuk".
4. **Validasi**: Cek input tidak boleh kosong.
5. **Action**: `POST /auth/login`.
6. **Output**: Jika sukses, simpan token & redirect ke Dashboard. Jika gagal, muncul toast error.

### B. Dashboard Profile
1. Header menampilkan:
   - Avatar & Nama Player.
   - Saldo Coin & Gems (Auto-refresh dari `GET /wallet/balance`).
2. Tampilkan riwayat transaksi terakhir (list ringkas).
3. Tombol CTA besar: **"Top Up Sekarang"**.

### C. Top Up Flow
1. User masuk halaman Top Up (`/products`).
2. Tampilkan daftar paket dalam grid (2 kolom di mobile).
3. User klik paket -> Muncul rincian harga.
4. User klik "Bayar".
5. **Action**: `POST /topup/create-order`.
6. **Payment**:
   - Redirect user ke `payment_url` (Midtrans/Xendit/Airwallex).
   - ATAU tampilkan QRIS di modal (jika support).
7. **Waiting State**: Tampilkan loading spinner / "Menunggu Pembayaran".
8. **Polling**: Frontend cek status berkala tiap 5 detik ke `GET /topup/order/:id`.
9. **Success**:
   - Tampilkan animasi sukses.
   - Update saldo di header otomatis.
   - Tombol "Kembali ke Dashboard".

---

## 3. Spesifikasi Teknis

### Tech Stack Rekomendasi
- **Framework**: Next.js (React) v14+ (App Router).
- **Styling**: Tailwind CSS (untuk kecepatan dev).
- **State Management**: React Query / TanStack Query (wajib untuk handling server state & caching).
- **Icons**: Lucide React atau Heroicons.

### Security Frontend
- **Auth**: Simpan JWT di `httpOnly` cookie (preferable) atau `localStorage`.
- **Protection**:
  - Rate limit klik tombol "Bayar" (debounce/throttle).
  - Validasi input di client sebelum kirim ke API.
  - Jangan pernah menyimpan *secret key* payment gateway di kode frontend.

---

## 4. API Integration Guide

Gunakan kontrak endpoint berikut untuk integrasi dengan Backend:

### Auth
- **Login**: `POST /api/v1/auth/login`
  - Body: `{ "identifier": "player123" }`
  - Response: `{ "token": "...", "user": { ... } }`

### Profile & Wallet
- **Get Profile**: `GET /api/v1/profile`
  - Headers: `Authorization: Bearer <token>`
- **Get Balance**: `GET /api/v1/wallet/balance`
  - Response: `{ "coins": 1000, "gems": 50 }`

### Transaction
- **List Products**: `GET /api/v1/products`
  - Response: `[{ "id": "gem_100", "name": "100 Gems", "price": 15000, "currency": "IDR" }]`
- **Create Order**: `POST /api/v1/topup/create-order`
  - Body: `{ "product_id": "gem_100" }`
  - Response: `{ "order_id": "trx_abc", "payment_url": "https://gateway..." }`
- **Check Status**: `GET /api/v1/topup/order/:order_id`
  - Response: `{ "status": "pending" | "paid" | "failed" }`
