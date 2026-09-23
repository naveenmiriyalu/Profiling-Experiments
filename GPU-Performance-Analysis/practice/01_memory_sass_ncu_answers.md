# GPU Performance Practice Test 01 — Answer Key

Use this only after completing the question sheet.

1. 128 threads; 4 warps.
2. i=101; warp 1; lane 5.
3. `__global__`: host-launched GPU kernel; `__device__`: GPU function called from GPU code; ordinary function: host by default.
4. It supplies non-aliasing information under the restrict contract, enabling optimizations that would be unsafe if the pointers could overlap in prohibited ways.
5. Ceiling division can launch extra threads in the final block.
6. 128 useful B; 4 sectors; 32 useful B/sector.
7. stride2=8; stride4=16; stride8=32 sectors.
8. There are only 32 lane accesses for the scalar instruction; once every lane occupies a distinct sector there can be no more than 32 distinct touched sectors.
9. 5 sectors; 128/(5×32)=80%.
10. They are observations at different hierarchy/program levels and need not be equal.
11. 100M/32=3.125M warps; ×4=12.5M load sectors and 12.5M store sectors.
12. threadIdx.x→thread special register/TID; blockIdx.x→CTAID; blockDim.x→launch/block dimension loaded for index generation.
13. Multiply forms i×stride; shift by 2 multiplies by sizeof(float)=4.
14. Stride is a runtime kernel parameter; this separately compiled kernel was not specialized to the host's value 1.
15. Read thread/block identity and use integer multiply-add/wide arithmetic to form the global index.
16. Source global input load and output global store.
17. STG consumes R7 produced by LDG; until R7 is ready the dependent consumer cannot issue.
18. PTX is a virtual ISA; ptxas lowers it to architecture-specific SASS.
19. Compare/propagate state across low/high words; mathematically high word dominates unless equal, while machine extended compares can implement the result branchlessly.
20. A, because A_hi=2 > B_hi=1.
21. Low half, because high halves are equal.
22. Both propagate state between machine-word operations: carry for addition; predicate/extended comparison state for comparison.
23. 4 sectors/request and exactly 12.5M load/store sectors.
24. 12,500,480×32=400,015,360 B ≈400.015 MB, essentially the 400 MB source input.
25. It is a throughput/utilization ratio relative to the profiler's peak reference, not a fraction of requested bytes reaching DRAM.
26. L2 operation counters describe L2-level activity, not source global-load/store requests.
27. L1TEX-source L2 reads/writes are exactly 12.5M while total L2 operations are ~18.77M.
28. State the observed difference and investigate cache/writeback/internal timing/traffic with more counters; do not assign a precise cause without evidence.
29. 32 is threads per warp; NCU states a maximum of 16 warps per scheduler.
30. Theoretical occupancy is resource-capacity potential; achieved occupancy is runtime-average active residency.
31. Warp limit: 256/32=8 warps/block; 64 warps/SM / 8 = 8 blocks/SM.
32. No. Registers permit 16 blocks while warp limit permits only 8.
33. Residency does not imply readiness; many resident warps can simultaneously wait on dependencies.
34. Active=residing and not completed; eligible=ready to issue next instruction; issued=selected by scheduler to execute.
35. It indicates waiting on a scoreboard dependency associated with a long-latency memory result; 34.7 cycles is not direct HBM latency.
36. Occupancy only provides potential latency-hiding contexts; those contexts may all be stalled.
37. LDG produces R7→STG consumes R7→scoreboard blocks dependent progress→few eligible warps→73% no-eligible cycles→insufficient ready work to fully drive memory→55% DRAM throughput. Treat final causality as the working explanation supported by current measurements.
38. Vary independent loads per thread/warp (1/2/4/8); keep access coalescing, working-set intent, block size and comparable byte accounting controlled; measure eligible/no-eligible, long scoreboard, issue rate, DRAM throughput, registers/occupancy. Support: more independent requests improve readiness/throughput before another limit. Weakening evidence: no meaningful scheduler/throughput response or another bottleneck clearly dominates.
39. Expected eligible↑, no-eligible↓, latency hiding improves/scoreboard fraction may fall, DRAM throughput↑ until saturation; register usage likely↑.
40. More independent loads may increase ILP/MLP while occupancy can stay constant or even decrease due to extra registers.
41. Input: 8 sectors/request, 25M sectors, 16 useful B/sector. Output: 4 sectors/request, 12.5M sectors.
42. Verify actual stride argument, SASS/address generation, metric semantics, alignment/base allocation, launch selection/warmup, compiler specialization/optimization, and whether the intended kernel was profiled.
43. Source/access pattern→hand byte/sector model→PTX/SASS→request counters→L1/L2/DRAM→occupancy→scheduler/warp stalls→controlled hypothesis test.
44. A kernel can spend most time waiting on memory latency while achieved bandwidth remains below peak; bandwidth saturation is one possible memory bottleneck, not the definition of memory-bound.
45. Shared principle: enough independent outstanding work is needed to hide latency/use bandwidth. CPU relies heavily on OoO, prefetchers, buffers and cores; GPU relies heavily on warp-level latency hiding plus available ILP/MLP.
46. This kernel already has 100% theoretical occupancy capability and substantial achieved occupancy, yet only 0.38 eligible warps/scheduler. More residency alone may not create ready work.
47. Strongest validation: exact 4 sectors/request and 12.5M load/store sectors. Open item: precise origin/semantics of the ~6.25M additional L2 operation-level activity (and related write-path behavior).
48. Increasing W supplies more contexts; increasing R supplies more independent requests/context. Both can increase outstanding work and cover L, until bandwidth B, request queues, issue pipelines, partitions, registers or another resource caps throughput.
49. If request generation/outstanding-request capacity is the bottleneck, doubling service bandwidth does not double delivered throughput; the kernel cannot feed the wider memory system.
50. Outstanding-request/queue occupancy counters; per-partition/channel traffic and utilization; detailed L2 source/op/fill/eviction counters; scheduler eligible/issue/stall counters; DRAM busy/throughput/read-write counters and latency/queue information where available.
