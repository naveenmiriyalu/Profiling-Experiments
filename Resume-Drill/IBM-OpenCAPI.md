# IBM OpenCAPI — Resume Drill

## Confirmed experience
- Modeled OpenCAPI/coherent accelerator attach in an IBM architecture/performance simulation environment.
- Worked from architecture specifications and designer timing diagrams.
- Integrated the feature with the existing uncore/memory subsystem.
- Prior POWER coherence-modeling experience was relevant to reasoning about a new coherent participant.
- The modeling problem required choosing which protocol/timing details to preserve and which to abstract.

## Public architecture background
OpenCAPI separates transaction semantics from lower link details. For interview preparation, reason primarily at transaction level: commands, responses, data movement, ordering, flow control, coherent memory behavior, address translation, queues and latency.

## Reconstruction checklist
Do not convert any item below into claimed experience until confirmed from memory/artifacts.
- Exact attachment point in IBM simulator.
- Transaction classes/enums implemented.
- Request/data/response path separation.
- Credit types and return rules.
- Queue structures and depths.
- Backpressure/retry behavior.
- Coherence requests/probes/ownership transitions.
- Address translation / ATC treatment.
- MMIO/control path.
- Clock-domain boundaries.
- Statistics added.
- Validation workloads and correlation reference.

## Timing-diagram method
For each spec timing diagram:
1. Draw actors horizontally.
2. Mark request/response/data events.
3. Annotate latency between visible events.
4. Mark resource acquisition/release.
5. Mark arbitration points.
6. Mark finite queues/credits.
7. Mark possible backpressure.
8. Mark clock-domain crossings.
9. Collapse deterministic internal stages with no externally relevant contention.
10. Preserve stages where occupancy changes throughput or latency.

### Example abstraction
Detailed:
request accepted → decode → queue → arbitrate → transmit → receiver decode → host queue.

Possible performance abstraction:
request accepted → consume queue/credit → schedule host-arrival event at t+L → release/return resource according to protocol.

This abstraction is only valid if hidden stages cannot introduce relevant contention or backpressure.

## Event-driven implementation questions
- What timestamp representation was used?
- How were different clock domains represented?
- Were events stored in a priority queue?
- How were equal timestamps deterministically ordered?
- Did IP arbitration live inside the IP model rather than global event priority?
- Could a fixed-latency path be one scheduled completion event?
- Which OpenCAPI resources forced intermediate events?

## Interview answer spine
“OpenCAPI was a good example of translating a new architecture specification into an existing performance-modeling framework. I worked with the spec and designers to understand transaction and timing behavior, identified the portions that materially affected performance, integrated those with the existing uncore/memory model, and kept the implementation extensible as the interface evolved.”

Then stop and let interviewer choose the drill-down.

## Drill questions
1. Why was a fixed-latency model insufficient?
2. What would credit starvation look like in model statistics?
3. How would you validate unloaded latency separately from loaded throughput?
4. How would you model a CDC without reproducing synchronizer RTL?
5. What would cause a trace-driven OpenCAPI model to diverge from execution-driven behavior?
6. Which protocol details are correctness-only versus performance-critical?
7. How would you prove an abstraction is safe?
