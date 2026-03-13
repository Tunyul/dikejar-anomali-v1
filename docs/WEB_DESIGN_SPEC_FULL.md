# ANOMALY RUSH - WEB DESIGN & ASSET GUIDELINES
**Status: MANDATORY (Wajib diikuti oleh Tim Web)**

Dokumen ini dibuat berdasarkan analisis visual langsung dari aset in-game. Website tidak boleh menggunakan style "Corporate/SaaS". Website harus terasa seperti ekstensi dari game itu sendiri.

---

## 1. CORE VISUAL IDENTITY (Identitas Visual Utama)

### A. Color Palette (Palet Warna)
Gunakan kode warna ini (atau yang mendekati) untuk elemen UI:

| Elemen | Deskripsi Visual | Estimasi Hex Code |
| :--- | :--- | :--- |
| **Primary Action** | **Tombol Hijau Glossy** (Start, Ambil) | `#76D629` (Top) to `#5BB51E` (Bottom) |
| **Secondary Action** | **Tombol Biru Glossy** (Shop, Ganti Avatar) | `#42A5F5` (Top) to `#1E88E5` (Bottom) |
| **Tertiary Action** | **Tombol Ungu Glossy** (Settings, Ganti Border) | `#7E57C2` (Top) to `#5E35B1` (Bottom) |
| **Accent / Highlight** | **Kuning Emas** (Coin, Judul Pop-up, Tombol Close) | `#FFCA28` (Top) to `#FFB300` (Bottom) |
| **Panel Background** | **Hijau Neon Transparan** (Misi, Pengaturan) | `#B2FF59` (Opacity 90%) dengan Border Kuning/Oranye |
| **Dark Panel** | **Hitam Transparan** (Shop Item, Hadiah Season) | `#212121` (Opacity 85%) dengan Border Abu-abu |
| **Text Color** | Putih dengan Outline Hitam (Stroke) | `#FFFFFF` (Text), `#000000` (Stroke 2-3px) |

### B. Typography (Tipografi)
- **Font Utama**: Wajib menggunakan font yang **Rounded, Bold, dan Cartoonish**.
- **Referensi**: Mirip dengan **Fredoka One**, **Nunito Rounded (Black/ExtraBold)**, atau **Baloo 2**.
- **Style Teks**:
  - Judul Pop-up (misal: "Pengaturan", "Misi"): Warna Kuning/Putih dengan **Outline Hitam Tebal**.
  - Teks Tombol: Putih Polos dengan Drop Shadow tipis.

---

## 2. UI COMPONENT BREAKDOWN (Bedah Komponen UI)

### A. Buttons (Tombol) - KRUSIAL!
Jangan pernah membuat tombol flat (datar). Semua tombol utama harus memiliki karakteristik:
1.  **Shape**: Rounded Rectangle (Sangat tumpul, hampir seperti kapsul).
2.  **Efek 3D**:
    -   Bagian atas lebih terang (Highlight).
    -   Bagian bawah lebih gelap (Shadow/Depth).
    -   Ada "lip" atau ketebalan di bagian bawah tombol (efek pencetan).
3.  **Icon**: Icon putih sederhana (Outline tebal) di tengah.

### B. Panels & Containers (Wadah Konten)
Ada 2 jenis panel utama yang harus dibuat di web:

**Type 1: The "Jelly" Panel (Untuk Misi, Pengaturan)**
-   **Background**: Hijau Muda Cerah (Gradient halus).
-   **Border**: Tebal, warna Oranye/Kuning Emas.
-   **Header**: Judul panel menempel di atas border (floating title).
-   **Close Button**: Tombol 'X' bulat warna Oranye di pojok kanan atas (keluar dari frame).

**Type 2: The "Dark" Panel (Untuk Shop, Inventory, Profil)**
-   **Background**: Hitam/Abu-abu gelap (#1F2937) dengan sedikit transparansi.
-   **Border**: Garis tipis warna Emas atau Kuning (#FFC107).
-   **Card Item**: Setiap item (misal: paket koin) ada di dalam kotak abu-abu gelap dengan sudut rounded.

### C. Progress Bars (Bar Proses)
-   **Wadah**: Abu-abu gelap / Hitam transparan.
-   **Isi (Fill)**: Kuning Emas atau Hijau Neon.
-   **Bentuk**: Rounded full (kapsul).
-   **Label**: Teks persentase/angka di tengah bar.

### D. HUD & Gameplay Elements (Elemen In-Game)
-   **Health Bar Style**: Bar merah tebal dengan sudut rounded, bisa diadaptasi untuk progress bar yang sifatnya "Urgent" atau "Limit".
-   **Floating Action Buttons (FAB)**: Tiru style tombol "Jump" (Hijau Transparan) dan "Attack" (Oranye Transparan) untuk tombol aksi melayang di versi mobile web (misal: tombol "Top Up Cepat" atau "Chat Support").
-   **Environment Colors**: Gunakan warna Coklat Tanah (#8D6E63) dan Hijau Rumput (#66BB6A) untuk bagian Footer website atau batas bawah container.

---

## 3. PAGE SPECIFIC INSTRUCTIONS (Instruksi Per Halaman)

### Halaman Utama (Homepage)
-   **Background**: WAJIB menggunakan gambar pemandangan bukit hijau berlayer + awan kartun + langit biru (Lihat screenshot Main Menu).
-   **Layout**: Logo "Anomaly Rush" besar di tengah atas. Menu navigasi (Top Up, Profil, Misi) menggunakan gaya tombol kotak besar di bagian bawah (seperti menu game).

### Halaman Top Up (Shop)
-   **Referensi**: Screenshot "Toko".
-   **Background**: Pattern biru muda dengan ikon-ikon samar (tulang, kotak, dll) atau Polos Biru Langit.
-   **Grid Item**: Tampilkan paket top-up dalam Grid Card gelap (Type 2 Panel).
-   **Harga**: Tampilkan harga dengan tombol kuning di bagian bawah setiap kartu.

### Halaman Profil
-   **Referensi**: Screenshot "Profil Pemain".
-   **Layout**:
    -   Kiri: Avatar Besar dalam bingkai (frame).
    -   Kanan: Stats (Level, XP, Trophy).
    -   Bawah: Tombol aksi (Ganti Avatar, Edit Profil).
-   **Background Pop-up**: Gelap transparan (Modal Overlay).

---

## 4. ASSETS HANDOVER (Serah Terima Aset)
Developer Web, harap gunakan placeholder dengan warna yang sesuai panduan ini sampai aset final (PNG/SVG) dikirimkan.
-   **JANGAN** gunakan aset default Bootstrap/Tailwind/Material UI.
-   **JANGAN** gunakan shadow yang terlalu soft (blur). Gunakan shadow yang tajam/solid untuk kesan kartun.
-   **JANGAN** gunakan font Serif atau font kaku (Arial/Roboto).

*Gunakan screenshot yang dilampirkan sebagai "Kitab Suci" desain Anda.*
