#!/usr/bin/env python3
"""Create reproducible gzip sidecars and report transfer sizes; no server dependency."""
import gzip
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
report = []
for path in sorted(root.iterdir()):
    if path.suffix not in {".wasm", ".pck", ".js", ".html", ".ttf"}:
        continue
    raw = path.read_bytes()
    compressed = gzip.compress(raw, compresslevel=9, mtime=0)
    path.with_name(path.name + ".gz").write_bytes(compressed)
    report.append({"file": path.name, "raw_bytes": len(raw), "gzip_bytes": len(compressed)})
(root / "size-report.json").write_text(json.dumps(report, indent=2) + "\n")
print(json.dumps({"raw_bytes": sum(x["raw_bytes"] for x in report),
                  "gzip_bytes": sum(x["gzip_bytes"] for x in report)}))
