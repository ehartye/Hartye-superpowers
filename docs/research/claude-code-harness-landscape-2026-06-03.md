# Synthesis Report — Claude Code Dev-Process Harnesses: What to Sample and Meld into h-superpowers

**Original question:** Find at least 3 other highly popular Claude Code dev-process harnesses in the wild like obra/superpowers. What makes them special? What parts of them could enhance existing or become new parts of h-superpowers?

**Framing:** The user wants h-superpowers to transcend its upstream connection and become a broad-spectrum sampler and melder of concepts — divergence and original synthesis are the goal.

**Method:** Four perspectives (Business/Strategy, Integrator, User/Consumer, Synthesist/Melder) explored independently (Round 1), then cross-pollinated (Round 2). This report consolidates all eight files. Produced via the `h-superpowers:perspective-research` skill (team-driven path) on 2026-06-03.

---

## Positions Summary

### Business / Strategy
- **Stance:** Don't be a bigger Superpowers. Position h-superpowers as the *melder/conductor* that owns the **seams between** what incumbents each own in isolation — and lead with the assets no one else has.
- **Key bets (priority order):** (1) **Right-sized ceremony router** — white space no framework owns; after seeing User's HARD-GATE finding, reframed as *negative-cost* (it removes self-imposed ceremony). (2) **perspective-research/review as the flagship** — already h-superpowers' most original asset, generative multi-perspective reasoning nobody else owns. (3) **Thin memory/learning layer built ON native Claude memory**, not a proprietary runtime.
- **Round 2 sharpenings:** "Negative-cost differentiation" is the headline — the highest-value move *removes* code. True moat = the pairing of *discipline-as-content* × *the machinery to enforce/learn it* (writing-skills RED-step, hooks, perspective engine). Reframe "conductor" as a **filter**, not a feature.
- **Top risks:** Me-too/catch-up trap; **junk-drawer dilution** (the single biggest risk of the breadth mandate); betting on a trend (memory) Anthropic is absorbing; inheriting everyone's token cost; Spec Kit's gravity.

### Integrator
- **Stance:** The ecosystem splits into two integration classes — adopt from only one. **Markdown-native** harnesses (spec-kit, BMAD's prompt layer, shinpr, SuperClaude) map cleanly onto existing Skill/agent/command primitives. **Stateful-runtime** harnesses (claude-flow/ruflo, claude-mem) assume a daemon + external DB + custom hook engine that fights h-superpowers' "state lives in git, no external runtime" architecture.
- **Key alternatives:** Cleanest-fit adoption = spec-kit's `constitution` + spec→plan→tasks artifact chain (h-superpowers has the back half, lacks durable principles). shinpr/claude-code-workflows is the lowest-friction donor (same primitives). Adopt the memory *goal*, re-implement on the existing hook primitive — veto the daemon.
- **Round 2 insights:** **N1** — every durable artifact must be a **git-native file whose evolution is a git diff** (admits constitution/standards/living-spec; rejects AgentDB, `.specify/` trees, dated one-shots). **N2** — there is a **missing primitive nobody named: a session-scoped scratch-state store** that hooks and skills both read/write; it is the shared substrate under learning, tripwires, and instinct-capture. **N3** — the melder identity's precise form: pure markdown-native spine + exactly two small infra pieces (decisioning-hook capability + scratch-state file) + consume (never re-host) daemons via MCP/sibling plugins. **N4** — ECC's AgentShield (config-security scanning) is the single cleanest-fit new capability (read-only, no state, no runtime).
- **Top risks:** Runtime-dependency creep; state-management mismatch / second source of truth; CLI/installer collision; persona/ceremony bloat; spec-kit's fat-command model splitting logic; upstream-divergence governance; experimental-flag stacking.

### User / Consumer
- **Stance:** h-superpowers wins on *in-session process discipline* but has two acute, frequent gaps: **no persistent project memory/standards** and **no lightweight fast-path for small work** (the HARD-GATE that forces design-doc on *every* project "regardless of perceived simplicity" is the literal abandonment trigger).
- **Key alternatives:** Agent OS (durable 3-layer standards), OpenSpec (lightweight diffable living specs), BMAD's tiered Quick/Standard/Enterprise flow (adopt the tiers, NOT the personas), Spec Kit (confirmation the spine is right + cautionary "don't out-ceremony it").
- **Round 2 insights:** **A** — the two big complaints share one root cause: h-superpowers applies the *same fixed altitude to everything*. One per-request "altitude + context check" fixes both → sellable story: *"h-superpowers right-sizes itself to your task."* **B** — the **learning loop** may be the highest *felt* value (solves "I corrected it yesterday and it did the same thing today" — more emotionally acute than static standards). **C** — compose with already-installed plugins (ralph-loop, hookify, claude-md-management, crucible) rather than reinventing. **D** — "verify in a real browser, not just tests" (gstack/Playwright) is a real missed pain.
- **Top risks:** Solving hype not pain (role personas); the HARD-GATE makes the ceremony complaint *worse*; spec/standards drift (stale standards are worse than none); onboarding complexity growth; over-adopting = becoming nothing.

### Synthesist / Melder
- **Stance:** h-superpowers' core primitive is **behavioral discipline encoded as agent-invoked skills**. It is absent on three primitives others own: durable cross-session learning, spec-as-governing-artifact, autonomous looping. The goal is not to copy any one — it is to **meld** them with the discipline primitive, producing hybrids no one has.
- **Key melds (post-cross-pollination ranking):** (1) **`altitude-router`** [promoted in R2 after 3-lens convergence], (2) **`harvesting-lessons`** (capture→cluster→validate→promote funnel), (3) **`living-spec`** (diffable + code-verifier gate), (4) **`house-style`** (project standards via the same pull-gate), (5) **`tripwires`** (push-enforcement), (6) **`disciplined-loop`** (re-parented to GSD-native) + **`red-team-spec`**.
- **Round 2 deepest insight (E):** Every lens independently concluded the *learning/standards/spec layers are commodity* while **validation + multi-perspective reasoning are uniquely ours**. The spine: **"the harness that *validates*"** — won't promote a lesson without a failing baseline, won't claim done without evidence, won't let code drift from spec without a diff, reasons from multiple perspectives before committing.
- **Top risks:** Skill-bloat/Frankenstein incoherence; philosophical incompatibility (Ralph vs. human-in-the-loop); spec-as-truth vs. discipline-as-truth; push-enforcement false positives; "clever-but-empty" melds; mandate drift (breadth without a spine = junk drawer).

---

## The Harness Landscape (deduplicated across all four perspectives)

Star counts are reported by secondary comparison sources circa April–June 2026 and disagree across articles. Treat them as **relative signal, not audited figures**. The concepts, not the numbers, drive the recommendation.

| Harness | Core primitive / what makes it special | Popularity evidence (soft) |
|---|---|---|
| **obra/superpowers** (our parent) | *Behavioral discipline as agent-invoked skills* — no production code without a failing test; brainstorm→plan→execute→review; the discipline is the point. | The reference framework; every comparison article frames around it. Strong evangelism (Jesse Vincent / fsck.com). |
| **github/spec-kit** | *Spec-as-source-of-truth contract* — Constitution → Specify → Plan → Tasks → Implement; agent-neutral (29–30+ agents); plans WHAT, not HOW. | ~90–108K stars, 8K forks, 200+ contributors. GitHub-backed; the de-facto vocabulary of the space. |
| **GSD / get-shit-done** | *Context-rot defeat* — fresh subagent per task (clean 200K window), orchestrator held <40%, state-to-disk markdown, wave-based parallelism. **Entirely native** (no runtime). | ~31–51K stars. Claims engineers at Amazon/Google/Shopify/Webflow. The native-only existence proof. |
| **gstack / GSTACK** | *Role-based governance* — virtual 23-person team, role-scoped context, `/office-hours`, real browser/deployment verification, retrospectives. | High stars. Strong product-first positioning. Cost flag: ~10K tokens/skill. |
| **BMAD-METHOD** | *Hyper-detailed handoff artifacts (story files)* + persona agents + planning/dev split + tiered Quick/Standard/Enterprise flow. | ~37–43K stars; widely reviewed. Caveat: praised as planning accelerator, criticized for ceremony on small fixes. |
| **Agent OS** (buildermethods) | *Persistent 3-layer context* — Standards (how you build) / Product (what+why) / Specs (this feature); "define once, available everywhere"; v3 auto-discovers standards. | Consistently named a dominant 2026 framework alongside Spec Kit/BMAD. |
| **OpenSpec** (Fission-AI) | *Lightweight diffable change proposals* — current-spec vs. proposed-change-as-delta; spec as living source-of-truth; explicitly branded "lightweight" as a reaction to heavier frameworks. | Named in May 2026 roundups among three frameworks "dominating real engineering conversations." |
| **shinpr/claude-code-workflows** | *Closest structural twin* — itself a Claude Code plugin (marketplace + agents + skills); `requirement-analyzer` complexity router; `code-verifier` (diffs code against the design doc); document-driven development. | Lowest-friction donor: same primitives, same philosophy. |
| **cc-sdd** (gotalab) | *Portable SDD across 8 agents, 13 languages* — minimal, adaptable; competes with Spec Kit on portability. | Smaller; portability-focused. |
| **ECC / everything-claude-code** (affaan-m) | *Layered operator OS + self-improvement* — **Instincts** (confidence-scored, auto-captured, clusterable into skills), memory-persistence hooks, **AgentShield** (102 config-security rules), research-first skills. Push-enforcement via lifecycle hooks. | Quoted star count almost certainly inflated; perspectives relied on concepts only. |
| **claude-flow / ruflo** | *Stateful MCP swarm runtime* — ~210 MCP tools, background workers, AgentDB vector store, blackboard coordination, swarm topologies, consensus gating. | The heavyweight runtime end of the market. |
| **claude-mem** | *Session-memory plugin* — captures session activity, AI-compresses, re-injects at session start. **Plugin-native** (the right-sized memory template). | Honorable mention; the lighter, plugin-native memory model. |
| **claude-reflect-system** (haddock-dev) | *Correct once, never again* — detect feedback signals (HIGH/MED/LOW confidence), extract the pattern, write it into a skill file, apply retroactively. | The learning-loop reference. |
| **Ralph loop** (snarktank/ralph) | *Autonomous closed-loop iteration* — fresh context per iteration + external durable memory + circuit-breakers + locked completion criteria. | The "ship while you sleep" pattern (also present as the installed `ralph-loop` plugin). |
| **Native Claude memory (the moving floor)** | *Platform absorption of the memory layer* — subagent memory (v2.1.33, Feb 2026); Managed Agents memory + "Dreaming" (review past sessions, refine knowledge; May 2026). | The most important strategic signal: Anthropic is absorbing memory into the platform. |

---

## Cross-Pollination Results

### Hybrid Approaches / Melds

The most important synthesis output: the perspectives, building on each other, converged on a small set of **validated melds** — each combining an external concept with an asset only h-superpowers has, and each laddering to one spine sentence.

**1. `altitude-router` — the meld every lens validated (HIGHEST CONFIDENCE).**
*Parents:* shinpr's `requirement-analyzer` complexity router (Integrator) × BMAD's Quick/Standard/Enterprise tiers (User) × h-superpowers' `using-superpowers` Skill-Priority gate (Synthesist).
The Synthesist *had no routing meld in Round 1* and promoted it to #1 in Round 2 specifically because three independent lenses reached it from different directions — Business from market white-space, Integrator from a working reference implementation in the same primitives, User from lived abandonment pain. The melded novelty: the parents route to *different workflows*; this routes to **different ceremony levels of the SAME discipline spine**. It dials brainstorm-doc and full-plan ceremony up/down by task altitude while keeping TDD + verification non-negotiable at every tier. This is the meld that resolves the central tension (see below) by making the HARD-GATE *altitude-aware* instead of all-or-nothing. Business reframed it as **negative-cost** (it removes self-imposed ceremony rather than adding surface).

**2. `harvesting-lessons` — the three-gate validated-learning funnel (DEFENSIBLE MOAT).**
*Parents:* claude-reflect's confidence-tiered capture × ECC's "cluster into skills" × h-superpowers' `writing-skills-IS-TDD` RED-step.
Cross-pollination turned this from a single idea into a **capture (confidence-scored) → cluster (recurrence threshold N≥2) → validate (RED-step) → promote** funnel. The melded novelty no existing harness has: claude-reflect captures+promotes *without* recurrence or validation; ECC captures+clusters *without* validation; writing-skills validates *without* capture. The full funnel is uniquely ours. Business and User independently flagged the underlying pain ("I corrected it yesterday…") and the platform-absorption risk, which *narrowed* the meld correctly: **don't own storage — write into the native memory substrate (or git-tracked Markdown today); our defensible seat is "validated learning," not "more memory."**

**3. `living-spec` — diffable spec + completion drift-gate (LOWER EFFORT THAN THOUGHT).**
*Parents:* spec-kit's spec-as-source-of-truth × OpenSpec's diffable-change framing (User) × shinpr's `code-verifier` (Integrator) × h-superpowers' `verification-before-completion`.
The Integrator and User independently supplied the engine (shinpr's working `code-verifier` diff-against-doc) and the freshness model (OpenSpec's living diff, not a dated one-shot). Result: the completion gate verifies code matches the *current* spec, and any intended divergence must be **written back as a spec delta (a git diff) before the claim passes**. This closes the spec-drift failure all three circled and makes "living" actually true.

**4. `house-style` — project standards via the existing pull-gate (CLEAN FIT).**
*Parents:* Agent OS's discover/index/inject standards (User) × h-superpowers' `using-superpowers` "does a skill apply?" pre-action gate.
The cleanest architectural fit: the same pull-gate that asks "does a skill apply?" also asks "does a local standard apply?" — **one mechanism, two knowledge sources.** Integrator refined the layering: constitution = project-global (session-injected), standards = file-pattern-scoped (pull-loaded), both git-tracked.

**5. `tripwires` — push-enforcement of TDD/verification (HIGH VALUE, HIGHEST ARCH COST).**
*Parents:* ECC's lifecycle-hook push-enforcement × h-superpowers' pull-based discipline content.
The one meld that exploits an asset competitors can't copy (our discipline *content*) via a modality we lack (push). But cross-pollination corrected the Synthesist's "the hooks slot already exists" optimism — see Challenges below.

**6 & 7. `disciplined-loop` (re-parented) + `red-team-spec` (KEEP, LOWER PRIORITY).**
`disciplined-loop` was re-parented in Round 2 from "Ralph × discipline" toward "**GSD's native state-to-disk** × discipline" — because GSD proves the loop can be native-first (matching our worktree bias) where Ralph is an external shell script. All three of the other lenses argue for *composing with the installed `ralph-loop` plugin* rather than rebuilding.

**The meld-of-melds (Synthesist Insight E, validated by all):** the spine sentence is **"h-superpowers is the harness that *validates*"** — and every meld above is an instance of it. This is simultaneously Business's "conductor identity," the Integrator's curation criterion, and User's "curated breadth with a spine." It only became visible by sampling across all four lenses.

### Challenges & Rebuttals

**Integrator vs. Synthesist — "the hooks slot already exists" (T1, the sharpest direct conflict).**
The Synthesist treated `tripwires` (MELD 5) as structurally cheap because h-superpowers is "a plugin with a hooks slot already." The Integrator rebutted hard: h-superpowers' *only* hook is `SessionStart` doing **pure context injection** (`additionalContext`, `exit 0`). PreToolUse/Stop are a **categorically different contract** — input inspection, permission decisions, and **session-scoped state** ("was a failing test run this session?") that h-superpowers has no mechanism for today, plus doubled cross-platform (bash/PowerShell) burden. The slot existing ≠ the mechanism being cheap. **Resolution:** build it, but cost it honestly as new infrastructure and ship warn-and-confirm (`permissionDecision: "ask"`) first — which the Synthesist accepted.

**Integrator vs. Business — "build ON native memory" vs. "plugin-owned flat file" (T2, the lead's Open Question 2).**
Detailed below in Open Questions — this is a genuine bet-vs-fit tension the perspectives did *not* fully resolve.

**Business vs. User — does the standards layer lead the story? (a tension on emphasis, not direction.)**
Both agree to build a standards layer. They disagree on whether it *leads*: User ranks persistent standards #1 (highest value, lowest cost); Business ranks it *behind* the router and perspective-flagship because, from the positioning lens, it is **defensive table-stakes, not differentiation** — "leading with 'we have a standards layer too' makes us a follower."

**User vs. Synthesist/Business — perspective-research is the flagship, but it's heavy.**
User strongly endorsed perspective-research as the one thing developers can't get elsewhere — then flagged that it spawns a subagent army and a token bill, so a first-timer triggering it on a trivial question gets burned. **Resolution:** the same altitude-router must gate perspective-research to fire on genuine "X or Y" decisions, not "what should I name this variable." Flagship — but not the default reflex.

**All four vs. Ralph/autonomous-loop — converged AGAINST building it.**
Business: most-commoditized corner of the market, me-too. User: sharper *consumer* risk — "I came back and it had spent $40 confidently building the wrong thing." Integrator: a `ralph-loop` plugin is already installed; reimplementing is packaging collision. Synthesist: accepted, re-parented to compose with the existing plugin and contribute only the disciplined loop-body + discipline-violation circuit-breaker.

**All vs. role personas — converged AGAINST.**
BMAD's 7-persona ceremony is the most-*marketed*, most-*complained-about* idea ("a 4-hour bug fix shouldn't need a PRD and a sprint story"). Adopt BMAD's **story-file artifact** and **tiered flow**, not its personas. This retroactively validates h-superpowers' existing "lightweight, task-derived teammate roles" choice.

### Converging Themes

1. **Right-sized ceremony is the #1 opportunity** — reached by all four (Business white-space, Integrator's shinpr reference impl, User's HARD-GATE abandonment evidence, Synthesist's promoted altitude-router). It is the single highest-confidence finding, and it is *negative-cost* (removes a self-inflicted wound).
2. **A durable project-knowledge layer (standards/constitution) is table-stakes** — reached by all four via different routes. Build it, fold it into existing surfaces (CLAUDE.md/MEMORY.md), don't brand on it.
3. **No daemons, no external DBs, no installers; everything git-native** — Business ("build above the platform"), Integrator ("two-class rule + git-diff acceptance criterion"), User ("adopt content never installers"), Synthesist ("artifacts must be git-tracked Markdown the agent writes"). GSD is the existence proof that context-stability is achievable natively.
4. **Validation + multi-perspective reasoning are the true moat** — everyone concluded learning/standards/spec layers are commodity (Anthropic absorbing memory) while the RED-step validation, the code-verifier gate, the evidence-before-completion gate, and the perspective engine are uniquely ours.
5. **Compose with installed plugins, don't reinvent** — ralph-loop, hookify, claude-md-management, crucible are already present; reimplementing creates "which one do I use?" confusion and onboarding bloat.
6. **A session-scoped scratch-state store is the unnamed shared substrate** — the Integrator identified that learning, tripwires, and instinct-capture all secretly depend on it; the Synthesist's "one hook, three loads" consolidation (SessionEnd writes git-tracked Markdown, SessionStart re-injects) is the delivery channel.

---

## Recommendation

### Recommended adoptions/melds (prioritized)

1. **`altitude-router` — right-sized ceremony triage. (Confidence: HIGH)**
   A triage step at the top of `using-superpowers`' existing pull-gate classifies each request (trivial-fix / feature / multi-subsystem) and dials *ceremony* (brainstorm-doc, full plan, perspective-research) up or down — while keeping the *discipline* spine (TDD, root-cause-before-fix, evidence-before-done) non-negotiable at every tier. Make the brainstorming `<HARD-GATE>` altitude-aware rather than all-or-nothing. Reference implementation exists in shinpr's `requirement-analyzer`. Negative-cost. Ship FIRST — it gates ceremony and makes every other adoption affordable.

2. **`harvesting-lessons` — validated-learning funnel. (Confidence: Medium-High)**
   capture (confidence-scored) → cluster (recurrence N≥2) → validate (writing-skills RED-step) → promote. Write into the native memory substrate / git-tracked Markdown via a SessionEnd/Stop hook re-injected at SessionStart. Our defensible seat: *validated* learning, not more memory. This is moat-extending and addresses the highest *felt* pain.

3. **`house-style` + lightweight constitution — durable project knowledge. (Confidence: High on value, Medium on placement)**
   Standards = file-pattern-scoped, pull-loaded through the existing "does a skill apply?" gate; constitution = project-global, session-injected. **Fold into existing surfaces (CLAUDE.md / MEMORY.md) — do NOT add a third/fourth principles file.** Defensive table-stakes: ship it, don't brand on it.

4. **`living-spec` — diffable spec + completion drift-gate. (Confidence: Medium)**
   Living, updatable spec where changes land as git diffs; `verification-before-completion` refuses the "done" claim until code↔spec correspondence is shown, with divergences written back as a spec delta. Engine = shinpr's `code-verifier`. Lower effort than first estimated.

5. **`tripwires` — push-enforcement, warn-and-confirm only. (Confidence: Medium on value, LOW on cost certainty)**
   PreToolUse/Stop decisioning hooks surfacing the TDD Prime Directive and verification-before-completion as `permissionDecision: "ask"` prompts. Highest architecture cost (new hook contract + session-scoped state + doubled cross-platform). Build on the shared scratch-state substrate.

6. **ECC AgentShield-style config-security scan. (Confidence: Medium-High as a low-risk quick win)**
   Read-only static analysis of CLAUDE.md/hooks/MCP/skills for prompt-injection/misconfiguration, as a `security-review`-style skill or non-blocking hook. The Integrator's pick for "lowest-integration-cost differentiated thing" — no durable artifact, no state, no runtime.

7. **`disciplined-loop` (compose with installed `ralph-loop`) + real-browser verification (Playwright) + `red-team-spec`. (Confidence: Low-Medium)**
   Contribute the disciplined loop-body and discipline-violation circuit-breaker to the existing ralph-loop plugin rather than rebuilding. Add browser verification as a low-ceremony enrichment to `verification-before-completion`.

**Do NOT build:** a proprietary memory runtime/vector DB; role-persona theater; an autonomous loop from scratch; any external installer (uv/pipx/npx) dependency; a parallel filesystem-of-record (`.specify/` trees, dated one-shot specs).

### Key tradeoffs to accept
- **Altitude-aware gate vs. upstream rigidity.** Making the HARD-GATE altitude-aware is a deliberate, sanctioned divergence from upstream's "every project regardless of simplicity." The breadth mandate authorizes it, but it should be explicit (and per CLAUDE.md, upstream alignment checked/flagged).
- **Two small new infra pieces.** Accepting `tripwires` and `harvesting-lessons` means accepting a *decisioning-hook capability* and a *session/cross-session scratch-state file* — the minimal infrastructure the Integrator says the melder identity requires. Anything beyond these two pieces (daemon, DB) is out.
- **Defensive table-stakes won't differentiate.** The standards/spec layers must ship to not look dated, but they will not be the brand. Identity rides on validation + perspective reasoning + provable leanness.

### Mitigations for top risks
- **Junk-drawer dilution (the #1 risk of the mandate):** every meld must ladder to the one spine sentence ("the harness that *validates*"); reject anything that's just "also do what gstack does." Curated breadth, not breadth-for-breadth.
- **Platform-eats-memory:** don't own storage; write to the native substrate / git, keep our value in the *validation funnel*.
- **Hook false positives:** warn-and-confirm (`ask`), never hard-block; align with how the repo already attributes consent gates.
- **Onboarding bloat / three-sources-of-truth:** reuse CLAUDE.md/MEMORY.md, compose with installed plugins, prove the token win with the in-repo crucible plugin.
- **Token cost:** position right-sized ceremony as *provably lean* and measure it with crucible.

### Investigate further before deciding
1. **Audience (lead's Open Question 1 — answered below):** personal harness vs. public star-competing framework shifts the weighting.
2. **Native-memory granularity vs. platform-absorption (lead's Open Question 2 — presented below):** unresolved bet-vs-fit tension.
3. **Empirically validate the altitude-router and any tripwire with crucible** before broad rollout — does the fast-path actually cut tokens/correction-cycles on small tasks?
4. **Upstream alignment:** which of constitution, router, memory-hook, story-file does obra/superpowers already have or reject? Per CLAUDE.md, check and flag before landing.
5. **Confirm the session-scoped scratch-state primitive** (`.h-superpowers/session-state.json` or similar) as the shared substrate before building three skills that each invent their own storage.

---

## Lead's Two Open Questions — Explicit Answers

### Open Question 1 — Is this the user's personal harness or a public star-competing framework?

Raised by Business as the question that "flips the entire calculus." **How the recommendation shifts either way:**

| | If **personal harness** (optimize the user's own workflow, ignore adoption) | If **public framework** (competing for stars/mindshare) |
|---|---|---|
| **`altitude-router` (Rec 1)** | Still #1 — it removes ceremony tax the user personally feels on small tasks. | Still #1 — it's also the unclaimed "spec-disciplined but right-sized" brand and attacks the loudest market complaint. |
| **perspective-research flagship (Business Bet 2)** | Right for both — it's the user's own highest-leverage reasoning tool. | Right for both — it's the differentiated public identity nobody else owns. |
| **`harvesting-lessons` / memory (Rec 2)** | **Weighted UP** — a personal harness benefits enormously from learning *the user's* corrections; platform-absorption risk matters less (no competitor to lose to). | **Weighted DOWN slightly** — risk that Anthropic's native memory + Dreaming makes a public memory feature look redundant in two releases; lead with validation, not memory. |
| **Standards/constitution (Rec 3)** | Build minimally; fold into the CLAUDE.md the user already maintains. Lower urgency (the user knows their own conventions). | **Weighted UP as defensive table-stakes** — needed to not look dated next to Agent OS/Spec Kit, even though it won't differentiate. |
| **AgentShield config-security (Rec 6), browser-verify** | Nice-to-have. | **Weighted UP** — a defensible public niche nobody else fills. |
| **Token-cost / leanness positioning** | Matters for the user's own bill. | **Becomes a brand** — "provably lean discipline," measured by crucible. |
| **Onboarding/first-run simplicity** | Largely irrelevant. | **Critical** — every new layer is first-run surface; "fewer concepts" is itself a differentiator in a 30-framework market. |

**Net:** Bet 2 (perspective flagship) and Rec 1 (altitude-router) are correct regardless. The split mainly re-weights *memory* (up for personal, down/lead-with-validation for public) and *standards + niche + onboarding* (up for public, lower-urgency for personal). **This question should be answered by the user before sequencing Recs 2, 3, and 6.**

### Open Question 2 — "Build ON native Claude memory" (Business) vs. "plugin-owned git-tracked file" (Integrator)

This is a genuine, **unresolved** bet-vs-fit tension (the Integrator explicitly said "I don't think this fully resolves"). Both sides:

**Business — build ON native subagent memory + Dreaming (strategic absorption argument):**
- Anthropic is shipping native subagent memory (v2.1.33) and Managed-Agent memory + Dreaming. Building a proprietary memory runtime is the classic "platform eats your feature" mistake — GSD and Superpowers both stayed native and won.
- Strategic play: a thin instinct-capture skill that writes into the native store with our own confidence/clustering convention. Ride the platform; don't compete with it.

**Integrator — plugin-owned git-tracked flat file (integration-fit/granularity argument):**
- Native subagent memory is a **per-subagent** store. h-superpowers' value lives in the **orchestrator** (the lead in team/subagent-driven-development), and the lessons worth keeping are the *orchestrator's*, not a transient subagent's.
- Writing to native per-subagent memory **scatters learnings across ephemeral agents that get deleted on `TeamDelete`** — a granularity mismatch.
- A plugin-owned git-tracked Markdown file (claude-mem model) fits the orchestrator level *and* satisfies the "every durable artifact is a git diff" acceptance criterion — but it may be redundant in two releases if the platform's memory grows orchestrator-level support.

**The tension in one line:** the strategic-risk lens (avoid platform absorption → use native) and the integration-fit lens (orchestrator-level granularity → use a git file) point in **opposite directions**.

**Synthesis recommendation (does not force a premature pick):**
- **Decouple capture from storage.** The defensible value — the **capture→cluster→validate→promote funnel** — is storage-agnostic and is what differentiates us from both ECC (capture without validation) and native Dreaming (refinement without a falsifiable test). Build the funnel first.
- **Default to a git-tracked Markdown file today** (orchestrator-level granularity, git-diff-native, no platform dependency, works now) — the Integrator's fit argument wins for *today's* implementation.
- **Abstract the storage write** behind one interface so the file can be swapped for / mirrored to native orchestrator-level memory *if and when* Anthropic ships it at the right granularity — the Business risk argument wins for *future-proofing*.
- This is a **decision the user should ratify**, because it trades a small abstraction cost now against the platform-absorption bet.

---

## Decision Record (ADR)

# Position h-superpowers as "the harness that validates" — adopt a right-sized-ceremony router and a small set of validation-spine melds, staying pure markdown-native + git

## Status
Proposed

## Context
h-superpowers is a fork of obra/superpowers whose owner wants it to transcend its upstream connection and become a broad-spectrum sampler and melder of dev-process-harness concepts. A four-perspective research effort (Business/Strategy, Integrator, User/Consumer, Synthesist/Melder), run over two cross-pollinating rounds, surveyed the popular harness landscape (spec-kit, GSD, gstack, BMAD, Agent OS, OpenSpec, shinpr/claude-code-workflows, cc-sdd, ECC, claude-flow, claude-mem, claude-reflect, Ralph, and Anthropic's native memory/Dreaming).

Key verified constraints: h-superpowers carries **zero persistent state outside git and the live session** (no daemon, no DB); its only hook is a `SessionStart` context-injection hook; it deliberately keeps roles lightweight and avoids external installers. Several sibling plugins (ralph-loop, hookify, claude-md-management, crucible) are already installed.

Four themes converged across all lenses: (1) right-sized ceremony is the #1, negative-cost opportunity; (2) a durable project-knowledge layer is table-stakes; (3) stay daemon-free and git-native; (4) **validation + multi-perspective reasoning are the true, copy-resistant moat** while learning/standards/spec layers are commodity (Anthropic is absorbing memory).

## Decision
Position h-superpowers as **"the harness that validates"** and adopt, in priority order:
1. **`altitude-router`** — right-sized ceremony triage that dials *ceremony* by task altitude while keeping the *discipline* spine non-negotiable; make the brainstorming HARD-GATE altitude-aware. (Ship first; negative-cost.)
2. **`harvesting-lessons`** — a capture→cluster→validate(RED-step)→promote learning funnel; storage-agnostic, defaulting to git-tracked Markdown via a SessionEnd/SessionStart hook, behind a swappable storage interface.
3. **`house-style` + a lightweight constitution** — project standards loaded through the existing pull-gate, folded into CLAUDE.md/MEMORY.md (no new principles file).
4. **`living-spec`** — a diffable living spec with a code-vs-spec completion drift-gate (shinpr `code-verifier` engine).
5. **`tripwires`** — warn-and-confirm push-enforcement of TDD/verification, costed honestly as new hook infrastructure on a shared session-scratch-state primitive.
6. **AgentShield-style config-security scan** — a low-risk, no-state differentiated niche.
7. **Compose** with `ralph-loop` for autonomy and add browser-based verification; **do not** rebuild them.

Keep h-superpowers pure markdown-native (Skills + agents + commands) plus exactly two minimal new infra pieces (a decisioning-hook capability and a session-scoped scratch-state file); consume — never re-host — anything needing a daemon/DB via MCP or sibling plugins.

## Alternatives Considered
- **Be a bigger Superpowers / out-ceremony Spec Kit** — rejected; me-too into a better-funded incumbent, and it amplifies the #1 complaint.
- **Build a proprietary memory runtime / vector DB (claude-flow model)** — rejected; platform-absorption risk + fights the no-runtime architecture.
- **Adopt BMAD-style role personas** — rejected by all four lenses; most-marketed, most-complained-about, imports ceremony senior devs reject.
- **Build an autonomous Ralph-style loop from scratch** — rejected; commoditized, consumer-burn risk, duplicates the installed ralph-loop plugin.
- **Add a third/fourth durable principles file (spec-kit constitution as a standalone artifact)** — rejected; three sources of truth worsen onboarding; fold into existing surfaces.
- **Adopt external installers (uv/pipx/npx) or `.specify/`-style parallel filesystem-of-record** — rejected; installer collision and git-desync.
- **Lead the brand with a standards/memory layer** — rejected as positioning; those are defensive table-stakes, not differentiation.

## Consequences

### Positive
- A coherent, defensible identity ("the harness that validates") that no incumbent owns and that *rejects* sprawl by construction.
- The #1 abandonment complaint (ceremony tax) is addressed at negative cost.
- A learning funnel (capture→cluster→validate→promote) that is genuinely unique (no existing harness combines all four gates).
- Everything stays git-native and daemon-free, preserving the "install a plugin, no external services" value prop.
- Reuses existing surfaces and sibling plugins, keeping onboarding surface flat; token wins are measurable via the in-repo crucible plugin.

### Negative
- Deliberate divergence from upstream's "ceremony on every project" rigidity (sanctioned by the mandate, but must be flagged per CLAUDE.md).
- Two new infra pieces (decisioning hooks + session scratch-state) add a real, cross-platform (bash/PowerShell) maintenance surface.
- Standards/spec layers must be built to stay current yet will not differentiate — sustaining cost without brand payoff.

### Risks
- **Junk-drawer dilution** — the central risk of the breadth mandate; mitigated by requiring every meld to ladder to the spine sentence.
- **Platform eats memory** — mitigated by decoupling the validation funnel from storage and abstracting the write path.
- **Hook false positives** training users to disable hooks — mitigated by warn-and-confirm only.
- **Open Question 1 (audience)** unresolved — re-weights memory vs. standards vs. niche; must be answered before sequencing Recs 2/3/6.
- **Open Question 2 (native memory vs. git file)** unresolved bet-vs-fit — mitigated by the storage-agnostic-funnel + swappable-interface compromise, pending user ratification.
- **Upstream alignment** unverified for the net-new primitives — must be checked and flagged before landing per CLAUDE.md.
