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
No actual HBM traffic values, cache hit rates, eligible-warp rates or scoreboard percentages have yet been measured in the provided output. Do not infer them from profiling console timings.
