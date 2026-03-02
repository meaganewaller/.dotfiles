#!/usr/bin/env python3
"""
Generate a tabbed HTML dashboard for weekly engineering review.
Includes: Dashboard (metrics), Review (rendered markdown), Data (formatted JSON)
"""
import json
import sys
import re
from pathlib import Path
from datetime import datetime

summary_path = Path(sys.argv[1]).resolve()
review_dir = summary_path.parent
charts_dir = review_dir / "charts"
review_md_path = review_dir / "review.md"

summary = json.loads(summary_path.read_text(encoding="utf-8"))
summary_json = json.dumps(summary, indent=2)

# Read markdown review if exists
review_md = ""
if review_md_path.exists():
    review_md = review_md_path.read_text(encoding="utf-8")

def md_to_html(md_text: str) -> str:
    """Convert markdown to styled HTML for readable display."""
    lines = md_text.split('\n')
    html_lines = []
    in_code_block = False
    in_list = False
    in_ordered_list = False
    in_table = False
    in_table_header = True
    paragraph_buffer = []

    def flush_paragraph():
        nonlocal paragraph_buffer
        if paragraph_buffer:
            text = ' '.join(paragraph_buffer)
            text = apply_inline_styles(text)
            html_lines.append(f'<p>{text}</p>')
            paragraph_buffer = []

    def apply_inline_styles(text):
        # Skip HTML comments (placeholders)
        if '<!-- PLACEHOLDER:' in text or '<!-- END:' in text:
            return ''
        # Bold
        text = re.sub(r'\*\*([^*]+)\*\*', r'<strong>\1</strong>', text)
        # Italic
        text = re.sub(r'(?<!\*)\*([^*]+)\*(?!\*)', r'<em>\1</em>', text)
        text = re.sub(r'(?<!_)_([^_]+)_(?!_)', r'<em>\1</em>', text)
        # Inline code
        text = re.sub(r'`([^`]+)`', r'<code>\1</code>', text)
        # Links
        text = re.sub(r'\[([^\]]+)\]\(([^)]+)\)', r'<a href="\2">\1</a>', text)
        return text

    for i, line in enumerate(lines):
        # Code blocks
        if line.startswith('```'):
            flush_paragraph()
            if in_code_block:
                html_lines.append('</code></pre>')
                in_code_block = False
            else:
                lang = line[3:].strip() or 'text'
                html_lines.append(f'<pre class="code-block"><code class="language-{lang}">')
                in_code_block = True
            continue

        if in_code_block:
            escaped = line.replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            html_lines.append(escaped)
            continue

        # Tables
        if '|' in line and line.strip().startswith('|'):
            flush_paragraph()
            cells = [c.strip() for c in line.strip().split('|')[1:-1]]
            # Check if separator row
            if all(re.match(r'^:?-+:?$', c) for c in cells if c):
                in_table_header = False
                continue
            if not in_table:
                html_lines.append('<div class="table-wrapper"><table>')
                in_table = True
                in_table_header = True
            tag = 'th' if in_table_header else 'td'
            styled_cells = [apply_inline_styles(c) for c in cells]
            html_lines.append(f'<tr>{"".join(f"<{tag}>{c}</{tag}>" for c in styled_cells)}</tr>')
            continue
        elif in_table:
            html_lines.append('</table></div>')
            in_table = False
            in_table_header = True

        # Close list if needed
        stripped = line.strip()
        if in_list and not stripped.startswith('- ') and not stripped.startswith('* '):
            html_lines.append('</ul>')
            in_list = False
        if in_ordered_list and not re.match(r'^\d+\.\s', stripped):
            html_lines.append('</ol>')
            in_ordered_list = False

        # Headers
        if line.startswith('#'):
            flush_paragraph()
            match = re.match(r'^(#{1,6})\s+(.+)$', line)
            if match:
                level = len(match.group(1))
                content = apply_inline_styles(match.group(2))
                html_lines.append(f'<h{level}>{content}</h{level}>')
            continue

        # Unordered lists
        if stripped.startswith('- ') or stripped.startswith('* '):
            flush_paragraph()
            if not in_list:
                html_lines.append('<ul class="styled-list">')
                in_list = True
            content = stripped[2:]
            content = apply_inline_styles(content)
            html_lines.append(f'<li>{content}</li>')
            continue

        # Ordered lists
        ol_match = re.match(r'^(\d+)\.\s+(.+)$', stripped)
        if ol_match:
            flush_paragraph()
            if not in_ordered_list:
                html_lines.append('<ol class="styled-list">')
                in_ordered_list = True
            content = apply_inline_styles(ol_match.group(2))
            html_lines.append(f'<li>{content}</li>')
            continue

        # Horizontal rule
        if re.match(r'^(-{3,}|\*{3,}|_{3,})$', stripped):
            flush_paragraph()
            html_lines.append('<hr>')
            continue

        # Blockquote
        if stripped.startswith('>'):
            flush_paragraph()
            content = apply_inline_styles(stripped[1:].strip())
            html_lines.append(f'<blockquote>{content}</blockquote>')
            continue

        # Empty line = paragraph break
        if not stripped:
            flush_paragraph()
            continue

        # Regular text - accumulate into paragraph
        paragraph_buffer.append(stripped)

    # Flush remaining content
    flush_paragraph()
    if in_list:
        html_lines.append('</ul>')
    if in_ordered_list:
        html_lines.append('</ol>')
    if in_table:
        html_lines.append('</table></div>')
    if in_code_block:
        html_lines.append('</code></pre>')

    return '\n'.join(html_lines)

def pct(v):
    if v is None:
        return "N/A"
    return f"{v*100:.1f}%"

counts = summary.get("counts", {})
events_by_type = summary.get("events_by_type", {})
friction = summary.get("top_friction_domains", [])
friction_sub = summary.get("top_friction_subdomains", [])
principles = summary.get("top_principles_invoked", [])
skills = summary.get("top_skills_used", [])
projects = summary.get("projects", [])
files_modified = summary.get("top_files_modified", [])
window = summary.get("window", {})

# Calculate failure rate
total = counts.get("events_total", 0)
failures = counts.get("failures", 0)
failure_rate = f"{(failures/total*100):.1f}%" if total > 0 else "N/A"

# Generate per-project table rows
project_rows = ''.join(
    f'''<tr>
        <td>{p.get("project", "unknown")}</td>
        <td>{p.get("events", 0)}</td>
        <td>{p.get("sessions", 0)}</td>
        <td>{p.get("writes", 0)}</td>
        <td>{p.get("failures", 0)}</td>
    </tr>''' for p in projects
) or '<tr><td colspan="5">No project data</td></tr>'

# Generate friction list items
friction_items = ''.join(f'<li><strong>{d["domain"]}</strong>: {d["count"]}</li>' for d in friction) or '<li>No friction data</li>'
friction_sub_items = ''.join(f'<li>{d["subdomain"]}: {d["count"]}</li>' for d in friction_sub) or '<li>No subdomain data</li>'
principle_items = ''.join(f'<li>{p["principle"]}: {p["count"]}</li>' for p in principles) or '<li>No principles data</li>'
skill_items = ''.join(f'<li>{s["skill"]}: {s["count"]}</li>' for s in skills) or '<li>No skills data</li>'
file_items = ''.join(f'<li><code>{f}</code></li>' for f in files_modified[:15]) or '<li>No files data</li>'

# Convert review markdown to HTML
review_html = md_to_html(review_md) if review_md else '<p>No review content generated yet.</p>'

html = f"""<!DOCTYPE html>
<html>
<head>
<meta charset="utf-8">
<title>Weekly Engineering Dashboard</title>
<style>
:root {{
  --bg-primary: #0f172a;
  --bg-card: #1e293b;
  --bg-hover: #334155;
  --text-primary: #e2e8f0;
  --text-muted: #94a3b8;
  --text-dim: #64748b;
  --accent: #3b82f6;
  --accent-dim: #1e40af;
  --success: #22c55e;
  --warning: #f59e0b;
  --danger: #ef4444;
}}
* {{ box-sizing: border-box; }}
body {{
  font-family: system-ui, -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif;
  margin: 0;
  background: var(--bg-primary);
  color: var(--text-primary);
  line-height: 1.6;
}}
.container {{
  max-width: 1400px;
  margin: 0 auto;
  padding: 32px 40px;
}}
h1 {{ margin: 0 0 4px 0; font-size: 28px; }}
.subtitle {{ color: var(--text-muted); font-size: 14px; margin-bottom: 24px; }}

/* Tabs */
.tabs {{
  display: flex;
  gap: 8px;
  border-bottom: 1px solid var(--bg-hover);
  margin-bottom: 24px;
}}
.tab {{
  padding: 12px 20px;
  cursor: pointer;
  color: var(--text-muted);
  border-bottom: 2px solid transparent;
  transition: all 0.2s;
  font-weight: 500;
}}
.tab:hover {{ color: var(--text-primary); }}
.tab.active {{
  color: var(--accent);
  border-bottom-color: var(--accent);
}}
.tab-content {{ display: none; }}
.tab-content.active {{ display: block; }}

/* Dashboard Grid */
.grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(160px, 1fr));
  gap: 16px;
  margin-bottom: 32px;
}}
.card {{
  background: var(--bg-card);
  padding: 20px;
  border-radius: 12px;
}}
.metric {{
  font-size: 32px;
  font-weight: 700;
  margin-bottom: 4px;
}}
.metric-label {{ color: var(--text-muted); font-size: 13px; }}
.metric.success {{ color: var(--success); }}
.metric.warning {{ color: var(--warning); }}
.metric.danger {{ color: var(--danger); }}

/* Sections */
.section {{ margin-top: 40px; }}
.section h2 {{
  font-size: 18px;
  margin-bottom: 16px;
  color: var(--text-primary);
}}
.two-col {{
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 24px;
}}
@media (max-width: 768px) {{ .two-col {{ grid-template-columns: 1fr; }} }}

/* Tables */
table {{
  width: 100%;
  border-collapse: collapse;
  background: var(--bg-card);
  border-radius: 8px;
  overflow: hidden;
}}
th, td {{
  padding: 12px 16px;
  text-align: left;
  border-bottom: 1px solid var(--bg-hover);
}}
th {{
  background: var(--bg-hover);
  font-weight: 600;
  font-size: 13px;
  text-transform: uppercase;
  color: var(--text-muted);
}}
tr:last-child td {{ border-bottom: none; }}

/* Lists */
ul {{
  list-style: none;
  padding: 0;
  margin: 0;
}}
li {{
  padding: 8px 12px;
  background: var(--bg-card);
  margin-bottom: 4px;
  border-radius: 6px;
  font-size: 14px;
}}
li code {{
  background: var(--bg-hover);
  padding: 2px 6px;
  border-radius: 4px;
  font-size: 12px;
}}

/* Charts */
.charts-grid {{
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(350px, 1fr));
  gap: 24px;
}}
.chart-card {{
  background: var(--bg-card);
  padding: 20px;
  border-radius: 12px;
}}
.chart-card h3 {{
  margin: 0 0 16px 0;
  font-size: 14px;
  color: var(--text-muted);
}}
.chart-card img {{
  width: 100%;
  border-radius: 8px;
  background: #fff;
}}

/* Review Tab - Readable Typography */
.review-content {{
  background: var(--bg-card);
  padding: 48px 56px;
  border-radius: 16px;
  font-size: 16px;
  line-height: 1.8;
}}
.review-content h1 {{
  font-size: 28px;
  margin: 0 0 8px 0;
  color: var(--text-primary);
  font-weight: 700;
  letter-spacing: -0.5px;
}}
.review-content h2 {{
  font-size: 22px;
  margin: 48px 0 20px 0;
  padding-bottom: 12px;
  border-bottom: 2px solid var(--bg-hover);
  color: var(--accent);
  font-weight: 600;
}}
.review-content h3 {{
  font-size: 18px;
  margin: 32px 0 16px 0;
  color: var(--text-primary);
  font-weight: 600;
}}
.review-content h4 {{
  font-size: 16px;
  margin: 24px 0 12px 0;
  color: var(--text-muted);
  font-weight: 600;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}}
.review-content p {{
  color: var(--text-muted);
  margin: 0 0 16px 0;
}}
.review-content p:last-child {{ margin-bottom: 0; }}
.review-content strong {{
  color: var(--text-primary);
  font-weight: 600;
}}
.review-content em {{
  color: var(--text-muted);
  font-style: italic;
}}
.review-content a {{
  color: var(--accent);
  text-decoration: none;
}}
.review-content a:hover {{
  text-decoration: underline;
}}

/* Review Lists */
.review-content .styled-list {{
  margin: 20px 0;
  padding: 0;
  list-style: none;
}}
.review-content .styled-list li {{
  position: relative;
  padding: 12px 16px 12px 32px;
  margin: 8px 0;
  background: var(--bg-primary);
  border-radius: 8px;
  border-left: 3px solid var(--accent);
  color: var(--text-muted);
  font-size: 15px;
  line-height: 1.6;
}}
.review-content .styled-list li strong {{
  color: var(--text-primary);
  display: inline-block;
  margin-right: 4px;
}}
.review-content ol.styled-list {{
  counter-reset: item;
}}
.review-content ol.styled-list li {{
  counter-increment: item;
}}
.review-content ol.styled-list li::before {{
  content: counter(item);
  position: absolute;
  left: 10px;
  top: 12px;
  font-size: 12px;
  font-weight: 700;
  color: var(--accent);
}}

/* Review Tables */
.review-content .table-wrapper {{
  margin: 24px 0;
  overflow-x: auto;
  border-radius: 8px;
}}
.review-content table {{
  width: 100%;
  border-collapse: collapse;
  font-size: 14px;
}}
.review-content th {{
  background: var(--bg-hover);
  padding: 12px 16px;
  text-align: left;
  font-weight: 600;
  color: var(--text-primary);
  font-size: 12px;
  text-transform: uppercase;
  letter-spacing: 0.5px;
}}
.review-content td {{
  padding: 12px 16px;
  border-bottom: 1px solid var(--bg-hover);
  color: var(--text-muted);
}}
.review-content tr:last-child td {{
  border-bottom: none;
}}

/* Review Code */
.review-content code {{
  font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace;
  font-size: 13px;
  background: var(--bg-primary);
  padding: 3px 8px;
  border-radius: 4px;
  color: #f472b6;
}}
.review-content .code-block {{
  background: var(--bg-primary);
  padding: 20px 24px;
  border-radius: 10px;
  margin: 24px 0;
  overflow-x: auto;
  border: 1px solid var(--bg-hover);
}}
.review-content .code-block code {{
  background: none;
  padding: 0;
  color: var(--text-muted);
  font-size: 13px;
  line-height: 1.6;
}}

/* Review Blockquote */
.review-content blockquote {{
  margin: 24px 0;
  padding: 16px 24px;
  background: var(--bg-primary);
  border-left: 4px solid var(--warning);
  border-radius: 0 8px 8px 0;
  color: var(--text-muted);
  font-style: italic;
}}

/* Review Horizontal Rule */
.review-content hr {{
  border: none;
  height: 1px;
  background: var(--bg-hover);
  margin: 40px 0;
}}

/* JSON Tab */
.json-container {{
  background: var(--bg-card);
  border-radius: 12px;
  overflow: hidden;
}}
.json-header {{
  background: var(--bg-hover);
  padding: 12px 20px;
  font-size: 13px;
  color: var(--text-muted);
  border-bottom: 1px solid var(--bg-primary);
}}
.json-content {{
  padding: 20px;
  overflow-x: auto;
  max-height: 80vh;
}}
.json-content pre {{
  margin: 0;
  font-family: 'SF Mono', 'Fira Code', 'Consolas', monospace;
  font-size: 13px;
  line-height: 1.5;
}}
.json-string {{ color: #a5d6ff; }}
.json-number {{ color: #79c0ff; }}
.json-boolean {{ color: #ff7b72; }}
.json-null {{ color: #8b949e; }}
.json-key {{ color: #7ee787; }}

/* Footer */
.footer {{
  margin-top: 48px;
  padding-top: 24px;
  border-top: 1px solid var(--bg-hover);
  font-size: 12px;
  color: var(--text-dim);
}}
</style>
</head>
<body>
<div class="container">
  <h1>📊 Weekly Engineering Dashboard</h1>
  <div class="subtitle">
    {window.get("since", "N/A")} → {window.get("until", "N/A")} ·
    {counts.get("projects_touched", 0)} projects ·
    {counts.get("sessions_total", 0)} sessions ·
    {total} events
  </div>

  <div class="tabs">
    <div class="tab active" onclick="switchTab('dashboard')">Dashboard</div>
    <div class="tab" onclick="switchTab('review')">Review</div>
    <div class="tab" onclick="switchTab('data')">Data</div>
  </div>

  <!-- Dashboard Tab -->
  <div id="dashboard" class="tab-content active">
    <div class="grid">
      <div class="card">
        <div class="metric">{counts.get("projects_touched", 0)}</div>
        <div class="metric-label">Projects</div>
      </div>
      <div class="card">
        <div class="metric">{counts.get("files_modified", 0)}</div>
        <div class="metric-label">Files Modified</div>
      </div>
      <div class="card">
        <div class="metric">{counts.get("writes", 0)}</div>
        <div class="metric-label">Writes</div>
      </div>
      <div class="card">
        <div class="metric {'danger' if failures > 20 else 'warning' if failures > 5 else ''}">{failures}</div>
        <div class="metric-label">Failures ({failure_rate})</div>
      </div>
      <div class="card">
        <div class="metric">{counts.get("tradeoff_events", 0)}</div>
        <div class="metric-label">Tradeoffs</div>
      </div>
      <div class="card">
        <div class="metric {'danger' if counts.get('reversal_events', 0) > 3 else ''}">{counts.get("reversal_events", 0)}</div>
        <div class="metric-label">Reversals</div>
      </div>
      <div class="card">
        <div class="metric">{pct(counts.get("test_stability_rate"))}</div>
        <div class="metric-label">Test Stability</div>
      </div>
    </div>

    <div class="section">
      <h2>📁 Per-Project Activity</h2>
      <table>
        <thead>
          <tr>
            <th>Project</th>
            <th>Events</th>
            <th>Sessions</th>
            <th>Writes</th>
            <th>Failures</th>
          </tr>
        </thead>
        <tbody>
          {project_rows}
        </tbody>
      </table>
    </div>

    <div class="section two-col">
      <div>
        <h2>🔁 Friction by Domain</h2>
        <ul>{friction_items}</ul>
      </div>
      <div>
        <h2>🔬 Friction by Subdomain</h2>
        <ul>{friction_sub_items}</ul>
      </div>
    </div>

    <div class="section two-col">
      <div>
        <h2>🧠 Principles Invoked</h2>
        <ul>{principle_items}</ul>
      </div>
      <div>
        <h2>🛠 Skills Demonstrated</h2>
        <ul>{skill_items}</ul>
      </div>
    </div>

    <div class="section">
      <h2>📈 Charts</h2>
      <div class="charts-grid">
        <div class="chart-card">
          <h3>Event Distribution</h3>
          <img src="charts/events_by_type.png" onerror="this.parentElement.innerHTML='<p style=\\'color:var(--text-dim)\\'>Chart not generated</p>'">
        </div>
        <div class="chart-card">
          <h3>Friction Trends</h3>
          <img src="charts/friction_domains.png" onerror="this.parentElement.innerHTML='<p style=\\'color:var(--text-dim)\\'>Chart not generated</p>'">
        </div>
        <div class="chart-card">
          <h3>Principles Heat</h3>
          <img src="charts/principles_invoked.png" onerror="this.parentElement.innerHTML='<p style=\\'color:var(--text-dim)\\'>Chart not generated</p>'">
        </div>
      </div>
    </div>

    <div class="section">
      <h2>📝 Recent Files Modified</h2>
      <ul>{file_items}</ul>
    </div>
  </div>

  <!-- Review Tab -->
  <div id="review" class="tab-content">
    <div class="review-content">
      {review_html}
    </div>
  </div>

  <!-- Data Tab -->
  <div id="data" class="tab-content">
    <div class="json-container">
      <div class="json-header">summary.json · {len(summary_json)} bytes</div>
      <div class="json-content">
        <pre id="json-display"></pre>
      </div>
    </div>
  </div>

  <div class="footer">
    Generated {datetime.utcnow().isoformat()}Z ·
    <a href="review.md" style="color:var(--accent)">review.md</a> ·
    <a href="summary.json" style="color:var(--accent)">summary.json</a>
  </div>
</div>

<script>
function switchTab(tabId) {{
  document.querySelectorAll('.tab').forEach(t => t.classList.remove('active'));
  document.querySelectorAll('.tab-content').forEach(c => c.classList.remove('active'));
  document.querySelector(`[onclick="switchTab('${{tabId}}')"]`).classList.add('active');
  document.getElementById(tabId).classList.add('active');
}}

// Syntax highlight JSON
const jsonData = {json.dumps(summary_json)};
const highlighted = jsonData
  .replace(/&/g, '&amp;')
  .replace(/</g, '&lt;')
  .replace(/>/g, '&gt;')
  .replace(/"([^"]+)":/g, '<span class="json-key">"$1"</span>:')
  .replace(/: "([^"]*)"([,\\n]|$)/g, ': <span class="json-string">"$1"</span>$2')
  .replace(/: (\\d+\\.?\\d*)([,\\n]|$)/g, ': <span class="json-number">$1</span>$2')
  .replace(/: (true|false)([,\\n]|$)/g, ': <span class="json-boolean">$1</span>$2')
  .replace(/: (null)([,\\n]|$)/g, ': <span class="json-null">$1</span>$2');
document.getElementById('json-display').innerHTML = highlighted;
</script>
</body>
</html>
"""

output_path = review_dir / "index.html"
output_path.write_text(html, encoding="utf-8")

print(str(output_path))
