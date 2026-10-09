# NVIDIA Resume Drill — Day 03 (October 9, 2026)

## Goal: implementation-level ownership
For each IBM or AMD project, distinguish known experience from a hypothetical public-architecture exercise. Be ready to explain the component boundary, prior model deficiency, specific implementation change, functional invariants, latency/throughput validation, and architectural decision enabled.

## 06:00–07:15 AMD coherent sharing
Trace one-line writer-to-reader behavior across CCXs. Specify home/directory, ownership resolution, probes, data return, and queueing as conceptual roles, not unverified proprietary structures. Design tests for stale-copy avoidance, ownership uniqueness, read-after-write via synchronization, and intervening eviction. Sweep reader count and locality to distinguish coherence serialization from traffic saturation.

## 07:15–08:00 IBM lock scaling
Revisit cache-coherence integration, atomic/lock scaling, and simulation races. Explain how same-cycle resource collisions are resolved and how functional correctness and timing observability are independently tested.

## 08:00–09:00 OpenCAPI transaction timing
Draw AFU → command queue → TLx/DLx → host → memory/coherence → response. Label credits, tags, ordering, resource occupancy and backpressure. Collapse only deterministic stages with no performance-relevant contention. Public TLx/DLx reference: https://github.com/OpenCAPI/OpenCAPI3.0_Client_RefDesign

Toy exercise: 16 B/cycle at 1 GHz is a 16 GB/s link; 64-byte responses, two outstanding credits and 20 ns reuse time cap the window at 6.4 GB/s. Eight credits raise window cap to 25.6 GB/s, leaving the link as the 16 GB/s limiter. Enlarging the link with two credits does not fix the 6.4 GB/s window bottleneck.

## 09:00–09:45 Event framework
Represent events by integer timestamp, simulation phase, deterministic sequence and callback/transaction. Collect requests during arrival phase, arbitrate within the modeled IP, then update state. Global event insertion order must not accidentally define CPU/GPU QoS. Compare cycle-driven versus sparse event-driven execution and test equal-tick races and backpressure.

## 09:45–10:15 Correlation debugging
Synthetic model/silicon: CPU P99 290/670 ns, GPU bandwidth 210/155 GB/s, NoC utilization 55/57%, arbitration P99 70/360 ns, MC service P99 120/125 ns. Prioritize arbiter wait and per-class stalls over adding global latency. Verify counter definitions, input traffic matching, credit stalls and HOL behavior.

## 10:15–11:00 Mock
Spend 15 minutes on AMD personal contribution, 15 on IBM OpenCAPI timing and fidelity, 10 on NoC/DRAM GPU correlation, and 5 on limits and architectural judgment. Score 0–2 each for ownership, mechanism, validation, model-vs-silicon diagnosis, assumptions, quantitative reasoning, alternatives, and candor. Target 12/16.

## Sources
- https://www.accellera.org/activities/working-groups/systemc-tlm
- https://gem5.googlesource.com/public/gem5/+/8eb84518f15fcef59da90e7ec72e2bc88fb5b59d/src/sim/eventq.hh
- https://doi.org/10.1109/JSSC.2017.2752839
