# Resume Drill — NVIDIA Principal Architect Prep

Purpose: reconstruct and defend the resume at implementation depth for the October 16 NVIDIA architecture/performance-modeling interview. These notes deliberately separate **confirmed experience** from **background material / reconstruction prompts**. Do not claim a reconstructed detail unless it matches actual memory or artifacts.

## 1. Core interview narrative

The recurring thread across the resume is:

**architecture question → choose model abstraction → implement mechanisms → expose observability → validate/correlate → use results for architecture decisions**

Four primary stories:
1. IBM POWER coherence / lock-scaling model
2. IBM OpenCAPI coherent-attach modeling
3. AMD data-sharing / cross-CCX coherence modeling and validation
4. Modern GPU / AI performance characterization and silicon correlation

For each story be able to answer:
- What problem were we solving?
- What existed before my work?
- What did I personally implement?
- What state/resources/timing did the model represent?
- What was intentionally abstracted?
- Cycle-driven, event-driven, trace-driven, execution-driven, or hybrid — and why?
- How was time represented across clock domains?
- How were queues, arbitration, credits/backpressure and contention represented?
- What statistics/counters did the model expose?
- How did we validate: unit/invariant tests, microbenchmarks, RTL, silicon?
- What mismatch did we find and how was it localized?
- What decision/result did the work enable?
- What would I model differently today?

## 2. OpenCAPI drill

### Confirmed from resume / recollection
- Worked on OpenCAPI modeling at IBM.
- Added a coherent accelerator/CPU-GPU attach capability into an existing architecture/performance simulation environment.
- Worked from specifications and designer discussions/timing diagrams.
- Integrated with the memory/uncore side of the model.
- A key modeling task was deciding which protocol/timing behavior required explicit representation and which could be abstracted.

### Public architecture background to refresh
OpenCAPI 3.0 defines a transaction layer and separate data-link/physical layers. The transaction-level view is the right place to reason about commands, responses, data, ordering, flow control, coherent memory behavior and address translation without modeling electrical signaling.

Reconstruction prompts:
- Where exactly did OpenCAPI attach in the IBM simulator?
- Which command/response classes did the implementation represent?
- Were protocol credits explicitly modeled? If yes, what resource did each credit represent and when was it returned?
- Were request/data/response paths separate?
- How was backpressure represented?
- Which coherence interactions reached existing POWER cache/coherence logic?
- Was address translation/ATC modeled, approximated or outside scope?
- How were MMIO/control operations treated relative to bulk/coherent memory traffic?
- What was the latency decomposition from attached device to host memory/cache and back?
- Which timing-diagram stages could be collapsed into a single scheduled event?
- Which stages could *not* be collapsed because arbitration, queue occupancy or backpressure affected performance?
- What clock domains existed, and was CDC represented explicitly or folded into latency?

### Timing-diagram abstraction exercise
For every real timing diagram:
1. List externally visible events.
2. Identify state/resources consumed at each event.
3. Mark places where another transaction can contend.
4. Mark places where backpressure/credits can stall progress.
5. Mark clock-domain boundaries.
6. Collapse deterministic internal stages that have no observable contention.
7. Preserve stages whose occupancy changes throughput or tail latency.
8. Define statistics needed for validation: queue occupancy, stall cycles, credit starvation, latency by segment, throughput.

A possible abstract transaction flow for practice (not a claim about the IBM implementation):

AFU/accelerator → request queue → transaction/link processing → host coherence/memory subsystem → cache/DRAM service → response/data path → accelerator.

The interview question is not “did I reproduce every signal?” but “did the abstraction preserve the mechanisms required by the architecture question?”

## 3. Time representation / event framework drill

Important distinction:
- **Time resolution**: smallest timestamp quantum the framework can represent.
- **Scheduling policy**: when simulator code actually executes.

For rational clock domains, a common base frequency can represent all clock edges as integer ticks. Example:
- 3.0 GHz period = 333.33 ps
- 2.4 GHz period = 416.67 ps
- 12 GHz base → 83.33 ps tick
- 3 GHz = 4 ticks/cycle; 2.4 GHz = 5 ticks/cycle.

Do not confuse this with requiring the simulator to execute every base tick. A discrete-event engine can jump between timestamps.

Same-timestamp events:
- Global scheduler ordering should provide reproducibility/determinism.
- Architectural priority should live in the modeled resource (arbiter, queue, scheduler), not as an accidental global “CPU first” rule.
- If same-cycle components must observe old state before updates, use explicit evaluate/update phases, delta-cycle-like semantics, or another documented ordering contract.

Cycle-driven vs event-driven:
- Cycle-driven is simple and natural for dense activity and cycle-level state.
- Idle short-circuiting can reduce work.
- Event-driven avoids processing inactive intervals.
- A fixed, fully pipelined 5-cycle path can often be represented by scheduling completion at +5.
- If intermediate stages can stall because of credits, arbitration or downstream backpressure, a +5 abstraction may lose the mechanism that matters.

## 4. AMD data-sharing / coherence drill

### Confirmed story
- High-fidelity performance model did not adequately represent coherent data sharing across threads for important server behavior.
- Learned the coherence architecture and interactions.
- Helped establish a structured validation/test strategy.
- Functional checks/invariants guarded coherence correctness.
- Cache-to-cache latency and bandwidth microbenchmarks were used.
- Configurable data-sharing proxy traffic exercised varying sharing patterns.
- Cross-CCX/topology behavior was studied.
- Model behavior was compared with RTL and silicon.

### Validation ladder
1. Functional protocol/state-transition correctness.
2. Component invariants after transitions.
3. Unloaded latency microbenchmarks.
4. Unloaded bandwidth.
5. Topology/local-vs-remote cases.
6. Controlled sharing proxies.
7. Loaded latency / contention.
8. RTL correlation.
9. Silicon correlation.
10. Regression automation.

Mismatch debugging:
- First establish equivalent frequency/configuration/workload.
- Decompose end-to-end latency into segments.
- Find first divergent segment rather than tuning total latency.
- For bandwidth, inspect queues, occupancy, service rates, backpressure and resource saturation.
- Decide whether mismatch is a bug or intentional abstraction based on target workloads and the model contract.
- Document known limitations.

## 5. Memory-controller / DRAM drill

Interviewer-specific area: DDR/LPDDR/GDDR memory-subsystem architecture.

Request path:
producer → NoC/cache → MC queues → address mapping → scheduler → bank/rank/channel → ACT/RD/WR/PRE → return path.

Be ready to reason about:
- theoretical vs achieved bandwidth
- channel/rank/bank/bank-group parallelism
- row hit / closed / conflict
- tRCD, CL/tCAS, tRP, tRAS, tRC
- queue depth and outstanding requests
- address mapping/interleaving
- FR-FCFS and fairness/starvation
- read/write batching and turnaround
- refresh
- QoS among CPU/GPU/DMA traffic
- latency under load vs unloaded latency
- burstiness and P99
- whether bottleneck is producer, NoC, MC or DRAM

Key modeling lesson: higher theoretical bandwidth does not imply system speedup. Identify offered load, burstiness, locality, concurrency and the downstream service bottleneck.

## 6. GPU chip-performance drill

Use actual GPU experiments as evidence, not only theory.

Reasoning chain for low achieved HBM bandwidth:
1. Is the kernel actually memory-bound?
2. Access coalescing / useful bytes vs transferred sectors.
3. L1/L2 hit behavior.
4. Outstanding memory requests / memory-level parallelism.
5. Active vs eligible warps.
6. Dependency chains.
7. Occupancy and register pressure.
8. HBM utilization and partition balance.
9. Kernel duration and launch/runtime effects.

Keep distinctions crisp:
- occupancy ≠ utilization
- theoretical BW ≠ achieved BW
- achieved BW ≠ useful BW
- high active warps ≠ enough eligible warps
- high fidelity ≠ demonstrated accuracy

Modern heterogeneous-system connection: coherent CPU-GPU systems such as Grace Hopper combine CPU memory, GPU HBM and a coherent C2C interconnect. This is useful conceptual background for relating older coherent-attach experience to current GPU systems, without claiming implementation equivalence.

## 7. NoC / CPU-GPU system drill

Traffic characterization before changing architecture:
- source/destination matrix
- read/write mix
- packet/request size
- sustained vs bursty traffic
- average and peak offered load
- outstanding requests / MLP
- latency-sensitive vs bandwidth-sensitive classes
- QoS priority
- locality/topology

If average utilization is 50% but CPU P99 explodes with GPU traffic, inspect time-windowed utilization, queue depth, arbitration wait, HOL blocking, credit stalls, burst length and downstream congestion before widening links.

Wider links:
- increase theoretical link bandwidth at fixed frequency
- can reduce serialization latency
- cost area/power
- do not fix downstream bottlenecks
- QoS changes may improve CPU tail while hurting GPU throughput; evaluate both objectives.

## 8. Model-quality framework

Start with the architectural question. Then balance:
- **Coverage** — workloads/configurations/phases represented
- **Fidelity** — mechanisms/details represented
- **Accuracy** — measured correlation to a trusted reference
- **Development time**
- **Simulation time**

Fidelity and accuracy are not synonyms. A detailed model can be inaccurate; a simpler calibrated model can be accurate for a specific question.

Functional model: primarily “does behavior/state remain correct?”
Performance model: primarily “when/how fast, under resource constraints?”
Virtual prototype: system-level executable platform that can contain functional and/or timed models.

## 9. C++ / software-engineering drill

Simulator-relevant refresh:
- RAII and explicit ownership
- unique_ptr as default single-owner resource; std::move transfers ownership
- shared_ptr only for genuine shared lifetime; beware cycles
- deque/queue for FIFO behavior
- priority_queue for event scheduling; define earliest-time comparator and deterministic tie-break
- unordered_map for frequent ID lookup when ordering is unnecessary
- composition/configuration vs inheritance
- const/reference semantics
- interfaces and SOLID principles
- observability/stats as first-class model infrastructure

Build/reproducibility:
- CMake describes targets/dependencies and can generate builds for Make/Ninja/IDE toolchains.
- Containers freeze compiler/library/runtime dependencies.
- CI (e.g. Jenkins) automates build, unit/integration/regression tests, coverage and performance-regression checks.
- Models should be composable/configurable so products can reuse components with different sizing/policies.

## 10. Research-backed reminders

OpenCAPI public specifications are archived by the CXL Consortium and include Transaction Layer, Data Link Layer, discovery/configuration and memory-agent material. Use the transaction-layer spec for timing/abstraction exercises.

NVIDIA Hopper publicly documents a large shared L2 and HBM3 subsystem; NVIDIA's public material emphasizes that memory hierarchy and achieved bandwidth are central to GPU performance. Modern NVIDIA coherent platforms (Grace Hopper) provide a useful current example of CPU/GPU coherent memory and address-translation interactions.

Memory-controller research repeatedly shows that scheduler sophistication is workload dependent; do not assume a more complex policy is automatically better. Always connect policy to workload locality, parallelism, fairness and QoS.

## 11. Daily resume-drill rule

For each bullet, answer at three depths:
- **30 seconds:** problem + contribution + outcome.
- **3 minutes:** architecture + implementation + validation.
- **15 minutes:** timing/state/resources, alternatives, bugs, correlation, limitations, and design decisions.

If a detail is uncertain, say so during preparation and reconstruct it from specs/artifacts. Never convert a plausible reconstruction into claimed experience without confirming it.
