# GPU Performance Practice Test 02 — MLP, Latency Hiding, and Bottleneck Diagnosis

**Basis:** H200 Copy → Triad → controlled MLP1/2/4/8 experiments.

**Suggested time:** 45 minutes. Do the questions before opening the answer key.

## Part A — Concepts

1. Define instruction-level parallelism (ILP), memory-level parallelism (MLP), occupancy, active warp, eligible warp, and issued warp. Which pairs are commonly confused?

2. Why can a GPU kernel have high occupancy but still fail to hide memory latency?

3. Explain why two independent loads can increase MLP even if the warp later spends more cycles stalled on a scoreboard dependency.

4. Contrast CPU STREAM latency hiding with the mechanisms used by the GPU Copy kernel. Include SIMD vectorization, loop unrolling, OoO execution, prefetching, and warp scheduling.

5. Explain why SIMD width and MLP are not the same quantity.

## Part B — Hand calculations

6. MLP4 uses 25,000,000 threads. Calculate the number of warps and total warp-level LDG instructions if every warp executes four LDGs.

7. MLP8 uses 12,500,000 threads and eight LDGs/warp. Perform the same calculation. What important control property does this reveal?

8. Every variant moves 400 MB of useful input and 400 MB of useful output. If MLP1 takes 0.299 ms and MLP4 takes 0.199 ms, calculate useful bandwidth for both and their speedup.

9. For a fully coalesced FP32 load, derive 4 sectors/request and 32 useful bytes/sector.

10. If MLP4 and MLP8 both report 12.5M load sectors, what does that tell you about their aggregate coalescing/traffic?

## Part C — Interpret the measurements

Use:

| Metric | MLP1 | MLP2 | MLP4 | MLP8 |
|---|---:|---:|---:|---:|
| Useful BW TB/s | 2.674 | 3.671 | 4.010 | 3.865 |
| DRAM % | 55.94 | 76.66 | 85.15 | 82.80 |
| L2 % | 66.80 | 86.64 | 90.58 | 88.61 |
| No eligible % | 77.12 | 78.35 | 83.22 | 87.13 |
| Long scoreboard cycles | 40.9 | 48.5 | 71.6 | 76.1 |
| Achieved occupancy % | 70.83 | 75.42 | 81.37 | 85.08 |
| Registers/thread | 8 | 12 | 20 | 30 |

11. At which point is the observed performance knee?

12. Why does increasing long-scoreboard waiting not contradict the increase in bandwidth from MLP1 to MLP4?

13. Does the table support “higher occupancy always improves performance”? Explain with MLP4 vs MLP8.

14. Does MLP8 appear to be slower because of register spilling? What additional evidence is required?

15. MLP8's register block limit is 8 and warp block limit is 8. Why does this not reduce theoretical occupancy below 100% for this launch configuration?

16. Why should 90.58% L2 throughput not automatically be translated into “L2 is definitively the bottleneck”?

## Part D — SASS reasoning

17. MLP4 SASS contains four LDGs before four STGs. Why was verifying this essential before interpreting the benchmark?

18. Draw the dependency graph for four independent LDG results feeding four later STGs.

19. What would it mean for the experiment if SASS instead showed LDG0→STG0→LDG1→STG1?

20. Why does increasing MLP tend to increase register requirements?

## Part E — Hypothesis elimination

21. For each proposed MLP8 explanation, identify the measurement that weakens or eliminates it:
   a. bad coalescing
   b. more useful bytes
   c. more aggregate LSU requests
   d. register spilling
   e. occupancy collapse
   f. obvious downstream memory imbalance

22. MLP4 and MLP8 both issue 3.125M load requests and 3.125M store requests. Explain what actually changed between them.

23. L1TEX request min/max widens strongly at MLP8, while L2 and DRAM reductions remain much tighter/similar. What may we conclude, and what must we avoid claiming?

24. Write the most defensible one-paragraph explanation for why MLP4 is faster than MLP1.

25. Write the most defensible one-paragraph explanation for why MLP8 does not improve on MLP4.

## Part F — Experiment design / interview questions

26. An interviewer gives you a memory kernel at 55% of peak HBM bandwidth. Give a measurement plan that distinguishes poor coalescing, insufficient MLP, occupancy limitation, and true bandwidth saturation.

27. Design an experiment that changes MLP without changing total useful bytes.

28. Why is “add more warps” different from “add more independent requests per warp”?

29. Suppose MLP16 used enough registers to reduce theoretical occupancy to 50%. Predict two competing effects on performance.

30. How would you explain this entire Copy→Triad→MLP experiment in three minutes to a GPU performance-modeling interviewer?

## Challenge

31. A future GPU doubles HBM peak bandwidth but leaves memory latency, request tracking, scheduler resources, and L2 throughput unchanged. Predict whether MLP1, MLP4, and MLP8 would all receive a 2× speedup, and explain why.

32. Propose a simple analytical model that separates:
- useful bytes,
- transaction efficiency,
- number of outstanding requests,
- latency-hiding capacity,
- sustainable hierarchy bandwidth.

Explain where the MLP sweep fits in that model and where the upcoming stride sweep fits.
