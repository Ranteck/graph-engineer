# `/goal` templates for the graph-engineer cycle

The quality of the condition is what decides whether the cycle terminates
cleanly or burns Codex calls indefinitely. Pick the template that matches the
project and paste it as-is, adjusting the feature name and scope.

Reminder: `/goal` is a stop-gate — evaluated when Claude tries to end the
turn, not a scheduler. To reset it: `/goal clear`.

## Two-message mode (recommended when the contract is ambiguous)

Use this when the feature needs a real design decision — send the task
request first, review the SPEC node's contract, then lock in the goal.

**Message 1** (triggers the skill):
```
implement [feature] in [file/folder] using Codex — Codex writes the code,
adversarially self-reviews it, and only applies a fix once you've debated
the finding with it. You don't touch code directly, only the contract and
arbitration.
```

**Message 2**, once the contract is shown:
```
/goal [feature]'s adversarial-review comes back with no valid findings
(debatable ones were discussed and resolved, false positives documented)
AND the test suite passes clean AND no implementation file was edited by
Claude directly (only by Codex via codex:codex-rescue). If valid findings
persist after 3 iterations of the CRITIQUE node, stop and report instead of
continuing.
```

## Single-message mode (task + stop condition combined)

Trade-off: you skip reviewing the contract before it's locked in — Claude
writes `PROJECT_CONTEXT.md` using its best judgment from what you wrote here,
and you review it once the cycle has already started. Fine for well-scoped
tasks; riskier when "what to build" is ambiguous.

```
/goal Implement/review [what you want] in [file/folder or scope], code
written and fixed by Codex via graph-engineer (I don't edit anything
directly). Stop condition: [your verifiable criterion] AND no valid findings
remain from the adversarial-review (debatable ones get debated, not accepted
blindly). If the same error persists for 2 rounds in a row, stop and tell me
instead of continuing.
```

## Default — project with reliable tests

```
/goal The adversarial-review of Codex on [feature] comes back with no valid
findings (debatable ones were debated and resolved, false positives
documented) AND the project's test suite passes clean AND no implementation
file was edited by Claude directly (only by Codex via codex:codex-rescue).
If valid findings persist after 3 iterations of the CRITIQUE node, stop and
report instead of continuing to iterate.
```

## Project without reliable tests

```
/goal The adversarial-review of Codex on [feature] comes back with no valid
findings, after at least one round of debate on the debatable ones. This
project has no reliable test suite, so don't require a green run as the
criterion — instead, before closing, list a summary of the changes Codex
applied so I can review manually. Cap of 3 iterations of the CRITIQUE node;
if reached without resolution, stop and escalate the decision to me.
```

## Refactor-only (no new feature, existing code)

```
/goal An adversarial-review of Codex ran over the current working tree
(without --base), the valid findings were applied by Codex via
codex:codex-rescue --resume-last, and a second adversarial-review pass finds
no new findings related to the ones already fixed. Cap of 3 iterations.
```

## Review-only (no `--write`, Codex is not authorized to touch files)

```
/goal An adversarial-review of Codex ran over [scope] and I have the full
report returned verbatim. I'm not authorizing --write in this cycle — the
goal is only a triaged findings report (valid/debatable/false positive) so I
can decide manually what to apply. Stop as soon as the report and the triage
are complete, without moving to the REFACTOR node.
```

## Notes

- The iteration cap (3 above) is a recommendation, not a fixed value: raise
  it for large/multi-file tasks, lower it to 1-2 for small changes.
- If the user wants the cycle running truly unattended across sessions (not
  just within one turn), use `/loop` with the skill's trigger prompt instead
  of (or in addition to) `/goal` — `/goal` is a per-turn stop-gate and doesn't
  survive closing the session.
