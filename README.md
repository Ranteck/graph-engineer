# graph-engineer

A Claude Code skill for a common problem: you want a second model (Codex) to
apply the code while Claude preserves context for orchestration and judgment,
and you don't want Codex grading its own homework without arbitration.
`graph-engineer` makes Claude the orchestrator and arbiter, and Codex the one
who writes, adversarially reviews, and fixes the code, running as a
self-correcting loop instead of a single implement-and-hope pass. The split
isn't only about token cost: it also separates roles and puts a different
model in the arbitration path.

> **Status: design-stage, adversarially reviewed, not yet dogfooded end-to-end.**
> The 8-node cycle and the QUALITY GATE resolver below converged through
> repeated Claude↔Codex adversarial review of the design itself. Neither has
> been run against a real feature in a real repository yet — treat this as
> "reviewed on paper" rather than "battle-tested." See
> [Limitations / Risks](#limitations--risks) before running `--write` against
> anything you care about.

## Requirements

This skill needs the official OpenAI Codex plugin for Claude Code:
**[openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc)**.

```
/plugin marketplace add openai/codex-plugin-cc
/plugin install codex@openai-codex
/codex:setup
```

`/codex:setup` should report `Status: ready`. Also needs
[Claude Code](https://claude.com/claude-code) itself — this skill relies on
the built-in `/goal` command; confirm it's available in your installed
build, since this repository doesn't currently pin a verified Claude Code
version.

**Source-inspected against `openai-codex` plugin v1.0.6.** The routing,
flag, and sandbox assumptions (single `codex:codex-rescue` entry point,
`--write` / `--resume-last` flag behavior, sandbox enforcement of read-only
CRITIQUE calls) were checked against that version's installed plugin
sources — not exercised end-to-end (see Status above). Installing via the
commands above pulls whatever version is current, which may not be v1.0.6;
check your installed version and treat anything other than v1.0.6 as
compatibility-unverified.

## Installation

```bash
npx skills add Ranteck/graph-engineer
```

This uses the [`skills` CLI](https://www.skills.sh/) (`vercel-labs/skills`)
— an independent installer, not a Claude Code builtin. Requires Node/npm.

Or manually, after cloning this repository and from its root:
```bash
mkdir -p ~/.claude/skills
cp -R skills/graph-engineer ~/.claude/skills/
```

Before authorizing any `--write` cycle, exercise the review-only template
(see Usage below) against a disposable repository that starts with a clean
`git status`, and confirm the final `git status` still reports clean
afterward (a clean starting point is what makes that comparison meaningful).

## Usage

**This is the write-authorized template — it lets Codex edit files.** For a
read-only audit with no edits, use the dedicated review-only template in
[`skills/graph-engineer/references/goal-templates.md`](skills/graph-engineer/references/goal-templates.md)
instead of substituting "review" into the prompt below; the two modes have
different, incompatible permissions.

**Single message** (fastest — combines the task and the stop condition):
```
/goal Implement [what you want] in [file/folder or scope], code written and
fixed by Codex via graph-engineer (Claude does not edit implementation files
directly). Stop condition: [your verifiable criterion] AND no valid findings
remain from the adversarial-review (debatable ones get debated, not accepted
blindly). If the cycle reaches 3 CRITIQUE passes without satisfying the stop
condition, stop and report the remaining findings instead of continuing. If
the same underlying finding is restated with no net code change across 2
consecutive CRITIQUE passes, stop and tell me instead of continuing — this
floor applies even if you'd otherwise keep going. If no usable quality-gate
resolution exists without an explicit opt-out, or one activation reaches 3
failed QUALITY GATE runs, stop and tell me instead of continuing.
At any node, stop and report immediately on an environmental failure (timeout,
out-of-memory, read-only filesystem, or a missing command/dependency), or if
PRE-FLIGHT aborts for a dirty working tree, wrong branch, or no usable safety
precondition.
```

**Two messages** (recommended when the contract needs discussion first — you
get to review it before the goal locks in, and before Codex is authorized to
write anything):
```
Use graph-engineer to prepare [feature] in [file/folder]. Run PRE-FLIGHT and
SPEC only, write and show me the contract in PROJECT_CONTEXT.md, then stop
before IMPL. Do not invoke Codex with --write until I approve the contract.
```
then, after reviewing the contract Claude writes to `PROJECT_CONTEXT.md`:
```
/goal [your verifiable stop condition]. I approve the contract; continue
from IMPL. If the cycle reaches 3 CRITIQUE passes without satisfying the
stop condition, stop and report the remaining findings instead of
continuing. If the same underlying finding is restated with no net code
change across 2 consecutive CRITIQUE passes, stop and tell me instead of
continuing — this floor applies even if you'd otherwise keep going. If no
usable quality-gate resolution exists without an explicit opt-out, or one
activation reaches 3 failed QUALITY GATE runs, stop and tell me instead of
continuing.
At any node, stop and report immediately on an environmental failure (timeout,
out-of-memory, read-only filesystem, or a missing command/dependency), or if
PRE-FLIGHT aborts for a dirty working tree, wrong branch, or no usable safety
precondition.
```

More templates (with tests, without tests, refactor-only, review-only) in
[`skills/graph-engineer/references/goal-templates.md`](skills/graph-engineer/references/goal-templates.md).

## What is "graph engineering"?

Not an official term — no Anthropic or OpenAI product is called that. It's
useful as a mental model anyway: think of the workflow as a small graph.

- **Nodes** are units of work: Claude writing a spec, Codex implementing,
  Codex critiquing, Claude triaging.
- **Edges** are handoffs between them: spec → implementation → mechanical
  quality gate → critique → triage → fix.

What makes it a *graph* instead of a *list* is its return edges: a failed
QUALITY GATE returns to the last writer, and **VERIFY loops back to
CRITIQUE**. The latter lets the same critique step run again, and again, over
code that's already been through one round of fixes — until a stop condition
is actually met. Take those edges out and you just have a pipeline: write
once, review once, done, bugs and all.

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
writes or fixes something, critique may run only on a tree that has passed
the mechanical QUALITY GATE since that write, or for which a currently-valid
persisted user-confirmed opt-out exists — because a fix can introduce its own
problems, and because a first pass rarely catches everything. The outer loop
keeps going until a condition you define is verifiably true: usually "no valid
findings left, and functional tests pass."

`/goal` (see [Usage](#usage)) is the success condition that keeps the turn
alive — Claude Code's built-in stop-gate, holding the turn open until it's
verifiably true. On top of that, the outer critique loop has two brakes for
when it *isn't* converging, and both are conditional on your `/goal` text
actually including them — neither is enforced by the skill unconditionally:

- **An anti-loop cutoff** — if, across two rounds in a row, Claude judges a
  CRITIQUE finding to be the same underlying complaint restated with no real
  change to the code, the cycle is meant to stop and escalate to you instead
  of spinning. But `/goal` binds Claude to its literal condition: this
  cutoff can only actually end the turn early if your `/goal` text itself
  includes an explicit escalation/stop clause (the templates in
  [`skills/graph-engineer/references/goal-templates.md`](skills/graph-engineer/references/goal-templates.md)
  include one — make sure yours does too). Without that clause, Claude
  remains bound by "keep working until true" and will surface the repeated
  finding rather than unilaterally stopping. Don't rely on this as an
  unconditional guarantee.
- **A recommended total CRITIQUE cap** (3 passes in the templates below) —
  unlike the anti-loop cutoff, this isn't a distinct finding-comparison
  rule; it's a plain iteration ceiling you write into `/goal` so a string of
  *different* findings can't keep the cycle going indefinitely. Same
  caveat: only as real as the clause your `/goal` text includes.

QUALITY GATE has its own separate absolute brake: no more than 3 failed runs
per writer activation. That cap never expands based on apparent progress.

## The cycle (8 nodes)

```
[0 PRE-FLIGHT] Claude checks branch, worktree, and gate resolution
      ↓
[1 SPEC]       Claude writes the contract to PROJECT_CONTEXT.md  (cheap, Claude only)
      ↓
[2 IMPL]       Agent → codex:codex-rescue --write                (Codex writes)
      ↓
[3 QUALITY GATE] Claude runs the resolved mechanical checks
      ├── fail → back to the last writer (max 3 failed runs per activation)
      └── pass
             ↓
[4 CRITIQUE]   Agent → codex:codex-rescue (read-only, adversarial)
      ↓
[5 DEBATE]     Claude reads findings and TRIAGES them:            (read-only, cheap)
              · valid          → goes to refactor
              · debatable      → reinjected to Codex with a counterargument
              · false positive → discarded, with written justification
      ├── valid findings → [6 REFACTOR] → [3 QUALITY GATE]
      └── no findings    → [7 VERIFY]
                              ├── pass → DONE
                              └── fail → [4 CRITIQUE] → [5 DEBATE]
```

QUALITY GATE is numbered so the invariant is visible, but it is not a new
actor or an unconditional pipeline stage: it is a capped retry edge attached
to whichever writer, IMPL or REFACTOR, just ran. CRITIQUE may run only on a
tree that has passed QUALITY GATE since the last write, or for which a
currently-valid persisted user-confirmed opt-out exists. The gate is mechanical
only (lint, formatting, type checking, and build), while VERIFY owns functional
tests and acceptance criteria. A VERIFY failure returns to CRITIQUE for
classification as an implementation defect, test defect, contract mismatch,
or environmental failure; it never takes the fast mechanical-fixer route. If
VERIFY cannot execute assertions at all because of an environmental block, the
cycle escalates directly to the user.

Before IMPL, PRE-FLIGHT resolves the project's real local quality command and
stores the resolution—not a previous result—inside the current feature's
section in `PROJECT_CONTEXT.md`. It revalidates that cached resolution after
each write. Ambiguous or unsafe candidates require one user decision; no
usable candidate stops the cycle before IMPL unless the user explicitly opts
out. See
[`skills/graph-engineer/references/quality-gate-detection.md`](skills/graph-engineer/references/quality-gate-detection.md)
for the resolver order, safety checks, cache schema, bundled-command split,
retry cap, and escalation rules.

Node 5 isn't a flat pass/fail filter — "debatable" findings open their own
small sub-loop, invisible in the 8-node diagram above:

```
[5 DEBATE]  finding classified as "debatable"
      ↓
      Claude reinjects it to codex:codex-rescue with a counterargument
      ("Codex flagged X, but Y because Z — do you stand by it or reconsider?"),
      always with --resume-last so the thread stays continuous
      ↓
      Codex replies (still read-only — no --write in this call either)
      ↓
      Claude decides: valid → refactor, or false positive → discarded
      (with written justification either way)
```

This sub-loop happens entirely inside node 5, before anything reaches node
6 — it's an extra round-trip to Codex per debatable finding, not just a
triage checkbox.

## A hypothetical worked example

This is an illustrative flow, not a transcript of an executed end-to-end run
(see the Status note above). Loosely modeled on the single-message template
— **shortened here for readability; don't copy this exact text, use the
full template in [Usage](#usage) or
[`goal-templates.md`](skills/graph-engineer/references/goal-templates.md),
which includes the CRITIQUE cap, anti-loop, QUALITY GATE, and environmental
stop clauses this shortened version omits:**
```
/goal Implement a POST /api/webhooks/verify endpoint in src/routes/webhooks.ts,
code written and fixed by Codex via graph-engineer. Stop condition: the
endpoint verifies webhook signatures and returns the documented status codes,
AND no valid findings remain from the adversarial-review. [...full template's
CRITIQUE cap, anti-loop, QUALITY GATE, and environmental clauses apply too.]
```

0. **PRE-FLIGHT** — Claude confirms the branch and worktree are safe, then
   resolves and persists the feature's mechanical quality gate.
1. **SPEC** — Claude writes the endpoint's contract (inputs, signature
   verification rule, response codes) to `PROJECT_CONTEXT.md`.
2. **IMPL** — Codex writes `webhooks.ts` following that contract.
3. **QUALITY GATE** — The resolved local lint/typecheck/build command passes
   over the newly written tree.
4. **CRITIQUE** — Codex reviews its own code adversarially and reports, say,
   two findings: *"the signature comparison uses `===` instead of a
   constant-time compare — timing attack surface"* and *"the handler doesn't
   log request IDs"*.
5. **DEBATE** — Claude reads the full security-related file before ruling,
   then triages: the timing-attack finding is **valid**, so it goes to
   refactor. The logging one is judged a **false positive** for this repo (it
   has no logging convention anywhere else) — discarded, with that reason
   written down, not silently dropped.
6. **REFACTOR** — Codex swaps in a constant-time comparison.
   - **Mini-loop:** Return to node **3 QUALITY GATE**, then node **4
     CRITIQUE** — both pass this time.
7. **VERIFY** — Functional tests run green. The `/goal` condition is met and
   the loop ends.

## Why

1. **Intended token and context savings.** This split is designed to keep
   Claude's context focused on the contract, orchestration, and judgment
   while Codex carries the implementation-heavy work — not independently
   benchmarked yet. "Cheap" is relative, not free: repeated loops still
   accumulate findings and triage context. Nor does the design mean "Codex
   always implements only because it costs fewer Claude tokens": Codex is
   also routed to implementation because applying code is a role it
   performs well, independent of cost.
2. **Less correlated self-review failure (intended).** Reflection improves
   results, but a writer evaluating its own output can repeat the same
   blind spots; see Andrew Ng's
   [Agentic Design Patterns — Reflection](https://www.deeplearning.ai/the-batch/agentic-design-patterns-part-2-reflection/)
   (that source backs the general reflection pattern, not a specific claim
   about same-model self-preference bias). Claude's DEBATE arbitration adds
   a different model to the decision path instead of letting Codex apply
   every self-critique automatically. This is meant to mitigate, not
   eliminate, the risk of correlated blind spots: IMPL and CRITIQUE still
   use the same underlying Codex model.
3. **Specialization by role.** Codex writes and mechanically repairs code;
   Codex's adversarial pass challenges it; Claude owns the contract, checks
   evidence, and arbitrates disputed findings. Each role gets a narrower,
   explicit responsibility instead of one model silently switching between
   author, reviewer, and judge.

## How it works

| Graph role | Piece | Invocation |
|---|---|---|
| Orchestrator | User + Claude Code session | — |
| Loop driver | `/goal <condition>` | built-in; `/goal clear` to reset |
| Worker (implements) | subagent `codex:codex-rescue` | `Agent` tool, `--write` |
| Mechanical gate | project-local resolved command | local shell, cached per feature |
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
- **Codex's cost is separate from Claude's.** This skill is designed to
  reduce Claude's context/token usage (not independently benchmarked, see
  [Why](#why)); Codex calls are billed through your own OpenAI account.
- **A read-only Codex session may stay read-only when resumed.** A session
  created without write access has been observed rejecting a later
  `--resume-last --write` attempt at the sandbox boundary. Recovery is to
  compare a before/after snapshot (untracked-file status, tracked diff, and
  content hashes — `git diff --check` alone doesn't prove nothing changed)
  and, only if they match, start a fresh, non-resumed Codex session with
  `--write` from the beginning instead of retrying the resume.
- **Same-model review is not independent verification.** IMPL and CRITIQUE
  both use Codex, so they can share blind spots and self-preference bias.
  Claude's evidence-based DEBATE is a mitigation, not a proof of correctness.
- **`/goal` is a per-turn stop-gate, not a scheduler.** It keeps one turn
  alive until the condition is met; it doesn't survive closing the session.
  Some Claude Code environments offer `/loop` for unattended runs across
  turns (see the note in
  [`skills/graph-engineer/references/goal-templates.md`](skills/graph-engineer/references/goal-templates.md);
  `sources.md` only confirms turn-level persistence, not that it survives
  closing the session) — this is the highest-risk way to run this skill,
  since it authorizes unattended `--write` cycles with no human reviewing
  the contract or the findings as they happen. This project has not
  independently benchmarked or stress-tested `/loop` specifically for this
  use case.
- **The skill creates or updates `PROJECT_CONTEXT.md` in the target
  repository.** It's a real, persistent file in your repo, namespaced per
  feature — not cleaned up automatically. Review it explicitly (and decide
  whether to commit it) before wrapping up the work.

## Feedback / bug reports

Open an issue at
[github.com/Ranteck/graph-engineer/issues](https://github.com/Ranteck/graph-engineer/issues).
Please include: your Claude Code version, the `openai-codex` plugin
version, the ecosystem/language of the target repo, the QUALITY GATE
command that got resolved (from `PROJECT_CONTEXT.md`), and sanitized
output — this skill has not been dogfooded across ecosystems yet, so
real-world reports are the fastest way to close that gap.

## License

MIT — see [LICENSE](LICENSE).
