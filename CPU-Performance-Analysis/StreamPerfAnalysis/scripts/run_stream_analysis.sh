#!/usr/bin/env bash
set -euo pipefail

# Reproducible STREAM/PCM/perf analysis driver for one SNC domain.
#
# Usage:
#   ./run_stream_analysis.sh build
#   ./run_stream_analysis.sh sweep
#   ./run_stream_analysis.sh tma
#   ./run_stream_analysis.sh cas
#   ./run_stream_analysis.sh pcm --pcm-bin-dir /path/to/pcm/bin
#   ./run_stream_analysis.sh all --pcm-bin /path/to/pcm-memory
#
# Configuration can also be overridden through PCM_BIN or PCM_BIN_DIR.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BENCHMARK_SOURCE="${BENCHMARK_SOURCE:-$SCRIPT_DIR/stream_single_kernel.c}"
BENCHMARK_BIN="${BENCHMARK_BIN:-$SCRIPT_DIR/stream_single_kernel}"
RESULTS_ROOT="${RESULTS_ROOT:-$SCRIPT_DIR/../results}"
RUN_ID="${RUN_ID:-$(hostname -s)_$(date -u +%Y%m%dT%H%M%SZ)}"
RESULTS_DIR="$RESULTS_ROOT/$RUN_ID"

CPU_START="${CPU_START:-0}"
MEM_NODE="${MEM_NODE:-0}"
ELEMENTS="${ELEMENTS:-100000000}"
ITERATIONS="${ITERATIONS:-200}"
LONG_ITERATIONS="${LONG_ITERATIONS:-2000}"
CORE_COUNTS=(${CORE_COUNTS:-1 2 4 8 16 24 32})
COUNTER_CORE_COUNTS=(${COUNTER_CORE_COUNTS:-8 16 32})
PCM_BIN="${PCM_BIN:-}"
PCM_BIN_DIR="${PCM_BIN_DIR:-}"

mode="${1:-all}"
if [[ $# -gt 0 ]]; then
    shift
fi

while [[ $# -gt 0 ]]; do
    case "$1" in
        --pcm-bin-dir)
            [[ $# -ge 2 ]] || { echo "Missing value for --pcm-bin-dir" >&2; exit 2; }
            PCM_BIN_DIR="$2"
            shift 2
            ;;
        --pcm-bin)
            [[ $# -ge 2 ]] || { echo "Missing value for --pcm-bin" >&2; exit 2; }
            PCM_BIN="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 {build|sweep|tma|cas|nt-compare|read-breakdown|pcm|all} [--pcm-bin-dir DIR | --pcm-bin FILE]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $1" >&2
            exit 2
            ;;
    esac
done

if [[ -n "$PCM_BIN_DIR" ]]; then
    PCM_BIN="${PCM_BIN_DIR%/}/pcm-memory"
elif [[ -z "$PCM_BIN" ]]; then
    PCM_BIN="pcm-memory"
fi

mkdir -p "$RESULTS_DIR"

cpu_range()
{
    local threads="$1"
    local last_cpu=$((CPU_START + threads - 1))
    printf '%d-%d' "$CPU_START" "$last_cpu"
}

build_benchmark()
{
    gcc -O3 -march=native -fopenmp         "$BENCHMARK_SOURCE" -o "$BENCHMARK_BIN"

    objdump -d -M intel "$BENCHMARK_BIN" > "$RESULTS_DIR/stream_single_kernel.asm"
    grep -Ei 'vmovnt|movnt' "$RESULTS_DIR/stream_single_kernel.asm"         > "$RESULTS_DIR/non_temporal_stores.txt" || true
}

capture_metadata()
{
    {
        date -u
        uname -a
        lscpu
        numactl --hardware
        gcc --version
        perf --version
    } > "$RESULTS_DIR/system_metadata.txt" 2>&1

    perf list --details unc_m_cas_count_sch0.rd         > "$RESULTS_DIR/cas_event_definitions.txt" 2>&1
    perf list --details unc_m_cas_count_sch1.rd         >> "$RESULTS_DIR/cas_event_definitions.txt" 2>&1
    perf list --details unc_m_cas_count_sch0.wr         >> "$RESULTS_DIR/cas_event_definitions.txt" 2>&1
    perf list --details unc_m_cas_count_sch1.wr         >> "$RESULTS_DIR/cas_event_definitions.txt" 2>&1

    for pmu in /sys/bus/event_source/devices/uncore_imc_*; do
        [[ -d "$pmu/events" ]] || continue
        echo "===== $(basename "$pmu") ====="
        for event_file in "$pmu"/events/cas_count_read "$pmu"/events/cas_count_write; do
            [[ -f "$event_file" ]] || continue
            printf '%s: ' "$event_file"
            cat "$event_file"
        done
    done > "$RESULTS_DIR/generic_cas_aliases.txt"
}

run_kernel()
{
    local kernel="$1"
    local threads="$2"
    local iterations="$3"
    local cpus
    cpus="$(cpu_range "$threads")"

    numactl --physcpubind="$cpus" --membind="$MEM_NODE"         env OMP_NUM_THREADS="$threads"             OMP_PLACES=cores             OMP_PROC_BIND=close         "$BENCHMARK_BIN" "$kernel" "$iterations" "$ELEMENTS"
}

run_sweep()
{
    local output="$RESULTS_DIR/triad_core_sweep.txt"
    : > "$output"

    for threads in "${CORE_COUNTS[@]}"; do
        {
            echo "===== THREADS=$threads CPUS=$(cpu_range "$threads") ====="
            run_kernel triad "$threads" "$ITERATIONS"
        } 2>&1 | tee -a "$output"
    done
}

run_long_triad()
{
    run_kernel triad 32 "$LONG_ITERATIONS"         2>&1 | tee "$RESULTS_DIR/triad_32c_long.txt"
}

run_tma()
{
    for threads in "${COUNTER_CORE_COUNTS[@]}"; do
        local cpus
        cpus="$(cpu_range "$threads")"

        perf stat             -o "$RESULTS_DIR/tma_${threads}c.txt"             -M tma_backend_bound,tma_memory_bound,tma_dram_bound             -e cycles,instructions             --             numactl --physcpubind="$cpus" --membind="$MEM_NODE"             env OMP_NUM_THREADS="$threads"                 OMP_PLACES=cores                 OMP_PROC_BIND=close             "$BENCHMARK_BIN" triad "$ITERATIONS" "$ELEMENTS"             > "$RESULTS_DIR/tma_${threads}c_benchmark.txt"
    done
}

run_cas()
{
    for threads in "${COUNTER_CORE_COUNTS[@]}"; do
        local cpus
        cpus="$(cpu_range "$threads")"

        perf stat -a             -o "$RESULTS_DIR/cas_subchannels_${threads}c.txt"             -e unc_m_cas_count_sch0.rd             -e unc_m_cas_count_sch1.rd             -e unc_m_cas_count_sch0.wr             -e unc_m_cas_count_sch1.wr             --             numactl --physcpubind="$cpus" --membind="$MEM_NODE"             env OMP_NUM_THREADS="$threads"                 OMP_PLACES=cores                 OMP_PROC_BIND=close             "$BENCHMARK_BIN" triad "$ITERATIONS" "$ELEMENTS"             > "$RESULTS_DIR/cas_subchannels_${threads}c_benchmark.txt"
    done
}

run_nt_comparison()
{
    for threads in 8 16; do
        local cpus
        cpus="$(cpu_range "$threads")"

        for kernel in triad triad_nt; do
            perf stat -a                 -o "$RESULTS_DIR/cas_${kernel}_${threads}c.txt"                 -e unc_m_cas_count_sch0.rd                 -e unc_m_cas_count_sch1.rd                 -e unc_m_cas_count_sch0.wr                 -e unc_m_cas_count_sch1.wr                 --                 numactl --physcpubind="$cpus" --membind="$MEM_NODE"                 env OMP_NUM_THREADS="$threads"                     OMP_PLACES=cores                     OMP_PROC_BIND=close                 "$BENCHMARK_BIN" "$kernel" "$ITERATIONS" "$ELEMENTS"                 > "$RESULTS_DIR/cas_${kernel}_${threads}c_benchmark.txt"
        done
    done
}

run_read_breakdown()
{
    for threads in 8 16; do
        local cpus
        cpus="$(cpu_range "$threads")"

        perf stat -a             -o "$RESULTS_DIR/read_breakdown_${threads}c.txt"             -e unc_m_cas_count_sch0.rd_reg             -e unc_m_cas_count_sch1.rd_reg             -e unc_m_cas_count_sch0.rd_underfill             -e unc_m_cas_count_sch1.rd_underfill             --             numactl --physcpubind="$cpus" --membind="$MEM_NODE"             env OMP_NUM_THREADS="$threads"                 OMP_PLACES=cores                 OMP_PROC_BIND=close             "$BENCHMARK_BIN" triad "$ITERATIONS" "$ELEMENTS"             > "$RESULTS_DIR/read_breakdown_${threads}c_benchmark.txt"
    done
}

run_pcm()
{
    if ! command -v "$PCM_BIN" >/dev/null 2>&1 && [[ ! -x "$PCM_BIN" ]]; then
        echo "PCM executable not found: $PCM_BIN" >&2
        echo "Use --pcm-bin-dir /path/to/pcm/bin, --pcm-bin /path/to/pcm-memory, or set PCM_BIN." >&2
        return 1
    fi

    for kernel in copy scale add triad; do
        local output="$RESULTS_DIR/pcm_${kernel}_32c.txt"

        "$PCM_BIN" 0 --             numactl --physcpubind="$(cpu_range 32)" --membind="$MEM_NODE"             env OMP_NUM_THREADS=32                 OMP_PLACES=cores                 OMP_PROC_BIND=close             "$BENCHMARK_BIN" "$kernel" "$ITERATIONS" "$ELEMENTS"             > "$output" 2>&1
    done
}

case "$mode" in
    build)
        build_benchmark
        capture_metadata
        ;;
    sweep)
        [[ -x "$BENCHMARK_BIN" ]] || build_benchmark
        capture_metadata
        run_sweep
        ;;
    tma)
        [[ -x "$BENCHMARK_BIN" ]] || build_benchmark
        capture_metadata
        run_tma
        ;;
    cas)
        [[ -x "$BENCHMARK_BIN" ]] || build_benchmark
        capture_metadata
        run_cas
        ;;
    nt-compare)
        build_benchmark
        capture_metadata
        run_nt_comparison
        ;;
    read-breakdown)
        [[ -x "$BENCHMARK_BIN" ]] || build_benchmark
        capture_metadata
        run_read_breakdown
        ;;
    pcm)
        [[ -x "$BENCHMARK_BIN" ]] || build_benchmark
        capture_metadata
        run_pcm
        ;;
    all)
        build_benchmark
        capture_metadata
        run_sweep
        run_long_triad
        run_tma
        run_cas
        run_nt_comparison
        run_read_breakdown
        run_pcm
        ;;
    *)
        echo "Usage: $0 {build|sweep|tma|cas|nt-compare|read-breakdown|pcm|all} [--pcm-bin-dir DIR | --pcm-bin FILE]" >&2
        exit 2
        ;;
esac

echo "Results: $RESULTS_DIR"
