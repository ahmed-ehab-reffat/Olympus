#!/bin/bash
# Blocks until pipeline/INBOX.md changes, pipeline/STOP appears, or MAX_SECONDS pass.
# Run with run_in_background so the orchestrator is re-invoked when it exits.
cd "$(dirname "$0")/../../.." || exit 1
MAX_SECONDS="${1:-7200}"
sum() { md5sum pipeline/INBOX.md 2>/dev/null | cut -d' ' -f1; }
start=$(sum)
elapsed=0
while [ "$elapsed" -lt "$MAX_SECONDS" ]; do
  if [ -e pipeline/STOP ]; then echo "WAKE: STOP"; exit 0; fi
  if [ "$(sum)" != "$start" ]; then echo "WAKE: INBOX changed"; exit 0; fi
  sleep 30
  elapsed=$((elapsed + 30))
done
echo "WAKE: timeout after ${MAX_SECONDS}s"
