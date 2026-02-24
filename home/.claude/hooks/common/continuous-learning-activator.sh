#!/bin/bash

# Continuous Learning Skill Auto-Activation Hook
# This hook ensures the continuous-learning skill evaluates each interaction for
# extractable knowledge worth documenting.
#

cat << 'EOF'

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
🧠 MANDATORY SKILL EVALUATION REQUIRED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

CRITICAL: After completing this user request, you MUST evaluate whether
it produced extractable knowledge using the continuous-learning skill.

EVALUATION PROTOCOL (NON-NEGOTIABLE):

1. COMPLETE the user's request first
2. EVALUATE: Ask yourself:
   - Did this require non-obvious investigation or debugging?
   - Was the solution something that would help in future similar situations?
   - Did I discover something not immediately obvious from documentation?

3. IF YES to any question above:
   ACTIVATE: Use Skill(continuous-learning) NOW to extract the knowledge

4. IF NO to all questions:
   SKIP: No skill extraction needed

This is NOT optional. Failing to evaluate means valuable knowledge is lost.
The continuous-learning skill will decide whether to actually create a new
skill based on its quality criteria.

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
EOF
