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
continuing. Regardless of that 3-iteration cap, the skill's own anti-loop
cutoff applies too: if the same underlying finding gets restated with no net
code change across 2 consecutive CRITIQUE passes, stop and escalate to me
immediately — whichever limit (2 or 3) is hit first wins. If no usable
quality-gate resolution exists and no explicit opt-out was given, or one
activation reaches the absolute cap of 3 failed QUALITY GATE runs, stop and
report instead of continuing.
At any node, stop and report immediately on an environmental failure (timeout,
out-of-memory, read-only filesystem, or a missing command/dependency), or if
PRE-FLIGHT aborts for a dirty working tree, wrong branch, or no usable safety
precondition.
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
blindly). If the same underlying finding persists for 2 rounds in a row with
no net code change, stop and tell me instead of continuing — this is the
skill's own floor and applies even if you'd otherwise keep going. If no usable
quality-gate resolution exists and no explicit opt-out was given, or one
activation reaches the absolute cap of 3 failed QUALITY GATE runs, stop and
report instead of continuing.
At any node, stop and report immediately on an environmental failure (timeout,
out-of-memory, read-only filesystem, or a missing command/dependency), or if
PRE-FLIGHT aborts for a dirty working tree, wrong branch, or no usable safety
precondition.
```

## Default — project with reliable tests

```
/goal The adversarial-review of Codex on [feature] comes back with no valid
findings (debatable ones were debated and resolved, false positives
documented) AND the project's test suite passes clean AND no implementation
file was edited by Claude directly (only by Codex via codex:codex-rescue).
If valid findings persist after 3 iterations of the CRITIQUE node, stop and
report instead of continuing to iterate. Also apply the skill's anti-loop
floor: if the same underlying finding is restated with no net code change
across 2 consecutive CRITIQUE passes, stop and escalate immediately — that
2-round floor wins over the 3-iteration cap whenever it triggers first. If no
usable quality-gate resolution exists and no explicit opt-out was given, or
one activation reaches the absolute cap of 3 failed QUALITY GATE runs, stop
and report instead of continuing.
At any node, stop and report immediately on an environmental failure (timeout,
out-of-memory, read-only filesystem, or a missing command/dependency), or if
PRE-FLIGHT aborts for a dirty working tree, wrong branch, or no usable safety
precondition.
```

## Project without reliable tests

```
/goal The adversarial-review of Codex on [feature] comes back with no valid
findings, after at least one round of debate on the debatable ones. This
project has no reliable test suite, so don't require a green run as the
criterion — instead, before closing, list a summary of the changes Codex
applied so I can review manually. Cap of 3 iterations of the CRITIQUE node;
if reached without resolution, stop and escalate the decision to me. Also,
regardless of that cap: if the same underlying finding is restated with no
net code change across 2 consecutive CRITIQUE passes, stop and escalate
right away instead of waiting for iteration 3. If no usable quality-gate
resolution exists and no explicit opt-out was given, or one activation
reaches the absolute cap of 3 failed QUALITY GATE runs, stop and report
instead of continuing.
At any node, stop and report immediately on an environmental failure (timeout,
out-of-memory, read-only filesystem, or a missing command/dependency), or if
PRE-FLIGHT aborts for a dirty working tree, wrong branch, or no usable safety
precondition.
```

## Refactor-only (no new feature, existing code)

Follow the refactor-only entry path defined in `../SKILL.md`:
PRE-FLIGHT (write-authorized, with the standard cycle's preconditions) ->
first fresh-thread CRITIQUE over the current tree -> DEBATE -> REFACTOR when
findings are valid -> QUALITY GATE -> second CRITIQUE -> DEBATE, repeating
until no findings remain -> DONE. PRE-FLIGHT resolves and persists the QUALITY
GATE command because REFACTOR writes are expected, but the gate does not run
before the first CRITIQUE; it first runs after the first REFACTOR write.

```
/goal An adversarial-review of Codex ran over the current working tree
(without --base), the valid findings were applied by Codex through the
sanctioned REFACTOR procedure—either the normal codex:codex-rescue
--resume-last session or the documented fresh-session fallback with its
required inline continuity summary—and a second adversarial-review pass finds
no new findings related to the ones already fixed. Cap of 3 iterations.
Anti-loop floor applies too: if the same underlying finding is restated
with no net code change across 2 consecutive CRITIQUE passes, stop and
escalate to me instead of running further iterations. If no usable
quality-gate resolution exists and no explicit opt-out was given, or one
activation reaches the absolute cap of 3 failed QUALITY GATE runs, stop and
report instead of continuing.
At any node, stop and report immediately on an environmental failure (timeout,
out-of-memory, read-only filesystem, or a missing command/dependency), or if
PRE-FLIGHT aborts for a dirty working tree, wrong branch, or no usable safety
precondition.
```

## Review-only (no `--write`, Codex is not authorized to touch files)

Review-only uses a distinct read-only PRE-FLIGHT. Require only that the
repository and requested scope are readable, Codex is reachable, and CRITIQUE
can produce its report. Do not require a clean working tree, a non-`main`
branch, a writable filesystem, any `PROJECT_CONTEXT.md` write, or QUALITY GATE
resolution/execution. Escalate only an environmental failure that actually
prevents the report from being produced.

```
/goal An adversarial-review of Codex ran over [scope] and I have the full
report returned verbatim. I'm not authorizing --write in this cycle — the
goal is only a triaged findings report (valid/debatable/false positive) so I
can decide manually what to apply. Stop as soon as the report and the triage
are complete, without moving to the REFACTOR node. (No iteration cap needed
here — this mode never loops back to CRITIQUE, so the skill's anti-loop
floor doesn't apply.)
Use the review-only PRE-FLIGHT: require only readable repo/scope, reachable
Codex, and a CRITIQUE invocation capable of producing the report. A dirty
working tree, `main` branch, or read-only filesystem is allowed. Do not write
PROJECT_CONTEXT.md or resolve/run QUALITY GATE. Stop and report only if an
environmental failure actually prevents CRITIQUE from producing the report.
```

## Notes

- The iteration cap (3 above) is a recommendation, not a fixed value: raise
  it for large/multi-file tasks, lower it to 1-2 for small changes.
- The skill's anti-loop cutoff (2 consecutive CRITIQUE passes restating the
  same underlying finding with no net code change) is a separate, harder
  floor — it is not a recommendation and applies regardless of whatever
  iteration cap you write into `/goal`. Whichever limit triggers first
  wins. But note that limit can only actually end the turn if your `/goal`
  text includes an explicit escalation/stop clause, as in the templates
  above — without one, `/goal`'s literal condition still binds Claude to
  keep working.
- Include QUALITY GATE escalation in autonomous `/goal` stop clauses: stop
  and report if no usable gate resolution or explicit opt-out exists, or if
  one activation reaches the absolute cap of 3 failed gate runs. Never turn
  either condition into a silent skip or an unbounded retry.
- Include the full environmental/write-safety PRE-FLIGHT stop clause only in
  modes that may reach IMPL or REFACTOR. Review-only still enters PRE-FLIGHT at
  node 0, but uses its lighter variant above: dirty trees, `main`, read-only
  filesystems, omitted `PROJECT_CONTEXT.md` writes, and omitted QUALITY GATE
  work are allowed. Escalate only if repo/scope readability, Codex
  reachability, or another environmental condition actually prevents CRITIQUE
  from producing its report.
- If the user wants the cycle running truly unattended across sessions (not
  just within one turn), use `/loop` with the skill's trigger prompt instead
  of (or in addition to) `/goal` — `/goal` is a per-turn stop-gate and doesn't
  survive closing the session.
