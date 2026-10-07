# Qualcomm — SMMU / IOMMU Sizing Quick Sheet

## Path
Device/DMA → SMMU → IOTLB → page-table walk/cache → translated transaction → NoC/SLC/DRAM.

## Core concepts
- **SMMU/IOMMU:** translation and protection for device memory accesses.
- **Stream ID/context:** selects translation/protection context for a traffic source.
- **IOTLB:** caches device translations.
- **TLB reach:** approximately entries × page size.
- **Page walk:** translation miss can create multiple dependent memory accesses.
- **ATS:** permits capable devices to cache translations obtained through translation services.
- **PRI:** supports page-request style handling in capable systems.
- **Invalidation:** removes stale cached translations after mapping changes.
- **Translation fault:** permission/unmapped/translation error; distinct from a normal IOTLB miss.

## Sizing equations
- Translation request rate ≈ payload transaction rate where translation lookup is required.
- IOTLB miss walks/s ≈ request rate × miss rate.
- Walk traffic ≈ walks/s × external walk references/miss × bytes/reference.
- Concurrent walkers ≈ walk rate × average walk latency.
- Average translation latency ≈ hit latency + miss rate × miss penalty.

## IOTLB reach
Exercises:
- 2048 entries × 4 KiB pages: calculate reach.
- Repeat for 64 KiB pages.
- Compare reach to a 512-MB streaming DMA working set.
- Discuss larger IOTLB vs larger pages vs translation prefetch vs ATS vs more walkers.

## Page-walk bandwidth / concurrency
Device generates 500M translated transactions/s with 0.2% IOTLB misses:
1. Misses/s?
2. Four external 64-B page-table reads/miss: walk BW?
3. 300-ns average walk latency: concurrent walks required?
4. What happens if walker capacity is insufficient?
5. Why can tiny page-walk GB/s still gate huge payload BW?

## SoC interaction
Page-table walks share NoC/cache/memory resources with payload. Translation pressure can cause payload stalls even while DRAM payload utilization looks low. Check forward progress and QoS for translation traffic.

## Invalidations / context switching
Frequent remapping can cause invalidation bursts, IOTLB refills and tail-latency spikes. Compare global vs targeted invalidation and inspect context-switch behavior.

## Faults
Do not confuse an IOTLB miss with a translation fault. Fault paths protect isolation and may be recoverable in supported systems, but should not be treated as normal throughput paths.

## Integrated problem
NPU DMA=64 GB/s, transaction=64 B, 4096-entry IOTLB, 4-KiB pages, 1-GB mapped working set, miss rate=0.5%, four external 64-B walk reads/miss, average walk latency=250 ns.

Calculate:
1. Payload transactions/s.
2. IOTLB reach.
3. Misses/s.
4. Page-walk BW.
5. Concurrent walks.
6. Whether 256 walkers is enough on average.
7. What changes with 64-KiB pages.
8. How translation traffic could worsen CPU P99 despite DRAM headroom.

## Counters / diagnostics
IOTLB hit/miss, walk-cache hit, active walkers, walk queue occupancy, invalidations, faults, translation latency, payload stalls, NoC link/queue occupancy, and MC queue/channel balance.

## Interview answer
Separate payload performance from translation performance. Quantify device transaction rate and mapped working set; check IOTLB reach/hit rate, page size, walk-cache behavior, walk latency and walker concurrency; account for page-table traffic in NoC/memory; inspect invalidations/context switching; then correlate translation stalls with payload BW and P99 before resizing the SMMU.
