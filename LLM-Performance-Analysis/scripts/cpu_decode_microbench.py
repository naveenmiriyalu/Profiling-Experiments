#!/usr/bin/env python3
import argparse,time
import numpy as np
p=argparse.ArgumentParser()
p.add_argument("--hidden",type=int,default=4096)
p.add_argument("--ffn",type=int,default=11008)
p.add_argument("--steps",type=int,default=100)
p.add_argument("--warmup",type=int,default=10)
a=p.parse_args()
rng=np.random.default_rng(1)
x=rng.standard_normal(a.hidden,dtype=np.float32)
w1=rng.standard_normal((a.ffn,a.hidden),dtype=np.float32)
w2=rng.standard_normal((a.hidden,a.ffn),dtype=np.float32)
def step(x):
    y=w1@x
    y=np.maximum(y,0)
    return w2@y
for _ in range(a.warmup): x=step(x); x/=np.linalg.norm(x)+1e-9
t=time.perf_counter()
for _ in range(a.steps): x=step(x); x/=np.linalg.norm(x)+1e-9
dt=time.perf_counter()-t
weight_bytes=(w1.nbytes+w2.nbytes)
flops=2*a.hidden*a.ffn*2
print(f"hidden={a.hidden} ffn={a.ffn} steps={a.steps}")
print(f"time/step={dt/a.steps*1e3:.3f} ms")
print(f"steps/s={a.steps/dt:.3f}")
print(f"nominal weight bytes/step={weight_bytes/1e6:.2f} MB")
print(f"nominal FLOPs/step={flops/1e9:.3f} GFLOP")
print(f"nominal AI={flops/weight_bytes:.3f} FLOP/B")
