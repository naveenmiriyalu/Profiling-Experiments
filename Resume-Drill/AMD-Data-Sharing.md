# AMD Data Sharing / Cross-CCX — Resume Drill

## Confirmed experience
- Worked on a high-fidelity model that did not adequately represent coherent sharing across threads for important server behavior.
- Learned/implemented the required sharing/coherence behavior.
- Developed/used a structured test strategy.
- Functional state-transition/invariant checks.
- Cache-to-cache latency and bandwidth tests.
- Configurable data-sharing proxy traces.
- Cross-CCX/topology studies.
- RTL and silicon correlation.
- Maintained regression health and worked with designers.

## Story arc
Existing model worked well for many conventional workloads → server sharing exposed a fidelity gap → understand coherence architecture → add behavior → build tests that fail for the right reasons → correlate simple cases → add topology/contention → use regressions to keep model healthy.

## Validation pyramid
### Functional
- Legal coherence-state transitions.
- Single-writer/multiple-reader invariants.
- Ownership uniqueness where required.
- Dirty-data source correctness.
- Probe/response completion.
- No stuck transactions/deadlocks.

### Microarchitectural performance
- local cache-to-cache latency
- remote/cross-CCX latency
- unloaded bandwidth
- reader-count scaling
- writer/read-sharing patterns
- queue occupancy and stalls

### System
- synthetic data-sharing proxy
- server workload traces
- loaded latency under competing traffic
- fairness and tail latency
- topology sensitivity

## Correlation method
1. Match configuration/frequencies.
2. Match workload and placement.
3. Start unloaded.
4. Decompose latency path.
5. Find first divergent segment.
6. For throughput mismatches inspect queue depth, service rate, occupancy and backpressure.
7. Add contention only after simple cases correlate.
8. Classify mismatch: model bug, intentional abstraction, reference mismatch, or workload/config mismatch.

## Principal-level questions
- When is silicon the reference and when can RTL be more useful?
- How do you avoid tuning a model to one microbenchmark?
- What accuracy metric matters: absolute error, rank ordering, sensitivity, or bottleneck prediction?
- How do you validate tails rather than averages?
- What regression set prevents future coherence changes from breaking sharing?
- When would you document a known error instead of increasing fidelity?
