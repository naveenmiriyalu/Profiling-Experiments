# GPU Performance Analysis

Hands-on GPU performance and architecture study using NVIDIA H200 first, followed by AMD MI355X.

## Study flow

1. Memory microbenchmarks: bandwidth, coalescing/alignment, latency, MLP, cache/working-set behavior.
2. Compute microbenchmarks: dependency chains, ILP, instruction throughput, scheduling and occupancy.
3. Hardware profiling and ISA inspection.
4. Trace-driven simulation and hardware/simulator correlation.
5. LLM track: prefill, decode, GEMV/GEMM, attention and KV-cache behavior.
6. Graphics track: shader execution, texture/memory behavior and graphics-pipeline fundamentals.

## Current experiment

Start with `microbenchmarks/memory/stride/stride_read.cu`.

Build on H200:

```bash
nvcc -O3 -arch=sm_90 -lineinfo microbenchmarks/memory/stride/stride_read.cu -o stride_read
./stride_read
```

The first run intentionally uses stride 1 only. We will make predictions before adding NCU profiling or sweeping stride.
