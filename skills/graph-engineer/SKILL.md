---
name: graph-engineer
description: Orchestrates a Claude↔Codex cycle where Claude Code designs the contract and arbitrates, while Codex (via the official openai/codex-plugin-cc plugin) writes, adversarially reviews, and fixes the code — Claude never edits implementation files. Use when the user asks to "implement with Codex", "have Codex review and fix", "peer review with Codex", "graph engineering", "orchestrator-workers with Codex", or wants an autonomous Claude+Codex implement→review→debate→refactor loop. (ES triggers: "implementar con Codex", "que Codex revise y corrija", "peer review con Codex", "graph engineering", "orchestrator-workers con Codex")
---

# Graph Engineer

An **Evaluator-Optimizer** cycle (an official Anthropic pattern, see
`references/sources.md`) nested inside an **Orchestrator-Workers** pattern:
the user is the orchestrator, Claude is the sub-orchestrator, and Codex is
both the worker that implements and the evaluator that critiques. The hard
rule across the whole flow: **Claude never edits implementation files** with
Edit/Write — only Codex does, via the `codex:codex-rescue` subagent. That is
what keeps Claude's own context/token usage low, which is the point of this
skill.

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

## The cycle (7 nodes)

Create one todo per node before starting.

0. **PRE-FLIGHT** (Claude, cheap) — Before node 2 (IMPL) is ever allowed to
   run, verify `git status` is clean and the repo is on a non-`main` branch.
   If either check fails, **abort with a clear message to the user** instead
   of proceeding — do not let Codex's `--write` calls land uncommitted work
   or land directly on `main`. This is what makes the "always run on a
   branch with a clean working tree" rule under Risks an enforced check
   instead of a hope.

1. **SPEC** (Claude, cheap) — Write the component's contract into
   `PROJECT_CONTEXT.md` in the active repo (create it if missing): what it
   does, interfaces, inputs/outputs, constraints. This is the only write
   Claude performs in the entire cycle.

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

3. **CRITIQUE** (Codex critiques, adversarially, no writes) — The first
   CRITIQUE call in a cycle starts a fresh thread. Every CRITIQUE call after
   that (i.e. after a REFACTOR has run at least once) must pass
   `--resume-last`, so Codex retains memory of its own prior findings and of
   Claude's prior triage decisions, instead of restating findings that were
   already ruled debatable or false-positive:
   ```
   # First CRITIQUE of the cycle (fresh thread):
   Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review
   the current implementation of [feature] against PROJECT_CONTEXT.md.
   Challenge the approach, design choices, and assumptions — don't just list
   defects. Read-only: do not fix anything, just report findings.")

   # Every subsequent CRITIQUE call in the same cycle (after a REFACTOR):
   Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review
   the current implementation of [feature] against PROJECT_CONTEXT.md, now
   that the previously agreed fixes have been applied. Challenge the
   approach, design choices, and assumptions — don't just list defects.
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

4. **DEBATE / TRIAGE** (Claude, read-only, cheap) — Classify each finding:
   - **Valid** → goes to node 5 as-is.
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

   **Known limitation — same-model self-preference bias.** CRITIQUE and IMPL
   both run on Codex, the same underlying model. That means CRITIQUE is not
   a fully independent adversarial reviewer — it inherits whatever blind
   spots or self-preference bias the model has about its own prior output.
   There is no structural fix for this within a single-plugin design; the
   targeted Read/Grep verification above is a mitigation, not a cure. Do not
   present CRITIQUE's findings as independent verification — they are a
   second pass by the same model, arbitrated by Claude.

5. **REFACTOR** (Codex fixes) —
   ```
   Agent(subagent_type: "codex:codex-rescue", prompt: "Apply the following
   agreed fixes: [triaged list]. --resume-last --write")
   ```

6. **VERIFY** (Claude, cheap) — Run the project's test suite. If it fails, or
   node 4 left valid findings unresolved, go back to node 3 — the critique now
   runs again over the code Codex just fixed. This return edge is what makes
   it a cycle instead of a one-pass pipeline.

### Anti-loop cutoff

The cutoff fires when, across two consecutive CRITIQUE passes, **Claude
judges a finding to be the same underlying complaint restated** — a semantic
judgment Claude makes by reading both findings, not a literal string or diff
match — **and** no net code change addressed it in between. When that
happens, **stop and escalate to the user** instead of continuing to iterate.
Never fabricate a false resolution just to exit the loop.

Because CRITIQUE is now stateful via `--resume-last` (see node 3), Codex
itself should rarely repeat a finding it already discussed — but "rarely"
is not "never," so this judgment call must still be made by Claude on every
loop-back to node 3, not assumed away.

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
- `PROJECT_CONTEXT.md` is per-repo, not global; never write to the user's
  global Claude Code instructions file.
