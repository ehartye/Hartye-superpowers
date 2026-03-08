# Perspective Catalogue

Reference material for perspective-review and perspective-research skills.
Read this file when selecting perspectives for an artifact or question.

## Available Perspectives

### User/Consumer
**Analytical procedure:** Trace every user journey and API interaction through
the artifact. For each touchpoint, apply use-case modeling: identify the actor,
their goal, the preconditions, the main success scenario, and the extensions
(what happens when things go wrong). Ask: "If I'm a developer using this for
the first time, what confuses me? What's missing from the happy path?"

**Catches:** Usability gaps, missing edge cases, confusing interfaces, unclear
error messages, poor API ergonomics, undocumented assumptions about user behavior.

---

### Adversary
**Analytical procedure:** Assume this design has already failed catastrophically
in production — or has been exploited by a malicious actor. Work backward from
the failure: what went wrong? Apply pre-mortem analysis (Klein, 2007) by
generating specific failure scenarios. Then apply red-team thinking: identify
attack surfaces, trust boundaries crossed, data exposed, and assumptions that
an attacker would exploit. For each finding, assess: how likely is this, and
how bad is the impact?

**Catches:** Security vulnerabilities, unexamined assumptions, single points of
failure, missing threat modeling, overly optimistic assumptions about inputs,
failure modes that cascade.

---

### Operator
**Analytical procedure:** It's 3am and this system is on fire. Evaluate the
artifact through the lens of someone who must deploy, monitor, debug, and scale
this in production. For deployment: what are the steps, what can go wrong, how
do you roll back? For monitoring: what signals indicate health or degradation?
For debugging: when something fails, can you tell what happened and why? For
scaling: what happens at 10x load?

**Catches:** Observability gaps, deployment complexity, missing rollback plans,
operational burden, unclear failure signals, scaling cliffs, missing runbooks.

---

### Maintainer
**Analytical procedure:** Fast-forward 6 months. You are a new developer who
has never seen this codebase. Read the artifact as if encountering it for the
first time. For each component: can you understand what it does and why without
asking the author? Identify implicit knowledge — things the author knows but
didn't write down. Check coupling: if you change one thing, how many other
things break? Look for patterns that will accumulate tech debt over time.

**Catches:** Coupling, missing documentation, implicit knowledge dependencies,
fragile abstractions, naming that only makes sense with context, patterns that
don't scale as the codebase grows.

---

### Business/Strategy
**Analytical procedure:** Evaluate the artifact against organizational goals,
resource constraints, and opportunity cost. What does this cost to build and
maintain? Does it align with current priorities, or is it solving a problem
nobody asked for? What alternatives were not chosen, and what's the opportunity
cost? Is the complexity proportional to the business value? Would a simpler
solution deliver 80% of the value at 20% of the cost?

**Catches:** Over-engineering, misaligned priorities, hidden maintenance costs,
scope creep, solutions looking for problems, ignoring cheaper alternatives.

---

### Performance/Scale
**Analytical procedure:** Model the system under load. Identify the hot paths
— the operations that will be called most frequently. For each hot path: what's
the time complexity? What are the memory characteristics? Where are the I/O
boundaries? Project data growth: what happens when the dataset is 10x, 100x
current size? Identify resource consumption patterns and bottleneck candidates.
Look for O(n²) hiding in innocent-looking loops, unbounded caches, and
connection pool exhaustion.

**Catches:** Scaling cliffs, hot paths with poor complexity, resource exhaustion,
unbounded growth, missing pagination, N+1 queries, cache invalidation issues.

---

### Integrator
**Analytical procedure:** Map every boundary where this system touches another
system — APIs consumed, APIs exposed, data flows in and out, shared state,
event buses, file formats. For each boundary: what's the contract? What happens
when the other side changes? What happens when the other side is down? Are
versions compatible? Is there a migration path? Check for assumptions about
external systems that aren't guaranteed.

**Catches:** Integration failures, contract mismatches, missing error handling
at boundaries, version incompatibilities, migration gaps, assumptions about
external system behavior.

## Selecting Perspectives

When recommending perspectives for an artifact or question, consider:

1. **Artifact type:** Design docs benefit from Maintainer + User/Consumer.
   Architecture decisions benefit from Adversary + Performance/Scale.
   Plans benefit from Operator + Business/Strategy.
2. **Domain signals:** Security-sensitive → Adversary. User-facing → User/Consumer.
   Infrastructure → Operator. API design → Integrator + User/Consumer.
3. **Cap at 3-4:** Per collective intelligence research (Woolley et al.),
   3-4 perspectives is the sweet spot. More than 4 adds coordination overhead
   that degrades quality.
4. **Explain why:** For each recommended perspective, state why it's relevant
   to this specific artifact — not just generic reasoning.
