# GPU Chip-Level Performance — Resume Drill

## Use real experiments
The goal is to connect current GPU measurements to long-standing modeling methodology.

### Memory-kernel reasoning
For unexpectedly low HBM throughput:
1. Establish kernel bottleneck with roofline/operation intensity.
2. Verify coalescing and transaction amplification.
3. Inspect L1/L2/HBM traffic separately.
4. Determine outstanding memory operations / MLP.
5. Inspect active versus eligible warps.
6. Identify dependency chains and scoreboard stalls.
7. Check occupancy/register/shared-memory constraints.
8. Check partition/channel imbalance.
9. Separate useful bandwidth from physical traffic.
10. Repeat with controlled microbenchmarks.

## Existing experimental story
Stride/triad/MLP-copy experiments are useful because they manipulate one mechanism at a time. Increasing independent loads per thread increases available MLP until another bottleneck/saturation point dominates. This is a clean model-vs-silicon experiment.

## Simulator correlation project
microbenchmark → silicon measurements → capture trace → detailed GPU simulator → compare latency/BW/cache/stall predictions → identify first divergence → determine missing mechanism/incorrect parameter.

Start with stride/triad/MLP before GEMM or full inference because simple workloads isolate mechanisms.

## Interview questions
- Why can occupancy be high while eligible warps are low?
- Why can useful BW exceed/lag reported physical traffic depending on cache reuse and accounting?
- What determines memory latency hiding?
- How would a trace-driven GPU simulator miss timing-dependent feedback?
- Which counters would validate an L2/HBM model?
- How would you separate GPU-core request-generation limits from memory-system limits?
