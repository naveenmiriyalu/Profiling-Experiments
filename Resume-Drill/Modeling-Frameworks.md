# Modeling Frameworks / Software Engineering — Resume Drill

## Model taxonomy
These labels overlap; do not treat them as mutually exclusive.
- functional vs performance
- analytical/statistical
- trace-driven
- execution-driven
- event-driven
- cycle-driven
- cycle-accurate vs cycle-approximate
- transaction-level
- hybrid/mixed fidelity

## Selection framework
Architectural question first, then:
1. coverage
2. fidelity
3. demonstrated accuracy
4. development time
5. simulation time
6. maintainability/extensibility

High fidelity does not guarantee accuracy.

## TLM mental model
TLM is primarily an interface/modeling style: pass transactions rather than reproduce signal toggles. Timing fidelity behind the transaction interface is a separate choice.

## Event framework
Event = timestamp + type/callback + transaction/context + deterministic sequence/tie-break metadata.
Priority queue selects earliest timestamp.
Architectural arbitration belongs inside the resource model.
A global scheduler should not accidentally implement QoS.

## C++ refresh
- RAII
- unique_ptr and move semantics
- shared_ptr only for genuine shared lifetime
- queue/deque
- priority_queue
- unordered_map
- references/const
- polymorphism/interfaces
- composition over unnecessary inheritance
- SOLID as maintainability principles, not dogma

## Build/CI
CMake: target/dependency description and portable build generation.
Docker/container: reproducible toolchain/dependencies.
Jenkins/CI: automate build, unit/integration/regression, coverage and performance-regression checks.

## Model observability
Stats are part of the architecture of a simulator:
- latency decomposition
- queue occupancy
- resource utilization
- stall reasons
- credits
- arbitration wins/waits
- throughput
- state-transition counters

A model that produces only final performance numbers is much harder to validate and debug.
