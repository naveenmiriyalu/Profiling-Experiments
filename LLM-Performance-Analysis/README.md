# LLM Prefill / Decode Performance Analysis

This study connects transformer inference to the CPU/GPU microarchitecture work.

## Goals
- Separate prefill and decode.
- Sweep prompt length, output length and batch/concurrency.
- Capture TTFT, ITL, tokens/s and request throughput.
- Correlate runtime metrics with GPU/CPU profiling.
- Build simple roofline / bytes-per-token upper bounds.

## Structure
- scripts/run_vllm_prefill_decode.sh — GuideLLM/vLLM workload driver.
- scripts/profile_vllm_gpu.sh — Nsight Systems capture wrapper.
- scripts/profile_vllm_cpu.sh — perf stat wrapper for CPU-side serving.
- scripts/cpu_decode_microbench.py — dependency-free CPU decode/GEMV proxy.
- scripts/summarize_results.py — CSV summary helper.

The serving scripts intentionally expose environment variables because installed GuideLLM/vLLM CLI versions differ. Run each tool's --help and override flags as needed.
