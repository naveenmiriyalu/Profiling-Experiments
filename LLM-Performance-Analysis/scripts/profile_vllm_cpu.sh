#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-vllm_cpu_perf}"; shift || true
if [[ $# -eq 0 ]]; then echo "Usage: $0 output_prefix command [args...]"; exit 1; fi
perf stat -o "${OUT}.txt" -e cycles,instructions,branches,branch-misses,cache-references,cache-misses,context-switches,cpu-migrations -- "$@"
