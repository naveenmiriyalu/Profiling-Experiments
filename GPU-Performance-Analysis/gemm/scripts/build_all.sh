#!/usr/bin/env bash
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
NVCC="${NVCC:-nvcc}"; ARCH="${ARCH:-sm_90}"
"$NVCC" -O3 -arch="$ARCH" -lineinfo "$ROOT/microbenchmarks/01_naive/gemm_naive.cu" -o "$ROOT/microbenchmarks/01_naive/gemm_naive"
"$NVCC" -O3 -arch="$ARCH" -lineinfo "$ROOT/microbenchmarks/02_tiled/gemm_tiled.cu" -o "$ROOT/microbenchmarks/02_tiled/gemm_tiled"
"$NVCC" -O3 -arch="$ARCH" -lineinfo -Xptxas=-v "$ROOT/microbenchmarks/01_naive/gemm_naive.cu" -o /tmp/gemm_naive_ptxas 2>&1 | tee "$ROOT/results_naive_ptxas.txt"
"$NVCC" -O3 -arch="$ARCH" -lineinfo -Xptxas=-v "$ROOT/microbenchmarks/02_tiled/gemm_tiled.cu" -o /tmp/gemm_tiled_ptxas 2>&1 | tee "$ROOT/results_tiled_ptxas.txt"
