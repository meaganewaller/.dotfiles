---
name: dependency-evaluator
description: Evaluate whether adding or upgrading a dependency is justified.
disable-model-invocation: true
context: fork
agent: Plan
---

Dependency:

$ARGUMENTS

Evaluate:

1. What problem does it solve?
2. Can we solve this in-house?
3. Maintenance risk?
4. Bus factor?
5. Upgrade volatility?
6. Security implications?
7. Exit strategy?

Recommend: adopt / reject / defer.
