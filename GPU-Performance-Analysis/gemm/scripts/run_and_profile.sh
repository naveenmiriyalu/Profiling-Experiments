#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="$ROOT/results/run_$(date +%Y%m%d_%H%M%S)";mkdir -p "$OUT"
"$ROOT/scripts/build_all.sh"
N="$ROOT/microbenchmarks/01_naive/gemm_naive";T="$ROOT/microbenchmarks/02_tiled/gemm_tiled"
for K in 64 512 4096;do "$N" 4096 4096 "$K"|tee "$OUT/naive_k$K.txt";done
"$T" 4096 4096 4096|tee "$OUT/tiled_k4096.txt"
"$ROOT/scripts/profile_gemm_targeted.sh" "$N" "$OUT/naive4096" 4096 4096 4096
"$ROOT/scripts/profile_gemm_targeted.sh" "$T" "$OUT/tiled4096" 4096 4096 4096
echo "$OUT"
