#!/usr/bin/env bash
set -euo pipefail
BIN="${1:?binary}"; PREFIX="${2:?prefix}"; shift 2
COMMON=(--force-overwrite --launch-skip 1 --launch-count 1)
ncu "${COMMON[@]}" --section SpeedOfLight -o "${PREFIX}_sol" "$BIN" "$@"
ncu "${COMMON[@]}" --section MemoryWorkloadAnalysis -o "${PREFIX}_memory" "$BIN" "$@"
ncu "${COMMON[@]}" --section SchedulerStats --section WarpStateStats -o "${PREFIX}_sched" "$BIN" "$@"
ncu "${COMMON[@]}" --section Occupancy -o "${PREFIX}_occ" "$BIN" "$@"
ncu "${COMMON[@]}" --section InstructionStats -o "${PREFIX}_inst" "$BIN" "$@" || true
for r in "${PREFIX}"_{sol,memory,sched,occ,inst}.ncu-rep*; do
  [[ -e "$r" ]] && ncu --import "$r" > "${r%.*}.txt" 2>&1 || true
done
