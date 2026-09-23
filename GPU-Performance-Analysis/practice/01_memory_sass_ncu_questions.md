# GPU Performance Practice Test 01 — Memory, SASS, NCU, Occupancy

**Basis:** H200 stride-read experiment completed in `GPU-Performance-Analysis`.

**Suggested time:** 45–60 minutes  
**Rule:** Answer without looking at the report first. Show calculations where relevant.

---

## Part A — CUDA execution model

1. For a launch `kernel<<<2, 64>>>()`, how many total threads and warps are launched?

2. For `blockIdx.x = 1` and `threadIdx.x = 37`, calculate:
   - global thread index
   - warp number within the block
   - lane number

3. Explain the difference between `__global__`, `__device__`, and a normal host C++ function.

4. What promise does `__restrict__` make to the compiler? Why can that matter for optimization?

5. Why is the bounds check `if (i < n)` normally required even when grid size is computed with ceiling division?

---

## Part B — Coalescing and sectors

6. A full NVIDIA warp performs one FP32 load per lane from consecutive addresses. Calculate:
   - useful bytes requested by the warp
   - number of 32-B sectors
   - useful bytes per sector

7. Repeat the sector calculation for input stride 2, 4, and 8.

8. Why does the number of sectors stop increasing beyond 32 sectors for a single scalar load instruction from a 32-lane warp?

9. A contiguous FP32 warp load starts at address `0x1004` rather than an aligned `0x1000`. How many 32-B sectors does it touch, and what is the simple useful-byte/sector-byte efficiency?

10. Explain the difference between:
    - source-level useful bytes
    - L1/TEX request sectors
    - L2 sector operations
    - DRAM bytes

11. Our stride-1 kernel launches 100,000,000 threads. Derive the predicted number of global-load sectors and global-store sectors.

---

## Part C — PTX and SASS

12. Map these CUDA built-ins to the PTX/SASS concepts observed in the experiment:
    - `threadIdx.x`
    - `blockIdx.x`
    - `blockDim.x`

13. In PTX, why did `i * stride * sizeof(float)` contain both a multiply and a shift-left-by-2?

14. Why did the compiler retain the stride multiplication even though the host program passed `stride = 1`?

15. Explain at a high level what this SASS sequence does:

```text
S2R  R2, SR_TID.X
S2UR UR4, SR_CTAID.X
IMAD.WIDE.U32 ...
```

16. What source operations correspond to these instructions?

```text
LDG.E.CONSTANT R7, ...
STG.E ..., R7
```

17. Identify the RAW dependency in the load/store pair and explain why the scoreboard cares about it.

18. Why is PTX not sufficient if the goal is to know the actual Hopper machine instructions executed?

---

## Part D — Multiword arithmetic

19. Represent a 64-bit value A as `[A_hi | A_lo]`. Explain how two 32-bit comparisons can implement a 64-bit unsigned comparison.

20. Given:

```text
A = 0x00000002_00000001
B = 0x00000001_FFFFFFFF
```

which is larger, and why can the low 32 bits be ignored?

21. Given:

```text
A = 0x00000001_00000020
B = 0x00000001_00000010
```

which half determines the result?

22. Relate an extended multiword comparison to carry propagation in multiword addition.

---

## Part E — Interpret the actual H200 NCU data

Use these measured values:

```text
Duration                         294.27 us
Memory Throughput                 2.65 TB/s
DRAM Throughput                  55.16%
L2 Cache Throughput              65.60%

Load sectors/request               4
Store sectors/request              4
Global load sectors       12,500,000
Global store sectors      12,500,000
L1 global-load hit rate            0%

DRAM read sectors         12,500,480
DRAM write sectors        11,892,616

L2 read operations        18,772,080
L2 write operations       18,760,856
L1TEX-source L2 reads     12,500,000
L1TEX-source L2 writes    12,500,000
```

23. Which measurements directly validate our stride-1 coalescing prediction?

24. Convert 12,500,480 DRAM read sectors to bytes using 32 B/sector. How does this compare with the source-level input size?

25. Why is it incorrect to say that 55.16% DRAM throughput means only 55.16% of the requested data reached DRAM?

26. Why should we not conclude that the ~18.77M L2 operations mean the coalescer generated ~18.77M source requests?

27. What evidence shows that the extra L2 operation count occurs downstream of the source request/coalescing level?

28. The source writes 400 MB, but measured DRAM writes are lower. Give the correct scientific response: what may we say, and what should we avoid claiming without further counters?

---

## Part F — Occupancy, scheduling, and latency hiding

Use:

```text
Theoretical active warps/SM       64
Theoretical occupancy           100%
Achieved active warps/SM       45.55
Achieved occupancy             71.17%

Active warps/scheduler          11.15
Eligible warps/scheduler         0.38
No eligible                     73.35%
Issued warp/scheduler             0.27

Warp cycles/issued instruction   41.84
Long-scoreboard waiting          ~34.7 cycles
Long-scoreboard share            ~82.9%
```

29. Why is `11.15 active warps/scheduler` not supposed to be compared with the warp width of 32?

30. Explain theoretical occupancy versus achieved occupancy.

31. Which resource limits theoretical blocks/SM in this experiment?

```text
Block Limit Barriers       32
Block Limit SM             32
Block Limit Registers      16
Block Limit Shared Mem     32
Block Limit Warps           8
```

Show the calculation using 256 threads/block.

32. Does register pressure limit theoretical occupancy here? Defend your answer with the measurements.

33. Explain why 71% achieved occupancy can coexist with 73% of scheduler cycles having no eligible warp.

34. Distinguish:
    - active warp
    - eligible warp
    - issued warp

35. What does a long-scoreboard stall tell us? What does it **not** tell us?

36. Why is this statement wrong?

> "The kernel has high occupancy, therefore memory latency must be fully hidden."

37. Build a causal argument connecting the SASS dependency to the observed 55% DRAM throughput.

---

## Part G — Performance-engineering design questions

38. Design a controlled experiment to test the hypothesis that insufficient per-warp ILP/MLP prevents the kernel from saturating HBM. Specify:
    - independent variable
    - dependent measurements
    - what must remain controlled
    - result that would support the hypothesis
    - result that would falsify or weaken it

39. Suppose a new kernel issues four independent coalesced loads before consuming their values. Predict qualitatively what should happen to:
    - eligible warps
    - no-eligible percentage
    - long-scoreboard stalls
    - DRAM throughput
    - register usage

40. Why must increased DRAM throughput in that experiment not automatically be attributed solely to "more occupancy"?

41. Design the next stride-2 experiment. Before measuring, predict:
    - input sectors/request
    - input sectors total
    - useful bytes/input sector
    - output sectors/request
    - output sectors total

42. If stride 2 unexpectedly still measured four load sectors/request, list at least four things you would verify before claiming the architecture behaves differently from the sector model.

---

## Part H — Interview-style synthesis

43. You are shown a GPU kernel reaching only ~55% of peak memory bandwidth. Give a disciplined investigation flow from source code to architectural root cause.

44. Explain in two minutes why "memory-bound" and "memory-bandwidth-saturated" are not synonyms.

45. Compare the CPU streaming-copy/MLP problem with the GPU stride-read experiment. What performance principle is shared, and what latency-hiding mechanisms differ?

46. An interviewer says: "Just increase occupancy." Explain why that advice may not fix this kernel.

47. Give the strongest evidence from this experiment that our analytical model was correct, and separately identify one observation we still have **not** fully explained.

---

## Challenge

48. Construct a compact performance model with these conceptual variables:

```text
W = resident warps
E = eligible warps
R = independent memory requests per warp
L = effective memory latency
B = sustainable memory bandwidth
```

Explain, without needing an exact closed-form equation, how changing W and R can affect latency hiding and why throughput eventually stops increasing when B or another pipeline resource becomes the bottleneck.

49. If an architecture had twice the peak HBM bandwidth but identical latency, scheduler resources, and outstanding-request capacity, explain why this exact kernel might fail to obtain anything close to a 2× speedup.

50. What new hardware or simulator counters would you want if your goal were to distinguish among:
    - insufficient outstanding requests
    - memory-partition imbalance
    - L2 internal traffic amplification
    - scheduler starvation
    - DRAM saturation?
