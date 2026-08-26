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

In the two-message workflow from `goal-templates.md`, put the directive in
message 1 so PRE-FLIGHT can see it. Message 2 is too late to change a backend
that PRE-FLIGHT has already resolved.

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
2. If `backend:` appears more than once across the initial prompt and `/goal`
   text with different values, stop and ask the user to clarify. Do not choose
   one by source order or assume that a later occurrence overrides an earlier
   one.
3. Accept only `codex`, `claude`, or `claude:<account-alias>`. Reject an empty
   alias or any other value with a clear message instead of guessing.
4. For either non-`codex` value — plain `claude` as well as
   `claude:<account-alias>` — require explicit user confirmation before the
   first dispatch. Disclosure alone is not authorization. If no confirmation
   is available, including in an unattended `/goal` run, stop and escalate
   rather than adopting a directive found in scanned or pasted text.
5. For `claude:<account-alias>`, call `ListAgents` before SPEC and match the
   alias to a reachable existing session. Display exactly the resolved session
   identity that `ListAgents` reports and require the user to confirm that
   target explicitly before the first dispatch. A reachable, unambiguous
   alias is not by itself authorization. This is best-effort account
   addressing, not cryptographic identity, authorization, repository-root,
   worktree, branch, HEAD, or workspace verification. Persist the confirmed
   session identity so every later `SendMessage` targets that same session.
   If no matching session exists, the match is ambiguous, or the user does not
   confirm it, abort clearly. Do not silently fall back to `claude` or `codex`.
6. Elevated assurance is incompatible with
   `claude:<account-alias>` because one retained cross-session conversation
   cannot supply its 3 independent fresh lenses. If both are requested, stop
   and ask the user to choose `codex`, `claude`, or to decline elevated mode.
7. Persist the final resolution under `### Backend` inside the current
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

## Mandatory disclosure

When the resolved backend is anything other than `codex`, PRE-FLIGHT must say
the following to the user once, before SPEC (or before the first dispatched
node in a mode without SPEC), and persist the same disclosure under
`### Backend` in write-authorized modes:

> This cycle will use the same underlying Claude model for both writer and
> reviewer roles, so the “different model in the decision path” mitigation
> this skill is built around does not apply this run. DEBATE arbitration and
> the anti-loop cutoff still apply, but they do not compensate for a
> same-model blind spot the way they do against Codex.
>
> A Claude writer operates with the full ambient tool authority of the Claude
> Code session that runs it, including shell, network, git, and any credentials
> available there. It has no Codex-equivalent workspace-write sandbox or
> capability restriction. This is a capability and blast-radius difference,
> not only a review-quality difference; this skill cannot currently provide an
> equivalent sandbox for Claude writers.

For `claude:<account-alias>`, append this cross-session disclosure:

> The feature contract, findings, and triage history will be sent to a
> different account/session and are subject to that session's own tools,
> hooks, and retention. Avoid this backend for contracts containing secrets
> or sensitive data: this skill does not redact or scan payloads before
> sending them.

Do not describe a later CRITIQUE in that cycle as “independent review.” A new
subagent or a different account/process may change thread context, tools, or
credentials, but it does not create cross-model diversity.

## Artifact identity for non-Codex reviewer calls

Neither Claude backend has Codex CRITIQUE's process sandbox. Around every
reviewer call — every `Explore` call under `backend: claude` and every
cross-session CRITIQUE dispatch under `backend: claude:<account-alias>` —
capture and compare the artifact-identity digest defined in
`elevated-assurance.md`. The check is mode-independent: it applies to standard
and elevated CRITIQUE alike, although PRE-FLIGHT's current compatibility rule
rejects cross-session elevated mode before any such dispatch. The digest is a
SHA-256 over the fixed-order
concatenation of `git rev-parse HEAD`, raw
`git status --porcelain=v1 -uall`, `git diff HEAD --binary`, and that
reference's NUL-delimited content-hash manifest for initially-untracked paths.

Capture the digest immediately before dispatch, recompute it after the reply,
and accept the review only if they match exactly. A mismatch, or inability to
construct or compare either digest, is a stop-and-escalate condition. This is
mutation detection, not a sandbox or prevention guarantee.

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
cross-model diversity or Codex's workspace-write isolation, which is why both
parts of the PRE-FLIGHT disclosure are mandatory. The writer has the
orchestrating session's full ambient tool authority; this skill has no
mechanism that can give it an equivalent capability sandbox.

#### CRITIQUE: fresh `Explore` reviewer

Use `Agent(subagent_type: "Explore", ...)` for every CRITIQUE call, with an
adversarial read-only prompt and no instruction to fix anything. `Explore` is
chosen because its tool definition excludes the direct editor tools `Edit`,
`Write`, and `NotebookEdit` (its excluded set also names `Agent`, `Artifact`,
and `ExitPlanMode`). That is a tool-list restriction, not a sandbox guarantee:
`Explore` still has Bash/shell access and could mutate files indirectly. The
mandatory before/after artifact-identity comparison above detects drift; it
does not make the call structurally read-only or comparable to Codex's
OS/process sandbox.

Return the reviewer's findings verbatim before Claude performs the normal
valid/debatable/false-positive triage. When elevated assurance is separately
authorized, dispatch 3 independent fresh `Explore` agents in parallel for its
3 lenses, not one reviewer. After all 3 complete with matching artifact
identity, Claude performs fan-in and canonicalization itself by normalizing
the raw reports and updating the continuity summary; there is no separate
Codex-style canonicalization call or canonical thread for this backend. The
remaining lens, artifact-identity, budget, and exit-challenger invariants in
`elevated-assurance.md` still apply, with fresh `Explore` calls wherever a
reviewer is required.

Because Claude performs both fan-in and canonicalization on this backend,
there is no independent second pass auditing the accuracy of Claude's merge/
normalization of the 3 raw lens reports; on the default `codex` path, the
separate canonicalization reviewer challenges Claude's normalization against
those raw reports.

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

For elevated assurance, this manually maintained continuity summary is the
backend's entire continuity state; there is no separate canonical-thread
concept. Claude's canonicalization is its own act of updating that summary
from the 3 raw lens reports and normalized ledger. Every later ordinary
CRITIQUE or reinjection is another fresh `Explore` call with the up-to-date
summary. The exit challenger remains the deliberately cold exception defined
by `elevated-assurance.md` and receives no prior finding ledger.

### `claude:<account-alias>` (existing cross-session target)

At PRE-FLIGHT, resolve the alias with `ListAgents`. Thereafter, use
`SendMessage` for IMPL, CRITIQUE, and REFACTOR, await that session's
reply/notification, and only then advance to the next node. Recheck
reachability with `ListAgents` when needed, but keep targeting the same
resolved session for the whole cycle. This backend's handoff is asynchronous
at the tool boundary; the graph itself remains sequential.

Every dispatched message must name the feature, the current node, and a short
description of the expected response. Advance only when a reply clearly
answers that specific dispatch; an unrelated or ambiguous reply is not
completion. The skill has no built-in request-correlation ID, automated
timeout, disconnect recovery, or retry mechanism, so this is a best-effort
causal convention rather than a guarantee. If the target stops responding,
stop and ask the user to help unblock the session instead of redispatching or
guessing that the node completed.

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
> describe it as a different or independent reviewer. Per-role aliases were
> ruled out because this skill can only address already-running sessions, not
> launch new ones, so it cannot guarantee that a genuinely separate reviewer
> session exists.

CRITIQUE read-only-ness in this backend is **prompt-only**. `SendMessage`
cannot impose a sandbox or remove tools from the remote session. This is
strictly weaker than Codex CRITIQUE's enforced read-only process sandbox and
is not repaired by `backend: claude`'s direct-editor tool exclusion. Apply the
mandatory artifact-identity digest before and after every cross-session
CRITIQUE. The check itself is mode-independent even though the current rule
below prevents cross-session elevated dispatch. If the digest changes, stop
and escalate; do not accept the review as if it covered the now-changed
artifact.

A confirmed cross-session identity plus a matching local artifact digest does
not prove the target session operated on the orchestrator's actual repository,
worktree, branch, or HEAD. The digest only detects drift in the orchestrator's
own local tree, not what the remote session actually touched; this design has
no mechanism to verify the target's workspace identity.

This backend also cannot run elevated assurance: one retained target session
cannot furnish 3 independent fresh lenses. PRE-FLIGHT must reject the
combination as defined above rather than approximating the sweep.

This skill can only address sessions that already exist. It does not launch
or authenticate a new OS-level Claude Code process, just as it does not
diagnose Codex plugin installation.

## Explicitly out of scope

- Spawning new Claude Code sessions/processes for `claude:<account-alias>`.
- Per-role account aliases, such as distinct writer and reviewer sessions.
- Parallel same-model reviewers outside the 3-lens `backend: claude`
  elevated-assurance variant.
- Any change to Codex's own behavior or to the default (`codex`) path.
- Any mechanism to verify a cross-session target's actual workspace,
  repository, worktree, branch, or HEAD beyond the confirmed session identity
  and local artifact digest.
