#!/usr/bin/env python3
import argparse,re,pathlib,csv
p=argparse.ArgumentParser();p.add_argument("directory");p.add_argument("-o",default="summary.csv");a=p.parse_args()
rows=[]
patterns={"ttft":r"TTFT[^0-9]*([0-9.]+)","itl":r"(?:ITL|inter.?token)[^0-9]*([0-9.]+)","tokens_s":r"(?:tokens/s|token throughput)[^0-9]*([0-9.]+)"}
for f in pathlib.Path(a.directory).glob("*.log"):
 text=f.read_text(errors="ignore"); row={"case":f.stem}
 for k,pat in patterns.items():
  m=re.search(pat,text,re.I); row[k]=m.group(1) if m else ""
 rows.append(row)
with open(a.o,"w",newline="") as h:
 w=csv.DictWriter(h,fieldnames=["case","ttft","itl","tokens_s"]);w.writeheader();w.writerows(rows)
print(a.o)
