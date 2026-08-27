---
name: graph-engineer
description: >-
  Orchestrates a Claude↔Codex cycle where Claude Code designs the contract and arbitrates, while Codex by default (via the official openai/codex-plugin-cc plugin) writes, adversarially reviews, and fixes the code — the orchestrating Claude never edits implementation files. A per-cycle backend directive can opt into Claude workers instead without changing the Codex default. Use when the user asks to "implement with Codex", "have Codex review and fix", "peer review with Codex", "graph engineering", "orchestrator-workers with Codex", or wants an autonomous Claude+Codex implement→review→debate→refactor loop. (ES triggers: "implementar con Codex", "que Codex revise y corrija", "peer review con Codex", "graph engineering", "orchestrator-workers con Codex")
---

# Graph Engineer

An **Evaluator-Optimizer** cycle (an official Anthropic pattern, see
`references/sources.md`) nested inside an **Orchestrator-Workers** pattern:
the user is the orchestrator, Claude is the sub-orchestrator, and Codex is by
default both the worker that implements and the evaluator that critiques. The
hard rule across the whole flow: **the orchestrating Claude never edits
implementation files** with Edit/Write — the writer selected during
PRE-FLIGHT does. That writer is unconditionally Codex, via the
`codex:codex-rescue` subagent, unless the user explicitly opts into a Claude
backend for that cycle. This is what keeps the writer and arbiter roles
explicit.

This split has three independent motivations:

1. **Save Claude context/tokens.** Keep implementation-heavy work out of
   Claude's conversation so it can spend context on the contract,
   orchestration, and judgment. This is a relative saving, not zero cost:
   long loops still accumulate findings and triage history.
2. **Reduce correlated self-review failures.** Reflection is useful, but a
   writer reviewing its own output can repeat the same blind spots; see
   Andrew Ng's
   [Agentic Design Patterns — Reflection](https://www.deeplearning.ai/the-batch/agentic-design-patterns-part-2-reflection/).
   Use Claude's DEBATE arbitration to put a different model in the decision
   path. Preserve the limitation below: IMPL and CRITIQUE still share the
   same Codex model, so this is mitigation, not independent verification.
3. **Specialize by role.** Use Codex for applying code because it is good at
   that work, independent of cost; use its adversarial pass to challenge the
   result; use Claude for contract ownership and evidence-based arbitration.
   Do not reduce the design to "Codex always implements because it saves
   tokens."

Don't confuse this with "graph engineering" as a marketing term — it is not
an official Anthropic or OpenAI feature. This skill is a concrete pattern
built on top of real installed pieces: the official OpenAI `codex` plugin and
Claude Code's built-in `/goal` stop-gate.

## Prerequisite

When PRE-FLIGHT resolves the default `codex` backend, the official OpenAI
Codex plugin for Claude Code must be installed and authenticated:
[openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc).

```
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/codex:setup
```

`/codex:setup` should report `Status: ready`. If it doesn't, stop and tell the
user to fix their Codex setup — this skill doesn't try to diagnose plugin
installation problems. `backend: claude`,
`backend: claude:<account-alias>`, and
`backend: claude-writer:<account-alias>` do not require the Codex plugin
because those routes never call it, but PRE-FLIGHT backend resolution and
every other applicable skill invariant still apply.

**Tested against `openai-codex` plugin v1.0.6.** The routing assumptions in
this skill (single `codex:codex-rescue` entry point, `--write`/`--resume-last`
flag behavior, the sandbox enforcement described under CRITIQUE below) were
verified against that version. A future plugin update that changes the
command surface or flag semantics could silently break these assumptions —
if the cycle starts behaving unexpectedly, check the installed plugin
version first.

## Single Codex entry point: `codex:codex-rescue`

Every interaction with Codex in this cycle goes through one subagent:

```
Agent(subagent_type: "codex:codex-rescue", prompt: "...")
```

It's the only Codex plugin command without `disable-model-invocation`, so
it's the only one callable directly by the model — `/codex:review`,
`/codex:adversarial-review`, `/codex:status`, `/codex:result`, and
`/codex:cancel` are typed-by-human-only and out of scope for an autonomous
cycle. The subagent itself supports read-only runs: per its own definition,
it defaults to `--write` "unless the user explicitly asks for read-only
behavior or only wants review, diagnosis, or research without edits" — so the
CRITIQUE node below is just the same subagent invoked without `--write` and
with adversarial framing in the prompt, not a different mechanism.

(If the user prefers to drive a review by hand instead of through the cycle,
`/codex:adversarial-review` can still be typed directly — it's just not part
of what this skill automates.)

## Selecting a mode

Three entry paths exist. Pick one before starting — on the default `codex`
path, the cheapest costs a single Codex call and is a complete answer for most
review work.

Both columns below are derived, not measured. **Floor** is a run where
CRITIQUE finds nothing. **One-fix round** is a run where one finding is
accepted, fixed, and re-reviewed once — the smallest run that actually does
something. Real runs with several findings cost more.

| Mode | Path | Standard Codex calls (floor / one-fix round) | Use when |
|---|---|---|---|
| **Review-only** | PRE-FLIGHT → CRITIQUE → DEBATE/report → DONE | 1 / 1 | You want an adversarial read of code that already exists. Authorizes no writes; only the default Codex path enforces that with a sandbox. |
| **Refactor-only** | PRE-FLIGHT → CRITIQUE → DEBATE → REFACTOR → QUALITY GATE → CRITIQUE → … → DONE | 1 / 3 | Existing code needs fixing, with no new feature contract involved. |
| **Full 8-node write cycle** | PRE-FLIGHT → SPEC → IMPL → … → VERIFY | 2 / 4 | New functionality that needs a contract written before the code exists. |

Review-only is 1 in both columns because it never refactors — it reports and
stops. Refactor-only and the full cycle reach their one-fix number by adding
REFACTOR plus the re-review CRITIQUE that follows it.

On the default `codex` path, these counts are traced by node actor: IMPL,
CRITIQUE, and REFACTOR are Codex calls, while PRE-FLIGHT, SPEC, QUALITY GATE,
DEBATE, and VERIFY are Claude.
QUALITY GATE only reaches Codex when a mechanical check fails, and DEBATE only
when a `debatable` finding is reinjected. Elevated assurance expands node 4 and
adds exit-challenger passes — it does not multiply IMPL or REFACTOR — and its
floors are much higher, belong to that mode alone, and are listed under Risks.

Note that both write-authorized paths begin at PRE-FLIGHT for a reason: that
is where the clean-tree and non-`main` branch checks happen. Refactor-only
does not start by calling Codex.

**When not to authorize a write cycle.** The entry question is blast radius,
not whether a change is "structural" or "cosmetic". If a change alters no
behavior, crosses no module boundary, and touches no text another file cites
as a contract, it has not earned a write cycle — read it yourself, or use
review-only. Naming is not automatically exempt: a local variable's name has
no blast radius, but a term other files reference as a contract does, and
getting that wrong propagates silently.

`references/goal-templates.md` has a ready-to-use `/goal` template per mode.

## The cycle (8 nodes)

Create one todo per node before starting.

```
PRE-FLIGHT -> SPEC -> IMPL -> QUALITY GATE
                         ^        |
                         +- fail -+  (max 3 failed runs per activation)
                                  | pass
                                  v
                              CRITIQUE
                                  v
                               DEBATE
                         +--------+--------+
                  valid findings      no findings
                         v                 v
                     REFACTOR           VERIFY
                         v              +- pass -> DONE
                   QUALITY GATE         +- fail -> CRITIQUE
                         +- fail (max 3) -> REFACTOR
                         +- pass -> CRITIQUE
```

Review-only uses a separate terminal path rather than the 8-node write cycle:

```
PRE-FLIGHT (review-only variant) -> CRITIQUE -> DEBATE/report -> DONE
```

It explicitly skips SPEC, IMPL, QUALITY GATE, REFACTOR, and VERIFY. Its
CRITIQUE reviews the requested scope and any user-supplied criteria directly;
it neither requires nor assumes that a `PROJECT_CONTEXT.md` contract exists.

Refactor-only is a separate write-authorized entry path over already-existing
code, with no new SPEC or IMPL:

```
PRE-FLIGHT (write-authorized) -> CRITIQUE (first pass, fresh thread, current tree)
  -> DEBATE -> REFACTOR (if valid findings) -> QUALITY GATE
  -> CRITIQUE (second pass) -> DEBATE -> ... -> DONE (no findings remain)
```

**Elevated assurance** is an optional, opt-in variant of node 4 (CRITIQUE) —
it does not add a node and the diagrams above stay exactly as written. On the
default `codex` path, it replaces a single CRITIQUE call with an initial sweep
of 3 independent fresh lenses plus a canonicalization call (still counted as
one CRITIQUE pass), and gates entry to VERIFY (DONE in refactor-only) on a
fresh "exit challenger" pass that reruns after any REFACTOR it itself triggers,
until one pass finds nothing. `backend: claude` and
`claude-writer:<account-alias>` instead use 3 parallel fresh `Explore` lenses
and Claude's own canonicalization, with no separate canonicalization call,
canonical thread, `--resume-last`, or Codex-call budget consumed;
`claude:<account-alias>` is incompatible with elevated assurance:

```
Elevated assurance expands node 4 only; the node count stays 8:

[3 QUALITY GATE pass]
          |
          v
[4 CRITIQUE: 3 fresh read-only lenses]
          |
          v
Claude fan-in / normalize
          |
          v
[4 CRITIQUE: fresh canonicalization task]
          |
          v
[5 DEBATE]
     | valid findings ---------------------> [6 REFACTOR]
     |                                           |
     |                                           v
     |                                    [3 QUALITY GATE]
     |                                           |
     |                                           v
     |                              [4 CRITIQUE: --resume-last]
     |
     + no valid findings, exit pending
          |
          v
[4 CRITIQUE: fresh read-only exit challenger] <--------------------+
          |                                                        |
          v                                                        |
[5 DEBATE]                                                         |
     | valid findings -> [6 REFACTOR] -> [3 QUALITY GATE] ---------+
     + no valid findings (this pass, current artifact) -> [7 VERIFY]
```

Only the exit challenger's *last* pass clears entry to VERIFY/DONE — an
earlier pass that approved an artifact REFACTOR later changed does not.

It never activates by default or silently. See
`references/elevated-assurance.md` for the full activation triggers,
persisted schema, lens definitions, fan-in barrier, and budgets — that
reference is required reading before enabling this mode, not optional
background.

PRE-FLIGHT uses the same preconditions as the full 8-node write cycle and
still resolves and persists the QUALITY GATE command because later REFACTOR
writes are expected. It does not run QUALITY GATE before the first CRITIQUE:
no IMPL or REFACTOR write has happened yet, so there is nothing new to gate.
After the first REFACTOR write, every loop follows REFACTOR -> QUALITY GATE
-> CRITIQUE -> DEBATE until no findings remain, then refactor-only terminates
at DONE.

Treat QUALITY GATE as a numbered invariant checkpoint, not a new actor or a
fixed independent pipeline stage. Attach it as a capped retry edge to the
writer node—IMPL or REFACTOR—that most recently changed the tree. In
write-authorized modes, enforce this for CRITIQUE calls that follow an IMPL or
REFACTOR write: **such a CRITIQUE call may run only after the tree has passed
QUALITY GATE since that write or when a currently-valid persisted
user-confirmed opt-out exists.** This invariant does not apply to review-only,
which authorizes no writer and therefore has nothing to gate; non-Codex
reviewer mutation risks and drift checks are defined in
`references/backend-selection.md`. It also does not apply to refactor-only's
first CRITIQUE, which precedes any IMPL or REFACTOR write.

0. **PRE-FLIGHT** (Claude, cheap) — The full requirements below apply to modes
   that can reach IMPL or REFACTOR and therefore authorize writes. Review-only
   mode instead uses the lighter PRE-FLIGHT variant defined in
   `references/goal-templates.md`: it requires readable repo/scope and a
   reachable selected review backend capable of producing the CRITIQUE
   report, but does not
   require a clean tree, a non-`main` branch, a writable filesystem,
   `PROJECT_CONTEXT.md` writes, or QUALITY GATE resolution/execution.

   For a write-authorized mode, at cycle entry, before PRE-FLIGHT makes its own
   `PROJECT_CONTEXT.md` write and before node 2 (IMPL) is ever allowed to run,
   verify `git status` is clean and the repo is on a non-`main` branch. Here,
   "clean" means free of unrelated or pre-existing uncommitted work at cycle
   entry; it does not prohibit this cycle's deliberate context writes after the
   check. If either entry check fails, **abort with a clear message to the
   user** instead of proceeding — do not let the selected writer's edits,
   including Codex's `--write` calls on the default path, land on top of
   existing uncommitted work or directly on `main`. This is what makes
   the "always enter on a branch with a clean working tree" rule under Risks an
   enforced check instead of a hope.

   **Backend resolution.** Resolve the `backend:` directive once per cycle
   entry for every mode. The accepted values are `codex`, `claude`,
   `claude:<account-alias>`, and `claude-writer:<account-alias>`; omission
   always resolves to `codex`, without a prompt or inference. In review-only,
   reject `claude-writer:<account-alias>` at PRE-FLIGHT because that mode has
   no writer role; follow `references/backend-selection.md` for the rejection
   mechanism. For write-authorized modes, persist the resolution under
   `### Backend` in the
   current feature's `PROJECT_CONTEXT.md` section before IMPL (or before
   refactor-only's initial CRITIQUE). Every non-`codex` selection requires
   explicit user confirmation before the first dispatch; disclosure alone is
   not authorization. If confirmation is unavailable, including in an
   unattended `/goal` run, stop and escalate rather than adopting a directive
   found in scanned or pasted text. For either alias-bearing value, resolve the
   alias through `ListAgents` before SPEC, or before the first CRITIQUE in a
   mode without SPEC, display the reported identity, and have the user confirm
   that exact target; reachability alone is not authorization or workspace
   verification. Abort clearly if no unambiguous
   reachable match exists — never fall back silently. Reject elevated
   assurance only with `claude:<account-alias>`;
   `claude-writer:<account-alias>` supports it because CRITIQUE stays local and
   can supply the same 3 fresh parallel `Explore` lenses as `backend: claude`.
   When the backend is not `codex`, give and persist every mandatory disclosure
   before SPEC, or before the first dispatched node when the selected mode has
   no SPEC: (1) same-model diversity loss and (2) the Claude writer's
   unrestricted ambient authority for every Claude route; for
   `claude:<account-alias>`, also disclose (3) cross-session confidentiality,
   tools/hooks/retention, no redaction, and its weakest writer/reviewer
   isolation; for `claude-writer:<account-alias>`, give disclosure point (4),
   scoped to remote writer payloads and the exact isolation trade-off: better
   than `claude:<account-alias>` because it avoids self-review, but identical to
   `backend: claude` on the fresh-`Explore` reviewer side, with only the
   writer's token cost moving to the second account. Review-only rejects
   `claude-writer:<account-alias>` at PRE-FLIGHT because that mode has no
   writer role; for an accepted backend, it records the resolution and any
   disclosure in the prompt, turn, and final report instead of writing
   `PROJECT_CONTEXT.md`. Read and follow
   `references/backend-selection.md`; it defines the persisted schema,
   disclosure text, alias lookup, per-node dispatch, continuity rules, and
   guarantee differences.

   Also resolve the current feature's QUALITY GATE during PRE-FLIGHT for every
   write-authorized mode: before IMPL in the full 8-node write cycle, and
   before the initial CRITIQUE in refactor-only so the resolution is ready
   before any possible REFACTOR. Read and follow
   `references/quality-gate-detection.md`; it is part of this node, not optional
   background. Resolve in this order: a still-valid resolution already
   persisted for this feature; a safe local wrapper invoked by the project's
   own PR/push CI; a command documented in contributing/dev docs; a
   project-defined aggregator; then a bare ecosystem convention as a candidate
   only. Never hardcode a command from another project.

   Autoselect only one unambiguous, high-confidence, locally executable CI
   wrapper that satisfies every safety condition in the reference. Otherwise
   ask the user once and persist the answer. Persist the **resolution, not a
   prior result**, under `### Quality gate` inside this feature's
   `PROJECT_CONTEXT.md` section; revalidate it cheaply after each write
   instead of redetecting it. If no usable candidate or explicit opt-out
   exists, stop before IMPL or the initial refactor-only CRITIQUE. In
   autonomous `/goal` runs, treat this as an escalation condition, never a
   silent skip. `PROJECT_CONTEXT.md` is Claude's only writable artifact across
   the whole cycle: PRE-FLIGHT writes this QUALITY GATE resolution metadata
   and the `### Backend` resolution, and — see immediately below — writes
   `### Critique assurance` too, but
   only in refactor-only (there is no SPEC there to defer to). In the
   full 8-node write cycle, PRE-FLIGHT only *evaluates* elevated-assurance
   triggers here; it writes nothing for `### Critique assurance` yet — SPEC
   is what finalizes and persists that resolution, once the actual contract
   exists to evaluate triggers against. Claude never edits implementation
   files.

   Also make an initial elevated-assurance evaluation here: check explicit
   user authorization and any risk trigger visible from the requested scope
   before SPEC exists. Read `references/elevated-assurance.md` — it defines
   the trigger list, the persisted `### Critique assurance` schema, and how
   this initial read interacts with SPEC's re-evaluation below. In
   refactor-only, since there is no SPEC, this PRE-FLIGHT evaluation is final:
   persist `### Critique assurance` here from the requested scope and the
   code already on disk.

   Between the successful cycle-entry clean check and IMPL starting, the only
   expected tree changes are this cycle's own namespaced QUALITY GATE,
   `Backend`, and `Critique assurance` resolutions plus the feature contract
   in `PROJECT_CONTEXT.md`. Recheck that narrow window before IMPL and abort
   if any other path or unrelated delta appears.

   **Checkpoint commit policy.** Also decide, once per cycle entry, whether
   Claude will create local checkpoint commits after each passing QUALITY
   GATE run (node 3 defines what gets committed and how). Default to
   authorizing it unless something about the repo makes a non-interactive
   local commit unsafe or impossible — a commit hook that mutates the tree,
   required GPG signing that would block waiting on a passphrase, a detached
   HEAD, or similar. If any of those apply, ask the user once or fall back to
   no checkpoints, and say so. This authorization only ever covers local
   commits on the current branch — never push, never rewrite history, never
   touch any ref but the branch tip.

1. **SPEC** (Claude, cheap) — Write the component's contract into
   `PROJECT_CONTEXT.md` in the active repo (create it if missing): what it
   does, interfaces, inputs/outputs, constraints. `PROJECT_CONTEXT.md` is
   Claude's only writable artifact across the entire cycle: PRE-FLIGHT writes
   the `### Quality gate` and `### Backend` resolution metadata there, and
   SPEC writes the feature contract and finalizes `### Critique assurance`
   there (see immediately below). The orchestrating Claude never edits
   implementation files.

   In the full 8-node write cycle (not refactor-only), re-evaluate the
   elevated-assurance triggers here against the actual contract just written
   — a trigger may only become visible once the contract exists (e.g. "touches
   payments" is often clear only after SPEC). Before IMPL runs, persist the
   final `### Critique assurance` resolution: `standard` unless the user
   explicitly requested elevated mode or confirmed a matched trigger with
   evidence. If a trigger matches and no user decision is available (e.g. an
   unattended `/goal` run), stop before IMPL and escalate — never silently
   elevate and never silently treat an unanswered trigger as declined.

   **Namespace by feature.** `PROJECT_CONTEXT.md` is shared across every
   cycle run in a repo, so each feature's contract must live under its own
   heading, e.g. `## <feature-name>`. A given cycle run is scoped only to
   its own section — Claude and the selected backend actors should read and
   write only the section matching the current feature, never edit or reason
   over another feature's section. This avoids one cycle's contract silently
   contaminating or being contaminated by an unrelated feature's contract
   in the same file.

2. **IMPL** (selected backend writes; Codex by default) —
   ```
   Agent(subagent_type: "codex:codex-rescue", prompt: "Implement [feature]
   following the contract in PROJECT_CONTEXT.md. --write")
   ```

   **Backend dispatch.** The invocation above is the unchanged default
   `codex` path. For `claude`, `claude:<account-alias>`, or
   `claude-writer:<account-alias>`, dispatch the selected writer exactly as
   `references/backend-selection.md` specifies; do not inline or improvise
   substitute prompts here. The invariant is that the selected writer performs
   the implementation edit while the
   orchestrating Claude remains the contract owner and never uses Edit/Write
   on implementation files. Every backend returns to node 3.

3. **QUALITY GATE** (Claude runs mechanical checks; the selected writer fixes)
   — Revalidate
   the cached resolution, snapshot both `git status --porcelain=v1 -uall` and
   `git diff HEAD --binary`, then execute the persisted check-only command with
   its exact cwd and a timeout. Mutating, auto-fix, and write-mode commands are
   categorically ineligible as QUALITY GATE candidates; if no non-mutating
   candidate exists, use the existing no-usable-candidate flow rather than
   executing a mutating command. QUALITY GATE contains only mechanical checks
   such as lint, formatting, type checking, and build. It does not own
   functional tests or acceptance criteria. Follow
   `references/quality-gate-detection.md` for the complete rejection,
   resolution, and snapshot protocol.

   When the currently-valid persisted resolution has `mode: skipped`,
   QUALITY GATE is a no-op short-circuit: execute nothing, treat the gate as
   immediately satisfied for allowing CRITIQUE to proceed, and consume none
   of the 3-failure retry counter because there is nothing to fail.

   An activation begins **only** when entering IMPL from SPEC or entering
   REFACTOR from DEBATE. On failure, route directly back to the writer that
   opened that activation—IMPL or REFACTOR—without calling CRITIQUE. Any IMPL
   or REFACTOR invocation made specifically to fix a QUALITY GATE failure
   stays in the same activation and shares its counter; it never resets the
   counter. Allow at most **3 failed gate runs total per activation**: the
   initial failed run counts, leaving at most two fix attempts. Do not extend
   the cap because the raw error count shrank. Diagnostic signatures may
   classify the escalation as reduced, frontier moved, stuck, oscillating, or
   environmental, but must never grant another attempt.

   Escalate environmental failures—missing dependency, timeout,
   out-of-memory, read-only filesystem, or command not found—immediately and
   do not consume one of the three failed runs. Reset the counter only when
   the gate passes. After that pass, a subsequent REFACTOR entered from a
   fresh DEBATE decision opens a new activation with its own counter. After
   every run, compare both before/after snapshots and escalate on any
   unexpected delta in either. Report stdout, stderr, and exit code verbatim.
   Never interpret quiet output as success without checking the exit code,
   and never auto-install a missing dependency.

   **Checkpoint commit on a passing gate.** When PRE-FLIGHT authorized
   checkpoint commits (see node 0) and this run of QUALITY GATE passes,
   Claude — never Codex — creates one local git commit for the tree QUALITY
   GATE just approved, before CRITIQUE runs. This applies uniformly to the
   gate pass that follows the initial IMPL (round `r00`) and to the gate pass
   that follows every REFACTOR (`r01`, `r02`, …), since QUALITY GATE already
   treats both writer calls the same way. Claude does this itself with
   Bash/git rather than asking Codex, because REFACTOR does not yet know the
   gate's outcome when it runs, and pass/fail is Claude's own finding to act
   on. Stage only the paths this cycle actually touched — inspect
   `git status --porcelain=v1 -uall` and `git diff --cached` before
   committing, never `git add -A`/`git add .` blind — and never push.

   A checkpoint commit is a **restore point for a mechanically-admissible
   tree, not an approval**: QUALITY GATE covers lint/format/types/build only,
   never CRITIQUE or VERIFY's judgment. Say so in the commit itself. Use:

   ```
   graph-engineer(<feature>): checkpoint <IMPL r00 | REFACTOR r04> [review-pending]

   Mode: <standard | elevated>
   Round: <IMPL-r00 | REFACTOR-r04>
   Source: <CRITIQUE pass N / exit-challenger N / n/a for r00>
   Findings: <finding IDs or a short summary of what this round fixed>
   Quality-Gate: PASS — <command>, exit 0
   Critique: PENDING
   Verify: PENDING
   Cycle-State: CHECKPOINT
   ```

   `Cycle-State` must read `CHECKPOINT`, never `COMPLETE`, at every one of
   these commits — `COMPLETE` is reserved for the terminal commit once VERIFY
   (or, in refactor-only, the final DONE-clearing CRITIQUE/exit-challenger
   pass) has actually passed. Declaring `COMPLETE` early is exactly the
   mistake a real run made: a round was tagged "mark COMPLETE" and five more
   REFACTOR rounds followed it.

   This is a narrow, explicitly scoped exception to "Claude never edits
   implementation files": a local `git commit` writes to `.git` (index,
   objects, refs) on the current branch, never to the content of any tracked
   file. It authorizes checkpoint commits only — never editing file content,
   never `push`, never rewriting history.

4. **CRITIQUE** (selected backend critiques adversarially; Codex by default,
   with sandbox-enforced no-write behavior only on that path) — On the default
   Codex path, the first CRITIQUE call in a
   cycle starts a fresh thread. Every CRITIQUE call after that—including one
   reached from a VERIFY failure—must pass
   `--resume-last`, so Codex retains memory of its own prior findings and of
   Claude's prior triage decisions, instead of restating findings that were
   already ruled debatable or false-positive. **This blanket rule has
   documented exceptions in elevated mode** — the initial 3 lens calls, the
   canonicalization call after fan-in, and every exit-challenger call
   (including reruns) are fresh, not resumed; see the elevated-assurance
   paragraph below. If node 6 had to use its fresh
   REFACTOR fallback, `--resume-last` now targets that replacement thread;
   the first CRITIQUE after the fallback must also carry the required inline
   continuity summary described there:
   ```
   # First CRITIQUE of the cycle (fresh thread):
   Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review
   the current implementation of [feature] against PROJECT_CONTEXT.md.
   Challenge the approach, design choices, and assumptions — don't just list
   defects. Read-only: do not fix anything, just report findings.")

   # Every subsequent CRITIQUE call in the same cycle:
   Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review
   the current implementation of [feature] against PROJECT_CONTEXT.md,
   considering the prior findings, triage decisions, and any VERIFY failure
   supplied with this request.
   Continuity summary if the fresh REFACTOR fallback was used: [concise
   relevant prior findings, triage decisions, and constraints].
   Challenge the approach, design choices, and assumptions — don't just list
   defects.
   Read-only: do not fix anything, just report findings. --resume-last")

   # Review-only CRITIQUE (single fresh read-only thread):
   Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review
   [scope] directly, applying these user-supplied criteria if any: [criteria].
   Do not require or assume a PROJECT_CONTEXT.md contract exists.
   Challenge the approach, design choices, and assumptions — don't just list
   defects. Read-only: do not fix anything, just report findings.")

   # Refactor-only, first CRITIQUE (fresh thread, no SPEC contract exists):
   Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review
   [scope] as it currently exists on disk, applying these user-supplied
   criteria if any: [criteria]. PROJECT_CONTEXT.md's QUALITY GATE metadata is
   not a functional contract for this feature — do not require or assume one
   exists; judge the code against its own apparent intent and against the
   criteria given. Challenge the approach, design choices, and assumptions —
   don't just list defects. Read-only: do not fix anything, just report
   findings.")

   # Refactor-only, every subsequent CRITIQUE (same continuity rules as the
   # full 8-node write cycle — --resume-last, plus the fresh-fallback
   # continuity summary if node 6 had to use it):
   Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review
   [scope] again now that the previously agreed fixes have been applied,
   considering the prior findings and triage decisions.
   Continuity summary if the fresh REFACTOR fallback was used: [concise
   relevant prior findings, triage decisions, and constraints].
   Challenge the approach, design choices, and assumptions — don't just list
   defects. Read-only: do not fix anything, just report findings.
   --resume-last")
   ```
   Return the findings verbatim first, without summarizing.

   **Backend dispatch.** The invocations and `--resume-last` rules above are
   the unchanged default `codex` path. For `claude`,
   `claude:<account-alias>`, or `claude-writer:<account-alias>`, follow
   `references/backend-selection.md` in full for reviewer selection, manual
   continuity, the exact strength of the read-only guarantee, and the mandatory
   before/after artifact-identity digest around every non-Codex reviewer call;
   do not inline alternate prompt families here. Every backend must preserve
   the adversarial scope, return findings before Claude triages them, and leave
   valid/debatable/false-positive arbitration to node 5. A non-Codex review
   must never be narrated as independent or cross-model review.

   **Elevated assurance (opt-in variant).** On the default Codex path, when
   `### Critique assurance` in
   `PROJECT_CONTEXT.md` (or, in review-only, the user's explicit request)
   resolves to `mode: elevated`, the first CRITIQUE traversal of the cycle
   uses 3 fresh independent lenses plus a fresh canonicalization call instead
   of the single fresh-thread call above, and a fresh "exit challenger" call
   gates entry to VERIFY (or DONE in refactor-only) — rerun fresh after any
   REFACTOR the exit challenger itself triggers, until one pass finds no
   valid findings against the then-current artifact; see the pass-accounting
   note under Anti-loop cutoff. Every later resumed Codex round in elevated
   mode still uses `--resume-last` exactly as standard mode does. All
   canonicalization-call, canonical-thread, `--resume-last`, and Codex-call-
   budget mechanics in this paragraph apply only to the default `codex` path.
   The same-session `claude` and cross-session-writer
   `claude-writer:<account-alias>` backends instead use 3 fresh parallel
   `Explore` lenses, Claude-maintained continuity, and Claude's own
   canonicalization, with no separate canonicalization call, canonical thread,
   `--resume-last`, or Codex-call budget consumed; `claude:<account-alias>` is
   incompatible with elevated assurance. Follow
   `references/backend-selection.md` for those rules.
   This is not a separate node — it is entirely a node 4 variant. On the
   default `codex` path, follow `references/elevated-assurance.md` in full
   before running it; it defines the Codex lens prompts, the mandatory fan-in
   barrier (required specifically because the pinned plugin resolves
   `--resume-last` by newest `updatedAt` with no resume-by-thread-ID), the
   late-lens recovery rule, the normalized finding record, and the budgets.
   For `backend: claude` or `claude-writer:<account-alias>`, follow
   `references/backend-selection.md`'s replacement mechanics instead: 3
   parallel fresh `Explore` lenses, Claude's own canonicalization, and no
   canonical thread, `--resume-last`, or Codex budget.
   In write-authorized modes, do not activate
   elevated mode without a persisted `### Critique assurance` resolution of
   `mode: elevated`. In review-only, require the user's explicit request to be
   recorded in the prompt, the Claude turn, and the final report.

   **On the default Codex path, read-only is enforced, not just requested.**
   CRITIQUE's read-only
   behavior isn't a soft prompt instruction Codex could ignore — the
   underlying `codex-companion.mjs` script sets
   `sandbox: request.write ? "workspace-write" : "read-only"`. As long as the
   CRITIQUE invocation never includes `--write`, the sandbox itself blocks
   file edits at the OS/process level. This is a real guarantee for CRITIQUE
   calls specifically; it says nothing about IMPL or REFACTOR, which
   deliberately do pass `--write`.

5. **DEBATE / TRIAGE** (Claude, read-only, cheap) — Classify each finding:
   - **Valid** → goes to node 6 as-is.
   - **Debatable** → reinjected to the selected reviewer with the explicit
     counterargument ("The reviewer flagged X, but Y because Z — do you stand
     by it or reconsider?"). On the default Codex path, always use
     `codex:codex-rescue` with `--resume-last` and never `--write`, so the
     reinjection stays on the same thread instead of becoming the "latest"
     session that a later REFACTOR's `--resume-last` might mistakenly resume.
     Non-Codex backends use the continuity mechanism in
     `references/backend-selection.md`. Await the reply before deciding.
   - **False positive** → discarded, with one line of written justification
     (never silent acceptance or silent rejection).
   Without this step, the selected reviewer effectively self-reviews its
   backend's work with no filter, and the cycle can oscillate or apply
   unnecessary changes — DEBATE is what prevents an unarbitrated self-fix loop.

   **Elevated assurance fan-in.** When node 4 ran in elevated mode, first
   normalize the 3 lenses' reports into one finding record per underlying
   claim (see `references/elevated-assurance.md` for the exact fields) before
   applying the three classifications above. Corroboration across lenses
   (`corroboration_count`) is recorded as metadata only — it never becomes a
   fourth verdict, never makes a single-lens finding invalid by default, and
   never makes multi-lens agreement sufficient by itself without evidence.
   Batch all `debatable` records from one pass into a single reinjection call
   using stable finding IDs, rather than one round-trip per duplicate report.

   That routing applies only to write-authorized cycles. In review-only mode,
   all classified findings—valid, debatable (including the resolved
   counterargument), and false-positive—go into the final report. The flow
   terminates after DEBATE/report and no finding routes to node 6 REFACTOR,
   because review-only never authorizes a write.

   **The orchestrating Claude may read, never edit, implementation files
   during triage.** "The orchestrating Claude never edits implementation
   files" (see intro) is about Edit/Write, not about Read/Grep. Before ruling
   a finding valid or false-positive —
   especially before writing a false-positive justification — Claude should
   Read/Grep the specific lines or files the finding references to verify
   the claim rather than triage blind. This is cheap (a handful of lines,
   not the whole file) and is the main defense against rubber-stamping a
   false-positive call that turns out to be real, or dismissing a valid
   finding on a misreading.

   **Escalate security-sensitive reading depth.** If a finding touches auth,
   crypto, payments, credential handling, database queries, or migrations,
   Read the full related file—not only the referenced lines—before ruling on
   it. Remain read-only: this expands evidence collection, never Claude's
   authority to edit implementation files.

   **Known limitation — same-model self-preference bias.** On the default
   `codex` path, CRITIQUE and IMPL both run on Codex, the same underlying
   model. That means CRITIQUE is not a fully independent adversarial reviewer
   — it inherits whatever blind spots or self-preference bias the model has
   about its own prior output. There is no structural fix for this within a
   single-plugin design; the targeted Read/Grep verification above is a
   mitigation, not a cure. Do not present CRITIQUE's findings as independent
   verification — they are a second pass by the same model, arbitrated by
   Claude. Elevated assurance's 3 lenses (`references/elevated-assurance.md`)
   reduce single-thread anchoring and add angle diversity, but on that path
   they are still the same underlying Codex model — do not present N-lens
   agreement as independent verification either. Every non-Codex backend has
   the different, already-disclosed same-Claude-model limitation documented
   in `references/backend-selection.md`.

6. **REFACTOR** (selected backend fixes; Codex by default) —
   ```
   Agent(subagent_type: "codex:codex-rescue", prompt: "Apply the following
   agreed fixes: [triaged list]. --resume-last --write")
   ```

   **Backend dispatch.** The invocation and recovery protocol below are the
   unchanged default `codex` path. For `claude`,
   `claude:<account-alias>`, or `claude-writer:<account-alias>`, dispatch the
   selected writer and carry forward triage continuity exactly as
   `references/backend-selection.md` specifies; do not inline alternate prompt
   families here. The selected writer applies
   only the agreed fixes, and every backend returns to node 3 before another
   CRITIQUE.

   A Codex session created read-only may not upgrade to write access through
   `--resume-last --write`. If the sandbox rejects that transition, confirm
   that no changes landed, then start a **fresh, non-resumed session with
   `--write` from the beginning**. Do not keep retrying the read-only resume.
   The observed failure mode was a sandbox-permission rejection.

   `git diff --check` only detects whitespace/conflict-marker errors — it
   does not prove the tree is unchanged, and a rejected write can still leave
   a partial mutation behind. Before the resumed attempt, capture
   `git status --porcelain=v1 -uall`, `git diff HEAD --binary`, and the same
   NUL-safe content-hash manifest of initially-untracked paths used for
   QUALITY GATE side-effect detection. After the rejection, compare against
   that snapshot. Only start the fresh session if the snapshots match
   exactly; any delta, or any inability to prove equality, is an escalation
   condition, not a silent continue.

   Before starting that fresh session, build a concise continuity summary
   from the current feature's `PROJECT_CONTEXT.md` section and the
   conversation: the relevant prior findings, Claude's triage decisions, and
   any still-applicable constraints. Include that summary inline in the fresh
   REFACTOR prompt alongside the agreed fixes. Because this session becomes
   the new latest thread, the next CRITIQUE must both use `--resume-last` and
   repeat an updated concise inline continuity summary in its prompt. These
   are required fallback steps, not optional context; the thread switch must
   not silently discard the adversarial history.

   Every REFACTOR write returns to node 3 before CRITIQUE. A REFACTOR entered
   from DEBATE starts a new QUALITY GATE activation; a REFACTOR invocation
   made specifically to fix a QUALITY GATE failure remains in the same
   activation and shares its existing counter.

   **Elevated assurance continuity.** On the default `codex` path, after node
   4's canonicalization call or after the exit challenger runs, that call
   becomes the new latest/canonical thread. If a REFACTOR follows either of
   those without an intervening ordinary `--resume-last` CRITIQUE round, build
   the same kind of concise inline continuity summary described above for the
   fresh-fallback case — the canonical/exit thread did not see every prior
   lens finding — and include it in the REFACTOR prompt. `backend: claude` and
   `claude-writer:<account-alias>` instead use 3 parallel fresh `Explore`
   lenses and Claude's own canonicalization, with no separate canonicalization
   call, canonical thread, `--resume-last`, or Codex-call budget consumed;
   follow `references/backend-selection.md` rather than applying this Codex
   continuity paragraph to those backends.

7. **VERIFY** (Claude, judgment required) — Run functional tests and evaluate
   the acceptance criteria only after DEBATE has no valid findings awaiting
   REFACTOR. Keep lint, formatting, type checking, and build in QUALITY GATE.

   In elevated mode, do not enter VERIFY until the **most recent** exit
   challenger pass (see `references/elevated-assurance.md`) reported no
   valid findings against the artifact currently about to enter VERIFY. If
   an exit challenger's findings went through REFACTOR, that changed the
   artifact the exit challenger approved — route back to node 4 for another
   fresh exit challenger pass instead of proceeding to VERIFY on the strength
   of the earlier pass. Refactor-only has no VERIFY node; the same gate
   applies to entering DONE instead.

   If VERIFY executes its assertions and fails, always return to node 4, then
   instruct CRITIQUE to classify the root cause as exactly one of:
   **implementation-defect / test-defect / contract-mismatch /
   environmental**. Do not tell the selected backend to "just make the test
   pass." Continue through DEBATE and REFACTOR only after that judgment. Never
   route a VERIFY failure through the fast QUALITY GATE fixer.

   If VERIFY cannot execute its assertions at all because of an environmental
   block, escalate directly to the user—take neither the QUALITY GATE fixer
   path nor the CRITIQUE path.

   If the only project command bundles mechanical checks and functional tests,
   do not run the bundle as QUALITY GATE. Resolve an isolated fast mechanical
   subcommand or ask the user explicitly how to split it, so a functional test
   failure cannot enter the mechanical retry route.

### Anti-loop cutoff

The cutoff fires when, across two consecutive CRITIQUE passes, **Claude
judges a finding to be the same underlying complaint restated** — a semantic
judgment Claude makes by reading both findings, not a literal string or diff
match — **and** no net code change addressed it in between. When that
happens, **stop and escalate to the user** instead of continuing to iterate.
Never fabricate a false resolution just to exit the loop.

On the default `codex` path, CRITIQUE is stateful via `--resume-last` (see
node 4), so Codex itself should rarely repeat a finding it already discussed
— but "rarely" is not "never." `backend: claude` and
`claude-writer:<account-alias>` instead use fresh `Explore` reviewers with
Claude-maintained continuity and no `--resume-last`;
`claude:<account-alias>` uses its retained target session. Under every backend,
this judgment call must still be made by Claude on every loop-back to node 4,
not assumed away.

**Elevated-assurance pass accounting.** A CRITIQUE pass is one completed
traversal of node 4 that produces one normalized finding set for node 5. On
the default `codex` path, the initial 3 fresh lens calls, Claude's fan-in, and
the fresh canonicalization call together count as **one** CRITIQUE pass, not
four. Each later resumed canonical review counts as one pass, and each fresh
exit challenger pass counts as one additional CRITIQUE pass — there may be
more than one if an exit challenger's own findings go through REFACTOR and
require a re-run (see `references/elevated-assurance.md`). Separately from
pass accounting on that path, every Codex task invocation — each lens,
canonicalization, resumed review, exit challenger, and DEBATE reinjection —
consumes one unit of the persisted elevated-assurance model-call budget (see
`references/elevated-assurance.md` for the derived floor and the adjustable
default ceiling). Budget exhaustion is an escalation condition; it is never
permission to skip a required lens, canonicalization, or exit challenge.

For `backend: claude` and `claude-writer:<account-alias>`, the 3 parallel fresh
`Explore` lenses, Claude's fan-in, and Claude's own canonicalization together
count as the initial CRITIQUE pass. Each later fresh `Explore` review and each
fresh exit challenger counts as one additional pass. Those backends have no
separate canonicalization call, canonical thread, `--resume-last`, or
persisted Codex model-call budget, and consume no Codex budget; follow
`references/backend-selection.md` for their continuity and self-
canonicalization protocol. Under any compatible backend, DEBATE reinjections
stay inside node 5 and do not create CRITIQUE passes. Apply the two-pass
anti-loop comparison only to the normalized finding
sets emitted by consecutive passes; duplicate lens reports inside one pass can
neither trigger nor satisfy the cutoff.

**Reconciling with the iteration cap in `references/goal-templates.md`:**
this 2-round cutoff is this skill's own hard floor — it applies regardless
of any iteration count a user's `/goal` text specifies (templates commonly
suggest 3 as a soft recommendation). Whichever limit is hit first wins: if
the anti-loop cutoff fires at round 2, it stops the cycle even if the user's
`/goal` said "cap of 3." If the user's cap is 1, that stops it before the
anti-loop cutoff would ever trigger.

**This cutoff cannot unilaterally override `/goal`'s literal contract.**
`/goal` holds the turn open until its stated condition is true. If the
user's `/goal` text does not include an explicit escalation/stop clause
(the templates in `references/goal-templates.md` recommend one, but a user
can write a `/goal` without it), Claude remains bound by `/goal`'s literal
"keep working until true" instruction and cannot stop the turn on its own
authority just because the anti-loop cutoff fired internally — it can flag
the repeated finding to the user, but ending the turn early would violate
the `/goal` contract. Treat the anti-loop cutoff as a signal that must be
routed through the `/goal` condition, not a standalone override. Do not
claim this is an unconditional guarantee that the loop will stop.

## Sustaining the cycle with `/goal`

`/goal` is a Claude Code built-in — a stop-gate that evaluates a condition
before letting the turn end ("Set a goal — keep working until the condition
is met"). Use it to automate the cycle without per-turn intervention. See
`references/goal-templates.md` for ready-to-use templates per scenario (with
tests, without tests, refactor-only, review-only, and a single-message
variant).

## Risks

- **Writer edits are destructive**: the selected writer edits files directly;
  on the default `codex` path, that authority is requested with `--write`.
  Always run on a branch with a clean working tree, never on `main` with
  uncommitted changes.
- Codex's own cost is billed through the user's OpenAI account, not Claude
  tokens — this skill saves Claude's context/tokens, not total cost.
- A read-only Codex session may reject a resumed write request; recover with a
  fresh session that has `--write` from the start, as described under
  REFACTOR.
- `PROJECT_CONTEXT.md` is per-repo, not global; never write to the user's
  global Claude Code instructions file.
- **A checkpoint commit is not an approval.** The `Cycle-State: CHECKPOINT`
  commits described under QUALITY GATE only prove the tree passed mechanical
  checks — never that CRITIQUE or VERIFY have signed off. Treat every one as
  a restore point to revert to if a later round goes wrong, not as evidence
  the feature is done; a real run that tagged an intermediate round
  `COMPLETE` needed five more REFACTOR rounds after it.
- On the default `codex` path, elevated assurance
  (`references/elevated-assurance.md`) is opt-in and its call floors sit far
  above standard mode's (see Selecting a mode). A clean **elevated** run of
  the full 8-node write cycle costs at least 5 Codex
  review calls — 3 lenses, canonicalization, and the exit challenger — or 6
  Codex calls total counting IMPL; clean elevated refactor-only costs 5 total,
  and clean elevated review-only costs 4 total (3 lenses + canonicalization)
  because it has neither IMPL nor an exit challenger. Every number in this
  bullet describes elevated mode alone; the standard floors are 1 to 2. It
  also consumes extra Claude context during fan-in — it
  undercuts the token-savings motivation above if treated as a default rather
  than a risk-triggered exception. On that path, its N lenses share the same
  underlying Codex model and are not independent verification, and getting
  its fan-in barrier ordering wrong can misdirect `--resume-last` to the wrong
  thread. `backend: claude` and `claude-writer:<account-alias>` have neither
  that Codex-call floor nor that `--resume-last` fan-in risk; follow
  `references/backend-selection.md` for their different limitations. Elevated
  assurance must never activate without explicit user authorization on any
  compatible backend.
