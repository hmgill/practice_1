#!/usr/bin/env bash
# Builds a Linux-style practice tree under ./archive for the terminal/filesystem
# interview questions. Run from the root of your practice_1 repo:
#     bash setup_practice.sh          # create
#     bash setup_practice.sh --reset  # wipe archive/ + workspace/ and rebuild
# Portable across Linux (GNU) and macOS (BSD) tools.
set -euo pipefail

ROOT="$(pwd)"
A="$ROOT/archive"

if [[ "${1:-}" == "--reset" ]]; then
  rm -rf "$A" "$ROOT/workspace"
elif [[ -e "$A" ]]; then
  echo "archive/ already exists. Use --reset to rebuild." >&2
  exit 1
fi

H="$A/home/user"
mkdir -p \
  "$H/documents/reports" \
  "$H/documents/archive" \
  "$H/projects/client_a/production/pipelines/quarterly/input" \
  "$H/projects/client_a/production/pipelines/quarterly/output" \
  "$H/projects/client_a/archive" \
  "$H/projects/client_b/data/raw" \
  "$H/projects/client_b/notebooks" \
  "$H/.ssh" \
  "$H/.config/app" \
  "$A/opt/tools/bin" \
  "$A/opt/archive" \
  "$A/var/logs/old" \
  "$ROOT/workspace"

# ---------- home/user (hidden files) ----------
cat > "$H/.bashrc" <<'EOF'
export PATH="$HOME/bin:$PATH"
alias ll='ls -lah'
EOF
echo "theme = dark" > "$H/.config/app/settings.ini"

# Fake SSH material -- placeholders only, not real keys.
cat > "$H/.ssh/config" <<'EOF'
Host analytics
    HostName analytics.example.internal
    User user
    IdentityFile ~/.ssh/id_ed25519
EOF
echo "PLACEHOLDER -- a real private key would live here (chmod 600)" > "$H/.ssh/id_ed25519"
echo "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPLACEHOLDERKEYxxxxxxxxxxxxxxxxxxxxxxxx user@laptop" > "$H/.ssh/id_ed25519.pub"
echo "analytics.example.internal ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHOSTKEYPLACEHOLDERyyyyyyyyyyyyyyyyyyyy" > "$H/.ssh/known_hosts"

# ---------- documents ----------
cat > "$H/documents/README.md" <<'EOF'
# Documents
Personal working documents. Reports live in reports/.
EOF
cat > "$H/documents/Q3 Report final.txt" <<'EOF'
Q3 summary: revenue up 4%, churn flat.
customer_id 1042 escalated twice.
EOF
echo "Agenda: pipeline review, staffing" > "$H/documents/meeting notes 2026-09.txt"
echo "old draft" > "$H/documents/archive/draft_v1.txt"
: > "$H/documents/todo_empty.txt"                      # empty file
: > "$H/documents/reports/placeholder.txt"             # empty file
cat > "$H/documents/reports/keywords.txt" <<'EOF'
churn
revenue
pipeline
churn
retention
revenue
forecast
churn
EOF

# ---------- projects ----------
Q="$H/projects/client_a/production/pipelines/quarterly"
cat > "$Q/input/sales_2026_q3.csv" <<'EOF'
order_id,customer_id,amount,region
1,1042,250.00,north
2,1077,99.50,south
3,1042,12.25,north
4,1100,430.00,west
5,1013,88.10,east
EOF
cat > "$Q/input/customer_master.csv" <<'EOF'
customer_id,name,segment
1013,Acme Corp,enterprise
1042,Birch LLC,smb
1077,Cedar Inc,smb
1100,Delta Co,enterprise
EOF
: > "$Q/output/.gitkeep"
cat > "$H/projects/client_a/README.md" <<'EOF'
# Client A
Quarterly pipeline: production/pipelines/quarterly
EOF
echo "2025 q4 snapshot" > "$H/projects/client_a/archive/q4_2025_summary.txt"

cat > "$H/projects/client_b/data/raw/events.tsv" <<'EOF'
event_id	customer_id	event_type
e1	2001	login
e2	2002	purchase
EOF
cat > "$H/projects/client_b/data/raw/customer_segments.json" <<'EOF'
{"segments": [{"customer_id": 2001, "segment": "trial"}, {"customer_id": 2002, "segment": "paid"}]}
EOF
echo '{"cells": [], "metadata": {}}' > "$H/projects/client_b/notebooks/eda.json"
cat > "$H/projects/client_b/README.md" <<'EOF'
# Client B
Event data in data/raw.
EOF
: > "$H/projects/client_b/data/raw/.keep_empty"        # hidden + empty

# ---------- opt ----------
cat > "$A/opt/tools/bin/log_writer.sh" <<'EOF'
#!/usr/bin/env bash
# Appends a line to archive/var/logs/app.log every second (use with tail -f).
LOG="$(cd "$(dirname "$0")/../../.." && pwd)/var/logs/app.log"
i=0
while true; do
  i=$((i+1))
  lvl=INFO; (( i % 5 == 0 )) && lvl=ERROR
  echo "$(date '+%Y-%m-%d %H:%M:%S') $lvl live event $i" >> "$LOG"
  sleep 1
done
EOF
chmod +x "$A/opt/tools/bin/log_writer.sh"
echo "legacy tool v0.9" > "$A/opt/archive/legacy_tool_README.txt"
# Unfamiliar files: no extension / misleading extension.
printf 'customer_id,score\n1042,0.91\n' | gzip -c > "$A/opt/tools/mystery_payload"
printf '#!/usr/bin/env python3\nprint("hello")\n' > "$A/opt/tools/bin/runreport"
chmod +x "$A/opt/tools/bin/runreport"

# ---------- var/logs ----------
LOG="$A/var/logs/app.log"
: > "$LOG"
for i in $(seq 1 600); do
  case $((i % 37)) in
    0) lvl=ERROR; msg="failed to load customer_id=$((1000+i)) from warehouse" ;;
    5) lvl=WARN;  msg="slow query ${i}ms" ;;
    *) lvl=INFO;  msg="processed batch $i" ;;
  esac
  printf '2026-09-30 %02d:%02d:%02d %s %s\n' $((i/3600)) $(((i/60)%60)) $((i%60)) "$lvl" "$msg" >> "$LOG"
done
printf '2026-09-29 23:59:59 ERROR disk quota exceeded\n' > "$A/var/logs/old/app.log.1"
# >10 MB file (zeros compress to almost nothing in git).
dd if=/dev/zero of="$A/var/logs/old/core_dump.bin" bs=1048576 count=12 2>/dev/null

# ---------- workspace (scratch area for questions 13-21) ----------
echo "remember: verify every step" > "$ROOT/workspace/notes.txt"
echo "delete me" > "$ROOT/workspace/unwanted.tmp"

# ---------- timestamps: make "modified within the last day" meaningful ----------
# Everything gets an old mtime, then a few files are touched "now".
find "$A" "$ROOT/workspace" -exec touch -t 202501151030 {} +
touch "$LOG" "$Q/input/sales_2026_q3.csv" "$ROOT/workspace/notes.txt"

echo "Practice tree created under $A"
echo "Scratch area for file-manipulation questions: $ROOT/workspace"
