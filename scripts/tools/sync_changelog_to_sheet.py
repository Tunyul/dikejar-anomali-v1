import re
import requests
import time
from datetime import datetime

# Konfigurasi
CHANGELOG_PATH = "CHANGELOG.md"
WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbyeIQqu0D5NaAS3ig7fQ5-ENpNnplu1HuQ5ix_MYLQ88ZResOLrbwgg5k92Hx4FZcGD9Q/exec"

def parse_changelog(file_path):
    with open(file_path, "r", encoding="utf-8") as f:
        content = f.read()

    # Regex untuk menangkap versi dan tanggal: ## [1.3.57-beta] - 2026-03-09
    version_pattern = re.compile(r"## \[(.*?)\] - (\d{4}-\d{2}-\d{2})")

    entries = []
    current_date = None
    current_version = None

    for line in content.split("\n"):
        line = line.strip()

        # Cek Header Versi
        match = version_pattern.match(line)
        if match:
            current_version = match.group(1)
            current_date = match.group(2)
            # Format ulang tanggal agar cantik: 2026-03-09 -> 09 Mar 2026
            dt = datetime.strptime(current_date, "%Y-%m-%d")
            current_date = dt.strftime("%d %b %Y")
            continue

        # Cek Item List (Bulleted)
        if line.startswith("- ") and current_date:
            description = line[2:].strip()
            # Bersihkan markdown bold/italic jika ada
            description = description.replace("**", "").replace("*", "")

            entries.append({
                "date": current_date,
                "version": current_version,
                "message": description,
                "jenis": "Coding", # Default karena dari changelog
                "status": "✅ Completed" # Karena sudah masuk changelog berarti done
            })

    # Balik urutan agar yang terlama (bawah) dikirim duluan
    return entries[::-1]

def sync_to_sheet(entries):
    total = len(entries)
    print(f"🔄 Found {total} entries in Changelog. Starting sync...")

    for i, entry in enumerate(entries):
        payload = {
            "message": entry["message"],
            "status": entry["status"],
            "jenis": entry["jenis"],
            # Kita bisa kirim tanggal custom jika Apps Script mendukung,
            # tapi script kita sekarang pakai tanggal hari ini.
            # Jadi kita kirim tanggal asli sebagai bagian dari pesan atau ubah script GS.
            # SEMENTARA: Kita kirim pesan format "[Tanggal Asli] Pesan" agar jelas di sheet.
            "message": f"[{entry['version']}] {entry['message']}"
        }

        # Kirim Request
        try:
            response = requests.post(WEBHOOK_URL, json=payload)
            if response.status_code == 200:
                print(f"[{i+1}/{total}] ✅ Sent: {entry['date']} - {entry['message'][:30]}...")
            else:
                print(f"[{i+1}/{total}] ❌ Failed: {response.text}")
        except Exception as e:
            print(f"[{i+1}/{total}] ❌ Error: {str(e)}")

        # Delay sedikit agar tidak kena rate limit Google
        time.sleep(1.5)

    print("\n🎉 Sync Completed!")

if __name__ == "__main__":
    data = parse_changelog(CHANGELOG_PATH)
    sync_to_sheet(data)
