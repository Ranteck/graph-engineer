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

## The cycle (6 nodes)

Create one todo per node before starting.

1. **SPEC** (Claude, cheap) — Write the component's contract into
   `PROJECT_CONTEXT.md` in the active repo (create it if missing): what it
   does, interfaces, inputs/outputs, constraints. This is the only write
   Claude performs in the entire cycle.

2. **IMPL** (Codex writes) —
   ```
   Agent(subagent_type: "codex:codex-rescue", prompt: "Implement [feature]
   following the contract in PROJECT_CONTEXT.md. --write")
   ```

3. **CRITIQUE** (Codex critiques, adversarially, no writes) —
   ```
   Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review
   the current implementation of [feature] against PROJECT_CONTEXT.md.
   Challenge the approach, design choices, and assumptions — don't just list
   defects. Read-only: do not fix anything, just report findings.")
   ```
   Return the findings verbatim first, without summarizing.

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

If two consecutive iterations of node 3 return the same finding with no net
change to the file (identical diff or a textually repeated finding), **stop
and escalate to the user** instead of continuing to iterate. Never fabricate
a false resolution just to exit the loop.

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
