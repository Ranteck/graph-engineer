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
- **Codex review/debate call budget**: 13 (template default)

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
existing in this cycle (README.md:396-404, SKILL.md:23-27).

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
directive if present (default `codex` if absent). Persist the resolution
under `### Backend` in this file before IMPL. If `backend: claude:<alias>`
is given, resolve `<alias>` to a reachable session via `ListAgents` *at
PRE-FLIGHT*, before SPEC — if no matching session is found, abort with a
clear message (same escalate-don't-guess posture as an unreachable Codex
plugin) rather than silently falling back to `claude` or `codex`.

**Mandatory disclosure when `backend != codex`.** PRE-FLIGHT must state to
the user, once, in plain terms, before SPEC: this cycle will use the same
underlying model for both writer and reviewer roles, so the "different model
in the decision path" mitigation this skill is built around
(README.md:396-404) does not apply this run; DEBATE arbitration and the
anti-loop cutoff still apply, but they no longer compensate for a
same-model blind spot the way they do against Codex. This disclosure text
is also persisted under `### Backend` in this file, not just spoken once and
discarded — future CRITIQUE/DEBATE steps must not narrate it as "independent
review."

**Per-backend node behavior:**

- **`codex` (default).** No behavior change. Nodes 2/4/6 exactly as
  documented in `SKILL.md` today.

- **`claude` (same-session subagents).**
  - IMPL/REFACTOR (writer): `Agent(subagent_type: "general-purpose", ...)`,
    instructed to implement the contract in `PROJECT_CONTEXT.md` directly
    with Edit/Write — this agent, not the orchestrating Claude, performs the
    edit, so the core invariant ("Claude [[the orchestrator]] never edits
    implementation files") holds; it is a distinct actor the orchestrator
    dispatches to, structurally the same relationship the orchestrator has
    to Codex today.
  - CRITIQUE (reviewer): `Agent(subagent_type: "Explore", ...)` — chosen
    specifically because `Explore`'s tool list structurally excludes
    Edit/Write/NotebookEdit (per its own definition: "All tools except
    Agent, Artifact, ExitPlanMode, Edit, Write, NotebookEdit"). This gives a
    **structural** read-only guarantee comparable in kind (not in strength —
    see Risks) to Codex's `workspace-write`/`read-only` sandbox distinction,
    rather than a prompt-only promise.
  - Continuity across CRITIQUE calls: plain `Agent()` subagents do not carry
    memory between calls the way `--resume-last` does for Codex. Every
    CRITIQUE call in `backend: claude` mode must therefore include an
    explicit continuity summary (prior findings, triage verdicts, still-
    applicable constraints) built by the orchestrator from
    `PROJECT_CONTEXT.md` and its own conversation memory — this is the same
    technique `SKILL.md` node 6 already documents for the "fresh REFACTOR
    fallback" case, generalized here to every call instead of a fallback-only
    path.

- **`claude:<account-alias>` (cross-session).**
  - The orchestrator uses `SendMessage` to the resolved session for both
    IMPL/REFACTOR and CRITIQUE, and awaits its reply/notification before
    advancing to the next node — this makes node sequencing asynchronous for
    this backend only; document this as a structural difference, not a
    defect.
  - **Both roles target the same session by default**, because this skill
    has no mechanism to launch a new OS-level Claude Code process under a
    given account — it can only address sessions that already exist,
    exactly as it doesn't diagnose Codex plugin installation. This means
    the reviewer literally remembers writing the code it is reviewing: it is
    the **weakest** writer/reviewer isolation of the three backends, weaker
    than `backend: claude`'s fresh-`Explore`-subagent reviewer, despite
    sounding the most separated because it's a different account/process.
    State this explicitly wherever this backend is documented — do not let
    "different account" read as "different reviewer."
  - CRITIQUE's read-only-ness here is **prompt-only** — there is no sandbox
    or tool-list enforcement across a cross-session `SendMessage` the way
    there is for Codex's sandbox or same-session `Explore`. Document this
    gap explicitly next to the claim, per this skill's existing "read-only
    is enforced, not just requested" framing for Codex CRITIQUE — this
    backend cannot make the same claim.

**Consistency requirement.** `SKILL.md`'s node 2 (IMPL), node 4 (CRITIQUE),
and node 6 (REFACTOR) each need a backend-dispatch note pointing to a new
reference file (`references/backend-selection.md`) rather than inlining all
three backends' prompts into the already-long node bodies — follow the same
"link out to a reference, keep the node body describing the invariant" style
already used for `elevated-assurance.md`. `README.md` gets a short mention
(what the option is, link to the reference) — it must not duplicate the
reference's content, per this repo's own `CLAUDE.md` guidance that
`README.md` and `SKILL.md` share claims, not layout, and per the existing
precedent of not duplicating the elevated-write-goal template into
`README.md`.

**Explicitly out of scope for this feature** (do not attempt in this
cycle): spawning new Claude Code sessions/processes for `claude:<alias>`;
per-role account aliases (e.g. distinct writer vs. reviewer sessions);
parallel same-model reviewers for sample diversity (mentioned as a possible
future mitigation, not required now); any change to Codex's own behavior or
to the default (`codex`) path.
