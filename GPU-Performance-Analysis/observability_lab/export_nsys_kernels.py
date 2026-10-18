#!/usr/bin/env python3
"""Export Nsight Systems GPU kernel activity events from SQLite to JSONL.

This preserves GPU kernel timeline activity; it is NOT a full instruction,
per-warp, or memory-transaction trace suitable for cycle-accurate replay.
"""
import argparse
import json
import sqlite3
from pathlib import Path


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("input_db", type=Path)
    parser.add_argument("output_jsonl", type=Path)
    args = parser.parse_args()

    # Read-only open prevents accidental modifications of source dataset.
    db = sqlite3.connect(f"file:{args.input_db.resolve()}?mode=ro", uri=True)
    db.row_factory = sqlite3.Row
    tables = {r[0] for r in db.execute(
        "SELECT name FROM sqlite_master WHERE type='table'")}
    table = "CUPTI_ACTIVITY_KIND_KERNEL"
    if table not in tables:
        raise SystemExit(f"Missing {table}. Present tables: {sorted(tables)}")

    names = {}
    if "StringIds" in tables:
        columns = {r[1] for r in db.execute("PRAGMA table_info(StringIds)")}
        if {"id", "value"} <= columns:
            names = {r["id"]: r["value"] for r in db.execute(
                "SELECT id, value FROM StringIds")}

    args.output_jsonl.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with args.output_jsonl.open("w", encoding="utf-8") as out:
        for row in db.execute(f"SELECT * FROM {table} ORDER BY start"):
            d = dict(row)
            if "start" not in d or "end" not in d:
                raise SystemExit("Kernel table missing start/end columns")
            key = d.get("demangledName") or d.get("shortName")
            name = names.get(key, key if isinstance(key, str) else None)
            event = {
                "kind": "gpu_kernel_activity",
                "source": "nsys_cupti_activity",
                "name": name,
                "start_ns": d["start"],
                "end_ns": d["end"],
                "duration_ns": d["end"] - d["start"],
                "device_id": d.get("deviceId"),
                "context_id": d.get("contextId"),
                "stream_id": d.get("streamId"),
                "correlation_id": d.get("correlationId"),
                "timestamp_domain": "nsys_export_timeline",
                "is_memory_access_trace": False,
            }
            out.write(json.dumps(event, sort_keys=True) + "\n")
            count += 1
    print(f"Exported {count} GPU kernel events to {args.output_jsonl}")


if __name__ == "__main__":
    main()
