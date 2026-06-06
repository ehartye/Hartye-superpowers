# Two-Tier Git-Native Lesson Store with Pull-on-Demand Retrieval

## Status
Proposed. **Partially superseded (2026-06-05):** the design spec
`docs/superpowers/specs/2026-06-05-running-retrospectives-design.md` found this
ADR conflated "reuse the existing `memory/` convention" with "git-diffable
promotion" — no repo-local `memory/` exists. v1 promotes into the agent's
project-scoped auto-memory (not git-tracked), with the RED→GREEN validation gate +
interactive approval as the correctness guarantee in place of git review. The
two-tier model, pull-on-demand-vs-inject reasoning, and ~15-lesson budget below
still stand.

> Decision record for `harvesting-lessons` (Rec 2 of
> `docs/research/claude-code-harness-landscape-2026-06-03.md`) storage + retrieval.
> Produced via `h-superpowers:perspective-research` (team-driven, four lenses:
> Integrator, Performance/Scale, Maintainer, Data Integrity) on 2026-06-05.
> Full synthesis + all eight round files: `.perspectives/storage-adr/`.

## Context
The `harvesting-lessons` validated-learning funnel (capture → cluster →
validate-with-RED-step → promote) needs a place to store harvested lessons and a
way to recall them at the moment they would prevent a repeat mistake. Constraints:
git-native, no daemon, no external DB service, compose with installed sibling
plugins, cross-platform (Windows-primary + bash), and low concept-count for a
stranger who installs the plugin without the author present.

The user rejected the original "native Claude memory vs. flat .md" binary (ADR
Open Question 2 of the landscape research) on two grounds: a flat .md loses
semantic search, and yet-another-.md risks context bloat. A four-lens perspective
study converged on a reframe that dissolves both objections: **storage and
retrieval are separable concerns, and pull-on-demand retrieval bounds per-session
context cost regardless of store size** (inject-all is O(store size) per session —
~120k tokens at 1,000 lessons; pull top-k is O(k), flat). Both user objections are
objections to the *same* mistake: one large file injected at SessionStart.

The study also established a **two-lifecycle** structure: disposable,
machine-generated *captures* vs. low-volume, reviewed, authoritative *promoted*
lessons — with promotion as a one-way door between them. And it surfaced one
load-bearing gap (the RED-step contract for prose) that the storage decision must
not be allowed to obscure (see Risks).

## Decision
Adopt a **two-tier, git-native store with pull-on-demand retrieval**, shipping only
the git-native half in v1:

1. **Candidate tier:** one project-local, append-target flat file
   (`.superpowers/lessons-candidates.*`). Each entry carries minimal frontmatter
   provenance — **content-hash of CRLF-normalized text, session id, timestamp** —
   so the N≥2 recurrence gate counts *distinct corrections across distinct
   sessions*. No SQLite. Pull-only; **never injected at SessionStart.**

2. **Promoted tier:** reuse the existing **`memory/` convention** (one file per
   lesson, frontmatter `type: feedback`, an index line in `MEMORY.md`). No new
   `.superpowers/lessons/` tree. Promotion **moves** (not copies) the lesson from
   candidates into `memory/`, leaving exactly one authoritative copy.

3. **Retrieval:** pull-on-demand via the **existing `using-superpowers` pull-gate**
   ("does a prior lesson apply before I act?"), v1 using plain grep/ripgrep over
   `memory/`. SessionStart stays `using-superpowers`-only (`exit 0`).

4. **Crossover rule:** promoted lessons may live always-in-context (via MEMORY.md)
   **only while under ≈15 promoted lessons** (keeping SessionStart growth under ~2k
   tokens at ~120 tokens/lesson). At/above that threshold, the promoted tier becomes
   pull-on-demand behind a `lessons query <intent>` seam.

5. **Deferred index seam:** name (in prose) a single `lessons query` retrieval
   interface and an FTS5 index contract; **do not build it in v1.** When grep recall
   is measured insufficient, fill the seam with SQLite **FTS5** (stdlib, zero ML
   deps, deterministic, instant rebuild). Any index is git-ignored, content-
   addressed, rebuildable, and degrades to grep. Embeddings are a later opt-in
   adapter behind the same seam, only on measured paraphrase-recall need.

**First increment:** candidate file with provenance → harvesting skill clusters via
read/grep-filter, counts N≥2 over distinct sessions, validates, promotes by moving
into a `memory/` `type: feedback` entry → recall = one added question on the
existing pull-gate over `memory/`. Net new concepts for a stranger: ~1–2.

## Alternatives Considered
- **Flat .md only (single file):** rejected — conflates store with inject; loses
  semantic search AND risks SessionStart bloat (the user's two objections). The
  two-tier + pull-on-demand design supersedes it.
- **Native Claude memory as the store:** rejected as store — per-subagent
  granularity mismatches the orchestrator-level value; not git-reviewable/diffable;
  depends on a moving platform floor. Retained only as a possible future mirror
  target behind the seam.
- **Local SQLite (+ optional embeddings) as v1 store:** rejected — binary blob that
  doesn't `git diff`, can't be hand-edited or reviewed in a PR, adds schema +
  query-surface + (for embeddings) a heavy ML runtime concept. Solves a scale the
  funnel is designed to prevent. SQLite returns only as the *FTS5 derived index*
  (git-ignored, rebuildable) behind the deferred seam.
- **Reuse agent-stalker's capture + clustering as a dependency:** rejected as a
  hard dependency — forces a second plugin dragging two runtimes (Bun + Python) plus
  an opt-in PyTorch-class ML stack (sentence-transformers/bertopic/hdbscan/umap),
  with a private/undocumented schema and async/lossy capture. Allowed only as
  *opportunistic* capture/recurrence enrichment if installed. (Reuse the pattern,
  never the dependency — unanimous across all four lenses after filesystem
  verification.)
- **MCP-backed retrieval:** rejected — adds a runtime dependency and a server
  concept, directly violating "no daemon, no external DB service."
- **Hybrid git + derived index, index built now:** rejected for v1 — the index
  (build + rebuild command + staleness + CRLF hashing landmine) is 3–4 net-new
  concepts and cross-platform maintenance for fuzzy search over a corpus the funnel
  deliberately keeps small. Adopted as the *deferred end-state* (named seam, unbuilt)
  rather than v1.

## Consequences
### Positive
- Per-session context cost is decoupled from store size (pull-on-demand, O(k));
  both user objections dissolve at one point.
- Everything durable is a single reviewable git diff; promotion is one diff; no
  committed binary blob.
- Lowest concept-count consistent with the constraints (~1–2 net-new): reuses
  `memory/`, the existing pull-gate, and the `drift`/skill-local-script precedent;
  SessionStart untouched.
- Storage-agnostic funnel: the index can be added later (grep → FTS5 → embeddings)
  behind one seam without touching the funnel.
- The N≥2 + RED-step gate doubles as a performance control (it bounds the
  SessionStart budget), aligning the funnel's defensible value with the scarce
  resource.

### Negative
- v1 grep gives lexical, not semantic, recall — paraphrased prior corrections can
  be missed until the FTS5 seam is filled.
- Capture is a deliberate skill step, not automatic/lossless; some corrections may
  go uncaptured.
- Folding promoted lessons into MEMORY.md *is* SessionStart injection under a
  curation gate — it silently regresses toward the unbounded case if promotion
  outruns pruning and the ~15-lesson budget is ignored.

### Risks
- **RED-step undefined for prose (highest, unresolved):** if promotion is gated
  only on N≥2 recurrence, the funnel is recurrence-gated, not validation-gated, and
  a confident wrong prose lesson can be injected every session via MEMORY.md.
  *Must be resolved before/with the build.* This is the next piece of work.
- **SessionStart budget creep:** mitigated by the ~15-lesson crossover rule +
  active pruning/retirement of superseded lessons (budget reclamation).
- **Recurrence double-counting:** mitigated by content-hash dedup + session/
  timestamp provenance at capture; recurrence counted over distinct sessions.
- **CRLF-vs-LF hashing:** mitigated by hashing CRLF-normalized text (mandatory the
  moment hashing is introduced — at capture, in v1).
- **Future-index drift / committed binary:** mitigated by the git-ignored,
  content-addressed, rebuildable, degrade-to-grep contract as a tested invariant.
- **agent-stalker coupling:** mitigated by keeping it opportunistic-only; the
  promoted tier is always h-superpowers-owned and dependency-free.

## Open Questions (carry into design)
1. **[LOAD-BEARING] What does the RED-step / failing baseline assert for a PROSE
   lesson?** All four lenses converged on this as the most important unanswered
   question. A failing test is obvious for a *code* lesson; for "stop assuming the
   user wants X" there is no defined falsifiable baseline. If the gate is only N≥2,
   the funnel is recurrence-gated, not validation-gated — and the brand claim
   ("won't promote a lesson without a failing baseline") is unmet. Resolve before or
   jointly with the storage build.
2. **Realistic steady-state promoted-lesson count per project** — sets whether the
   ~15-lesson crossover is hit in months or years (and thus when the FTS5 seam needs
   filling). Measurable with crucible (A/B grep vs. FTS5 recall on a seeded set).
3. **Candidate capture trigger:** confirm deliberate skill-step capture suffices, or
   prove a need for automatic Stop/SubagentStop hook capture (reintroduces net-new
   cross-platform hook infrastructure).
4. **Commit policy for the candidate file:** create it project-local; decide whether
   the plugin commits it or leaves git-tracking to the user (lean: create, let the
   user decide; don't force a `.gitignore` edit).
