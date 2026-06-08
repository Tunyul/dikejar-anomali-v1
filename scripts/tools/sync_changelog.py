import re
import time
import json
import sys
import subprocess
from datetime import datetime

# Konfigurasi
CHANGELOG_PATH = "CHANGELOG.md"
WEBHOOK_URL = "https://script.google.com/macros/s/AKfycbzR89AWgAfoMi7Va1D_IW1oM7A8c2Lq9T4vrV-3W9UKFLOnvvYOoJGHxw6rft7tR3nN5w/exec"

def print_dual_progress(iteration, total, current_date, request_status="Waiting"):
    # Clear screen (ANSI escape code) biar bersih
    # print("\033[2J\033[H", end="")
    # ^ Jangan clear screen, nanti history hilang. Kita print baris baru aja.

    # 1. Total Progress
    percent_total = "{0:.1f}".format(100 * (iteration / float(total)))
    filled_total = int(40 * iteration // total)
    bar_total = '█' * filled_total + '-' * (40 - filled_total)

    # 2. Task Progress (Simulasi visual)
    # Karena request HTTP itu blocking, kita tidak bisa update progress bar realtime saat request.
    # Jadi kita buat visualisasi statusnya saja.
    status_icon = "⏳" if request_status == "Waiting" else "🚀" if request_status == "Sending" else "✅"

    sys.stdout.write(f"\n[{iteration}/{total}] {percent_total}% |{bar_total}| TOTAL\n")
    sys.stdout.write(f"       Task: {status_icon} {request_status}: {current_date}\n")
    sys.stdout.flush()

def parse_changelog(file_path):
    try:
        with open(file_path, "r", encoding="utf-8") as f:
            content = f.read()
    except FileNotFoundError:
        print(f"❌ File not found: {file_path}")
        return []

    version_pattern = re.compile(r"## \[(.*?)\] - (\d{4}-\d{2}-\d{2})")
    entries_by_date = {}
    current_date = None
    current_version = None

    for line in content.split("\n"):
        line = line.strip()
        match = version_pattern.match(line)
        if match:
            current_version = match.group(1)
            date_str = match.group(2)
            dt = datetime.strptime(date_str, "%Y-%m-%d")
            current_date = dt.strftime("%d %b %Y")
            if current_date not in entries_by_date:
                entries_by_date[current_date] = {"version": current_version, "messages": []}
            continue

        if line.startswith("- ") and current_date:
            description = line[2:].strip().replace("**", "").replace("*", "").replace("`", "")
            entries_by_date[current_date]["messages"].append(description)

    sorted_dates = sorted(entries_by_date.keys(), key=lambda x: datetime.strptime(x, "%d %b %Y"))

    final_entries = []
    for d in sorted_dates:
        entry = entries_by_date[d]
        final_entries.append({"date": d, "version": entry["version"], "messages": entry["messages"]})

    return final_entries

def categorize_task(messages):
    text = " ".join(messages).lower()
    if any(x in text for x in ["bug", "fix", "error", "crash", "issue"]):
        return "Bug Fixing (AI & System)"
    elif any(x in text for x in ["test", "qa", "verifikasi", "check"]):
        return "Testing"
    elif any(x in text for x in ["desain", "asset", "icon", "sprite", "ui", "ux", "toko", "polish"]):
        return "Creative/Aset"
    elif any(x in text for x in ["setup", "install", "config", "build", "upload", "deploy"]):
        return "Admin/Setup"
    else:
        return "Coding"

def generate_smart_title(version, messages):
    if not messages:
        return f"Update {version}"

    first_msg = messages[0]
    title = first_msg.split(":")[0] if ":" in first_msg else first_msg

    if len(title) > 40:
        title = title[:37] + "..."

    return f"[{version}] {title}"

def sync_to_sheet(entries):
    total = len(entries)
    print(f"🔄 Found {total} days to sync. Connecting to Google Sheet...")

    for i, entry in enumerate(entries):
        idx = i + 1

        # Tampilkan Progress Awal
        print_dual_progress(idx, total, entry['date'], "Sending")

        # Siapkan Data
        jenis_pekerjaan = categorize_task(entry["messages"])
        main_task = generate_smart_title(entry["version"], entry["messages"])

        detail_msg = ""
        for msg in entry["messages"]:
            detail_msg += f"• {msg}\n"

        payload = {
            "task": main_task,
            "message": detail_msg,
            "status": "✅ Completed",
            "jenis": jenis_pekerjaan,
            "date_override": entry["date"]
        }

        json_data = json.dumps(payload)

        # Eksekusi CURL
        try:
            cmd = [
                "curl", "-L", "-X", "POST",
                "-H", "Content-Type: application/json",
                "-d", json_data,
                WEBHOOK_URL
            ]
            result = subprocess.run(cmd, capture_output=True, text=True)

            if result.returncode != 0:
                 print(f"       ❌ Failed: {result.stderr}")
            else:
                 # Update status jadi Done di layar (overwrite baris task)
                 sys.stdout.write(f"\033[F       Task: ✅ Done: {entry['date']}             \n")
        except Exception as e:
            print(f"       ❌ Error: {str(e)}")

        time.sleep(1.0)

    print("\n🎉 Sync Completed!")

if __name__ == "__main__":
    data = parse_changelog(CHANGELOG_PATH)
    if data:
        sync_to_sheet(data)
