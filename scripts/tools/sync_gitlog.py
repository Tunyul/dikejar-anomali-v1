import subprocess
import json
import time
import sys
import re
from datetime import datetime

# Konfigurasi
CHANGELOG_PATH = "CHANGELOG.md"
WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbzR89AWgAfoMi7Va1D_IW1oM7A8c2Lq9T4vrV-3W9UKFLOnvvYOoJGHxw6rft7tR3nN5w/exec"

def print_progress(iteration, total, current_task):
    percent = "{0:.1f}".format(100 * (iteration / float(total)))
    filled_length = int(40 * iteration // total)
    bar = '█' * filled_length + '-' * (40 - filled_length)
    # Tampilkan task singkat di progress bar
    display_task = (current_task[:30] + '..') if len(current_task) > 30 else current_task
    print(f"[{iteration}/{total}] {percent}% |{bar}| Syncing: {display_task}", flush=True)

# --- 1. AMBIL SEMUA ITEM (GIT + MANUAL) ---
def get_all_items():
    all_items = []

    # A. GIT LOG
    cmd = ["git", "log", "--pretty=format:%h|%ad|%s", "--date=format:%d %b %Y"]
    result = subprocess.run(cmd, capture_output=True, text=True, encoding="utf-8")
    # Regex untuk Conventional Commits: feat(scope): message
    type_pattern = re.compile(r"^(feat|fix|refactor|perf|style|docs|chore|test)(\((.*)\))?: (.*)")

    if result.returncode == 0:
        for line in result.stdout.strip().split("\n"):
            try:
                parts = line.split("|")
                if len(parts) < 3: continue
                date_str, msg = parts[1], parts[2]

                match = type_pattern.match(msg)
                if match:
                    ctype = match.group(1)
                    scope = match.group(3) if match.group(3) else "General"
                    clean_msg = match.group(4)

                    if ctype in ["chore", "style", "test", "merge"]: continue

                    # LOGIKA BARU:
                    # Tugas Utama = Nama Fitur / Scope
                    # Detail = Pesan Commit Lengkap (dengan emoji)
                    icon = "✨" if ctype == "feat" else "🐛" if ctype == "fix" else "🔨"
                    main_task = f"Sistem {scope.title()}" if scope != "General" else f"Update {ctype.title()}"
                    detail_text = f"{icon} {clean_msg}"
                else:
                    main_task = "Update Development"
                    detail_text = f"🔹 {msg}"

                all_items.append({
                    "date": date_str,
                    "task": main_task,      # Kolom B: Judul Besar
                    "detail": detail_text,  # Kolom C: Deskripsi Kerja
                    "source": "git"
                })
            except: continue

    # B. CHANGELOG MANUAL
    try:
        with open(CHANGELOG_PATH, "r", encoding="utf-8") as f:
            content = f.read()

        current_date = None
        version_pattern = re.compile(r"## \[(.*?)\] - (\d{4}-\d{2}-\d{2})")

        for line in content.split("\n"):
            line = line.strip()
            match = version_pattern.match(line)
            if match:
                dt = datetime.strptime(match.group(2), "%Y-%m-%d")
                current_date = dt.strftime("%d %b %Y")
                continue

            if line.startswith("- ") and current_date:
                msg = line[2:].strip().replace("**", "").replace("*", "").replace("`", "")
                all_items.append({
                    "date": current_date,
                    "task": "Manual Log",
                    "detail": f"📝 {msg}",
                    "source": "manual"
                })
    except: pass

    # Urutkan (Lama ke Baru)
    return sorted(all_items, key=lambda x: datetime.strptime(x["date"], "%d %b %Y"))

# --- 2. TENTUKAN JENIS PEKERJAAN ---
def determine_type(text, detail):
    full_text = (text + " " + detail).lower()
    if any(x in full_text for x in ["bug", "fix", "error", "crash"]): return "Bug Fixing"
    if any(x in full_text for x in ["desain", "asset", "ui", "ux", "polish", "toko"]): return "Creative/Aset"
    if any(x in full_text for x in ["test", "qa", "verifikasi"]): return "Testing"
    if any(x in full_text for x in ["setup", "deploy", "config", "install"]): return "Admin/Setup"
    return "Coding"

# --- 3. SYNC ONE-BY-ONE ---
def sync_final():
    items = get_all_items()
    total = len(items)
    print(f"🚀 Found {total} tasks. Starting Final Polish Sync...\n")

    for i, item in enumerate(items):
        idx = i + 1

        payload = {
            "task": item["task"],
            "message": item["detail"],
            "status": "✅ Completed",
            "jenis": determine_type(item["task"], item["detail"]),
            "date_override": item["date"]
        }

        print_progress(idx, total, item["task"])

        try:
            subprocess.run([
                "curl", "-L", "-X", "POST",
                "-H", "Content-Type: application/json",
                "-d", json.dumps(payload),
                WEBHOOK_URL
            ], capture_output=True)
        except: pass

        time.sleep(1.2)

    print("\n🎉 Timeline Synchronized Successfully!")

if __name__ == "__main__":
    sync_final()
