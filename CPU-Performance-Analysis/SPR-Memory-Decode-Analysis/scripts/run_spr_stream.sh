#!/usr/bin/env bash
set -euo pipefail
# Run from any directory. Requires gcc, numactl, lscpu, awk.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
SRC="$ROOT/CPU-Performance-Analysis/StreamPerfAnalysis/scripts/stream_single_kernel.c"
OUT="${RESULTS_ROOT:-$ROOT/CPU-Performance-Analysis/SPR-Memory-Decode-Analysis/results}/$(hostname -s)_$(date -u +%Y%m%dT%H%M%SZ)"
BIN="$OUT/stream_single_kernel"
ELEMENTS="${ELEMENTS:-100000000}"
ITERATIONS="${ITERATIONS:-20}"
COUNTS="${COUNTS:-1 2 4 8 16 24 32}"
mkdir -p "$OUT"
command -v numactl >/dev/null; command -v gcc >/dev/null; command -v lscpu >/dev/null
[[ -f "$SRC" ]] || { echo "Missing shared STREAM source: $SRC" >&2; exit 1; }
gcc -O3 -march=native -fopenmp "$SRC" -o "$BIN"
{ date -u; lscpu; numactl -H; gcc --version | head -1; } > "$OUT/system.txt" 2>&1
echo "ELEMENTS=$ELEMENTS ITERATIONS=$ITERATIONS COUNTS=$COUNTS" > "$OUT/config.txt"
# lscpu -p fields are logical CPU, physical core, socket, NUMA node.
# Select exactly one logical CPU per physical core (do not count SMT siblings).
lscpu -p=CPU,CORE,SOCKET,NODE | awk -F, '!/^#/ && NF==4 && $4>=0 {k=$3":"$2; if(!seen[k]++) print $1","$4}' > "$OUT/one_cpu_per_core.csv"
cut -d, -f2 "$OUT/one_cpu_per_core.csv" | sort -nu > "$OUT/nodes.txt"
run_node() {
  local node="$1" count="$2" cpus
  cpus="$(awk -F, -v n="$node" '$2==n {print $1}' "$OUT/one_cpu_per_core.csv" | head -n "$count" | paste -sd, -)"
  [[ "$(awk -F, -v n="$node" '$2==n {i++} END{print i+0}' "$OUT/one_cpu_per_core.csv")" -ge "$count" ]] || return 0
  printf '\n=== node=%s cores=%s cpus=%s ===\n' "$node" "$count" "$cpus" | tee -a "$OUT/triad_sweep.txt"
  numactl --physcpubind="$cpus" --membind="$node" env OMP_NUM_THREADS="$count" OMP_PLACES=threads OMP_PROC_BIND=close "$BIN" triad "$ITERATIONS" "$ELEMENTS" 2>&1 | tee -a "$OUT/triad_sweep.txt"
}
while read -r node; do
  for count in $COUNTS; do run_node "$node" "$count"; done
done < "$OUT/nodes.txt"
echo "Results: $OUT"
