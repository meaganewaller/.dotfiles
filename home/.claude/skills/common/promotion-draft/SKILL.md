---
name: promotion-draft
description: This skill should be used when preparing a promotion packet, writing self-review for leveling, or asking "am I ready for promotion?", "what does senior/staff look like?", or "help me write my promo doc". Generates level-appropriate impact narratives with scope and influence evidence.
argument-hint: target level, review period, or accomplishments to include
disable-model-invocation: true
---

# Promotion Draft

Build a complete promotion case from recent engineering work.

## Input

$ARGUMENTS

---

## Level Expectations Framework

### Scope of Impact by Level

| Level | Scope | Typical Evidence |
|-------|-------|------------------|
| **Junior (L3)** | Task/Feature | Completes assigned work, learns codebase |
| **Mid (L4)** | Project | Owns features end-to-end, mentors juniors |
| **Senior (L5)** | Team | Shapes team direction, influences architecture |
| **Staff (L6)** | Org/Multi-team | Drives org-wide initiatives, sets standards |
| **Principal (L7)** | Company | Industry influence, company-wide strategy |

### Key Dimensions by Level

#### Junior → Mid (L3 → L4)

| Dimension | Evidence Needed |
|-----------|-----------------|
| Independence | Completes work without daily guidance |
| Scope | Owns full features, not just tasks |
| Quality | Writes production-ready code first time |
| Communication | Explains technical decisions clearly |

#### Mid → Senior (L4 → L5)

| Dimension | Evidence Needed |
|-----------|-----------------|
| Technical leadership | Others seek your opinion, you shape decisions |
| Ambiguity | Navigate unclear requirements, define solutions |
| Multiplier | Make the team more effective, not just yourself |
| Influence | Drive outcomes beyond assigned work |

#### Senior → Staff (L5 → L6)

| Dimension | Evidence Needed |
|-----------|-----------------|
| Org impact | Work affects multiple teams |
| Strategy | Connect technical work to business goals |
| Standards | Create patterns others adopt |
| Sponsorship | Senior leadership knows your work |

#### Staff → Principal (L6 → L7)

| Dimension | Evidence Needed |
|-----------|-----------------|
| Industry | External recognition, conference talks, papers |
| Company strategy | Influence product/technical direction |
| Organization building | Grow senior talent, shape culture |
| Innovation | Novel solutions to hard problems |

---

## Translating Technical Work to Impact

For each accomplishment, use the **impact-narrative** skill to translate technical work into business language. It provides frameworks for quantifying impact, framing for different audiences, and the STAR-L narrative structure. This skill focuses on assembling those translated accomplishments into a level-appropriate promotion packet.

---

## Promotion Packet Structure

### 1. Summary Statement

One paragraph answering: "Why should this person be promoted now?"

**Formula:**
```
[Name] has consistently operated at [target level] by [key evidence].
Their work on [biggest accomplishment] demonstrates [key dimension].
Promoting them formalizes the scope they're already operating at.
```

### 2. Impact Themes (3-5)

Group accomplishments into themes that demonstrate level-appropriate scope.

| Theme Type | Example |
|------------|---------|
| Technical excellence | "Architected scalable solutions" |
| Leadership | "Elevated team capabilities" |
| Business impact | "Directly enabled revenue growth" |
| Cross-functional | "Partnered across org boundaries" |
| Innovation | "Introduced novel approaches" |

### 3. Accomplishment Bullets

For each theme, 2-4 specific accomplishments.

**Bullet Formula:**
```
[Strong verb] + [what] + [scope/scale] + [measurable result] + [so-what]
```

**Level-Appropriate Verbs:**

| Level | Verbs |
|-------|-------|
| Mid | Built, implemented, shipped, fixed, improved |
| Senior | Designed, led, drove, mentored, standardized |
| Staff | Architected, established, influenced, championed, transformed |
| Principal | Pioneered, defined, shaped, evangelized |

### 4. Scope Evidence

Concrete proof of operating at target level scope.

| Scope | Evidence Types |
|-------|----------------|
| Team | Code reviews given, mentoring, team process improvements |
| Multi-team | RFCs reviewed, cross-team projects, shared libraries |
| Org | Standards adopted, architecture decisions, hiring influence |
| Company | Company-wide tools, external visibility, exec presentations |

### 5. Stakeholder Quotes

Who can vouch for this work?

| Stakeholder | What They Can Speak To |
|-------------|----------------------|
| Manager | Day-to-day performance, growth |
| Skip-level | Strategic impact, leadership |
| Peers | Collaboration, technical respect |
| Cross-functional | Impact outside engineering |
| Reports | Mentorship, leadership style |

---

## Gathering Evidence

### From Git History
```bash
# Your commits in review period
git log --author="[you]" --since="[start date]" --oneline

# Files you've touched most
git log --author="[you]" --since="[start date]" --name-only --format="" | sort | uniq -c | sort -rn | head -20

# Your PRs with reviews
gh pr list --author="[you]" --state=merged --limit=100
```

### From Dev OS Events
```bash
# Your impact events
grep "tool_write" ~/.claude/dev-os-events.jsonl | jq -r '.payload.files[]' | sort | uniq -c | sort -rn

# Large changes (architecture-level work)
grep "large_change" ~/.claude/dev-os-events.jsonl

# Decisions documented
grep "decision_tradeoff" ~/.claude/dev-os-events.jsonl
```

### From Documents
- Design docs authored
- RFCs proposed/reviewed
- Post-mortems led
- Documentation written

---

## Common Promotion Pitfalls

| Pitfall | Problem | Fix |
|---------|---------|-----|
| **Activity, not impact** | Lists tasks done | Connect to outcomes |
| **Solo hero** | All "I" statements | Show multiplier effect |
| **Recency bias** | Only recent work | Cover full review period |
| **Missing scope** | Work without context | Explain why it mattered |
| **Vague claims** | "Improved performance" | Add numbers, specifics |
| **Wrong audience** | Too technical | Lead with business impact |

---

## Self-Assessment: Am I Ready?

### Checklist for Target Level

#### For Senior (L5)
- [ ] Others on the team come to me for technical guidance
- [ ] I've driven at least one project without manager direction
- [ ] I've improved a team process or practice
- [ ] I've mentored at least one junior engineer
- [ ] My code reviews teach, not just approve

#### For Staff (L6)
- [ ] I've influenced technical direction beyond my team
- [ ] Engineers outside my team know my work
- [ ] I've written standards/patterns others adopted
- [ ] I can connect my work to business metrics
- [ ] Senior leadership has visibility into my contributions

#### For Principal (L7)
- [ ] I've shaped company-wide technical strategy
- [ ] I have external industry presence
- [ ] I've grown engineers to senior/staff level
- [ ] My work has multi-year impact
- [ ] I'm consulted on org-level decisions

---

## Output Format

### Promotion Packet: [Name] → [Target Level]

#### Summary

[One paragraph summary statement]

---

#### Theme 1: [Name]

**Scope:** [Team/Multi-team/Org]

- [Accomplishment bullet with metrics]
- [Accomplishment bullet with metrics]

**Evidence:** [Specific artifacts, links, quotes]

---

#### Theme 2: [Name]

**Scope:** [Team/Multi-team/Org]

- [Accomplishment bullet with metrics]
- [Accomplishment bullet with metrics]

**Evidence:** [Specific artifacts, links, quotes]

---

#### Theme 3: [Name]

**Scope:** [Team/Multi-team/Org]

- [Accomplishment bullet with metrics]
- [Accomplishment bullet with metrics]

**Evidence:** [Specific artifacts, links, quotes]

---

### Scope Summary

| Dimension | Evidence |
|-----------|----------|
| Technical leadership | [examples] |
| Cross-team influence | [examples] |
| Mentorship/multiplier | [examples] |

### Stakeholder Support

| Name | Role | Can Speak To |
|------|------|--------------|
| [name] | [title] | [topic] |

### Gaps to Address

[Any areas where evidence is thin, with plan to strengthen]

### Recommendation

**Ready for promotion:** [Yes / Not yet / Needs more time]

**If not yet:** [Specific gaps and timeline to address]
