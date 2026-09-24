#!/usr/bin/env bash
set -euo pipefail
: "${TARGET_URL:?set TARGET_URL to OpenAI-compatible endpoint}"
MODEL="${MODEL:?set MODEL}"
OUT="${OUT:-results/llm_$(date +%Y%m%d_%H%M%S)}"
mkdir -p "$OUT"
# Override GUIDELLM_EXTRA if your installed GuideLLM uses different endpoint/model flags.
EXTRA=(${GUIDELLM_EXTRA:-})
run_case(){
 local name=$1 isl=$2 osl=$3 conc=$4
 echo "=== $name ISL=$isl OSL=$osl concurrency=$conc ===" | tee "$OUT/$name.log"
 guidellm benchmark --target "$TARGET_URL" --model "$MODEL" --data "prompt_tokens=$isl,output_tokens=$osl" --rate-type concurrent --rate "$conc" "${EXTRA[@]}" 2>&1 | tee -a "$OUT/$name.log"
}
# Prefill-heavy: long prompt, short generation.
run_case prefill_8k 8192 32 1
run_case prefill_8k_c8 8192 32 8
# Decode-heavy: modest prompt, long generation.
run_case decode_512 512 512 1
run_case decode_512_c8 512 512 8
echo "Results: $OUT"
