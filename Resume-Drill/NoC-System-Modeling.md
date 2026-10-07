# NoC / System Modeling — Resume Drill

## Characterize traffic first
- source/destination matrix
- reads/writes
- request/packet/flit size
- sustained vs bursty
- average and peak injection
- locality
- MLP/outstanding transactions
- traffic classes / QoS
- latency-sensitive vs throughput-sensitive

## Core mechanisms
router pipeline, routing, virtual channels, buffers, arbitration, credits, link width/frequency, serialization, backpressure, HOL blocking, topology and destination service rate.

## Width experiment
256→512 bits at same frequency doubles theoretical raw link width and can reduce serialization, but system performance improves only if this link is limiting.

If average utilization is 50% but CPU P99 explodes under GPU traffic:
- inspect short-window utilization
- GPU burst length
- arbitration wait
- per-class queues
- HOL blocking
- credits/backpressure
- downstream SLC/MC congestion

Try QoS before paying area/power for width if raw bandwidth is not the root cause. But validate GPU throughput/fairness after CPU-priority changes.

## Event-driven NoC model project
Phase 1: fixed-latency link + FIFO.
Phase 2: pipelined throughput.
Phase 3: finite credits.
Phase 4: router arbitration.
Phase 5: virtual channels.
Phase 6: topology/routing.
Phase 7: QoS/aging.
Phase 8: compare with established NoC simulator.
Phase 9: connect to GPU simulator/H200 correlation.

## Metrics
offered load, accepted load, link utilization, queue occupancy, credit stalls, per-hop latency, serialization latency, arbitration wait, end-to-end median/P95/P99, throughput/fairness.
