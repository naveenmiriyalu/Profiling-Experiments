# Qualcomm — Christine Chan — SoC Sizing V2

## Sizing method
Product SLA → workload → compute → local SRAM/cache → NoC → SLC → MC/DRAM → QoS/latency → power/thermal/area → sensitivity → validation.

Always separate **capacity**, **throughput**, and **latency/concurrency** sizing.

## Traffic accounting
Track useful payload, cache-line/sector amplification, request and response traffic, RFO/write allocate, dirty writebacks, coherency/protocol metadata, compression, burst factor, and retries.

## CPU cluster
- Core throughput: cores × frequency × IPC.
- LLC miss rate from MPKI and instruction rate.
- Miss BW = misses/s × line size.
- Outstanding misses ≈ miss BW × loaded latency / line size.
- Back-solve maximum instruction rate from a fixed DRAM budget.
- Compare wide/fewer vs smaller/more cores for MLP, cache, NoC injection, power, and tail latency.

## GPU / graphics
- Frame budget = 1000/FPS ms.
- Peak compute = work/frame × FPS / effective utilization.
- Account for color/depth read/write traffic, textures, render targets, compression, and tile-local reuse.
- Size to frame-time tails, not average FPS alone.

## NPU / SRAM / tiling
- GEMM ops ≈ 2MNK.
- Required peak TOPS = sustained demand / effective utilization.
- Explicitly size activation, weight, and output tiles plus double buffering.
- Check SRAM capacity, bank bandwidth, ports, NoC and DRAM independently.
- Use roofline to avoid adding MACs to a bandwidth-limited design.

## SRAM/cache
Check capacity, banks, ports, frequency, access balance, line amplification, hit rate, replacement, and QoS independently.

## NoC
Size individual links and critical cuts, not aggregate fabric capacity. Build producer→consumer traffic matrices. Check topology, bisection, path length, hotspots, router pipeline, VCs, arbitration, credits, and QoS.

## Buffers / credits
- Credit window ≈ target BW × credit RTT / flit size.
- Burst FIFO ≈ (arrival rate − service rate) × burst duration.
- Deeper queues can absorb bursts while worsening tail latency.

## SLC
Translate per-client injection and hit rates into DRAM traffic; add writebacks. Sweep capacity to find the hit-rate knee. Check bank/port contention and cross-IP interference.

## DRAM / memory controller
Peak = MT/s × width/8 × channels. Apply workload-specific efficiency. Check read/write turnaround, row locality, bank/channel balance, controller queue depth, scheduler, outstanding requests, and QoS.

## Latency
Decompose request path: source cache → request NoC → SLC → MC queue → DRAM → return NoC. Separate fixed latency from load-dependent queueing.

## QoS
Distinguish latency-critical CPU, deadline-critical ISP/display, and throughput-oriented GPU/NPU. Consider weighted arbitration, aging, bounded priority, reservations, and admission control.

## Camera / ISP / display
BW = W × H × bits/pixel / 8 × FPS. Count every intermediate read/write surface, compression, SLC reuse, decoder output, and concurrent display traffic.

## LLM
Start with weight bytes/token, then add KV-cache capacity/traffic, activations, quantization metadata, batch effects, cache reuse, and concurrent UI/system traffic.

## Power / thermal / area
Dynamic power ~ αCV²f. Individual IP peak points usually cannot be summed under a sustained SoC thermal envelope. Compare area spent on compute, SRAM/SLC, NoC width, and memory controllers using sensitivity studies.

## Sensitivity and SKU sizing
Sweep workload ±10/20/30%, cache hit rate, compression, loaded latency, DRAM efficiency, concurrency, and thermal operating points. Find architectural knee points for low/mid/high SKUs instead of scaling every block linearly.

## Validation
Progress from analytical model → trace/event model → execution-driven model where feedback matters → RTL/emulation → silicon. Correlate traffic, latency, utilization, queue occupancy, power, and tail behavior.

## Whiteboard drill
Given CPU/GPU/NPU/ISP/display requirements:
1. Build traffic ledger.
2. Size compute.
3. Size SRAM/cache.
4. Identify critical NoC cuts.
5. Size SLC and memory channels/controllers.
6. Compute outstanding concurrency.
7. Define QoS.
8. Check thermal/area.
9. Sweep uncertain assumptions.
10. State validation plan.
