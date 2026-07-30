---
name: graph-engineer
description: >-
  Orchestrates a Claude↔Codex cycle where Claude Code designs the contract and arbitrates, while Codex (via the official openai/codex-plugin-cc plugin) writes, adversarially reviews, and fixes the code — Claude never edits implementation files. Use when the user asks to "implement with Codex", "have Codex review and fix", "peer review with Codex", "graph engineering", "orchestrator-workers with Codex", or wants an autonomous Claude+Codex implement→review→debate→refactor loop. (ES triggers: "implementar con Codex", "que Codex revise y corrija", "peer review con Codex", "graph engineering", "orchestrator-workers con Codex")
---

# Graph Engineer

An **Evaluator-Optimizer** cycle (an official Anthropic pattern, see
`references/sources.md`) nested inside an **Orchestrator-Workers** pattern:
the user is the orchestrator, Claude is the sub-orchestrator, and Codex is
both the worker that implements and the evaluator that critiques. The hard
rule across the whole flow: **Claude never edits implementation files** with
Edit/Write — only Codex does, via the `codex:codex-rescue` subagent. That is
what keeps the writer and arbiter roles explicit.

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

The official OpenAI Codex plugin for Claude Code must be installed and
authenticated: [openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc).

```
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/codex:setup
```

`/codex:setup` should report `Status: ready`. If it doesn't, stop and tell the
user to fix their Codex setup — this skill doesn't try to diagnose plugin
installation problems.

**Tested against `openai-codex` plugin v1.0.6.** The routing assumptions in
this skill (single `codex:codex-rescue` entry point, `--write`/`--resume-last`
flag behavior, the sandbox enforcement described under CRITIQUE below) were
verified against that version. A future plugin update that changes the
command surface or flag semantics could silently break these assumptions —
if the cycle starts behaving unexpectedly, check the installed plugin
version first.

## Single entry point: `codex:codex-rescue`

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

Treat QUALITY GATE as a numbered invariant checkpoint, not a new actor or a
fixed independent pipeline stage. Attach it as a capped retry edge to the
writer node—IMPL or REFACTOR—that most recently changed the tree. Enforce:
**no CRITIQUE call may run on a tree that has not passed QUALITY GATE since
the last write, or for which a currently-valid persisted user-confirmed
opt-out exists.**

0. **PRE-FLIGHT** (Claude, cheap) — At cycle entry, before PRE-FLIGHT makes
   its own `PROJECT_CONTEXT.md` write and before node 2 (IMPL) is ever allowed
   to run, verify `git status` is clean and the repo is on a non-`main`
   branch. Here, "clean" means free of unrelated or pre-existing uncommitted
   work at cycle entry; it does not prohibit this cycle's deliberate context
   writes after the check. If either entry check fails, **abort with a clear
   message to the user** instead of proceeding — do not let Codex's `--write`
   calls land on top of existing uncommitted work or directly on `main`. This
   is what makes the "always enter on a branch with a clean working tree"
   rule under Risks an enforced check instead of a hope.

   Also resolve the current feature's QUALITY GATE before IMPL. Read and
   follow `references/quality-gate-detection.md`; it is part of this node,
   not optional background. Resolve in this order: a still-valid resolution
   already persisted for this feature; a safe local wrapper invoked by the
   project's own PR/push CI; a command documented in contributing/dev docs;
   a project-defined aggregator; then a bare ecosystem convention as a
   candidate only. Never hardcode a command from another project.

   Autoselect only one unambiguous, high-confidence, locally executable CI
   wrapper that satisfies every safety condition in the reference. Otherwise
   ask the user once and persist the answer. Persist the **resolution, not a
   prior result**, under `### Quality gate` inside this feature's
   `PROJECT_CONTEXT.md` section; revalidate it cheaply after each write
   instead of redetecting it. If no usable candidate or explicit opt-out
   exists, stop before IMPL. In autonomous `/goal` runs, treat this as an
   escalation condition, never a silent skip. `PROJECT_CONTEXT.md` is
   Claude's only writable artifact across the whole cycle: PRE-FLIGHT writes
   this QUALITY GATE resolution metadata there, while SPEC writes the feature
   contract there. Claude never edits implementation files.

   Between the successful cycle-entry clean check and IMPL starting, the only
   expected tree changes are this cycle's own namespaced QUALITY GATE
   resolution and feature contract in `PROJECT_CONTEXT.md`. Recheck that
   narrow window before IMPL and abort if any other path or unrelated delta
   appears.

1. **SPEC** (Claude, cheap) — Write the component's contract into
   `PROJECT_CONTEXT.md` in the active repo (create it if missing): what it
   does, interfaces, inputs/outputs, constraints. `PROJECT_CONTEXT.md` is
   Claude's only writable artifact across the entire cycle: PRE-FLIGHT writes
   the `### Quality gate` resolution metadata there, and SPEC writes the
   feature contract there. Claude never edits implementation files.

   **Namespace by feature.** `PROJECT_CONTEXT.md` is shared across every
   cycle run in a repo, so each feature's contract must live under its own
   heading, e.g. `## <feature-name>`. A given cycle run is scoped only to
   its own section — Claude and Codex should read and write only the
   section matching the current feature, never edit or reason over another
   feature's section. This avoids one cycle's contract silently
   contaminating or being contaminated by an unrelated feature's contract
   in the same file.

2. **IMPL** (Codex writes) —
   ```
   Agent(subagent_type: "codex:codex-rescue", prompt: "Implement [feature]
   following the contract in PROJECT_CONTEXT.md. --write")
   ```

3. **QUALITY GATE** (Claude runs mechanical checks; Codex fixes) — Revalidate
   the cached resolution, snapshot both `git status --porcelain=v1 -uall` and
   `git diff HEAD --binary`, then run the resolved command with the exact cwd
   and a timeout. QUALITY GATE contains only mechanical checks such as lint,
   formatting, type checking, and build. It does not own functional tests or
   acceptance criteria.

   When the currently-valid persisted resolution has `command: skipped`,
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

4. **CRITIQUE** (Codex critiques, adversarially, no writes) — The first
   CRITIQUE call in a cycle starts a fresh thread. Every CRITIQUE call after
   that—including one reached from a VERIFY failure—must pass
   `--resume-last`, so Codex retains memory of its own prior findings and of
   Claude's prior triage decisions, instead of restating findings that were
   already ruled debatable or false-positive. If node 6 had to use its fresh
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
   ```
   Return the findings verbatim first, without summarizing.

   **Read-only is enforced, not just requested.** CRITIQUE's read-only
   behavior isn't a soft prompt instruction Codex could ignore — the
   underlying `codex-companion.mjs` script sets
   `sandbox: request.write ? "workspace-write" : "read-only"`. As long as the
   CRITIQUE invocation never includes `--write`, the sandbox itself blocks
   file edits at the OS/process level. This is a real guarantee for CRITIQUE
   calls specifically; it says nothing about IMPL or REFACTOR, which
   deliberately do pass `--write`.

5. **DEBATE / TRIAGE** (Claude, read-only, cheap) — Classify each finding:
   - **Valid** → goes to node 6 as-is.
   - **Debatable** → reinjected to `codex:codex-rescue` with the explicit
     counterargument ("Codex flagged X, but Y because Z — do you stand by it
     or reconsider?") and its reply is awaited before deciding.
   - **False positive** → discarded, with one line of written justification
     (never silent acceptance or silent rejection).
   Without this step Codex self-reviews with no filter, and the cycle can
   oscillate or apply unnecessary changes — this is what distinguishes it
   from "Codex fixing itself" with no oversight.

   **Claude may read, never edit, implementation files during triage.**
   "Claude never edits implementation files" (see intro) is about Edit/Write,
   not about Read/Grep. Before ruling a finding valid or false-positive —
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

   **Known limitation — same-model self-preference bias.** CRITIQUE and IMPL
   both run on Codex, the same underlying model. That means CRITIQUE is not
   a fully independent adversarial reviewer — it inherits whatever blind
   spots or self-preference bias the model has about its own prior output.
   There is no structural fix for this within a single-plugin design; the
   targeted Read/Grep verification above is a mitigation, not a cure. Do not
   present CRITIQUE's findings as independent verification — they are a
   second pass by the same model, arbitrated by Claude.

6. **REFACTOR** (Codex fixes) —
   ```
   Agent(subagent_type: "codex:codex-rescue", prompt: "Apply the following
   agreed fixes: [triaged list]. --resume-last --write")
   ```

   A Codex session created read-only may not upgrade to write access through
   `--resume-last --write`. If the sandbox rejects that transition, confirm
   that no changes landed, then start a **fresh, non-resumed session with
   `--write` from the beginning**. Do not keep retrying the read-only resume.
   The observed failure mode was a sandbox-permission rejection followed by
   `git diff --check` confirming no changes.

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

7. **VERIFY** (Claude, judgment required) — Run functional tests and evaluate
   the acceptance criteria only after DEBATE has no valid findings awaiting
   REFACTOR. Keep lint, formatting, type checking, and build in QUALITY GATE.

   If VERIFY executes its assertions and fails, always return to node 4, then
   instruct CRITIQUE to classify the root cause as exactly one of:
   **implementation-defect / test-defect / contract-mismatch /
   environmental**. Do not tell Codex to "just make the test pass." Continue
   through DEBATE and REFACTOR only after that judgment. Never route a VERIFY
   failure through the fast QUALITY GATE fixer.

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

Because CRITIQUE is now stateful via `--resume-last` (see node 4), Codex
itself should rarely repeat a finding it already discussed — but "rarely"
is not "never," so this judgment call must still be made by Claude on every
loop-back to node 4, not assumed away.

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

- **`--write` is destructive**: Codex edits files directly. Always run on a
  branch with a clean working tree, never on `main` with uncommitted changes.
- Codex's own cost is billed through the user's OpenAI account, not Claude
  tokens — this skill saves Claude's context/tokens, not total cost.
- A read-only Codex session may reject a resumed write request; recover with a
  fresh session that has `--write` from the start, as described under
  REFACTOR.
- `PROJECT_CONTEXT.md` is per-repo, not global; never write to the user's
  global Claude Code instructions file.
