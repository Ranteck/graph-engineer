# graph-engineer

A Claude Code skill for a common problem: you want a second model (Codex) to
do the actual coding — so Claude's own context stays cheap — but you don't
want Codex grading its own homework. `graph-engineer` makes Claude the
orchestrator and arbiter, and Codex the one who writes, adversarially
reviews, and fixes the code, running as a self-correcting loop instead of a
single implement-and-hope pass.

## What is "graph engineering"?

Not an official term — no Anthropic or OpenAI product is called that. It's
useful as a mental model anyway: think of the workflow as a small graph.

- **Nodes** are units of work: Claude writing a spec, Codex implementing,
  Codex critiquing, Claude triaging.
- **Edges** are handoffs between them: spec → implementation → critique →
  triage → fix.

What makes it a *graph* instead of a *list* is one specific edge: **VERIFY
loops back to CRITIQUE**. That return edge is what lets the same critique
step run again, and again, over code that's already been through one round
of fixes — until a stop condition is actually met. Take that edge out and
you just have a pipeline: write once, review once, done, bugs and all.

This skill is a concrete implementation of two patterns Anthropic *does*
document officially — **Orchestrator-Workers** and **Evaluator-Optimizer**,
from
[Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents)
— nested together. See
[`skills/graph-engineer/references/sources.md`](skills/graph-engineer/references/sources.md)
for exactly what's official versus what "graph engineering" gets credited
with online but isn't.

## It's a loop, not a pipeline

The cycle doesn't stop after one implement→review→fix pass. Every time Codex
fixes something, the critique step runs again on the *new* code — because a
fix can introduce its own problems, and because a first pass rarely catches
everything. The loop keeps going until a condition you define is verifiably
true: usually "no valid findings left, and tests pass."

Two brakes are meant to keep this from running forever, but the second one
is conditional, not automatic:

- **A `/goal` stop condition** (see [Usage](#usage)) — Claude Code's built-in
  stop-gate, which holds the turn open until the condition is met.
- **An anti-loop cutoff** — if, across two rounds in a row, Claude judges a
  CRITIQUE finding to be the same underlying complaint restated with no real
  change to the code, the cycle is meant to stop and escalate to you instead
  of spinning. But `/goal` binds Claude to its literal condition: this
  cutoff can only actually end the turn early if your `/goal` text itself
  includes an explicit escalation/stop clause (the templates in
  `references/goal-templates.md` include one — make sure yours does too).
  Without that clause, Claude remains bound by "keep working until true" and
  will surface the repeated finding rather than unilaterally stopping. Don't
  rely on this as an unconditional guarantee.

## The cycle

```
[1 SPEC]      Claude writes the contract to PROJECT_CONTEXT.md   (cheap, Claude only)
      ↓
[2 IMPL]      Agent → codex:codex-rescue --write                 (Codex writes)
      ↓
[3 CRITIQUE]  Agent → codex:codex-rescue (read-only, adversarial) (Codex critiques)
      ↓
[4 DEBATE]    Claude reads findings and TRIAGES them:             (read-only, cheap)
              · valid          → goes to refactor
              · debatable      → reinjected to Codex with a counterargument
              · false positive → discarded, with written justification
      ↓
[5 REFACTOR]  Agent → codex:codex-rescue --resume-last --write   (Codex fixes)
      ↓
[6 VERIFY]    Claude runs the project's tests                    (cheap)
      ↓
      └──────────── if it fails or valid findings remain ────────┘
                     back to [3] — this is the loop edge
```

Node 4 isn't a flat pass/fail filter — "debatable" findings open their own
small sub-loop, invisible in the 6-node diagram above:

```
[4 DEBATE]  finding classified as "debatable"
      ↓
      Claude reinjects it to codex:codex-rescue with a counterargument
      ("Codex flagged X, but Y because Z — do you stand by it or reconsider?")
      ↓
      Codex replies (still read-only — no --write in this call either)
      ↓
      Claude decides: valid → refactor, or false positive → discarded
      (with written justification either way)
```

This sub-loop happens entirely inside node 4, before anything reaches node
5 — it's an extra round-trip to Codex per debatable finding, not just a
triage checkbox.

## A worked example

You send one message:
```
implement a POST /api/webhooks/verify endpoint in src/routes/webhooks.ts
using Codex — Codex writes it, adversarially reviews its own work, and only
applies a fix once we've debated the finding.
```

1. **SPEC** — Claude writes the endpoint's contract (inputs, signature
   verification rule, response codes) to `PROJECT_CONTEXT.md`.
2. **IMPL** — Codex writes `webhooks.ts` following that contract.
3. **CRITIQUE** — Codex reviews its own code adversarially and reports, say,
   two findings: *"the signature comparison uses `===` instead of a
   constant-time compare — timing attack surface"* and *"the handler doesn't
   log request IDs"*.
4. **DEBATE** — Claude triages: the timing-attack finding is **valid**, goes
   to refactor. The logging one is judged a **false positive** for this repo
   (it has no logging convention anywhere else) — discarded, with that reason
   written down, not silently dropped.
5. **REFACTOR** — Codex swaps in a constant-time comparison.
6. **VERIFY** — Tests run green. CRITIQUE runs once more on the fixed code;
   no new findings. The `/goal` condition is met, the loop ends.

## Why

1. **Claude's context/tokens stay cheap — relative to doing the coding
   itself.** Only nodes 1, 4, and 6 involve Claude doing real work, and
   Claude never *edits* implementation code (Edit/Write) at any node — the
   expensive, code-writing work (nodes 2, 3, 5) runs entirely on Codex,
   billed through your OpenAI account instead of Claude usage. Node 4
   (DEBATE) is an exception to "Claude doesn't touch implementation code" in
   one narrow sense: Claude may *read* the specific lines/files a finding
   references, to verify the claim before ruling on it — reading a few
   lines to fact-check is cheap; editing is what's actually forbidden. Also
   note "cheap" is relative, not free in absolute terms: a cycle that loops
   many rounds accumulates CRITIQUE findings, triage notes, and prior
   context in Claude's own conversation across iterations, so a long-running
   loop is not free even though each individual node is lightweight.
2. **The debate node (4) prevents blind self-correction.** Without it, Codex
   critiques its own code and "fixes" it with no filter — findings get
   applied uncritically, and the loop can oscillate between two states
   forever. Triage forces every finding through valid/debatable/false-positive
   before anything gets refactored.

## Requirements

This skill needs the official OpenAI Codex plugin for Claude Code:
**[openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc)**.

```
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/codex:setup
```

`/codex:setup` should report `Status: ready`. Also needs
[Claude Code](https://claude.com/claude-code) itself, obviously.

**Tested against `openai-codex` plugin v1.0.6.** This skill's routing
assumptions (single `codex:codex-rescue` entry point, `--write` /
`--resume-last` flag behavior, sandbox enforcement of read-only CRITIQUE
calls) were verified against that version. A future plugin update could
change the command surface and silently break these assumptions.

## Installation

```bash
npx skills add <owner>/graph-engineer
```

Or manually:
```bash
cp -r skills/graph-engineer ~/.claude/skills/
```

## Usage

**Single message** (fastest — combines the task and the stop condition):
```
/goal Implement/review [what you want] in [file/folder or scope], code
written and fixed by Codex via graph-engineer (I don't edit anything
directly). Stop condition: [your verifiable criterion] AND no valid findings
remain from the adversarial-review (debatable ones get debated, not accepted
blindly). If the same error persists for 2 rounds in a row, stop and tell me
instead of continuing.
```

**Two messages** (recommended when the contract needs discussion first — you
get to review it before the goal locks in):
```
implement [feature] in [file/folder] using Codex — Codex writes the code,
adversarially self-reviews it, and only applies a fix once you've debated
the finding with it.
```
then, after reviewing the contract Claude writes to `PROJECT_CONTEXT.md`:
```
/goal [your verifiable stop condition]
```

More templates (with tests, without tests, refactor-only, review-only) in
[`skills/graph-engineer/references/goal-templates.md`](skills/graph-engineer/references/goal-templates.md).

## How it works

| Graph role | Piece | Invocation |
|---|---|---|
| Orchestrator | User + Claude Code session | — |
| Loop driver | `/goal <condition>` | built-in; `/goal clear` to reset |
| Worker (implements) | subagent `codex:codex-rescue` | `Agent` tool, `--write` |
| Evaluator (critiques) | same subagent, read-only | `Agent` tool, no `--write`, adversarial prompt |
| Fixer | same subagent, resumed | `Agent` tool, `--resume-last --write` |

Every Codex interaction goes through the single `codex:codex-rescue`
subagent — it's the only command in the plugin invocable directly by the
model (`/codex:review`, `/codex:adversarial-review`, `/codex:status`,
`/codex:result`, and `/codex:cancel` are typed-by-human-only). If you prefer
to run a review by hand instead of through the cycle, you can still type
`/codex:adversarial-review` yourself — it's just not what this skill
automates.

## Limitations / Risks

- **`--write` is destructive.** Codex edits files directly. Always run on a
  branch with a clean working tree, never on `main` with uncommitted changes.
- **Codex's cost is separate from Claude's.** This skill reduces Claude's
  context/token usage; Codex calls are billed through your own OpenAI
  account.
- **`/goal` is a per-turn stop-gate, not a scheduler.** It keeps one turn
  alive until the condition is met; it doesn't survive closing the session.
  For unattended runs across sessions, see the `/loop` note in
  [`skills/graph-engineer/references/goal-templates.md`](skills/graph-engineer/references/goal-templates.md).

## License

MIT — see [LICENSE](LICENSE).
