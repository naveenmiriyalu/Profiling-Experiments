# Evening runbook

## A. H200 GEMM
```bash
git pull origin main
cd GPU-Performance-Analysis/gemm
chmod +x scripts/*.sh
./scripts/run_and_profile.sh
```
This builds naive+tiled GEMM, runs the K sweep, captures ptxas register/spill data, and profiles naive/tiled 4096^3 with NCU.

## B. CPU decode proxy
```bash
cd ../../LLM-Performance-Analysis
chmod +x scripts/*.sh
./scripts/collect_system_info.sh cpu_system.txt
OMP_NUM_THREADS=1 OPENBLAS_NUM_THREADS=1 ./scripts/profile_cpu_decode.sh decode_1t --hidden 4096 --ffn 11008 --steps 100
OMP_NUM_THREADS=8 OPENBLAS_NUM_THREADS=8 ./scripts/profile_cpu_decode.sh decode_8t --hidden 4096 --ffn 11008 --steps 100
```
The proxy is deliberately GEMV-like and dependency-sequential across decode steps. It is not a transformer accuracy benchmark.

## C. Real vLLM/GuideLLM prefill/decode
Start your vLLM server normally, then in the benchmark shell:
```bash
export TARGET_URL=http://127.0.0.1:8000
export MODEL=<served-model-name>
./scripts/run_vllm_prefill_decode.sh
```
If your GuideLLM CLI differs, first run `guidellm benchmark --help` and adapt only the flags in the driver. Keep the four workload shapes unchanged.

## D. GPU timeline for serving
For a server launched directly under Nsight Systems:
```bash
./scripts/profile_vllm_gpu.sh vllm_server \
  python3 -m vllm.entrypoints.openai.api_server --model "$MODEL" [your normal server flags]
```
Run the GuideLLM workload from a second shell while the capture is active. For an already-running server, use your existing Nsight/OpenShift workflow instead.

## E. CPU-side runtime profiling
For a CPU inference server/process that you launch directly:
```bash
./scripts/profile_vllm_cpu.sh cpu_server <server command...>
```

## What to bring back
1. GEMM results directory (text summaries are enough initially).
2. cpu_decode_1t/8t perf + run text.
3. Four GuideLLM logs: prefill_8k, prefill_8k_c8, decode_512, decode_512_c8.
4. Nsight Systems report if available.
5. Exact model, runtime version, quantization, TP/PP/EP, GPU count and KV-cache settings.
