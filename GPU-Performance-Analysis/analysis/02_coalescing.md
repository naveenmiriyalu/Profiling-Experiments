# 02 — Coalescing and Stride

## Question

How does a warp's lane-address pattern translate into memory-sector requests, and how does stride change useful-byte efficiency?

## Foundation

For FP32, each lane requests 4 B. A full NVIDIA warp has 32 lanes, so a contiguous load requests:

```text
32 lanes × 4 B = 128 useful B
```

For the working Hopper mental model used in this experiment, requested data is tracked in 32-B sectors. Eight adjacent FP32 lane accesses fit in one 32-B sector.

## Prediction

| Stride | Lane spacing | Lanes / 32-B sector | Sectors / warp | Sector bytes | Useful bytes | Useful/sector-byte efficiency |
|---:|---:|---:|---:|---:|---:|---:|
| 1 | 4 B | 8 | 4 | 128 B | 128 B | 100% |
| 2 | 8 B | 4 | 8 | 256 B | 128 B | 50% |
| 4 | 16 B | 2 | 16 | 512 B | 128 B | 25% |
| 8 | 32 B | 1 | 32 | 1024 B | 128 B | 12.5% |
| 16 | 64 B | <=1 | 32 | 1024 B | 128 B | 12.5% |
| 32 | 128 B | <=1 | 32 | 1024 B | 128 B | 12.5% |

Once each of the 32 lanes lands in a distinct sector, this single warp load cannot require more than 32 distinct sectors.

## Alignment example

An aligned contiguous warp load beginning at 0x1000 spans 0x1000–0x107f and touches four sectors.

If the same 128 useful bytes begin at 0x1004, the accesses cross a sector boundary and touch five sectors. The simple useful-byte efficiency is then:

```text
128 / (5 × 32) = 80%
```

Coalescing and cache behavior are related but distinct questions:

- **Coalescing:** how many sectors are required by the active lane addresses?
- **Cache behavior:** which cache structures contain those sectors, and which requests hit or miss?
- **HBM traffic:** actual off-chip traffic is not assumed to equal source-level useful bytes or sector bytes.

## Experiment

Current kernel:

```cpp
out[i] = in[i * stride];
```

Initial run: stride = 1.

Next steps after validating the raw timing:

1. Inspect PTX and SASS.
2. Profile stride 1 with Nsight Compute.
3. Compare predicted sector behavior with measured sector/cache/HBM metrics.
4. Sweep stride 1, 2, 4, 8, 16, 32.
5. Add an independent alignment-offset experiment.
6. Port the conceptual experiment to HIP/MI355X and derive AMD behavior independently rather than imposing NVIDIA terminology.

## Results

Pending H200 run.
