#!/usr/bin/env python3
import json
import sys
from pathlib import Path
from datetime import datetime

summary_path = Path(sys.argv[1]).resolve()
review_dir = summary_path.parent
charts_dir = review_dir / "charts"

summary = json.loads(summary_path.read_text(encoding="utf-8"))

counts = summary.get("counts", {})
events_by_type = summary.get("events_by_type", {})
friction = summary.get("top_friction_domains", [])
principles = summary.get("top_principles_invoked", [])
window = summary.get("window", {})

def pct(v):
    if v is None:
        return "N/A"
    return f"{v*100:.1f}%"

html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Weekly Engineering Dashboard</title>
<style>
body {{
  font-family: system-ui, -apple-system, BlinkMacSystemFont, sans-serif;
  margin: 0;
  background: #0f172a;
  color: #e2e8f0;
}}
.container {{
  max-width: 1200px;
  margin: 0 auto;
  padding: 40px;
}}
h1 {{
  margin-bottom: 4px;
}}
.subtle {{
  color: #94a3b8;
  font-size: 14px;
}}
.grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(180px, 1fr));
  gap: 16px;
  margin-top: 24px;
}}
.card {{
  background: #1e293b;
  padding: 16px;
  border-radius: 8px;
}}
.metric {{
  font-size: 28px;
  font-weight: bold;
}}
.section {{
  margin-top: 48px;
}}
.chart {{
  margin-top: 16px;
}}
ul {{
  margin: 8px 0 0 16px;
}}
img {{
  max-width: 100%;
  border-radius: 6px;
  background: #fff;
}}
.footer {{
  margin-top: 60px;
  font-size: 12px;
  color: #64748b;
}}
</style>
</head>
<body>
<div class="container">
  <h1>📊 Weekly Engineering Dashboard</h1>
  <div class="subtle">
    Window: {window.get("since")} → {window.get("until")}
  </div>

  <div class="grid">
    <div class="card">
      <div class="metric">{counts.get("writes", 0)}</div>
      <div>Writes</div>
    </div>
    <div class="card">
      <div class="metric">{counts.get("failures", 0)}</div>
      <div>Failures / Friction</div>
    </div>
    <div class="card">
      <div class="metric">{counts.get("tradeoff_events", 0)}</div>
      <div>Tradeoff Events</div>
    </div>
    <div class="card">
      <div class="metric">{counts.get("large_change_events", 0)}</div>
      <div>Large Changes</div>
    </div>
    <div class="card">
      <div class="metric">{counts.get("reversal_events", 0)}</div>
      <div>Reversals</div>
    </div>
    <div class="card">
      <div class="metric">{pct(counts.get("test_stability_rate"))}</div>
      <div>Test Stability</div>
    </div>
  </div>

  <div class="section">
    <h2>🔁 Top Friction Domains</h2>
    <ul>
      {''.join(f"<li>{d['domain']} ({d['count']})</li>" for d in friction)}
    </ul>
  </div>

  <div class="section">
    <h2>🧠 Principles Invoked</h2>
    <ul>
      {''.join(f"<li>{p['principle']} ({p['count']})</li>" for p in principles)}
    </ul>
  </div>

  <div class="section">
    <h2>📈 Event Distribution</h2>
    <div class="chart">
      <img src="charts/events_by_type.png">
    </div>
  </div>

  <div class="section">
    <h2>⚠ Friction Trends</h2>
    <div class="chart">
      <img src="charts/friction_domains.png">
    </div>
  </div>

  <div class="section">
    <h2>🏗 Principles Heat</h2>
    <div class="chart">
      <img src="charts/principles_invoked.png">
    </div>
  </div>

  <div class="footer">
    Generated {datetime.utcnow().isoformat()}Z
  </div>
</div>
</body>
</html>
"""

output_path = review_dir / "index.html"
output_path.write_text(html, encoding="utf-8")

print(str(output_path))
