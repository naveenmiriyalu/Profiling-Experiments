#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${ROOT}/results/gemm_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$OUT"
NAIVE="${ROOT}/microbenchmarks/01_naive/gemm_naive"
TILED="${ROOT}/microbenchmarks/02_tiled/gemm_tiled"
echo "# GPU GEMM suite" | tee "$OUT/summary.txt"
nvidia-smi -L | tee "$OUT/gpu.txt" || true
for K in 64 512 4096; do
  echo "=== naive 4096 4096 $K ===" | tee -a "$OUT/summary.txt"
  "$NAIVE" 4096 4096 "$K" | tee -a "$OUT/summary.txt"
done
echo "=== tiled 4096 4096 4096 ===" | tee -a "$OUT/summary.txt"
"$TILED" 4096 4096 4096 | tee -a "$OUT/summary.txt"
echo "Results: $OUT"
