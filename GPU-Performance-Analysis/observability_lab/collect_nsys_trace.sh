#!/usr/bin/env bash
# Usage: bash collect_nsys_trace.sh <out_dir> <program> [program args...]
# Captures GPU kernel/API activity, not GPU instruction or memory access traces.
set -euo pipefail
if (( $# < 2 )); then
  echo "Usage: $0 <out_dir> <program> [args...]" >&2
  exit 2
fi
OUT=$1; shift
mkdir -p "$OUT"
OUT=$(cd "$OUT" && pwd)
command -v nsys >/dev/null || { echo "nsys is required" >&2; exit 1; }
{
  printf 'UTC capture: '; date -u +%FT%TZ
  printf 'Command:'; printf ' %q' "$@"; printf '\n'
  nsys --version
  (ncu --version || :) 2>&1
} > "$OUT/manifest.txt"
if command -v nvidia-smi >/dev/null; then
  nvidia-smi -q > "$OUT/nvidia-smi.txt"
fi
nsys profile --trace=cuda,nvtx --sample=none --cpuctxsw=none \
  --force-overwrite=true --output="$OUT/timeline" "$@"
nsys export --type=sqlite --output="$OUT/timeline.sqlite" \
  "$OUT/timeline.nsys-rep"
nsys stats --report cuda_gpu_kern_sum "$OUT/timeline.nsys-rep" \
  > "$OUT/kernel-summary.txt" || true
python3 "$(dirname "$0")/export_nsys_kernels.py" \
  "$OUT/timeline.sqlite" "$OUT/kernels.jsonl"
printf 'Trace package: %s\n' "$OUT"
