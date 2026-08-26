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
directive if present (default `codex` if absent). If `backend:` appears more
than once with conflicting values across the initial prompt and `/goal`,
stop and ask — never guess by source order. Persist the resolution under
`### Backend` in this file before IMPL. **Every non-`codex` selection —
`claude` as well as `claude:<alias>` — requires explicit user confirmation
before the first dispatch**, because both hand a writer full ambient tool
authority with no Codex-equivalent sandbox; disclosure alone is not
authorization, and confirmation is not limited to the alias case. For
`backend: claude:<alias>`, additionally resolve `<alias>` to a reachable
session via `ListAgents` *at PRE-FLIGHT*, before SPEC, and display the exact
identity `ListAgents` reports for the user to confirm — reachability alone
is best-effort account addressing, not authorization, and not repository
root/worktree/branch/HEAD verification; a session can confirm completion of
a dispatch while having operated on a different checkout entirely, and
nothing in this design can detect that. If no matching session is found, the
match is ambiguous, or confirmation isn't given, abort with a clear message
(same escalate-don't-guess posture as an unreachable Codex plugin) rather
than silently falling back to `claude` or `codex`. **Elevated assurance is
incompatible with `claude:<alias>`** (one retained conversation cannot supply
3 independent fresh lenses) — reject that combination at PRE-FLIGHT and ask
the user to choose `codex`, `claude`, or standard mode instead.

**Mandatory disclosure when `backend != codex`.** PRE-FLIGHT must state to
the user, once, in plain terms, before SPEC, and persist under `### Backend`
in this file — not just spoken once and discarded:
1. Same-model diversity loss: this cycle uses the same underlying model for
   both writer and reviewer roles, so the "different model in the decision
   path" mitigation this skill is built around (README.md:396-404) does not
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
    with mandatory mutation detection: capture the artifact-identity digest
    (SHA-256 over `git rev-parse HEAD` + `git status --porcelain=v1 -uall` +
    `git diff HEAD --binary`, per `elevated-assurance.md`) immediately before
    every `Explore` reviewer call and recompute/compare it after; any
    mismatch is a stop-and-escalate condition, standard or elevated mode
    alike.
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
    the **weakest** writer/reviewer isolation of the three backends, weaker
    than `backend: claude`'s fresh-`Explore`-subagent reviewer, despite
    sounding the most separated because it's a different account/process.
    Per-role aliases were ruled out of scope because this skill can only
    address already-running sessions, not launch new ones, so it cannot
    guarantee a genuinely separate reviewer session exists. State the
    weakest-isolation point explicitly wherever this backend is documented —
    do not let "different account" read as "different reviewer."
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
`README.md`. `CLAUDE.md` and `AGENTS.md` (both consuming-repo-agnostic
governing files, listing the skill's own file map and core invariant) must
not state Codex-only continuity/sandbox/canonical-thread rules as universal
— they need to be scoped to "on the default `codex` path" wherever
`backend-selection.md` documents a different rule for the other backends,
not just have their opening invariant sentence qualified.

**Explicitly out of scope for this feature** (do not attempt in this
cycle): spawning new Claude Code sessions/processes for `claude:<alias>`;
per-role account aliases (e.g. distinct writer vs. reviewer sessions);
parallel same-model reviewers for sample diversity beyond the 3-lens
`backend: claude` elevated-assurance variant defined above; any change to
Codex's own behavior or to the default (`codex`) path; any mechanism to
verify a cross-session target's actual workspace/repository identity beyond
the confirmed session identity and local artifact digest (a known,
disclosed limitation — see `claude:<account-alias>` above — not something
this cycle attempts to solve).
