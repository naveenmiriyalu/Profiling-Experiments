# Memory Controller / DRAM — Interviewer-Specific Drill

## Request path
producer → cache/NoC → MC ingress → address decode → per-channel/bank queues → scheduler → command generation → DRAM → return path.

## Performance dimensions
- theoretical vs sustainable bandwidth
- read/write mix
- request size and burst length
- outstanding requests / MLP
- channel/rank/bank/bank-group parallelism
- row-buffer locality
- address mapping/interleaving
- scheduler policy
- read↔write turnaround
- refresh
- QoS/fairness
- queue depth
- tail latency

## Timing refresh
- tRCD: ACT to column command.
- CL/tCAS: read command to returned data timing.
- tRP: precharge time.
- tRAS: minimum active-row time.
- tRC: ACT-to-ACT same-bank cycle time, approximately tRAS+tRP.
- Row hit avoids ACT/PRE path; row conflict generally requires closing current row then activating another.

## Diagnostic problem
Theoretical BW = 400 GB/s; workload sees 250 GB/s.

Do not immediately blame DRAM. Partition diagnosis:
1. Is producer offering >=400 GB/s useful demand?
2. Is NoC delivering requests fast enough?
3. Are MC queues populated?
4. Is traffic balanced across channels?
5. Enough bank-level parallelism?
6. Row-hit rate / conflicts?
7. Read-write turnaround losses?
8. Refresh/protocol overhead?
9. Controller scheduling bubbles?
10. Backpressure/credits?
11. Useful bytes vs transferred bytes?

## Scheduler discussion
FR-FCFS favors ready commands/row hits, improving throughput/locality but can hurt fairness. Principal-level answer should discuss workload dependence, starvation protection, aging/QoS and latency-sensitive traffic.

## DDR vs LPDDR vs GDDR vs HBM lens
Avoid memorizing product tables. Compare architectural goals:
- DDR: general-purpose capacity/bandwidth/latency balance.
- LPDDR: energy efficiency/mobile/SoC integration, different power states and channel organization.
- GDDR: high pin-rate graphics bandwidth, power/signaling tradeoffs.
- HBM: very wide interface and many channels/stacks for massive aggregate bandwidth; packaging/capacity/cost constraints.

Always tie technology choice to workload, controller architecture and traffic pattern.
