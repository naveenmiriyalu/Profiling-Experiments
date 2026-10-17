# H200 GPU Performance Study — Running Report

Status: initial Triad run recorded; **Nsight metrics not yet exported or analyzed**.

## Hardware / benchmark
- Target: NVIDIA H200, CUDA `sm_90` (exact product variant, clocks, driver and device metadata pending).
- Source: [triad.cu](../../microbenchmarks/memory/triad/triad.cu)
- Profiling runner: [profile_memory_kernel.sh](../../scripts/profile_memory_kernel.sh)
- 100,000,000 FP32 elements in each of 3 arrays (400 MB each; 1.2 GB useful traffic).
- Kernel: `a[i] = b[i] + 3*c[i]`; 256 threads/block; 390,625 blocks.
- Compile: `nvcc -O3 -arch=sm_90 -lineinfo -Xptxas=-v microbenchmarks/memory/triad/triad.cu -o triad`.
- ptxas: 12 registers/thread, zero spill loads/stores, 0 stack bytes, 0 barriers.

## Baseline (without NCU)
```text
Kernel time     : 0.349 ms
Useful traffic  : 1.200 GB
Useful bandwidth: 3436.27 GB/s
```
Single timed post-warmup launch, not repeated statistical characterization. Useful application bandwidth = logical 1.2 GB divided by CUDA-event time; not measured HBM-controller bandwidth.

## NCU capture
Command: `bash scripts/profile_memory_kernel.sh ./triad h200_triad`. Script uses `--launch-skip 1 --launch-count 1`.

| Report | Passes | In-program CUDA-event timing | In-program useful BW |
|---|---:|---:|---:|
| `h200_triad_memory.ncu-repz` | 4 | 2192.453 ms | 0.55 GB/s |
| `h200_triad_scheduler.ncu-repz` | 10 | 966.212 ms | 1.24 GB/s |
| `h200_triad_sol.ncu-repz` | 10 | 1069.308 ms | 1.12 GB/s |
| `h200_triad_occupancy.ncu-repz` | 1 | 774.476 ms | 1.55 GB/s |

**Interpretation:** NCU profiling/replay perturbs in-application CUDA-event timing. These values are not comparable with the baseline throughput and are not evidence of a runtime HBM bandwidth collapse. Use kernel profiler metrics and separate baseline timing; check profiler warnings and pass strategy.

## Export text and CSV
From `GPU-Performance-Analysis`:

```bash
mkdir -p reports/h200_triad
for section in memory scheduler sol occupancy; do
  report="h200_triad_${section}.ncu-repz"
  ncu --import "$report" --page details > "reports/h200_triad/${section}.txt"
  ncu --import "$report" --page raw --csv > "reports/h200_triad/${section}.csv"
done
```

Keep binary `.ncu-repz` files safely backed up. Exported reports have not been supplied yet.

## Next analysis
1. Check actual device SKU, clocks, sustained repeatability, and Nsight profiler warnings.
2. Compare DRAM read/write bytes and bandwidth against 1.2 GB useful traffic.
3. Inspect L1 sectors/request; L2 lookup hit/miss traffic; scheduler issue-active and eligible warps; warp stalls; theoretical and achieved occupancy.
4. Explain measured metrics using instruction address patterns and counter boundaries.
5. Repeat with stride and MLP kernels and compare against Triad.

## Data integrity
Actual NCU normalized throughput metrics are now available above, but HBM byte counts, cache hit rates, eligible-warp rates and scoreboard percentages have not yet been provided. Do not infer them from profiling console timings.

## Nsight Compute Speed of Light (measured)

Kernel `triad`, launch 390625 blocks x 256 threads; device CC 9.0, stream 7. Source: user-shared NCU SpeedOfLight text.

| Metric | Result |
|---|---:|
| GPU kernel duration | 342.37 us |
| Elapsed cycles | 677,353 |
| SM active cycles | 675,041.19 |
| SM frequency | 1.98 GHz |
| DRAM frequency (NCU reported) | 3.20 GHz |
| Memory throughput | 72.15% |
| DRAM throughput | 72.15% |
| L2 cache throughput | 82.82% |
| L1/TEX cache throughput | 18.93% |
| Compute (SM) throughput | 24.49% |

At 342.37 us and 1.2 GB algorithmic bytes, useful bandwidth would be approximately 3.505 TB/s. This is derived, **not** a measured DRAM byte throughput. L2/HBM percentage metrics are normalized to distinct peak baselines and cannot be interpreted as execution-time fractions. L2 being 82.82% vs DRAM 72.15% does not alone prove L2 is the limiter. Next inspect exact memory-sector and DRAM byte counters, scheduler eligibility/stalls, and occupancy.

## NCU targeted memory counters (user-supplied excerpt)

| Counter | Value |
|---|---:|
| DRAM read bytes (sum) | 800.05 MB |
| DRAM write bytes (sum) | 388.02 MB |
| DRAM read sectors (sum) | 25,001,632 |
| DRAM write sectors (sum) | 12,125,728 |
| L1TEX global load sectors (sum) | 25,000,000 |
| L1TEX global store sectors (sum) | 12,500,000 |
| L1TEX global load sectors/request | 4 |
| L1TEX global store sectors/request | 4 |
| L1TEX global load sector hit rate | 0 |
| L2 read sectors | 37,523,435 |
| L2 read lookup hit sectors | 853 |
| L2 read lookup miss sectors | 37,492,095 |

HBM total byte traffic = 1,188.07 MB. Using the 342.37-us duration from a different NCU profiling report gives ~3.47 TB/s, an approximate cross-report estimate rather than same-pass HBM BW. 4 sectors/request corresponds to 128 bytes across a coalesced full FP32 warp. L2 read sectors (~1200.75 MB) exceed global-load traffic (800 MB); investigate source and operation types, including write-related read operations; exact cause not yet established. Write count is ~12 MB below logical writes; do not ascribe cause without more evidence. The provided L2 read hit/miss aliases do not sum exactly to all read sectors, so do not interpret them as a complete partition.
