#!/usr/bin/env bash
set -u
OUT="${1:-system_info.txt}"
{ date; uname -a; lscpu; free -h; numactl --hardware 2>/dev/null || true; nvidia-smi 2>/dev/null || true; rocm-smi 2>/dev/null || true; python3 --version; python3 - <<'PY'
try:
 import torch
 print("torch",torch.__version__,"cuda",torch.version.cuda,"devices",torch.cuda.device_count())
except Exception as e: print("torch:",e)
PY
} > "$OUT" 2>&1
echo "$OUT"
