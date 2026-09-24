#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-cpu_decode}"
shift || true
CMD=(python3 "$(dirname "$0")/cpu_decode_microbench.py" "$@")
perf stat -r 3 -o "${OUT}_perf.txt" -e cycles,instructions,branches,branch-misses,cache-references,cache-misses -- "${CMD[@]}"
"${CMD[@]}" | tee "${OUT}_run.txt"
