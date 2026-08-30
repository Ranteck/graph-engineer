# Project Context

This file is written and maintained exclusively by Claude during
graph-engineer cycles in this repo. Each feature's contract lives under its
own `## <feature-name>` heading — read and write only the section matching
the feature currently in progress.

## backend-selection

### Quality gate

- **Resolution**: `mode: skipped`
- **Reasoning**: This repo has no build, lint, test, or CI tooling of any
  kind (no `package.json`, `Makefile`, CI config, or dev docs describing a
  command). The repo's own `CLAUDE.md` states explicitly: "There is nothing
  to build, lint, or test." "Development" here means editing Markdown and
  keeping cross-file claims consistent — there is no mechanical check to
  autoselect or ask the user for. Per `quality-gate-detection.md`'s
  resolution order, this is a legitimate `skipped` resolution, not a
  no-usable-candidate stop condition — the project genuinely has no gate.
- **Resolved by**: PRE-FLIGHT, this cycle.

### Critique assurance

**Current cycle (per-role-alias extension, this round).**

- **mode**: `standard`
- **resolution**: `default-standard`
- **reasoning**: Not explicitly requested by the user this round. Both
  matched triggers from the original authorship cycle below still hold
  (quality gate skipped; edits land in the skill's own public contract
  files), but the user gave an explicit, standing instruction this round to
  conserve Codex call budget after a recent near-lockout, and the scope is a
  narrower, compositional addition to an already elevated-reviewed contract
  (a fourth backend value assembled from two already-specified, already
  cross-model-reviewed mechanics — `claude:<account-alias>`'s writer dispatch
  and `backend: claude`'s `Explore` reviewer — not new mechanics authored
  from scratch). Standard is the documented default whenever the user hasn't
  explicitly requested elevated mode or confirmed a matched trigger with
  evidence; this round, the user's own quota-conservation instruction is that
  evidence-weighed choice.
- **Resolved by**: PRE-FLIGHT, this cycle, without an AskUserQuestion round
  trip (see reasoning above) — the user's standing quota-conservation
  directive is treated as the explicit steer standard mode's default rule
  requires.
- **CRITIQUE pass cap**: 3 (lower than the original cycle's 5, matching the
  narrower scope; escalate to the user before exceeding it rather than
  silently raising it).
- **Codex review/debate call budget**: 6 (IMPL + up to 2 CRITIQUE/REFACTOR
  round-trips at standard-mode's one-fix-round floor of ~4, plus headroom for
  one DEBATE reinjection). Escalate to the user before exceeding it.

**Original resolution (feature-authorship cycle, for provenance only — not
in effect this round).**

- **mode**: `elevated`
- **resolution**: `user-confirmed-trigger`
- **trigger matches**: (1) QUALITY GATE resolved to `mode: skipped` — the
  feature has no executable functional verification able to exercise its
  behavior, a listed recommendation trigger in `elevated-assurance.md`. (2)
  The modified artifact is `SKILL.md`/`README.md`/a new reference file
  themselves — the skill's own public, widely-read contract, a broad blast
  radius analogous to "changes a public API/contract shared by more than one
  component."
- **trigger evidence**: `PROJECT_CONTEXT.md` `### Quality gate` above;
  `skills/graph-engineer/SKILL.md`, `README.md`, and (once written)
  `skills/graph-engineer/references/backend-selection.md`.
- **User decision**: User confirmed "Elevated" via AskUserQuestion at
  PRE-FLIGHT (scope-level, pre-SPEC). Re-evaluated at end of SPEC once the
  contract existed — both triggers still held, no new information changed
  the call. This is the final resolution; both evaluation passes agreed.
- **lens count**: 3
- **lens set**: correctness-contracts; integration-state-reproducibility;
  security-abuse-data-loss
- **exit challenger**: required-before-verify-or-done-rerun-until-clean
- **CRITIQUE pass cap**: 5 (template default)
- **Codex review/debate call budget**: 16 (raised from the 13 template
  default by explicit user approval after an unrelated Codex usage-limit
  interruption mid-cycle, and after CRITIQUE round 3 found the 13 default
  insufficient to reach VERIFY with the exit challenger included)

### Backend

- **backend**: `codex` (not specified by user for this cycle)
- **resolution**: `default-codex`
- **resolved session**: not-applicable
- **disclosure**: not-applicable (default backend, no same-model caveat
  applies to this cycle's own IMPL/CRITIQUE/REFACTOR)
- **Resolved by**: PRE-FLIGHT, this cycle. Retroactively persisted after
  CRITIQUE identified (finding FB-10) that this section should have existed
  before IMPL per this feature's own new contract — the contract didn't
  exist yet at this cycle's PRE-FLIGHT time (it's the artifact SPEC was
  about to write), so this is the earliest point it could honestly be
  added. Future cycles — including this feature's own REFACTOR rounds —
  must persist it before IMPL, per the now-published contract.
- **Still in effect for the per-role-alias extension round**: this round's
  own IMPL/CRITIQUE/REFACTOR (i.e. Codex writing and reviewing the new
  `claude-writer:<account-alias>` documentation) also use `backend: codex`,
  unchanged. This round does not exercise any of the backends it documents
  on itself.

### Checkpoint commits

- **Authorized**: yes (default).
- **Reasoning**: `commit.gpgsign` is unset, branch is `develop` (not
  detached HEAD, not `main`), and `.git/hooks/` contains only sample hooks
  (no active hook that would mutate the tree or block on a passphrase). No
  condition from `SKILL.md` node 0's checkpoint policy applies that would
  make a non-interactive local commit unsafe.

### Feature contract

**What it does.** Adds a per-cycle, opt-in **backend selection** for the
writer/reviewer role that today is always Codex (node 2 IMPL, node 6
REFACTOR, and node 4 CRITIQUE). Codex remains the unconditional default —
nothing changes for a cycle that doesn't mention a backend. This lets a user
route IMPL/REFACTOR/CRITIQUE to Claude instead when they specifically want to
preserve a scarce Codex quota, while making explicit, every time, that doing
so gives up the cross-model diversity that is Codex's documented reason for
existing in this cycle (the "Less correlated self-review failure" passage under README.md's `## Why`
section (`README.md#why`) — cite the anchor, not a line range, since exact
line numbers drift as README is edited, SKILL.md:26-32).

**Invocation syntax.** A `backend:` directive in the user's `/goal` text or
initial prompt, read by Claude at PRE-FLIGHT like the existing `read-only`,
elevated-assurance-request, and checkpoint-commit-preference directives —
this skill has no CLI-style flag parser; every per-cycle option is a
natural-language directive PRE-FLIGHT interprets, and `backend:` follows that
same precedent instead of inventing a new mechanism.

- `backend: codex` or omitted — unchanged default behavior.
- `backend: claude` — same-session Claude subagents fill IMPL/REFACTOR
  (writer) and CRITIQUE (reviewer).
- `backend: claude:<account-alias>` — a separate Claude Code session
  (addressed by name via `ListAgents`/`SendMessage`, e.g. an account like
  `claude-personal`) fills both roles.
- `backend: claude-writer:<account-alias>` — **(new this round)** a fixed,
  opinionated split: the named cross-session alias fills only the writer
  role (IMPL/REFACTOR), while the reviewer role (CRITIQUE) always stays
  local — a fresh same-session `Explore` subagent, exactly as
  `backend: claude`'s reviewer works. This exists specifically to let a
  second already-running Claude account absorb the writer workload (and its
  own token pool) while avoiding `claude:<account-alias>`'s self-review
  problem, without requiring elevated assurance's 3-lens overhead just to
  get a non-self reviewer.

**Naming decision for the new value.** Considered and rejected a generic
`writer=<a> reviewer=<b>` keyword-pair grammar. A stricter version of that
grammar could technically be restricted to only the accepted target kinds
per role, so the rejection isn't that free role assignment is a logical
necessity of keyword syntax — it's a surface/UX argument: the shape itself
reads as an open, general-purpose role-assignment mechanism (implying
support for combinations like `reviewer=<account-alias>`, which this feature
does not and will not support, since it would just reintroduce a
cross-session self-review risk), and it breaks the single-token-directive
precedent every other `backend:` value follows, which a user has to learn
only once. Considered and rejected a `claude:<account-alias>+claude` suffix form: the
`+claude` suffix doesn't self-evidently say *which* role goes where, and
reads ambiguously next to `claude:<account-alias>`'s existing both-roles
meaning. `claude-writer:<account-alias>` was chosen because the name states
the one fact that varies (which role the alias fills) using the same
`<prefix>:<account-alias>` shape already established by
`claude:<account-alias>`, and requires no new grammar — PRE-FLIGHT still
reads one natural-language token, not a structured argument list.

**Rejected alternative: `graph-engineer:claude-personal`.** The colon-scoped
form collides with Claude Code's existing plugin-skill naming convention
(`plugin:skill`, e.g. `openai-codex:codex-rescue`) — a skill name followed by
a colon already means "this skill, scoped to this plugin" elsewhere in the
system, so reusing it for a runtime backend parameter would be ambiguous
with that convention and inconsistent with how every other per-cycle option
in this skill is already expressed (free-text directive in the goal prompt,
not a structured argument after the skill name).

**PRE-FLIGHT resolution (new sub-decision, node 0).** Once per cycle entry,
alongside quality gate and checkpoint-commit policy: parse the `backend:`
directive if present (default `codex` if absent, and rejected with a clear
message — not guessed — if it's present but empty or not one of the four
accepted values). If `backend:` appears more than once with conflicting
values across the initial prompt and `/goal`, stop and ask — never guess by
source order. The resolved backend applies to the whole cycle and does not
change between nodes. Persistence and disclosure timing differ by mode:

- **Full 8-node write cycle**: persist the resolution under `### Backend` in
  this file before IMPL; give and persist the mandatory disclosure(s) before
  SPEC.
- **Refactor-only** (no SPEC, no IMPL): persist under `### Backend` before
  the initial CRITIQUE; give and persist disclosure(s) before that same
  first CRITIQUE.
- **Review-only** (never writes this file): record the resolution and any
  disclosure in the user's prompt, the Claude turn, and the final report
  instead — never write `PROJECT_CONTEXT.md`.

**Every non-`codex` selection — `claude`, `claude:<alias>`, and
`claude-writer:<alias>` — requires explicit user confirmation before the
first dispatch**, because each hands a writer full ambient tool authority
with no Codex-equivalent sandbox; disclosure alone is not authorization, and
confirmation is not limited to the alias case. For `backend: claude:<alias>`, additionally
resolve `<alias>` to a reachable session via `ListAgents` *at PRE-FLIGHT*,
before SPEC (or before the first CRITIQUE in refactor-only), and display the
exact identity `ListAgents` reports for the user to confirm — reachability
alone is best-effort account addressing, not authorization, and not
repository root/worktree/branch/HEAD verification; a session can confirm
completion of a dispatch while having operated on a different checkout
entirely, and nothing in this design can detect that. If no matching session
is found, the match is ambiguous, or confirmation isn't given, abort with a
clear message (same escalate-don't-guess posture as an unreachable Codex
plugin) rather than silently falling back to `claude` or `codex`. **Elevated
assurance is incompatible with `claude:<alias>`** (one retained conversation
cannot supply 3 independent fresh lenses) — reject that combination at
PRE-FLIGHT and ask the user to choose `codex`, `claude`, or standard mode
instead.

**`claude-writer:<alias>` PRE-FLIGHT resolution (new this round).** Resolve
and confirm the alias with the identical `ListAgents` procedure as
`claude:<alias>` above — same reachability check, same exact-identity
display, same abort-don't-guess posture, same requirement for explicit user
confirmation before the first dispatch. The only difference from
`claude:<alias>` is scope: the confirmed session is authorized as the writer
target only. **Unlike `claude:<alias>`, elevated assurance is compatible
with `claude-writer:<alias>`**: because CRITIQUE never leaves the local
session in this mode, it can run the same 3-independent-fresh-`Explore`-lens
sweep `backend: claude` uses, with the identical fan-in/canonicalization-by-
Claude mechanics (see `backend: claude`'s elevated-assurance paragraph) —
only the writer dispatch mechanics differ. State this compatibility
explicitly wherever `claude:<alias>`'s incompatibility is stated, so the two
modes aren't conflated.

**Mandatory disclosure when `backend != codex`.** PRE-FLIGHT must state to
the user, once, in plain terms, before SPEC, and persist under `### Backend`
in this file — not just spoken once and discarded:
1. Same-model diversity loss: this cycle uses the same underlying model for
   both writer and reviewer roles, so the "different model in the decision
   path" mitigation this skill is built around (the "Less correlated self-review failure" passage under README.md's `## Why`
section (`README.md#why`) — cite the anchor, not a line range, since exact
line numbers drift as README is edited) does not
   apply this run; DEBATE arbitration and the anti-loop cutoff still apply,
   but they no longer compensate for a same-model blind spot the way they do
   against Codex.
2. Ambient authority: the selected Claude writer runs with the orchestrating
   session's full ambient shell, network, git, and credential authority, with
   no Codex-equivalent workspace-write sandbox or capability restriction —
   this skill cannot currently provide an equivalent sandbox for Claude
   writers.
3. For `claude:<alias>` specifically: the feature contract, findings, and
   triage history are sent to a different account/session and are subject to
   that session's own tools, hooks, and retention — avoid this backend for
   contracts containing secrets or sensitive data; this skill does not
   redact or scan payloads before sending them.
4. For `claude-writer:<alias>` specifically (new this round; applies only to
   the full 8-node write cycle and refactor-only, which have a writer role —
   see the review-only note below): the feature contract and, for REFACTOR,
   the triaged fix list and continuity summary are sent to a different
   account/session subject to that session's own tools, hooks, and
   retention — the same confidentiality caveat as point 3, scoped to the
   writer dispatch only, since CRITIQUE stays local in this mode.
   **`claude-writer:<alias>` has no writer role to dispatch to in
   review-only** (review-only never runs IMPL/REFACTOR), making it
   functionally indistinguishable from `backend: claude` there. Reject the
   combination at PRE-FLIGHT with a clear message asking the user to choose
   `codex`, `claude`, or `claude:<alias>` instead, rather than silently
   degrading it or emitting a disclosure describing a dispatch that will
   never happen. State the isolation trade-off accurately and specifically, not by
   reusing `claude:<alias>`'s wording verbatim: this mode is a **real
   improvement** over `claude:<alias>` — the reviewer does not literally
   remember authoring the code, because a fresh local `Explore` subagent
   performs CRITIQUE, never the cross-session writer — but it is still no
   improvement on point 1 above: writer and reviewer remain the same
   underlying Claude model, and the reviewer is still only a **tool-list
   restriction** (`Explore` lacks `Edit`/`Write`/`NotebookEdit` but retains
   Bash/shell access), not a structural sandbox, exactly as in
   `backend: claude`. Do not let "different account for the writer" be
   read as "independent review" — the review's independence comes only from
   using a fresh local subagent instead of the same retained session, not
   from anything about the cross-session split.
Future CRITIQUE/DEBATE steps must not narrate a non-Codex review as
"independent review."

**Per-backend node behavior:**

- **`codex` (default).** No behavior change. Nodes 2/4/6 exactly as
  documented in `SKILL.md` today.

- **`claude` (same-session subagents).**
  - IMPL/REFACTOR (writer): `Agent(subagent_type: "general-purpose", ...)`,
    instructed to implement the contract in `PROJECT_CONTEXT.md` directly
    with Edit/Write — this agent, not the orchestrating Claude, performs the
    edit, so the core invariant ("the orchestrating Claude never edits
    implementation files") holds; it is a distinct actor the orchestrator
    dispatches to, structurally the same relationship the orchestrator has
    to Codex today, but with none of Codex's sandbox isolation (see
    disclosure point 2 above).
  - CRITIQUE (reviewer): `Agent(subagent_type: "Explore", ...)`. `Explore`'s
    tool list excludes the direct editor tools `Edit`/`Write`/`NotebookEdit`
    (and `Agent`/`Artifact`/`ExitPlanMode`) — that is a **tool-list
    restriction, not a sandbox guarantee**: `Explore` retains Bash/shell
    access and is not structurally prevented from mutating files. Mitigate
    with mandatory mutation detection: capture the full artifact-identity
    digest exactly as `elevated-assurance.md` defines it — SHA-256 over
    `git rev-parse HEAD` + `git status --porcelain=v1 -uall` +
    `git diff HEAD --binary` + the NUL-delimited content-hash manifest of
    initially-untracked paths (that manifest is required, not optional: a
    mutation to an already-untracked file changes neither the porcelain
    status line nor `git diff HEAD`, so omitting it would miss exactly that
    mutation class) — immediately before every `Explore` reviewer call and
    recompute/compare it after; any mismatch is a stop-and-escalate
    condition, standard or elevated mode alike.
  - Continuity across CRITIQUE calls: plain `Agent()` subagents do not carry
    memory between calls the way `--resume-last` does for Codex. Every
    CRITIQUE call in `backend: claude` mode must therefore include an
    explicit continuity summary (prior findings, triage verdicts, still-
    applicable constraints) built by the orchestrator from
    `PROJECT_CONTEXT.md` and its own conversation memory — this is the
    backend's entire continuity state; there is no separate canonical-thread
    concept the way Codex's `--resume-last` has one.
  - **Elevated assurance for this backend**: dispatch 3 independent fresh
    `Explore` agents in parallel for the 3 lenses (mirroring Codex's 3-lens
    sweep) instead of one reviewer. After all 3 complete with matching
    artifact identity, Claude performs fan-in and canonicalization itself —
    normalizing the raw reports and updating the manually-maintained
    continuity summary above. There is no Codex-style canonicalization call
    or canonical thread for this backend; every later ordinary CRITIQUE or
    reinjection is another fresh `Explore` call carrying the up-to-date
    summary. The exit challenger remains the deliberately cold exception
    (fresh, no prior ledger) exactly as `elevated-assurance.md` defines.

- **`claude:<account-alias>` (cross-session).**
  - The orchestrator uses `SendMessage` to the resolved, user-confirmed
    session for both IMPL/REFACTOR and CRITIQUE, and advances only when a
    reply clearly answers that specific dispatch (named by feature, node,
    and expected response) — an unrelated or ambiguous reply is not
    completion. This skill has no request-correlation ID, automated
    timeout, disconnect recovery, or retry mechanism: this is a best-effort
    causal convention, not a guarantee. If the target stops responding, stop
    and ask the user to help unblock it rather than redispatching or
    guessing completion. This makes node sequencing asynchronous for this
    backend only — a structural difference, not a defect.
  - A confirmed session identity plus a matching local artifact digest still
    does not prove the target operated on the orchestrator's actual
    repository, worktree, branch, or HEAD — this design has no mechanism to
    verify that and does not claim to; the digest only proves the
    orchestrator's own local tree didn't drift.
  - **Both roles target the same session by default**, because this skill
    has no mechanism to launch a new OS-level Claude Code process under a
    given account — it can only address sessions that already exist,
    exactly as it doesn't diagnose Codex plugin installation. This means
    the reviewer literally remembers writing the code it is reviewing: it is
    the **weakest** writer/reviewer isolation of the four backends, weaker
    than `backend: claude`'s fresh-`Explore`-subagent reviewer, despite
    sounding the most separated because it's a different account/process. A
    user who wants the cross-session alias to act as writer only, with a
    genuinely separate local reviewer, should use `claude-writer:<alias>`
    below instead — general free per-role aliasing (e.g. a second,
    independently-named cross-session alias filling the reviewer role too)
    remains out of scope, for the same reason `claude:<alias>` itself is
    limited to already-running sessions: this skill cannot launch a new
    session to guarantee one exists. State the weakest-isolation point
    explicitly wherever this backend is documented — do not let "different
    account" read as "different reviewer."
  - CRITIQUE's read-only-ness here is **prompt-only** — `SendMessage` cannot
    impose a sandbox or remove tools from the remote session, and this is
    not repaired by `backend: claude`'s tool-list exclusion either. Apply
    the same mandatory artifact-identity digest (before/after) described
    above for `backend: claude`; a mismatch is a stop-and-escalate
    condition.
  - **This backend cannot run elevated assurance**: one retained target
    session cannot furnish 3 independent fresh lenses. PRE-FLIGHT rejects
    the combination (see PRE-FLIGHT resolution above) rather than
    approximating the sweep.

- **`claude-writer:<account-alias>` (cross-session writer, local reviewer —
  new this round).**
  - IMPL/REFACTOR (writer): same `SendMessage` mechanics as
    `claude:<account-alias>`'s writer dispatch — await a reply that clearly
    answers that specific dispatch, same best-effort causal convention, same
    lack of request-correlation ID/timeout/retry, same inability to verify
    the target's actual repository/worktree/branch/HEAD beyond the confirmed
    session identity — with one required difference: `claude:<account-alias>`
    can rely on the target session's own retained conversation for
    continuity, but the `claude-writer:<alias>` writer never saw CRITIQUE or
    node 5 reinjections. Every REFACTOR dispatch to it must therefore
    explicitly include the same manually-maintained continuity summary kept
    for the local reviewer (prior findings, triage verdicts, still-applicable
    constraints) alongside the triaged fix list — omitting it is a contract
    violation of this mode, not a stylistic nicety.
  - CRITIQUE (reviewer): identical mechanics to `backend: claude`'s reviewer
    above — a fresh local `Agent(subagent_type: "Explore", ...)` per call,
    never the cross-session alias, with the same mandatory before/after
    artifact-identity digest, the same tool-list-restriction-not-a-sandbox
    caveat, and the same manually-maintained continuity summary (this
    backend has no `--resume-last`-equivalent memory for CRITIQUE, exactly
    as `backend: claude` has none — the writer role's cross-session target
    does retain its own conversation, but that is irrelevant to CRITIQUE
    continuity since CRITIQUE never reaches that session in this mode).
  - **Elevated assurance for this backend (new capability)**: unlike
    `claude:<alias>`, this mode supports elevated assurance, using
    `backend: claude`'s exact 3-fresh-`Explore`-lens sweep and Claude-
    performed fan-in/canonicalization — CRITIQUE's locality is what makes
    this possible; the writer's cross-session dispatch is irrelevant to
    whether 3 independent local lenses can run. The exit challenger is also
    a fresh local `Explore` call, per `backend: claude`'s definition.
  - **Isolation summary — where this mode sits relative to the other two.**
    Strictly better writer/reviewer isolation than `claude:<alias>` (no
    self-review: the reviewer is a fresh local subagent, not the writer's
    own retained session) but not better than `backend: claude`'s isolation
    on the reviewer side, since both use the identical fresh-`Explore`
    reviewer — the only axis this mode changes relative to `backend: claude`
    is *where the writer's token cost lands* (a second account's pool
    instead of the orchestrating session's), not review independence. Do not
    describe this mode as combining "the best of both" other backends; it
    combines `claude:<alias>`'s writer dispatch with `backend: claude`'s
    reviewer, no more and no less, and both are still the same underlying
    Claude model.

**Consistency requirement.** `SKILL.md`'s node 2 (IMPL), node 4 (CRITIQUE),
and node 6 (REFACTOR) each need a backend-dispatch note pointing to a new
reference file (`references/backend-selection.md`) rather than inlining all
four backends' prompts into the already-long node bodies — follow the same
"link out to a reference, keep the node body describing the invariant" style
already used for `elevated-assurance.md`. `README.md` gets a short mention
(what the option is, link to the reference) — it must not duplicate the
reference's content, per this repo's own `CLAUDE.md` guidance that
`README.md` and `SKILL.md` share claims, not layout, and per the existing
precedent of not duplicating the elevated-write-goal template into
`README.md`. `CLAUDE.md` and `AGENTS.md` (both consuming-repo-agnostic
governing files, listing the skill's own file map and core invariant) must
not state Codex-only continuity/sandbox/canonical-thread rules as universal
— they need to be scoped to "on the default `codex` path" wherever
`backend-selection.md` documents a different rule for the other backends,
not just have their opening invariant sentence qualified.

**Explicitly out of scope for this feature** (do not attempt in this
cycle): spawning new Claude Code sessions/processes for `claude:<alias>` or
`claude-writer:<alias>`; **general free per-role account aliasing** — e.g. a
second, independently-named cross-session alias filling the reviewer role,
or any user-chosen writer/reviewer pairing beyond the two fixed shapes this
feature defines (`claude:<alias>` = both roles to one alias;
`claude-writer:<alias>` = writer to the alias, reviewer always local) — is
still out of scope, for the same reason: this skill can only address
already-running sessions, not launch new ones, so it cannot guarantee an
arbitrary second reviewer session exists; parallel same-model reviewers for
sample diversity beyond the 3-lens `backend: claude`-mechanics elevated-
assurance variant (now shared by both `backend: claude` and
`claude-writer:<alias>`); any change to Codex's own behavior or to the
default (`codex`) path; any mechanism to verify a cross-session target's
actual workspace/repository identity beyond the confirmed session identity
and local artifact digest (a known, disclosed limitation — see
`claude:<account-alias>` and `claude-writer:<account-alias>` above — not
something this cycle attempts to solve).

## project-context-scoped-disclosure

### Quality gate

- **Resolution**: `mode: skipped`
- **Reasoning**: Same as `backend-selection` above — this repo has no build,
  lint, test, or CI tooling (no `package.json`, `Makefile`, CI config, or dev
  docs describing a command). `CLAUDE.md` states explicitly: "There is
  nothing to build, lint, or test." Per `quality-gate-detection.md`'s
  resolution order, this is a legitimate `skipped` resolution, not a
  no-usable-candidate stop condition.
- **Resolved by**: PRE-FLIGHT, this cycle.

### Critique assurance

- **mode**: `elevated`
- **resolution**: `user-confirmed-trigger`
- **trigger matches**: (1) QUALITY GATE resolved to `mode: skipped` — the
  feature has no executable functional verification able to exercise its
  behavior, a listed recommendation trigger in `elevated-assurance.md`. (2)
  The contract changes a protocol/schema shared by every repo that consumes
  this skill (the internal structure of each consuming repo's own
  `PROJECT_CONTEXT.md`) and touches this skill's own core safety invariants —
  CRITIQUE/exit-challenger cold-review independence (node 4,
  `elevated-assurance.md`) and the "`PROJECT_CONTEXT.md` is Claude's only
  writable artifact" boundary (`CLAUDE.md`'s Core design invariant, `SKILL.md`
  intro) — a broad blast radius analogous to "changes a public API/contract
  shared by more than one component."
- **trigger evidence**: `PROJECT_CONTEXT.md` `### Quality gate` above;
  `SKILL.md`'s node 4 CRITIQUE dispatch templates and node 0's writable-
  artifact invariant; this repo's own `CLAUDE.md` "Core design invariant"
  section; measured evidence from prior design discussion: real consuming
  repos' `PROJECT_CONTEXT.md` reached 3,168 lines (`trading-engine_v3`, one
  active feature section alone 1,753 lines / 112,060 characters) and 2,624
  lines (`trading-engine_v2`), and `SKILL.md`'s own section-scoping
  instruction (`SKILL.md:392-398`) was verified absent from the actual
  dispatch prompt templates (`SKILL.md:401-404`, `513-530`) — a design gap in
  the skill's own contract, not a hypothetical risk.
- **User decision**: User confirmed "Elevated" via `AskUserQuestion` at
  PRE-FLIGHT (scope-level, pre-SPEC), given this exact reasoning.
- **lens count**: 3
- **lens set**: correctness-contracts; integration-state-reproducibility;
  security-abuse-data-loss
- **exit challenger**: required-before-verify-or-done-rerun-until-clean
- **CRITIQUE pass cap**: 5 (template default)
- **Codex review/debate call budget**: 13 (template default)
- **Resolved by**: PRE-FLIGHT (initial), to be re-evaluated at end of SPEC
  per `elevated-assurance.md`'s decision timing.

### Backend

- **backend**: `codex` (not specified by user for this cycle)
- **resolution**: `default-codex`
- **resolved session**: not-applicable
- **disclosure**: not-applicable (default backend)
- **Resolved by**: PRE-FLIGHT, this cycle.

### Checkpoint commits

- **Authorized**: yes (default).
- **Reasoning**: `commit.gpgsign` is unset, branch is `develop` (not detached
  HEAD, not `main`), and `.git/hooks/` contains no active hook that would
  mutate the tree or block on a passphrase (only the repo's own
  `PreToolUse`/`PostToolUse` Claude Code hooks, which are non-blocking or
  narrowly scoped — see `.claude/settings.json` and
  `.claude/hooks/*.sh`). No condition from `SKILL.md` node 0's checkpoint
  policy applies that would make a non-interactive local commit unsafe.

### Feature contract

#### Current state

**Problem.** `PROJECT_CONTEXT.md` grows without a lifecycle boundary when an
active feature mixes its present contract with every earlier revision and when
completed feature sections remain in the live file. A single active section
can itself become large (measured at 1,753 lines / 112,060 characters in a
consuming repository). Dispatched nodes also require different context:
continuity-aware triage needs history, while fresh lenses and the exit
challenger need a cold view of the current artifact. The disclosure policy is
instruction-based rather than a sandboxed read boundary.

**What it does.** Four coordinated changes to how every
write-authorized mode (full 8-node cycle, refactor-only) reads and writes a
feature's section in `PROJECT_CONTEXT.md`:

1. **Split every feature section into two named subheadings, enforced from
   SPEC onward:**
   - `#### Current state` — bounded and rewritten in place: the current
     contract or refactor-only scope/criteria. It contains no latest-round
     marker, rejected alternative, past actor refusal, prior-review conclusion,
     or other historical narrative. The existing `### Quality gate`, `###
     Critique assurance`, `### Backend`, and `### Checkpoint commits`
     resolutions remain in their current form and position as bounded current
     resolutions. Claude reads the last `#### Round log` entry when DEBATE or
     the anti-loop cutoff needs the latest completed iteration.
   - `#### Round log` — append-only and chronological, with one composite
     record per checkpointed writer iteration (`IMPL-r00` or
     `REFACTOR-rNN`), plus a `CRITIQUE-rNN-noop` record for a CRITIQUE-only
     terminal pass. Each record combines the CRITIQUE outcome, DEBATE
     classifications, resulting writer work (or `none`), actors/backend, a
     checkpoint locator, and optional decision notes. SPEC and individual
     CRITIQUE/DEBATE nodes do not get standalone entries.
     A checkpointed composite is written in the same commit as its writer
     changes. `Checkpoint: locate-by-feature-and-round` resolves uniquely from
     the current branch's first-parent ancestry using the literal subject token
     `graph-engineer(<feature-name>):` plus exact full-message lines
     `Round: <round>` and `Cycle-State: CHECKPOINT`; zero or multiple matches
     stop and escalate.
     It does not rely on Git's formal trailer parser. `Checkpoint: none` means
     no checkpoint exists. No stored hash, placeholder, or later backfill is
     used. Design rationale and review history stay in `Decision notes`, and
     secrets are referenced only by nature/location. A missing or duplicate
     composite is a protocol inconsistency, not a best-effort repair cue.

2. **Node-specific instruction-based disclosure.** Codex's sandbox blocks
   CRITIQUE writes, not reads, and Claude `Explore` retains shell access and
   can read or indirectly mutate other content. IMPL, CRITIQUE, and REFACTOR
   prompts therefore inline the permitted `#### Current state` raw bytes in an
   unambiguous fenced block and instruct the actor not to open the context file
   or read `#### Round log`:
   - Before any sentinel validation, extraction, or dispatch, the whole file
     must contain exactly one exact `## <feature-name>` heading. Zero or
     multiple matches stop and escalate.
   - The active feature must contain exactly one canonical `#### Current state`
     sentinel line and exactly one later canonical `#### Round log` sentinel
     line. The orchestrator extracts strictly between those exact lines.
   - Any intervening line matching `^[ ]{0,3}#{2,4}([ \t]|$)` is invalid and
     stops/escalates. Backtick and tilde runs are uninterpreted bytes; there is
     no fence parser or balance state.
   - The same count/order/body validation runs immediately after every write
     to Current state and immediately before every inlining dispatch. The
     extracted bytes are preserved exactly and dynamically outer-fenced;
     `context-lifecycle.md` is authoritative for serialization.
   - **SPEC**: reads and writes the full section, validates Current state after
     writing, and is summarized later in the `IMPL-r00` composite.
   - **IMPL**: receives the fenced `#### Current state` bytes inline.
   - **Ordinary resumed CRITIQUE** (`--resume-last`, standard mode or an
     elevated-mode resumed canonical round): receives fenced `#### Current
     state` bytes inline;
     relies on Codex's own session memory (`--resume-last`) for round
     continuity, not a re-read of `#### Round log`.
   - **Elevated fresh lenses**: receive fenced `#### Current state` bytes and
     no `#### Round log`, reducing shared-history anchoring.
   - **Exit challenger**: receives fenced `#### Current state` bytes (contract,
     current artifact, criteria) and no `#### Round log` or finding ledger.
   - **REFACTOR**: receives the triaged fix list plus fenced `#### Current
     state` bytes — never `#### Round log`.
   - **DEBATE/Claude's own triage** (not dispatched to a backend actor): may
     read `#### Round log` in full when needed — the anti-loop cutoff
     (`SKILL.md`) explicitly requires comparing consecutive CRITIQUE passes,
     which needs this history; Claude is not subject to the "stay cold"
     disclosure rule the dispatched reviewers are.
   - **A human or a future cycle** investigating a past decision reads
     `#### Round log` directly by round id.

3. **Archival at the terminal transition, as the sole second narrowly scoped
   writable path.**
   - New path: `PROJECT_CONTEXT.archive/<feature-slug>.md`, one file per
     archived feature, in the same consuming repo as `PROJECT_CONTEXT.md`
     (sibling directory, not inside `.git`).
   - **Trigger**: only at VERIFY's pass in the full 8-node write cycle, or at
     the final DONE-clearing CRITIQUE/exit-challenger pass in refactor-only —
     i.e. only once the cycle has already reached its existing terminal
     success condition. This is not a new node; it is folded into the
     existing terminal-commit step under node 3's checkpoint mechanics, using
     `Cycle-State: COMPLETE` instead of `CHECKPOINT`. Before either terminal
     edge declares DONE, `SKILL.md` explicitly invokes this transition.
   - **Zero-REFACTOR refactor-only exception**: when the first CRITIQUE finds no
     valid findings, bracket an empty porcelain-status check with two matching
     HEAD reads before any context write and retain that HEAD. DEBATE is pure
     reasoning. At the final clean pass, with zero REFACTOR rounds, repeat
     HEAD/status/HEAD before any write and require both HEAD values to match the
     baseline. Only then append one deferred composite no-op record. Stage
     exactly `PROJECT_CONTEXT.md`, reject unstaged/untracked residue, and
     recheck HEAD. As the last check, require the staged path/diff inspection
     to contain only that active-feature record, then invoke `git commit`
     immediately with no command in between. Any mismatch or command failure
     stops and escalates. The reviewer artifact digest remains available to
     elevated and non-Codex review paths but is not used for this gate.
   - **Slug/path safety**: derive `<feature-slug>` deterministically from the
     feature heading using lowercase kebab-case matching `[a-z0-9-]+`. Reject
     `/`, `..`, a leading `.`, an empty slug, any canonicalized path outside
     the resolved archive directory/repository, a symlinked archive directory,
     or a non-immediate-child target. PRE-FLIGHT recursively enumerates the
     archive tree and treats any archive-relative subdirectory separator as
     invalid.
   - **What moves**: the ENTIRE feature section — `#### Current state` and
     `#### Round log` — verbatim, losslessly. No summarization, no
     compaction. `PROJECT_CONTEXT.archive/<feature-slug>.md` is the full
     record; nothing is thrown away.
   - **What replaces it**: `PROJECT_CONTEXT.md`'s `## <feature-name>` heading
     is replaced with a one-line pointer: feature name, one-line outcome
     summary, completion date, the archive file's relative path, the SHA-256
     of the archived section, and the short hash of the **last checkpoint
     commit before this archival move** (the commit that holds the feature's
     finished work), never the archival commit's own self-referential hash. The
     archival commit itself needs no stored hash to be located: it is
     self-identifying via its own `Cycle-State: COMPLETE` message, exactly
     like every other checkpoint commit is located by its `Cycle-State`/round
     label — `git log --grep` for that trailer plus the feature name finds
     it directly.
   - **Atomicity**: the archive-file write, the `PROJECT_CONTEXT.md`
     rewrite, and the terminal `git commit` happen together as one commit —
     never as separate commits, and never with one landed and the other
     pending. If checkpoint commits were not authorized for this cycle (node
     0), skip the archival move entirely and escalate to the user instead of
     leaving an uncommitted archive write on disk. Capture HEAD when the
     sequence starts; after every other check, re-verify the same HEAD. Then,
     as the last check, inspect the staged path set and diff for exactly
     `PROJECT_CONTEXT.md` plus the intended archive file and the byte-exact
     move/pointer contents, and invoke `git commit` immediately with no command
     in between. Abort without committing and escalate on any mismatch; do not
     retry blindly.
   - **Interruption/inconsistency handling**: a future cycle entering
     PRE-FLIGHT on this repo must check, for every feature heading in
     `PROJECT_CONTEXT.md`, that a pointer's claimed archive is a regular
     non-symlink file resolving within the repository, exists, and matches the
     pointer's SHA-256, and that no archive descendant exists without exactly
     one valid pointer. Missing/hash-mismatched/orphan/nested/symlinked state
     is a stop-and-escalate condition at PRE-FLIGHT, not something to silently
     repair or guess about.

4. **Operational preconditions, identity, and continuity limits.** At most one
   active graph-engineer cycle may run per repository; concurrent cycles are
   unsupported and can corrupt shared context/index/branch state. In
   particular, making staged-content inspection the last command immediately
   before each applicable commit narrows but does not eliminate the residual
   race window; this protocol has no lock or compare-and-swap binding the
   inspected index to the commit. In refactor-only, PRE-FLIGHT commits its own
   Quality gate/Backend/Critique
   assurance scaffolding immediately before the first CRITIQUE so a no-op run
   cannot leave it pending. Every resumed CRITIQUE, DEBATE reinjection, and
   REFACTOR prompt names the active feature and stops if the resumed memory is
   for another feature. This mitigates but does not eliminate the pinned
   plugin's recency-based `--resume-last` limitation.
   `elevated-assurance.md` defines one canonical artifact digest as a literal
   shell recipe over NUL-delimited HEAD, porcelain status, binary diff, and
   sorted untracked-file path/content hashes. Its plain `mktemp` call uses the
   environment/system temporary-path resolution rather than a fixed `/tmp`
   template. Both sides of every comparison must use that recipe. Its drift
   coverage is limited to Git-visible tracked final working-tree content and
   coarse index/working-tree status plus
   initially untracked, non-ignored regular files; it does not cover ignored
   files, submodule internals, or
   filesystem state outside Git's view, and it does not uniquely encode
   different partially staged index splits when HEAD, final working-tree bytes,
   and porcelain status are otherwise identical.

**Explicitly out of scope for this feature**: lossy compaction or summarization
of `#### Round log`; one-live-file-per-active-feature layout; retrofitting
grandfathered feature sections; changing the fixed 3-lens set, the
exit-challenger fan-in barrier, or elevated-assurance mechanics unrelated to
disclosure/identity; and changing `quality-gate-detection.md`'s resolver.

**Consistency requirement.** `context-lifecycle.md` is authoritative for the
two-subheading shape, byte-exact prompt disclosure, round history, no-op rule,
and archival mechanics. `SKILL.md` links each affected node to it;
`elevated-assurance.md` owns the canonical artifact-identity recipe;
`backend-selection.md` reuses both contracts for every backend. The
orchestrator's archive write remains limited to the terminal transition, and
autonomous goal stop conditions require the terminal transition, the verified
zero-REFACTOR no-op, or the corresponding escalation.

#### Round log

##### IMPL-r00

- **Actors/backend**: Claude orchestrator and Codex writer / `backend: codex`
- **CRITIQUE outcome**: not applicable — initial implementation preceded the
  first review.
- **DEBATE classifications**: not applicable.
- **Resulting writer work**: Added the lifecycle reference, node-scoped
  disclosure, terminal archival protocol, and cross-file routing.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: The archive pointer stores the preceding finished-work
  checkpoint rather than the archival commit's impossible self-hash.

##### REFACTOR-r01

- **Actors/backend**: Elevated Codex reviewers, Claude triage, and Codex writer
  / `backend: codex`
- **CRITIQUE outcome**: Found cold-review disclosure, terminal-edge, path,
  identity, continuity, and archival-integrity gaps in IMPL-r00.
- **DEBATE classifications**: F1-F11 and F13 valid; F12 false-positive because
  the accepted pointer stores the preceding checkpoint, not a self-hash.
- **Resulting writer work**: Applied the first lifecycle, archival, disclosure,
  no-op, identity, and recovery corrections.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: A resumed write selected an unrelated cancelled session,
  confirming the named-feature memory check is a mitigation rather than
  resume-by-thread identity. A per-feature live-file split and lossy log
  compaction remained out of scope because neither bounds one active feature
  while preserving the full record.

##### REFACTOR-r02

- **Actors/backend**: Codex reviewer, Claude triage, and Codex writer /
  `backend: codex`
- **CRITIQUE outcome**: Confirmed F2, F4, F6-F11, and F13 closed; found F1, F3,
  and F5 residuals plus an underspecified digest encoding.
- **DEBATE classifications**: All four residual findings valid.
- **Resulting writer work**: Moved decision history out of Current state,
  strengthened the zero-REFACTOR identity gate, specified byte-exact inline
  extraction/serialization, and pinned the canonical digest recipe.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Pre-recipe digest strings used ad hoc delimiters and are
  not comparable to canonical values; the earlier clean-state conclusion was
  based on the three lenses' agreeing recomputations.

##### REFACTOR-r03

- **Actors/backend**: Codex reviewer, Claude triage, and Codex writer /
  `backend: codex`
- **CRITIQUE outcome**: Found F3 and F5 still partial, plus undefined
  checkpoint backfill and overclaimed digest coverage.
- **DEBATE classifications**: All four findings valid.
- **Resulting writer work**: Added fail-closed EOF extraction, reordered the
  no-op comparison before context writes, introduced checkpoint backfill, and
  scoped digest guarantees to Git-visible state.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: This iteration exposed that prose parsing, digest-gated
  no-op identity, and opportunistic hash backfill remained fragile even after
  their local edge cases were patched.

##### REFACTOR-r04

- **Actors/backend**: Codex design reviewer, Claude triage, and Codex writer /
  `backend: codex`
- **CRITIQUE outcome**: Confirmed F3 and F5 remained partial, checkpoint
  backfill was not followed by its introducing round, and the digest did not
  uniquely encode partially staged index state; challenged all three designs.
- **DEBATE classifications**: F3, F5, checkpoint-backfill ordering, and
  partial-index digest identity were valid under the corrected design; their
  root simplifications were exact sentinels, HEAD plus clean-tree for the no-op
  gate, immutable checkpoint locators, and composite iteration records.
- **Resulting writer work**: Replaced the fence parser, no-op digest gate,
  mutable checkpoint hash, and per-node best-effort ledger with the simplified
  present contracts; terminal archival mechanics remain unchanged.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Backtick and tilde runs are uninterpreted payload bytes.
  Structural validation runs after Current-state writes and before dispatch;
  generic autonomous goals stop on failure. This same checkpoint performs the
  one-time migration of pre-r04 per-node history into composites; future
  writer iterations may not defer their own record.

##### REFACTOR-r05

- **Actors/backend**: Prior Codex reviewer, user-confirmed triage, and Codex
  writer / `backend: codex`
- **CRITIQUE outcome**: Found feature-heading ambiguity, an overclaimed
  inspect-then-commit binding, a substring-collision-prone checkpoint locator,
  non-canonical migrated verdict vocabulary, and a fixed `/tmp` assumption in
  the canonical digest recipe.
- **DEBATE classifications**: All five findings valid.
- **Resulting writer work**: Required one exact active-feature heading, made
  staged-content inspection the last check adjacent to each applicable commit,
  delimited checkpoint subjects, normalized the migrated verdicts, and made
  temporary-file creation environment-aware.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Inspection adjacency narrows but does not eliminate the
  residual race window; the one-active-cycle precondition remains mandatory.
