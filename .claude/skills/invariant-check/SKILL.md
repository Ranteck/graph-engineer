---
name: invariant-check
description: Verify skills/graph-engineer/SKILL.md, README.md, and references/ all agree on the invariants documented in CLAUDE.md (8-node cycle, single entry point, pinned openai-codex version, DEBATE triage, anti-loop cutoff, goal-template location). Use after editing any of those files, or when asked to audit/check the skill docs for consistency.
disable-model-invocation: true
---

# Invariant Check

Dispatch the `doc-consistency-reviewer` subagent to audit the current state of the docs against the invariants list in `/CLAUDE.md`, then relay its findings verbatim (or "no issues found").

This repo has no build/test/lint step — this skill is the closest thing to a test suite it has, so run it after any non-trivial edit to `SKILL.md`, `README.md`, or a file under `skills/graph-engineer/references/`, and before committing doc changes.

Do not attempt to fix anything yourself as part of this skill — report only. If the reviewer finds a real mismatch, tell the user which files disagree and let them decide the fix (which version pin is current, which node name is correct, etc.) — these are content decisions, not mechanical ones.
