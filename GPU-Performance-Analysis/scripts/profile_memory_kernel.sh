#!/usr/bin/env bash
set -euo pipefail
if [[ $# -lt 2 ]]; then echo "Usage: $0 <binary> <output-prefix> [program args...]"; exit 1; fi
BIN="$1"; PREFIX="$2"; shift 2
COMMON=(--force-overwrite --launch-skip 1 --launch-count 1)
METRICS="l1tex__average_t_sectors_per_request_pipe_lsu_mem_global_op_ld,l1tex__average_t_sectors_per_request_pipe_lsu_mem_global_op_st,l1tex__t_sectors_pipe_lsu_mem_global_op_ld,l1tex__t_sectors_pipe_lsu_mem_global_op_st,l1tex__t_sector_pipe_lsu_mem_global_op_ld_hit_rate,dram__bytes_read,dram__bytes_write,dram__sectors_read,dram__sectors_write,lts__t_sectors_op_read,lts__t_sectors_op_read_lookup_hit,lts__t_sectors_op_read_lookup_miss,lts__t_sectors_op_write,lts__t_sectors_op_write_lookup_hit,lts__t_sectors_op_write_lookup_miss,lts__t_sectors_srcunit_tex_op_read,lts__t_sectors_srcunit_tex_op_write"
echo "==> Targeted memory hierarchy counters"
ncu "${COMMON[@]}" --metrics "$METRICS" -o "${PREFIX}_memory" "$BIN" "$@"
echo "==> Scheduler and warp-state analysis"
ncu "${COMMON[@]}" --section SchedulerStats --section WarpStateStats -o "${PREFIX}_scheduler" "$BIN" "$@"
echo "==> Occupancy"
ncu "${COMMON[@]}" --section Occupancy -o "${PREFIX}_occupancy" "$BIN" "$@"
echo "Done. Import generated reports with ncu --import."
