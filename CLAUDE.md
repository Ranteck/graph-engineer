# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repository is

This repo *is* a single Claude Code skill package named `graph-engineer` (plus its
README/LICENSE). There is no application code, no build step, no test suite, and no
package manifest — the repo's only artifact is the skill definition itself:

```
skills/graph-engineer/
├── SKILL.md                       # the skill's instructions (source of truth)
└── references/
    ├── goal-templates.md              # ready-to-use /goal templates per scenario
    ├── quality-gate-detection.md      # generic quality-gate command resolver algorithm
    └── sources.md                     # provenance: what's official Anthropic/OpenAI vs. not
```

`README.md` at the repo root is the human-facing explanation of the same skill and
must stay consistent with `skills/graph-engineer/SKILL.md` — they describe the same
8-node cycle from two angles (marketing/usage vs. operational instructions). When
editing one, check whether the other needs a matching update (e.g. node numbering,
flag names, the anti-loop cutoff wording).

## Working in this repo

There is nothing to build, lint, or test. "Development" here means editing Markdown
(`SKILL.md`, `README.md`, the reference files) and keeping the following
consistent across all of them:

- The 8-node cycle order and names: PRE-FLIGHT → SPEC → IMPL → QUALITY GATE → CRITIQUE
  → DEBATE/TRIAGE → REFACTOR → VERIFY.
- The single entry point claim: every Codex interaction routes through the
  `codex:codex-rescue` subagent — no other `/codex:*` command is invoked
  programmatically by this skill.
- The pinned plugin version (`openai-codex` v1.0.6) that the routing assumptions were
  verified against. If that version changes, `README.md`, `SKILL.md`, and
  `sources.md` all reference it and need to move together.

## Core design invariant

**Claude never edits implementation files with Edit/Write anywhere in the cycle** —
only Codex does, via `codex:codex-rescue --write`. `PROJECT_CONTEXT.md` in the
*consuming* repo is Claude's only writable artifact across the entire cycle:
PRE-FLIGHT writes the `### Quality gate` resolution metadata there, and SPEC writes
the feature contract there. Both are namespaced per feature under the applicable
`## <feature-name>` heading. Any change to `SKILL.md` that would have Claude editing
code directly breaks the reasons this skill exists: preserving Claude's
context/tokens for orchestration and judgment, reducing correlated self-review
failure by putting Claude in the arbitration path, and specializing Codex and
Claude into explicit writer/reviewer and contract/triage roles.

Related invariants worth preserving when editing `SKILL.md`:

- CRITIQUE calls never pass `--write` — this is enforced by the underlying
  `codex-companion.mjs` sandbox (`workspace-write` vs `read-only`), not just a prompt
  convention. Don't describe it as a soft/optional guarantee.
- After the first CRITIQUE in a cycle, every subsequent CRITIQUE and normal REFACTOR
  call passes `--resume-last` so Codex retains its own prior findings and Claude's
  triage decisions. The documented REFACTOR exception applies if a resumed read-only
  session rejects `--resume-last --write`: confirm no changes landed, then start a
  fresh non-resumed session with `--write` from the beginning instead of retrying the
  resume.
- DEBATE (node 5) must classify every finding as valid / debatable / false positive —
  never a flat pass/fail — and false-positive rulings need one line of written
  justification, not silent discard.
- The anti-loop cutoff (two consecutive CRITIQUE rounds restating the same underlying
  finding with no net code change) is a signal Claude escalates to the user — it does
  not by itself end a `/goal`-bound turn unless the user's `/goal` text includes an
  explicit stop/escalate clause. Don't describe it as an unconditional guarantee.

## Terminology to get right

- "Graph engineering" is explicitly *not* an official Anthropic or OpenAI term (see
  `sources.md`) — it's this skill's own mental-model framing for nesting
  Evaluator-Optimizer inside Orchestrator-Workers (both of which *are* real,
  documented Anthropic patterns). Don't imply otherwise in edits.
- Don't confuse this skill with `launchdarkly/agent-skills@agent-graphs`, an unrelated
  project about LaunchDarkly AI Configs (noted in `sources.md`).
