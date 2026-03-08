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

---

## Discipline-Based Perspectives

These perspectives evaluate against specific technical disciplines rather than
organizational roles. They complement role-based perspectives — a review might
combine Adversary (role) with Testing Strategy (discipline) to catch both
security vulnerabilities and test design gaps.

### Design Principles
**Analytical procedure:** Evaluate the codebase against established design
principles: SOLID, DRY, YAGNI, separation of concerns, appropriate abstraction
levels. For each component, assess coupling (how many other components does it
depend on or affect?) and cohesion (does this component do one thing well, or
is it a grab-bag?). Trace dependency directions — do high-level modules depend
on low-level details, or are abstractions properly inverted? Look for premature
abstractions (wrapping something used once) and missing abstractions (copy-pasted
logic that should be extracted). Ask: "If the requirements change in a likely
way, how many files need to change?"

**Catches:** Violations of SOLID principles, premature or missing abstractions,
high coupling, low cohesion, dependency direction problems, inappropriate
inheritance vs composition, god classes/functions, feature envy, shotgun surgery.

---

### Conventions & Idioms
**Analytical procedure:** Identify the languages, frameworks, and libraries in
use. For each, evaluate whether the code follows idiomatic patterns — the way
experienced practitioners of that technology would write it. Check for: using
framework features as intended vs fighting the framework, language-specific
patterns (Go error handling, Python context managers, React hooks rules,
TypeScript narrowing), consistent naming conventions, project-level patterns
that are followed in some places but violated in others. Look for patterns
that work in one language but are anti-patterns in the one being used.

**Catches:** Non-idiomatic code, framework misuse, inconsistent naming or
structure, language-specific anti-patterns, reinventing built-in features,
style inconsistencies across the codebase, patterns imported from other
languages that don't fit.

---

### Testing Strategy
**Analytical procedure:** Evaluate not just whether tests exist, but whether
they're well-designed. For each test: does it test behavior or implementation
details? Would it break if you refactored without changing behavior (fragile)?
Does it actually verify the thing it claims to verify, or does it mock so
heavily that it's testing the mocks? Check test boundaries — are unit tests
truly isolated? Do integration tests cover real integration points? Look for
missing boundary cases, error paths, and edge conditions. Assess the test
suite as a whole: could you confidently refactor the codebase with these tests
as your safety net?

**Catches:** Tests that test mocks instead of behavior, missing boundary/edge
cases, fragile tests coupled to implementation, gaps in error path coverage,
missing integration tests at real boundaries, test setup that hides bugs,
assertions that are too loose to catch regressions.

---

### Data Integrity
**Analytical procedure:** Trace data from entry point through storage to
retrieval. At each stage: what validates the data? What constraints enforce
correctness? For schemas: is normalization appropriate (not over- or under-),
are indexes aligned with query patterns, do migrations handle existing data
safely? For data flows: where can data become inconsistent (partial writes,
race conditions, failed transactions)? Check for orphaned references, missing
cascade rules, and implicit assumptions about data shape that aren't enforced
by the schema.

**Catches:** Schema/migration mismatches, missing constraints, data races,
partial write hazards, orphaned records, inconsistent data representations,
unsafe migrations, missing validation at storage boundaries, implicit shape
assumptions.

---

### API Design
**Analytical procedure:** Evaluate APIs (REST, GraphQL, RPC, internal module
interfaces) as contracts. For each endpoint/method: is the contract clear from
the signature and documentation alone? Are error responses specific enough to
act on? Is versioning handled? Check backward compatibility — could a consumer
upgrade without breaking? Look for: inconsistent naming across endpoints,
missing pagination on list operations, unclear ownership of side effects,
operations that should be idempotent but aren't. Evaluate whether the API
makes the common case easy and the complex case possible.

**Catches:** Unclear contracts, inconsistent naming/patterns across endpoints,
missing pagination, non-idempotent mutations, breaking changes without
versioning, error responses that don't help callers recover, leaking internal
implementation details through the API surface.

---

## Custom Perspectives

If the catalogue doesn't cover a lens the user needs, create a custom
perspective on the fly. Derive a specific analytical procedure from the
user's description — it should be as concrete and actionable as the catalogue
entries above, not a vague "look at X."

Example: If the user says "review for our team's error handling conventions,"
create a procedure like: "Trace every error path in the codebase. Check for
consistent error wrapping, whether errors cross module boundaries with context,
whether recovery vs propagation decisions follow a consistent pattern..."

Custom perspectives participate in the same Round 1 → Round 2 → Synthesis
flow as catalogue perspectives.

---

## Selecting Perspectives

When recommending perspectives for an artifact or question, consider:

1. **Artifact type determines the starting palette:**
   - Design docs → Maintainer + User/Consumer (role) or Design Principles (discipline)
   - Architecture decisions → Adversary + Performance/Scale
   - Plans → Operator + Business/Strategy
   - Code/implementation → mix role-based with discipline-based
   - Tech stack evaluation → Business/Strategy + Integrator + Operator
2. **Domain signals narrow the selection:**
   - Security-sensitive → Adversary
   - User-facing → User/Consumer
   - Infrastructure → Operator
   - API design → API Design (discipline) + Integrator (role)
   - Pattern/standards review → Design Principles + Conventions & Idioms + Testing Strategy
   - Data-heavy → Data Integrity + Performance/Scale
3. **Mix role-based and discipline-based when both add value.** A code review
   might pair Adversary (role — finds exploitable flaws) with Testing Strategy
   (discipline — finds test gaps that let those flaws ship). The cross-pollination
   between a role lens and a discipline lens is often more productive than
   two of the same type.
4. **Cap at 3-4:** Per collective intelligence research (Woolley et al.),
   3-4 perspectives is the sweet spot. More than 4 adds coordination overhead
   that degrades quality.
5. **Explain why:** For each recommended perspective, state why it's relevant
   to this specific artifact — not just generic reasoning.
