# GPU Performance Practice Test 02 — Answer Key

1. ILP: independent instructions available within an execution context; MLP: independent memory operations outstanding; occupancy: resident active-warp capacity/runtime residency depending metric; active warp: resident unfinished warp; eligible: ready to issue; issued: selected to execute. Occupancy/eligibility and ILP/MLP are often conflated.
2. Resident warps can simultaneously be stalled, leaving no eligible warp.
3. The warp can inject multiple requests before reaching a consumer that waits for them; aggregate memory work rises even if the later wait is longer.
4. CPU: SIMD + unrolling + OoO + buffers + hardware prefetchers + cores. GPU experiment: SIMT warp width + warp scheduling + explicit per-warp independent LDGs.
5. SIMD describes elements operated on by an instruction; MLP describes concurrent outstanding memory operations.
6. 25M/32=781,250 warps; ×4=3,125,000 LDGs.
7. 12.5M/32=390,625 warps; ×8=3,125,000 LDGs. Aggregate dynamic warp-level load count is controlled.
8. 0.8GB/0.000299≈2.676TB/s; 0.8/0.000199≈4.020TB/s; ≈1.50×.
9. 32 lanes×4B=128B; /32B=4 sectors; 128/4=32 useful B/sector.
10. Aggregate source request traffic remains equally coalesced and equal in sector count.
11. MLP4.
12. More independent requests are injected before the warp reaches its dependent phase; per-warp waiting can rise while system throughput rises.
13. No. Occupancy rises 81.37→85.08% from MLP4→8 while useful bandwidth falls.
14. No: ptxas reports zero spills for MLP8. Register count alone is insufficient; spill and occupancy evidence matter.
15. Both resources allow 8 blocks; 8 blocks×8 warps/block=64 warps/SM, the theoretical maximum.
16. A high utilization metric identifies pressure but not by itself the causal limiting resource; correlated pipeline/throughput behavior and controlled experiments are required.
17. Source code does not guarantee instruction ordering; the experiment requires independent LDGs to be exposed in machine code.
18. Four separate LDG→result-register→STG chains, with LDGs appearing before consumers.
19. Loads would be serialized with their consumers, weakening the intended per-warp MLP manipulation.
20. More independent addresses/results must remain live simultaneously.
21. a sectors/request=4; b both 400MB+400MB; c both 3.125M LD/ST requests; d zero spills; e occupancy rises and theoretical remains 100%; f L2/DRAM min/max do not show the dramatic upstream widening.
22. Temporal grouping: half as many warps at MLP8, twice as many independent loads/live results per warp.
23. Upstream request distribution is less uniform at MLP8; do not label metric instances as physical HBM channels without establishing mapping.
24. MLP4 exposes four independent LDGs/warp, increasing outstanding work and raising DRAM/L2 utilization from 55.9/66.8% to 85.2/90.6% while useful traffic/coalescing are controlled.
25. MLP8 adds no aggregate request work, does not improve downstream throughput, increases live state and dependency span, and operates after the hierarchy is already highly utilized. MLP4 is the empirical knee; do not invent a specific undocumented queue as the cause.
26. Hand sector model→sector/request counters→traffic→occupancy/resource limits→eligible/no-eligible/stalls→controlled MLP sweep→DRAM/L2 throughput.
27. Reduce thread count as independent loads/thread rises so total active elements/bytes remain fixed, as in this benchmark.
28. More warps adds execution contexts; more per-warp requests increases ILP/MLP inside each context. Either can increase outstanding work but costs/limits differ.
29. More MLP may improve request concurrency, while lower occupancy reduces the number of latency-hiding contexts; performance depends on which dominates.
30. Cover Copy baseline, exact coalescing validation, scoreboard starvation, Triad, controlled MLP sweep, SASS verification, knee at MLP4, and hypothesis elimination.
31. Not necessarily. If request generation/L2/latency hiding limits delivered throughput, more HBM peak alone does not provide proportional speedup; variants closer to hierarchy saturation may respond differently.
32. One conceptual form: achieved useful BW is bounded by transaction efficiency × ability to generate/maintain outstanding work × sustainable hierarchy bandwidth. MLP sweep changes concurrency while controlling useful bytes/coalescing; stride sweep changes transaction efficiency while holding useful work conceptually fixed.
