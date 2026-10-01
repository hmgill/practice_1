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
