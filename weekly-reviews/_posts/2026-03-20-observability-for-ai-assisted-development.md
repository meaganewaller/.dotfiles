---
title: "Building Observability for AI-Assisted Development"
date: 2026-03-20
layout: post
tags: [claude-code, observability, grafana, telemetry, dev-os, docker, loki]
summary: You can't improve what you can't measure. I built an observability stack that turns my Claude Code telemetry into dashboards, alerts, and actionable insights about how human and AI actually collaborate.
---

# Building Observability for AI-Assisted Development

Dev OS generates a lot of telemetry. Every tool call, every friction event, every cue fired, every reversal detected—it all gets logged to JSONL files. But raw logs aren't insights. Grepping through `dev-os-events.jsonl` gets old fast.

So I built an observability stack. Real dashboards. Real alerts. The same tools production systems use—but pointed at my development process.

## The Problem: Telemetry Without Visibility

After a few weeks of Dev OS, I had:

- `~/.claude/dev-os-events.jsonl` - 50,000+ events
- `~/.claude/skill-friction-log.jsonl` - 1,000+ friction events
- Weekly review scripts that could aggregate, but only on demand

The weekly review was useful. But I wanted:

- Real-time visibility into what's happening
- Alerts when things go wrong (friction spikes, resource limit breaches)
- Historical trends without running scripts
- The ability to explore data interactively

Basically, I wanted what every production system has: observability.

## The Architecture

I went with the Grafana LGTM stack—Loki, Grafana, Tempo, Mimir. It's what I know from work, it runs locally, and it's built for exactly this kind of log-based observability.

```
┌─────────────────────────────────────────────────────────────────┐
│                         Data Sources                            │
├─────────────────────────────────────────────────────────────────┤
│  ~/.claude/dev-os-events.jsonl    ~/.claude/skill-friction-log  │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    OpenTelemetry Collector                      │
│  - Tails log files                                              │
│  - Parses JSON into structured metadata                         │
│  - Adds log_source labels                                       │
└───────────────────────────┬─────────────────────────────────────┘
                            │ OTLP
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                           Loki                                  │
│  - Log storage and indexing                                     │
│  - LogQL queries                                                │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                          Grafana                                │
│  - 10 dashboards                                                │
│  - Alerts                                                       │
└───────────────────────────┬─────────────────────────────────────┘
                            │ Alert
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      Alert Webhook                              │
│  - Logs alerts to alerts.jsonl                                  │
│  - Could trigger notifications                                  │
└─────────────────────────────────────────────────────────────────┘
```

Three containers. One `docker compose up -d`. Done.

## The Collector: Turning Logs into Data

The OpenTelemetry Collector tails my JSONL files and forwards them to Loki with structured metadata:

```yaml
receivers:
  filelog/devos:
    include:
      - /claude-data/dev-os-events.jsonl
    start_at: end
    operators:
      - type: json_parser
        parse_from: body
      - type: add
        field: attributes.log_source
        value: dev-os-events

  filelog/friction:
    include:
      - /claude-data/skill-friction-log.jsonl
    start_at: end
    operators:
      - type: json_parser
        parse_from: body
      - type: add
        field: attributes.log_source
        value: friction
```

The `json_parser` operator extracts every field from the JSON line into queryable metadata. Event type, session ID, subdomain, tool name—all become first-class query dimensions.

The `log_source` attribute lets me distinguish between event logs and friction logs in queries.

## The Dashboards

Ten dashboards, each answering different questions about how I work.

### Mission Control

The single-pane-of-glass. Four gauges at the top:

| Metric | Formula | Good |
|--------|---------|------|
| Success Rate | writes / (writes + failures) | >90% |
| Friction Rate | friction per 100 writes | <15% |
| Reversal Rate | reversals per 100 writes | <3% |
| ADR-0008 Tracker | resource-limit errors (7d) | <25 |

Below that: activity timeline, friction breakdown pie chart, and quality signal indicators.

I check this dashboard at the start of each day. If something's red, I dig deeper.

### Friction Overview

Deep dive into what's causing friction. Stacked bar chart by subdomain over time shows patterns:

```logql
sum by (subdomain) (
  count_over_time({service_name="devos"} | log_source="friction" [$__interval])
)
```

The ADR-0008 goal tracker is here too—a gauge showing resource-limit errors against my target of <50/week. When I started tracking, this was at 878 cumulative errors. The visual accountability helps.

### Collaboration Insights

This is the interesting one. It answers: how do human and AI actually work together?

**Session Archetypes**: Are my sessions sprints (focused bursts), flow (steady work), or marathons (long slogs)? A pie chart shows the distribution.

**Change Types**: What kind of work am I doing? Architecture, bugfixes, features, tests, docs. A balanced distribution means healthy development; all bugfixes means something's wrong upstream.

**Risk Profile**: Low, medium, high risk changes. High risk ratio climbing? Time to slow down.

**Top Cues Fired**: Which guidance injections are helping most? If a cue never fires, maybe it's not needed. If one fires constantly, maybe the underlying issue should be fixed.

### Time & Effort

Productivity and efficiency metrics:

- **Writes per Session**: Throughput indicator
- **Writes per Friction**: Efficiency (higher = smoother flow)
- **Test Coverage Rate**: Tests per write (TDD indicator)
- **Duration Distribution**: How long do sessions typically last?

The efficiency metric (writes per friction event) is my favorite. It captures something real: how much forward progress am I making relative to setbacks? A rising trend means the system is helping.

### Weekly Trends

Week-over-week comparisons. This is where you see if your interventions are working:

- Friction by subdomain over 4 weeks
- This week vs last week comparison
- Daily success rate trend

When I implemented the resource-limit blocking rules (ADR-0008), the next week's trend line showed the impact immediately.

## The Alerts

Two alerts configured:

**Friction Spike**: >20 friction events in an hour triggers a warning. Something is systematically wrong—maybe a hook is broken, maybe I'm fighting the tools.

**ADR-0008 Breach**: >50 resource-limit errors in a week triggers critical. This is the goal I set; if I breach it, I need to understand why.

Alerts go to a simple Python webhook that logs to `alerts.jsonl`:

```python
for alert in alerts:
    record = {
        "timestamp": datetime.utcnow().isoformat() + "Z",
        "status": alert.get("status", "unknown"),
        "alertname": alert.get("labels", {}).get("alertname", "unknown"),
        "severity": alert.get("labels", {}).get("severity", "info"),
        "summary": alert.get("annotations", {}).get("summary", ""),
    }
    print(f"{'🔴' if record['status'] == 'firing' else '✅'} {record['alertname']}")
```

I could extend this to send Slack messages or desktop notifications. For now, just logging is enough—I check `docker logs devos-webhook` when I want to see alert history.

## Running It

The whole stack is three services in docker-compose:

```yaml
services:
  lgtm:
    image: grafana/otel-lgtm:latest
    ports:
      - "3000:3000"
    volumes:
      - ./grafana/dashboards:/devos-dashboards

  devos-collector:
    image: otel/opentelemetry-collector-contrib:latest
    volumes:
      - ./otel-collector-config.yaml:/etc/otelcol/config.yaml
      - ~/.claude:/claude-data

  devos-webhook:
    build: ./webhook
    ports:
      - "8085:8080"
```

Start it:

```bash
docker compose up -d
open http://localhost:3000  # admin / admin
```

The collector immediately starts tailing my log files. Within seconds, data appears in Grafana.

## What I've Learned

### 1. Visualization Changes Behavior

Seeing a red gauge labeled "Friction Rate: 32%" hits differently than reading "323 friction events this week" in a weekly review. The dashboard creates constant, gentle pressure to improve.

### 2. Alerts Create Accountability

Setting explicit targets (ADR-0008: <50 resource-limit errors/week) and alerting on breach transforms vague goals into commitments. The alert doesn't judge—it just reports. But knowing it's watching changes how I work.

### 3. Exploration Reveals Patterns

With LogQL, I can ask questions I didn't anticipate:

```logql
# What's the friction rate for sessions over 2 hours?
# Which cues fire but don't seem to reduce reversals?
# What's my success rate on Mondays vs Fridays?
```

Static weekly reports can't answer ad-hoc questions. Interactive dashboards can.

### 4. The Stack Is Overkill (And That's Fine)

Do I need Loki, Grafana, Tempo, Mimir, and Pyroscope for personal development telemetry? No. A simple SQLite database and some charts would work.

But I already know this stack. The setup took an afternoon. And now I have industrial-strength observability that will scale to whatever telemetry I throw at it.

## What's Next

The current dashboards answer questions I knew to ask. The next phase is discovering questions I should be asking:

- **Session replay**: Can I reconstruct what happened in a session from events alone? Would that help with debugging workflows?
- **Anomaly detection**: Instead of static thresholds, can the system learn what "normal" looks like and alert on deviations?
- **Cross-session correlation**: Do patterns in one session predict outcomes in the next?
- **Cost tracking**: If I add token usage events, I could track actual API costs against productivity.

The infrastructure is in place. The hard part—collecting clean, structured telemetry—is done. Now it's about asking better questions.

## The Bigger Picture

Observability is a production concept. You instrument systems to understand their behavior under real conditions.

AI-assisted development is a production system. It has inputs (prompts, context), processing (the model), outputs (code, actions), and failure modes (friction, reversals, hallucinations).

Treating it like a production system—with dashboards, alerts, and metrics—isn't overengineering. It's taking the work seriously.

The telemetry tells me things I wouldn't notice otherwise:
- My friction rate spikes on Fridays (tired, rushing to finish)
- Marathon sessions (>2 hours) have 3x the reversal rate of short ones
- The "file-verification" cue reduced file-not-found errors by 40%

These insights don't come from intuition. They come from measurement.

---

*The full observability stack is at [dev-os-observability](https://github.com/meaganewaller/dev-os-observability). It's tailored to Dev OS event schemas but could be adapted for any JSONL-based telemetry.*

Build the dashboards. Set the alerts. Let the system tell you how you're really working.
