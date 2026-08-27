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
