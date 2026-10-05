#!/usr/bin/env bash
# Commit and push all changes:  bash scripts/update.sh "your message"
set -e; cd "$(dirname "$0")/.."
if [ -f .git/MERGE_HEAD ] || grep -rlE "^(<<<<<<<|>>>>>>>) " pages includes assets scripts index.php README.md 2>/dev/null; then
  echo "STOP: unresolved merge or conflict markers found. Fix them first."; exit 1
fi
MSG="${1:-Update Mtalii Bora ($(date '+%Y-%m-%d %H:%M'))}"
git add -A
if git diff --cached --quiet; then echo "No changes to commit."; else git commit -m "$MSG"; fi
git pull --rebase origin main || { echo "Pull had conflicts. Resolve them, then run again."; exit 1; }
git push -u origin main && echo "Pushed to GitHub ✔"
