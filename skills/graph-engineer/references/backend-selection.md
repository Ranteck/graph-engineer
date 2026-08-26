# Backend selection: per-cycle writer/reviewer routing

Backend selection is a **per-cycle, opt-in routing decision** for the actors
that perform node 2 (IMPL), node 4 (CRITIQUE), and node 6 (REFACTOR). The
standard `codex` path remains the unconditional default: if the user does not
provide a `backend:` directive, nothing about the existing Codex behavior
changes.

This option changes who fills the writer and reviewer roles; it does not add a
node, change the 8-node cycle, bypass DEBATE's
valid/debatable/false-positive triage, or weaken the anti-loop cutoff. Claude,
as orchestrator and arbiter, still never edits implementation files directly
with Edit/Write.

## Directive syntax

Read `backend:` from the user's `/goal` text or initial prompt during
PRE-FLIGHT. This is a natural-language per-cycle directive, like the skill's
existing read-only, elevated-assurance, and checkpoint-commit preferences —
not a CLI flag and not a new parser.

- **`backend: codex` or omitted** — use the existing Codex behavior without
  modification.
- **`backend: claude`** — use same-session Claude subagents: a
  `general-purpose` writer for IMPL/REFACTOR and a fresh `Explore` reviewer
  for CRITIQUE.
- **`backend: claude:<account-alias>`** — send IMPL, CRITIQUE, and REFACTOR
  work to one already-running Claude Code session resolved by alias.

The directive applies to the whole cycle. Do not change backends between
nodes or reinterpret an omitted directive after PRE-FLIGHT.

### Rejected alternative: `graph-engineer:claude-personal`

Do not encode backend selection after the skill name. A colon-scoped name
already follows Claude Code's plugin-skill convention (`plugin:skill`, for
example `openai-codex:codex-rescue`). Reusing that shape for a runtime backend
parameter would be ambiguous with the existing convention and inconsistent
with this skill's other per-cycle options, which are natural-language
directives in the goal or initial prompt.

## PRE-FLIGHT resolution

Resolve the backend exactly once at cycle entry, alongside QUALITY GATE,
critique-assurance, and checkpoint-commit policy:

1. Read the `backend:` directive. If it is absent, resolve `codex`; do not ask
   the user and do not infer a different backend from quota, cost, or
   availability.
2. Accept only `codex`, `claude`, or `claude:<account-alias>`. Reject an empty
   alias or any other value with a clear message instead of guessing.
3. For `claude:<account-alias>`, call `ListAgents` before SPEC and match the
   alias to a reachable existing session. Persist the resolved session
   identity so every later `SendMessage` targets that same session. If no
   matching session exists — or the match is ambiguous — abort clearly. Do
   not silently fall back to `claude` or `codex`.
4. Persist the final resolution under `### Backend` inside the current
   feature's `PROJECT_CONTEXT.md` section before IMPL (or before the initial
   CRITIQUE in refactor-only). Review-only does not write
   `PROJECT_CONTEXT.md`; record its backend resolution in the user's prompt,
   the Claude turn, and the final report instead.

Use this persisted shape:

```markdown
### Backend
- backend: codex | claude | claude:<account-alias>
- resolution: default-codex | user-requested
- resolved session: not-applicable | <ListAgents-resolved session identity>
- disclosure: not-applicable | <mandatory disclosure text below>
```

The resolution is configuration, not a runtime progress log. Do not rewrite
it after each node, and do not record transient `SendMessage` status there.

## Mandatory same-model disclosure

When the resolved backend is anything other than `codex`, PRE-FLIGHT must say
the following to the user once, before SPEC (or before the first dispatched
node in a mode without SPEC), and persist the same disclosure under
`### Backend` in write-authorized modes:

> This cycle will use the same underlying Claude model for both writer and
> reviewer roles, so the “different model in the decision path” mitigation
> this skill is built around does not apply this run. DEBATE arbitration and
> the anti-loop cutoff still apply, but they do not compensate for a
> same-model blind spot the way they do against Codex.

Do not describe a later CRITIQUE in that cycle as “independent review.” A new
subagent or a different account/process may change thread context, tools, or
credentials, but it does not create cross-model diversity.

## Node dispatch by backend

The node invariants in `../SKILL.md` remain authoritative. The dispatch rules
below select the actor and continuity mechanism without changing the node's
place in the graph.

### `codex` (default)

Nodes 2, 4, and 6 behave exactly as documented in `../SKILL.md`:

- IMPL uses `codex:codex-rescue --write`.
- CRITIQUE uses the same subagent without `--write`; the plugin's read-only
  sandbox enforces that restriction. The first review is fresh and later
  reviews resume as documented, including elevated-assurance exceptions.
- REFACTOR uses `--resume-last --write`, including the existing snapshot and
  fresh-session recovery protocol if a read-only session cannot be upgraded.

Every Codex interaction still routes through the single
`codex:codex-rescue` entry point. Backend selection does not alter Codex's
prompts, flags, continuity rules, sandbox guarantees, or default status.
Node 5 reinjects a debatable finding to that same reviewer with
`--resume-last` and no `--write`, exactly as `../SKILL.md` documents.

### `claude` (same-session subagents)

The orchestrating Claude dispatches a new subagent for each writer or reviewer
call. The subagent edits or reviews; the orchestrator remains the contract
owner and DEBATE arbiter and never uses Edit/Write on implementation files.

#### IMPL and REFACTOR: `general-purpose` writer

Use `Agent(subagent_type: "general-purpose", ...)` for both writer nodes.
For IMPL, provide the active feature contract from `PROJECT_CONTEXT.md` and
instruct the agent to implement it directly with Edit/Write. For REFACTOR,
provide the triaged valid findings, relevant contract constraints, and the
continuity summary described below, and instruct the agent to apply those
fixes directly with Edit/Write. Every writer return still routes through
QUALITY GATE before CRITIQUE exactly as `../SKILL.md` requires.

This preserves the core orchestration invariant: a dispatched writer — not
the orchestrating Claude — edits implementation files. It does not preserve
cross-model diversity, which is why the PRE-FLIGHT disclosure is mandatory.

#### CRITIQUE: fresh `Explore` reviewer

Use `Agent(subagent_type: "Explore", ...)` for every CRITIQUE call, with an
adversarial read-only prompt and no instruction to fix anything. `Explore` is
chosen because its tool definition structurally excludes `Edit`, `Write`, and
`NotebookEdit` (its allowed set is described as all tools except `Agent`,
`Artifact`, `ExitPlanMode`, `Edit`, `Write`, and `NotebookEdit`). The reviewer
therefore cannot edit through those tools; read-only-ness is structural, not
merely requested in prose.

This is comparable in kind but not identical in strength or mechanism to the
Codex path: Codex CRITIQUE is blocked by an OS/process read-only sandbox,
whereas `backend: claude` relies on the `Explore` agent's structural tool-list
exclusion.

Return the reviewer's findings verbatim before Claude performs the normal
valid/debatable/false-positive triage. Elevated assurance, when separately
authorized, remains a node 4 variant and must preserve its lens,
canonicalization, artifact-identity, budget, and exit-challenger invariants;
only the backend dispatch changes.

#### Manual continuity summaries

Plain `Agent()` subagents do not have a `--resume-last`-style memory channel.
Treat every call as fresh. The orchestrator must build and include a concise
continuity summary from the active `PROJECT_CONTEXT.md` section and its own
conversation state:

- prior findings and their stable identities;
- Claude's valid/debatable/false-positive verdicts and reasons;
- fixes already attempted and any VERIFY failure classification; and
- constraints that still apply to the current artifact.

Include the applicable summary in every CRITIQUE after the first and in every
REFACTOR prompt. This is the normal continuity mechanism for
`backend: claude`, not an exception used only after a failed resume. It
preserves triage history across fresh subagents without pretending they share
memory. A node 5 reinjection for a debatable finding likewise uses a fresh
`Explore` subagent and includes the finding, Claude's counterargument, and
this continuity summary before Claude decides its final verdict.

### `claude:<account-alias>` (existing cross-session target)

At PRE-FLIGHT, resolve the alias with `ListAgents`. Thereafter, use
`SendMessage` for IMPL, CRITIQUE, and REFACTOR, await that session's
reply/notification, and only then advance to the next node. Recheck
reachability with `ListAgents` when needed, but keep targeting the same
resolved session for the whole cycle. This backend's handoff is asynchronous
at the tool boundary; the graph itself remains sequential.

For IMPL and REFACTOR, send the active contract or triaged fixes and authorize
the target session to edit. For CRITIQUE, send the current scope, contract,
prior findings and triage history, and an explicit adversarial, read-only
instruction. Because the same target session retains its conversation, it
already has continuity; still include the current triage decisions and
constraints so the requested review state is explicit rather than inferred.
Node 5 sends any debatable counterargument to this same resolved session and
awaits its answer before Claude decides the final verdict.

> **WEAKEST WRITER/REVIEWER ISOLATION.** Both roles target the **same session
> by default**. The reviewer literally remembers authoring the code it is
> reviewing. This is the weakest writer/reviewer isolation of all three
> backends — weaker even than `backend: claude`'s fresh `Explore` reviewer —
> despite using a different account or process from the orchestrator. Never
> describe it as a different or independent reviewer.

CRITIQUE read-only-ness in this backend is **prompt-only**. `SendMessage`
cannot impose a sandbox or remove tools from the remote session. This is
strictly weaker than Codex CRITIQUE's enforced read-only process sandbox and
weaker than `backend: claude`'s structural `Explore` exclusion. If the target
session edits during CRITIQUE, stop and escalate; do not accept the review as
if it covered the now-changed artifact.

This skill can only address sessions that already exist. It does not launch
or authenticate a new OS-level Claude Code process, just as it does not
diagnose Codex plugin installation.

## Explicitly out of scope

- Spawning new Claude Code sessions/processes for `claude:<account-alias>`.
- Per-role account aliases, such as distinct writer and reviewer sessions.
- Parallel same-model reviewers for sample diversity; that remains only a
  possible future mitigation.
- Any change to Codex's own behavior or to the default (`codex`) path.
