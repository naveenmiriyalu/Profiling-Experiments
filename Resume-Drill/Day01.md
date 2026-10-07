# Day 01 — OpenCAPI + AMD Data-Sharing Resume Drill

Focus: make two resume stories implementation-defensible. Separate **confirmed experience** from **public-spec reconstruction**.

## OpenCAPI — 90 min
30-second spine: I worked on adding OpenCAPI coherent-attach behavior into an IBM performance-modeling environment. The key modeling problem was deciding which transaction, timing, queueing, coherence and backpressure behaviors had to be explicit for the architecture questions, integrating those with the existing uncore/memory model, and validating the result.

Confirmed: OpenCAPI modeling; spec/designer timing-diagram work; uncore/memory integration; abstraction decisions.

Do not claim until remembered: exact commands, exact credit pools implemented, address-translation implementation, exact queue depths/frequencies.

Public-spec concepts to recognize:
- command/response virtual channels
- separate data-credit pools
- credit-return operations
- response tag matching
- ordering constraints
- xlate_touch / ATC hit-miss / retry-pending address-translation flow

Timing-diagram abstraction checklist:
1. externally visible events
2. transaction state/tags
3. finite resources
4. arbitration/contention
5. backpressure
6. clock-domain boundaries
7. observability: latency segments, queue occupancy, stalls, credit starvation

Drill:
- Why not model the link as one fixed latency? Because unloaded latency can match while loaded throughput and tail latency are wrong if credits, queues, ordering or backpressure matter.
- When may multiple pipeline stages become one +N completion event? When intermediate stages are deterministic and cannot independently contend or stall.
- Two same-time requests need one resource: the event framework is deterministic, but architectural priority belongs in the modeled arbiter/QoS policy.
- Different clocks: use common simulated time and schedule each domain on its own cadence; abstract CDC unless its internal behavior changes the performance question.

SystemC/TLM point: TLM is an interface/modeling style, not a fixed accuracy level. Timing may be loosely or more explicitly modeled. Temporal decoupling is a simulation-speed technique that lets local simulated time advance before synchronization.

## AMD data sharing / cross-CCX — 75 min
30-second spine: an otherwise high-fidelity server model did not adequately reproduce coherent sharing across threads. I worked through the coherence architecture, fixed/added the required behavior, and used a validation ladder from functional invariants through cache-to-cache latency/bandwidth and configurable sharing proxies, then correlated against RTL and silicon and kept the coverage in regression.

Validation ladder:
1. legal coherence transitions/invariants
2. cache-to-cache latency
3. cache-to-cache bandwidth
4. local vs cross-CCX
5. reader/writer sharing sweeps
6. loaded contention
7. RTL correlation
8. silicon correlation
9. regression gating

Drill:
- Model 20 ns faster than silicon: first match config/frequency/placement, then find the first divergent segment; never add a global 20 ns fudge.
- RTL matches model, silicon slower: investigate clock/power/firmware/physical effects, contention differences, config mismatch, measurement artifacts and silicon workarounds.
- Unloaded latency matches but sharing BW is too high: inspect overlap, queue depth, credits, arbitration, coherence serialization/probe concurrency and downstream limits.
- Simpler non-cycle-exact model is acceptable when it preserves decision-relevant bottlenecks/trends within a documented error envelope.

## Event-driven vs cycle-driven — 45 min
Scenario: 4-entry FIFO, 2-cycle decode, 1 req/cycle issue, 8-cycle downstream latency, 6 outstanding credits.

Minimum explicit state:
- FIFO occupancy/blocking
- next issue time
- outstanding-credit count
- completion event at issue + 8 cycles
- credit return
- stall counters

You do not need eight per-cycle events for each transaction if no relevant resource interaction occurs during those eight cycles.

## DDR/MC — 45 min
8 channels, theoretical 400 GB/s, measured 250 GB/s. Diagnose:
1. offered load
2. NoC ingress/backpressure
3. MC queue occupancy/depth
4. channel balance
5. bank/bank-group parallelism
6. row-hit/conflict behavior
7. read/write turnaround
8. refresh/protocol overhead
9. scheduler bubbles/fairness
10. return path
11. useful vs physical bytes

If average utilization is moderate but P99 is poor, inspect burst windows, hot banks/links, HOL blocking, QoS wait, long write drains and downstream congestion.

## GPU / NoC — 45 min
Use Hopper stride/triad/MLP-copy as the modern evidence story.

- High occupancy + low eligible warps: residency is not readiness; dependencies, scoreboards/memory, synchronization or pipeline constraints can stall resident warps.
- HBM ~55%: raise independent memory operations and inspect eligible warps/outstanding requests/L2-DRAM behavior. If BW rises, request generation/latency hiding was limiting.
- NoC average ~55% + CPU P99 explosion: averages can hide burst saturation, hot links/VCs, HOL blocking, credit stalls and downstream SLC/MC congestion.

## Final 30-minute mock
1. Tell me about OpenCAPI modeling.
2. What did you personally implement?
3. Why event-driven; how was time represented?
4. How did you choose fidelity?
5. Give a model-vs-RTL/silicon mismatch.
6. How did you isolate it?
7. 400 GB/s DDR gives 250 GB/s: debug it.
8. GPU HBM at 55%: debug it.
9. Why can average NoC utilization be low while P99 is bad?
10. What would you model differently today?

Exit criteria: OpenCAPI and AMD stories at 30-sec/3-min/10-min depth; clean event-time explanation; one DDR diagnosis; one GPU/NoC diagnosis; crisp personal-contribution statement for each resume story.
