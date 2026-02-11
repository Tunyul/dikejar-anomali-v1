# 🤖 Panduan Kolaborasi AI (AI Collaboration Guide)

Dokumen ini berisi standar dan instruksi bagi AI (Artificial Intelligence) yang bekerja pada proyek **Anomaly Rush!**. Tujuannya adalah untuk menjaga konsistensi kode, riwayat Git yang bersih, dan integritas proyek.

---

## 🛠️ Standar Operasional AI

### 1. Konvensi Commit (Conventional Commits)
Setiap commit yang dilakukan oleh AI harus mengikuti format:
`<type>: <description>`

**Jenis (Type):**
- `feat`: Fitur baru.
- `fix`: Perbaikan bug.
- `docs`: Perubahan dokumentasi.
- `style`: Perubahan format (white-space, formatting, missing semi-colons, dll).
- `refactor`: Perubahan kode yang tidak memperbaiki bug atau menambah fitur.
- `perf`: Perubahan kode untuk meningkatkan performa.
- `chore`: Perubahan pada build process atau tools tambahan.

**Contoh:** `feat: implement magnet power-up logic in player.gd`

### 2. Strategi Branching
AI dilarang melakukan push langsung ke `main` kecuali ada instruksi eksplisit.
- **`dev`**: Branch utama untuk pengembangan harian.
- **`beta`**: Branch untuk testing dan stabilisasi sebelum rilis.
- **`main`**: Branch produksi (hanya untuk versi stabil/tags).

### 3. Integritas Kode Godot
Sebelum melakukan perubahan, AI wajib:
- Membaca file skrip terkait secara utuh untuk memahami konteks.
- Menjaga konsistensi gaya penulisan GDScript (static typing, PascalCase untuk Class, snake_case untuk variable).
- Memastikan tidak merusak struktur `.tscn` (Scene) saat mengedit via teks.

### 4. Prosedur Push & Sinkronisasi
Setelah melakukan tugas, AI harus:
1. Melakukan `git add` hanya pada file yang relevan.
2. Melakukan commit dengan pesan yang jelas.
3. Melakukan sinkronisasi antar branch (dev -> beta -> main) jika diminta.
4. Membuat Git Tag jika mencapai versi stabil.

---

## 📜 Instruksi Khusus untuk AI
"Wahai AI, saat Anda bekerja di proyek ini, utamakan efisiensi dan kejelasan. Jangan ragu untuk memperbaiki dokumentasi jika Anda menemukan ketidaksesuaian antara kode dan penjelasan yang ada."

---
© 2026 **Rakhasa Team** - Dokumentasi Standar AI
