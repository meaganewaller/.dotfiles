# Career Matrix Principles

Engineering behaviors from Test Double's career matrix, organized for quick reference during decision-making.

## Decision-Making

### Making Principled Choices

**Core insight:** Make thoughtful, considered decisions, observe how they work out, and learn from them.

- Gather multiple perspectives and weigh trade-offs before making significant decisions
- Incorporate broader constraints (budget, change management, maintenance capability)
- Identify patterns that aid future decisions
- Verbalize your thought process, including heuristics others can follow
- Show your work by explaining trade-offs, constraints, and risks

**Heuristic example:** "A method should return a value or have a side effect, but never both."

**At scale:** Pressure test decisions affecting multiple teams by referencing prior art, considering unintended consequences & second-order effects, and winning buy-in.

### Planning Your Approach

**Core insight:** Translate requirements into sound software designs and implementation approaches.

- Collaborate with stakeholders to clarify needs
- Validate your approach with colleagues
- Raise concerns when you foresee obstacles
- Share progress continuously
- Point out when reality deviates from expectations

**At scale:** Counsel clients on ambitious, high-risk endeavors. Share wisdom from experience to broaden perspective and inform decision-making. Help identify simpler approaches they might not have considered.

### Uncovering Root Causes

**Core insight:** Respond to unexpected results by investigating their root cause.

- Navigate stack traces, dive into dependencies' source code
- Interrogate the system before reaching for Google/StackOverflow
- Develop fluency with step debuggers, REPLs, developer consoles
- Discern between one-off incidents and systemic issues
- Know when it's worth digging deeper vs. moving on

**At scale:** Help others incorporate root cause analysis into everyday work. Shift decision-making from abstract speculation to concrete understanding.

---

## Code Quality

### Delivering Great Code

**Core insight:** Write code that fulfills requirements AND is well-factored, well-named, and well-organized.

- Address cross-cutting concerns: security, a11y, logging
- Share progress consistently
- Identify challenges proactively
- Find support when needed

**At scale:** Lead teams through ambitious projects. Develop vision grounded in principles, leverage past experience, provide day-to-day collaboration.

### Simplifying For Change

**Core insight:** Maintain forward momentum in the face of complexity and technical debt.

- Add functionality without making existing problems worse
- Identify which areas cause the most pain
- Communicate technical challenges in terms stakeholders understand
- Refactor before introducing significant changes ("make the change easy, then make the easy change")
- Apply characterization testing for risky changes
- Use downtime for rainy day improvements

**At scale:** Navigate from complex hard-to-change systems to simple maintainable designs. Extract first services/packages as patterns for others to follow.

### Testing With Purpose

**Core insight:** Write tests that minimally specify behavior, express intent clearly, establish boundaries, run quickly, and only fail for useful reasons.

- Follow testing norms and patterns in place
- Ensure every meaningful behavior is tested
- Remain vigilant that tests provide good ROI
- Socialize problematic patterns and model remediation
- Address testing anti-patterns (they have broad-based effects)

**At scale:** Empower teams to go from good to great. Train others, establish novel patterns, create tools & infrastructure.

---

## Collaboration

### Norming On Conventions

**Core insight:** Streamline collaboration by seeking alignment on technologies, dependencies, formatting, organization, and version control.

- Respect client norms as a guest in their organization
- Follow conventions of chosen languages, frameworks, tools
- Write code consistent with how the team works
- Weigh "better ways" against costs of diverging from norms
- When friction arises, raise and resolve as a team

**At scale:** Implement tools that encode norms (formatters, git hooks, integrations). Balance standardization with individual creativity.

**Key insight:** Even if an existing design is "bad", it may be easy to remediate so long as it's consistently bad.

### Communicating With Empathy

**Core insight:** Tailor communication for audience and context. Apply the platinum rule: treat others how they want to be treated.

- Pair message with appropriate medium (low-stakes via text, high-stakes via video)
- Raise issues proactively, come prepared with solutions
- Consider others' incentives and constraints
- Address conflict directly using approaches like Crucial Conversations
- Embrace curiosity and empathy, not judgment

**At scale:** Translate technical topics for non-technical people. Connect with leaders by understanding their needs.

### Exchanging Effective Feedback

**Core insight:** Receive feedback graciously, give feedback tactfully. Invite teammates' feedback by sharing how you prefer to receive it.

- Rely on support structures for difficult situations
- Give timely, actionable feedback in the manner others best receive it
- Promote safety and trust in the team
- Help others find alternative strategies when direct feedback isn't working

**At scale:** Build high-trust relationships with longitudinal context for coaching at key career moments.

---

## Growth & Initiative

### Growing Your Skills

**Core insight:** Learn in both breadth and depth. Deepen understanding in day-to-day work, expand during growth time.

- Stay on leading edge of tomorrow's solutions
- Provide mentorship to others learning what you know
- Contribute educational resources

**At scale:** Play a leading role in others' growth. Develop systems that teach at scale.

### Maintaining Your Tools

**Core insight:** Develop ownership over your developer tools to continuously improve proficiency and productivity.

- Try new tools, adopt time-saving shortcuts
- Automate repetitive tasks
- Share tips & tricks
- Be open to using others' preferred tools for collaboration

**At scale:** Create tools that empower developers. Push the envelope of what tools help accomplish.

### Developing Thought Leadership

**Core insight:** Learn in the open by sharing discoveries, experiences, and insights.

- Share in #til, present at meetups, record screencasts, write blog posts
- Create content that resonates—educate and excite about new ways of doing things
- Build a following by consistently creating engaging content

**At scale:** Gain a platform to start meaningful conversations and foster communities.

---

## Impact

### Solving Client Problems

**Core insight:** Solve problems as asked. "Clients always know how to solve their problems, and tell the solution in the first five minutes."

- Listen intently, confirm understanding by summarizing
- Cultivate appreciation for context (teams, systems, business)
- Leverage outsider perspective to share insights insiders miss
- Connect work to opportunities to solve other problems

**At scale:** Steer teams to successful outcomes. Provide blocking and tackling. Find better ways to organize work, foster collaboration, communicate status.

### Optimizing For Scale

**Core insight:** Ensure systems perform reliably at anticipated scale within operational constraints.

- Load test, address bottlenecks, validate pre-prod consistency
- Address growing pains: early architecture decisions, slowing CI/CD, shared codebase friction

**At scale:** Unlock major performance gains in human and technical systems—especially where the two interact (Conway's Law).

### Owning Key Opportunities

**Core insight:** Find ways to add value by contributing to opportunities as they arise.

- Fix misconfigured builds, review others' work, suggest facilitation techniques
- Pitch in by helping others, responding to volunteer requests, identifying gaps

**At scale:** Shape the future by taking on major responsibilities—new technologies, greenfield architecture, organizational transformation.

---

## Quick Reference by Context

### When making architectural decisions:
- Making Principled Choices: Weigh trade-offs, show your work
- Planning Your Approach: Validate with colleagues, raise obstacles early
- Simplifying For Change: Can we make the change easy first?

### When debugging:
- Uncovering Root Causes: Interrogate the system, use debuggers/REPLs
- Testing With Purpose: Add characterization tests for risky changes

### When refactoring:
- Simplifying For Change: "Make the change easy, then make the easy change"
- Norming On Conventions: Is the existing pattern consistently applied?
- Delivering Great Code: Address cross-cutting concerns

### When writing tests:
- Testing With Purpose: Minimal specification, clear intent, good ROI
- Norming On Conventions: Follow existing patterns

### When choosing tools/conventions:
- Norming On Conventions: Weigh better ways against divergence costs
- Maintaining Your Tools: Automate, share, stay open to others' preferences

### When communicating decisions:
- Communicating With Empathy: Right medium, consider incentives
- Making Principled Choices: Verbalize thought process, show trade-offs
- Exchanging Effective Feedback: Timely, actionable, in preferred manner

### When creating content:
- Developing Thought Leadership: Learn in the open, educate and excite
- Growing Your Skills: Contribute educational resources

### When hitting resource limits:
- Optimizing For Scale: Address bottlenecks, validate constraints
- See also: `efficiency-principles.md` for actionable strategies

### When starting implementation:
- Planning Your Approach: Validate with colleagues, raise obstacles early
- See also: `model-first-development.md` for reducing reversals
