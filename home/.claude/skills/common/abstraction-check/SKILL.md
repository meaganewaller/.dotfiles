---
name: abstraction-check
description: Evaluate whether a proposed abstraction is justified or premature.
---

Evaluate this abstraction:

$ARGUMENTS

Analyze:

- Is duplication actually harmful?
- Is variability real or speculative?
- Is the abstraction leaking implementation detail?
- What is the cognitive load cost?
- Is this future-proofing or ego?

Return:
- Decision: keep simple / extract abstraction
- Justification
