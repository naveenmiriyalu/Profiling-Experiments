#!/usr/bin/env bash
set -euo pipefail
OUT="${1:-vllm_nsys}"
shift || true
if [[ $# -eq 0 ]]; then
 echo "Usage: $0 output_prefix command [args...]"; exit 1
fi
nsys profile --force-overwrite=true --trace=cuda,nvtx,osrt --cuda-memory-usage=true -o "$OUT" "$@"
