#!/usr/bin/env bash
set -euo pipefail
BIN="$1"; PREFIX="$2"; shift 2
COMMON=(--force-overwrite --launch-skip 1 --launch-count 1)
ncu "${COMMON[@]}" --section SpeedOfLight -o "${PREFIX}_sol" "$BIN" "$@"
ncu "${COMMON[@]}" --section MemoryWorkloadAnalysis -o "${PREFIX}_memory" "$BIN" "$@"
ncu "${COMMON[@]}" --section SchedulerStats --section WarpStateStats -o "${PREFIX}_scheduler" "$BIN" "$@"
ncu "${COMMON[@]}" --section Occupancy -o "${PREFIX}_occupancy" "$BIN" "$@"
