#!/usr/bin/env python3
import json
import sys
from pathlib import Path
import matplotlib.pyplot as plt

summary_path = Path(sys.argv[1]).resolve()
out_dir = summary_path.parent / "charts"
out_dir.mkdir(parents=True, exist_ok=True)

summary = json.loads(summary_path.read_text(encoding="utf-8"))

def bar_chart(items, title, xlabel, ylabel, out_file):
  labels = [k for k, _ in items]
  values = [v for _, v in items]

  plt.figure()
  plt.bar(range(len(labels)), values)
  plt.xticks(range(len(labels)), labels, rotation=45, ha="right")
  plt.title(title)
  plt.xlabel(xlabel)
  plt.ylabel(ylabel)
  plt.tight_layout()
  plt.savefig(out_file, dpi=160)
  plt.close()

# Events by type
events_by_type = summary.get("events_by_type", {})
bar_chart(
  list(events_by_type.items())[:12],
  "Events by Type (last 7 days)",
  "event_type",
  "count",
  out_dir / "events_by_type.png"
)

# Friction domains
friction = summary.get("top_friction_domains", [])
bar_chart(
  [(x["domain"], x["count"]) for x in friction],
  "Top Friction Domains (last 7 days)",
  "domain",
  "count",
  out_dir / "friction_domains.png"
)

# Principles invoked
principles = summary.get("top_principles_invoked", [])
bar_chart(
  [(x["principle"], x["count"]) for x in principles],
  "Principles Invoked (decision_tradeoff)",
  "principle",
  "count",
  out_dir / "principles_invoked.png"
)

print(str(out_dir))
