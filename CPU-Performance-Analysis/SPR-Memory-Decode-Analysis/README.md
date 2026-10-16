# Sapphire Rapids: STREAM → decode memory analysis

This is a new SPR-specific workspace. The existing GNR `StreamPerfAnalysis/scripts` remains unchanged. **The runner has not yet been executed on the SPR host.**

## Baseline machine (verify on host)

Two Intel Xeon Gold 6430 CPUs (32 physical cores/socket, SMT2); 2 NUMA nodes. Actual DDR speed/channel population, BIOS configuration and NUMA/SNC layout must be captured instead of assumed.

## Quick start on SPR

```bash
git checkout spr-decode-memory-study
bash CPU-Performance-Analysis/SPR-Memory-Decode-Analysis/scripts/run_spr_stream.sh
```

Optional short smoke test: `ITERATIONS=5 COUNTS="1 8 16 32" bash CPU-Performance-Analysis/SPR-Memory-Decode-Analysis/scripts/run_spr_stream.sh`.

Requires GCC, numactl, lscpu, awk, OpenMP. Reuses the repository's `stream_single_kernel.c`, and writes a separate timestamped results directory. By default runs each NUMA node at 1, 2, 4, 8, 16, 24 and 32 physical cores with memory bound locally; samples one logical CPU per core from lscpu topology. **Review thread placement, hotplug/offline CPUs, SNC domains and cluster permissions before interpreting measurements.** If the OS cpuset restricts CPU placement, adapt affinity to allowed CPUs. Use sufficiently long runs (increase ITERATIONS) for sustained bandwidth, and repeat three times. The stream workload uses 3 x 100 million doubles (~2.4 GB across three arrays), exceeding last-level cache.

## Measurement checklist

1. Capture `lscpu -e=CPU,CORE,SOCKET,NODE,ONLINE`, `numactl -H`, `free -h`, `dmidecode -t memory` (if permitted), idle utilization, and `perf list`.
2. Run local-node single-socket scaling; run dual-socket concurrent tests separately, using independent memory placement per socket. Sum concurrent measured bandwidth, *not* separate-run peaks.
3. Interpret reported STREAM useful-bandwidth vs uncore CAS-derived DRAM traffic. Store policy/RFO and NT writes can change actual DRAM bytes. Check assembly and perf.
4. Repeat each configuration >=3 times; report sustained steady-state median and variation. Avoid shared production load, thermal throttling and SMT double counting.
5. Save raw text and experiment metadata; do not commit multi-GB traces or model weights to Git.

## CPU decode study

Freeze engine, model, precision, context, batch, threads and CPU affinity. Begin with a small decoder-only transformer supported by llama.cpp or another explicitly documented CPU inference engine. Record prompt processing separately from steady-state autoregressive decode. Sweep context lengths and batch sizes (1 first). Track decode tokens/s, per-token latency distribution, weight bytes/token, KV bytes/token, LLC misses, memory bandwidth and CPU stalls. Use Intel PCM/perf with model-specific validated counter aliases; use `perf mem record` if the kernel and SPR PMU permit PEBS sampling, capturing anonymized virtual-address samples. Samples are **not** exhaustive DRAM traces. Dynamo FX graphs and PyTorch Profiler give operator-level attribution, not exact memory-controller request sequences.

## GPU H200 study

Use the same model and equivalent quantization, compare prefill and steady decode. Use Nsight Systems for phases/timeline; Nsight Compute for selected kernels, HBM/L2 bytes, warp stalls, occupancy and memory-sector metrics. Use `torch.profiler` for operator correlation (and Dynamo/FX for graph inspection). Nsight metrics do not automatically yield a full memory request trace: use sampled address analysis, targeted CUDA instrumentation or Accel-Sim/related tracing in a compatible configuration. Verify trace coverage/fidelity before using a simulator.

## Simulation

Create bounded microbenchmark traces (sequential, strided, irregular gather, KV append/read), labeling address space, read/write, size, ordering, timestamps or dependencies, thread/warp identity and source. For DRAMsim3/Ramulator 2, translate trace format to the simulator's accepted request representation, and explicitly specify DDR/HBM timing/address mapping. Distinguish demand requests at instruction/cache level from DRAM transactions after cache filtering. A PIM hypothesis requires a compute placement, data-movement and programming/area/power model; do not infer PIM benefit from STREAM peak alone.

## Interpretation

Decompose token time into weight traffic, KV/cache traffic, compute and fixed overheads. Compare predicted bytes/token divided by *measured achievable* BW against actual decode time. Investigate poor effective bandwidth via MLP, spatial locality, LLC hits, channel imbalance, page behavior, and serial dependencies. Preserve model/data/code hashes and repeatability.
