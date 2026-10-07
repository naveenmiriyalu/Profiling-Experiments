# Day 01 NVIDIA Resume Drill

Focus: OpenCAPI, AMD data sharing, event-driven modeling, DDR/MC, GPU/NoC.

## OpenCAPI
Practice a 30-second, 3-minute, and 10-minute explanation. Separate confirmed experience from public-spec reconstruction. Drill timing abstraction, queues, credits, backpressure, clock domains, and validation.

## AMD
Practice coherence/data-sharing story: model gap, implementation, functional invariants, cache-to-cache latency/bandwidth, cross-CCX tests, RTL/silicon correlation, regressions.

## Modeling
Explain cycle-driven vs event-driven, timestamp representation, deterministic same-time events, and why architectural arbitration belongs in the component rather than the global scheduler.

## Memory/GPU
Debug 400 GB/s theoretical DDR delivering 250 GB/s. Debug GPU HBM utilization at 55% and low eligible-warps despite high occupancy.
