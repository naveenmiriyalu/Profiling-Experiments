# STREAM Performance Analysis

Reproducible CPU memory-bandwidth experiments used as the baseline for the vLLM Llama decode analysis.

## Granite Rapids quick start

Run the complete one-SNC analysis:

```bash
cd CPU-Performance-Analysis/StreamPerfAnalysis/scripts

bash run_stream_full_analysis.sh \
  --pcm-bin-dir /path/to/pcm/build/bin
```

The full run performs:

1. benchmark compilation and system metadata capture;
2. Triad core-count sweep and long-duration validation;
3. Top-Down memory/DRAM-bound measurements;
4. explicit DDR5 subchannel CAS measurements;
5. temporal versus non-temporal Triad comparison;
6. regular versus underfill read classification;
7. split-scheduler RPQ insert/occupancy measurements;
8. per-kernel Intel PCM measurements.

Every invocation creates a timestamped directory under `results/`. Its `run_config.txt` records the effective parameters.

Individual wrappers are available in `scripts/`, including `run_stream_core_sweep.sh`, `run_stream_tma.sh`, `run_stream_cas.sh`, `run_stream_nt_comparison.sh`, `run_stream_read_breakdown.sh`, `run_stream_rpq.sh`, and `run_stream_pcm.sh`.

The completed one-SNC GNR baseline is in [GNR/report.html](GNR/report.html).
