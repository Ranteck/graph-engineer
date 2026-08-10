# `/goal` templates for the graph-engineer cycle

The quality of the condition is what decides whether the cycle terminates
cleanly or burns Codex calls indefinitely. Pick the template that matches the
project and paste it as-is, adjusting the feature name and scope.

Reminder: `/goal` is a stop-gate — evaluated when Claude tries to end the
turn, not a scheduler. To reset it: `/goal clear`.

## Two-message mode (recommended when the contract is ambiguous)

Use this when the feature needs a real design decision — send the task
request first, review the SPEC node's contract, then lock in the goal.

**Message 1** (triggers the skill, but does not authorize `--write` yet):
```
Use graph-engineer to prepare [feature] in [file/folder]. Run PRE-FLIGHT and
SPEC only, write and show me the contract in PROJECT_CONTEXT.md, then stop
before IMPL. Do not invoke Codex with --write until I approve the contract.
```

**Message 2**, once the contract is shown and you approve it:
```
/goal [feature]'s adversarial-review comes back with no valid findings
(debatable ones were discussed and resolved, false positives documented)
AND the test suite passes clean AND no implementation file was edited by
Claude directly (only by Codex via codex:codex-rescue). I approve the
contract; continue from IMPL. If valid findings persist after 3 iterations
of the CRITIQUE node, stop and report instead of continuing. Regardless of that 3-iteration cap, the skill's own anti-loop
cutoff applies too: if the same underlying finding gets restated with no net
code change across 2 consecutive CRITIQUE passes, stop and escalate to me
immediately — whichever limit (2 or 3) is hit first wins. If no usable
quality-gate resolution exists and no explicit opt-out was given, or one
activation reaches the absolute cap of 3 failed QUALITY GATE runs, stop and
report instead of continuing. If PRE-FLIGHT or SPEC's elevated-assurance
risk-trigger evaluation matches and no decision from me is available, stop
before IMPL and escalate instead of proceeding under either standard or
elevated mode.
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

This is the write-authorized template. For a read-only audit with no edits,
use the Review-only template below instead of substituting "review" into
this one — the two modes have different, incompatible permissions.

```
/goal Implement [what you want] in [file/folder or scope], code written and
fixed by Codex via graph-engineer (Claude does not edit implementation files
directly). Stop condition: [your verifiable criterion] AND no valid findings
remain from the adversarial-review (debatable ones get debated, not accepted
blindly). If the cycle reaches 3 iterations of the CRITIQUE node without
satisfying the stop condition, stop and report the remaining findings
instead of continuing. If the same underlying finding persists for 2 rounds
in a row with no net code change, stop and tell me instead of continuing —
this is the skill's own floor and applies even if you'd otherwise keep
going. If no usable
quality-gate resolution exists and no explicit opt-out was given, or one
activation reaches the absolute cap of 3 failed QUALITY GATE runs, stop and
report instead of continuing. If PRE-FLIGHT or SPEC's elevated-assurance
risk-trigger evaluation matches and no decision from me is available, stop
before IMPL and escalate instead of proceeding under either standard or
elevated mode.
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
and report instead of continuing. If PRE-FLIGHT or SPEC's elevated-assurance
risk-trigger evaluation matches and no decision from me is available, stop
before IMPL and escalate instead of proceeding under either standard or
elevated mode.
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
instead of continuing. If PRE-FLIGHT or SPEC's elevated-assurance
risk-trigger evaluation matches and no decision from me is available, stop
before IMPL and escalate instead of proceeding under either standard or
elevated mode.
At any node, stop and report immediately on an environmental failure (timeout,
out-of-memory, read-only filesystem, or a missing command/dependency), or if
PRE-FLIGHT aborts for a dirty working tree, wrong branch, or no usable safety
precondition.
```

## Refactor-only (no new feature, existing code)

Follow the refactor-only entry path defined in `../SKILL.md`:
PRE-FLIGHT (write-authorized, with the full 8-node write cycle's preconditions)
-> first fresh-thread CRITIQUE over the current tree -> DEBATE -> REFACTOR when
findings are valid -> QUALITY GATE -> second CRITIQUE -> DEBATE, repeating
until no findings remain -> DONE. PRE-FLIGHT resolves and persists the QUALITY
GATE command because REFACTOR writes are expected, but the gate does not run
before the first CRITIQUE; it first runs after the first REFACTOR write.

```
/goal An adversarial-review of Codex ran over the current working tree
(without --base), the valid findings were applied by Codex through the
sanctioned REFACTOR procedure—either the normal codex:codex-rescue
--resume-last session or the documented fresh-session fallback with its
required inline continuity summary—and subsequent adversarial-review passes
continue through DEBATE until a final pass leaves no valid findings in scope.
Cap of 3 iterations.
Anti-loop floor applies too: if the same underlying finding is restated
with no net code change across 2 consecutive CRITIQUE passes, stop and
escalate to me instead of running further iterations. If no usable
quality-gate resolution exists and no explicit opt-out was given, or one
activation reaches the absolute cap of 3 failed QUALITY GATE runs, stop and
report instead of continuing. If PRE-FLIGHT's elevated-assurance risk-trigger
evaluation (there is no SPEC in this entry path, so PRE-FLIGHT's read is
final) matches and no decision from me is available, stop before the first
CRITIQUE and escalate instead of proceeding under either standard or
elevated mode.
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

## Elevated assurance — explicit opt-in, write-authorized

Elevated assurance is the optional multi-lens CRITIQUE variant described in
`elevated-assurance.md`. It is **never implied by any other
template above** — use this one specifically, and only when you actually want
3 independent fresh lenses, a canonicalization barrier, and a fresh exit
challenger before VERIFY, in exchange for a materially higher Codex-call
floor (5 review calls — 6 total in a clean run of the full 8-node write
cycle, counting IMPL) and extra Claude context spent on fan-in. This is the
write-authorized template; substituting "review" into it is not equivalent —
use the Elevated review-only template below for that.
This template targets the full 8-node write cycle (with SPEC). For
refactor-only — which has no SPEC and no VERIFY node — use the dedicated
Elevated refactor-only template instead of this one.

<!-- elevated-write-goal:start -->
```
/goal Use graph-engineer's elevated-assurance mode
(references/elevated-assurance.md) for [feature] in [file/folder or scope]:
3 fresh independent lenses (correctness-contracts, integration-state-
reproducibility, security-abuse-data-loss) reviewed the implementation,
Claude normalized and fan-in'd their findings with corroboration recorded as
metadata only (never a fourth verdict, never a substitute for evidence), a
fresh canonicalization call adopted that ledger, and — after DEBATE first
reports no valid findings remaining — the most recent fresh exit challenger
reviewed the final artifact cold with no valid findings before VERIFY
(re-run fresh after any REFACTOR triggered by an earlier exit challenger
pass, until one pass finds nothing against the then-current artifact).
Persist mode: elevated in
PROJECT_CONTEXT.md's
### Critique assurance before IMPL. Code is written and fixed by Codex via
graph-engineer only (Claude does not edit implementation files directly).
Stop condition: [your verifiable criterion] AND no valid findings remain
from any lens, the canonicalization pass, or the exit challenger (debatable
ones get debated, not accepted blindly).
Elevated-mode caps: at most 5 CRITIQUE passes (the initial 3-lens sweep plus
canonicalization counts as one pass) and at most 13 total Codex review/
debate calls for this activation — these are adjustable starting points, not
derived constants; the structural review floor is 5 calls (3 lenses +
canonicalization + exit challenger), while the clean total floor is 6 after
counting IMPL. If either cap is reached without satisfying the stop
condition, stop and report the remaining findings instead of continuing. If
the same underlying finding persists for 2 rounds in a row with no net code
change, stop and tell me instead of continuing — this is the skill's own
floor and applies even if you'd otherwise keep going.
If a lens finishes after canonicalization began, apply the documented
late-lens recovery from references/elevated-assurance.md: wait for every
lens to reach a terminal state, merge the late result into the finding ledger,
and start a replacement fresh canonicalization call instead of treating
this alone as a stop condition. Recompute and compare the artifact-identity
digest both before dispatching each lens/canonicalization/exit-challenger
call and immediately after it completes; any mismatch means the reviewed
artifact is no longer current. If the elevated-assurance resolution is
missing or ambiguous, any required lens fails to return, that late-lens recovery
itself cannot establish terminal state or ledger completeness, canonical
latest-thread ownership still cannot be established after recovery, an
artifact-identity digest mismatch is detected at any of those checkpoints, the
digest cannot be constructed/recomputed or equality cannot be proven, the
required exit challenger cannot run, or the persisted Codex review/debate
call budget would be exceeded, stop and report instead of silently
downgrading to standard CRITIQUE, skipping a required call, discarding the
mismatch, or invoking --resume-last ambiguously. If no usable quality-gate resolution
exists and no explicit opt-out was given, or one activation reaches the
absolute cap of 3 failed QUALITY GATE runs, stop and report instead of
continuing.
At any node, stop and report immediately on an environmental failure
(timeout, out-of-memory, read-only filesystem, or a missing command/
dependency), or if PRE-FLIGHT aborts for a dirty working tree, wrong branch,
or no usable safety precondition.
```
<!-- elevated-write-goal:end -->

## Elevated review-only

No `--write`, same as the standard-mode review-only template, but with the
3-lens sweep, fan-in, and one canonicalization call instead of a single
reviewer.
No REFACTOR, QUALITY GATE, VERIFY, or exit challenger — there is no final
artifact distinct from what was just reviewed. Recommended reviewer budget:
5 calls (the clean structural floor is 4: 3 lenses + canonicalization, plus
at most 1 batched debatable reinjection). An incomplete lens sweep escalates;
never silently degrade to reporting only one lens's output.

```
/goal Use graph-engineer's elevated-assurance review-only mode
(references/elevated-assurance.md) over [scope]: 3 fresh independent lenses
(correctness-contracts, integration-state-reproducibility, security-abuse-
data-loss) reviewed it read-only, Claude normalized their findings with
corroboration as metadata only (never a fourth verdict), and a fresh
canonicalization call adopted that ledger to support at most one batched
reinjection for debatable findings. I'm not authorizing --write in this
cycle — the goal is a triaged, lens-attributed findings report (valid/
debatable/false positive) so I can decide manually what to apply. Stop as
soon as the report and triage are complete, without moving to REFACTOR.
Clean structural floor: 4 Codex review/total calls (3 lenses +
canonicalization). Recommended reviewer budget: 5 Codex calls total for this
activation, allowing at most 1 batched debatable reinjection. If a lens
finishes after canonicalization began, apply the documented late-lens
recovery: wait for every lens to reach a terminal state, merge the late
result into the finding ledger, and start a replacement fresh
canonicalization call, rather than treating this alone as a stop condition.
Recompute and compare the artifact-identity digest both before dispatching
each lens/canonicalization call and immediately after it completes. If any
of the 3 lenses fails to return, that recovery itself cannot establish
terminal state or ledger completeness, an artifact-identity digest mismatch
is detected at any of those checkpoints, or the digest cannot be
constructed/recomputed or equality cannot be proven, stop and escalate
instead of reporting on fewer than 3 lenses, discarding the mismatch, or
resuming ambiguously.
Use the review-only PRE-FLIGHT: require only readable repo/scope, reachable
Codex, and a CRITIQUE invocation capable of producing the report. A dirty
working tree, `main` branch, or read-only filesystem is allowed. Do not write
PROJECT_CONTEXT.md or resolve/run QUALITY GATE. An artifact-identity digest
mismatch is itself grounds to stop and report, not only an environmental
failure that prevents CRITIQUE from producing the report.
```

## Elevated refactor-only

Combines the refactor-only entry path (no SPEC, no VERIFY — see the
Refactor-only template above) with elevated assurance. The one behavior that
differs from the full 8-node write cycle's elevated template: the exit
challenger gates entry to **DONE**, not VERIFY, since refactor-only has no
VERIFY node. This template supersedes the standard-mode Refactor-only
template's 3-pass cap with elevated mode's own 5-pass cap and 13-call budget
below — don't combine both caps into one run.

```
/goal Use graph-engineer's refactor-only entry path with elevated-assurance
mode (references/elevated-assurance.md) over the current working tree
(without --base): the first CRITIQUE traversal used 3 fresh independent
lenses (correctness-contracts, integration-state-reproducibility, security-
abuse-data-loss), Claude normalized and fan-in'd their findings with
corroboration recorded as metadata only (never a fourth verdict, never a
substitute for evidence), and a fresh canonicalization call adopted that
ledger. Valid findings were applied by Codex through the sanctioned REFACTOR
procedure. Persist mode: elevated in PROJECT_CONTEXT.md's
### Critique assurance during PRE-FLIGHT (there is no SPEC in this entry
path, so PRE-FLIGHT's evaluation is final). After DEBATE first reports no
valid findings remaining, the most recent fresh exit challenger reviewed
the final artifact cold with no valid findings before DONE (re-run fresh
after any REFACTOR triggered by an earlier exit challenger pass, until one
pass finds nothing against the then-current artifact).
Elevated-mode caps: at most 5 CRITIQUE passes (the initial 3-lens sweep plus
canonicalization counts as one pass) and at most 13 total Codex review/
debate calls for this activation — these are adjustable starting points, not
derived constants; the structural review/total floor is 5 calls (3 lenses +
canonicalization + exit challenger) even in a clean cycle. If either cap is
reached without satisfying the stop condition, stop and report the
remaining findings instead of continuing. If the same underlying finding
persists for 2 rounds in a row with no net code change, stop and tell me
instead of continuing — this is the skill's own floor and applies even if
you'd otherwise keep going.
If a lens finishes after canonicalization began, apply the documented
late-lens recovery from references/elevated-assurance.md: wait for every
lens to reach a terminal state, merge the late result into the finding ledger,
and start a replacement fresh canonicalization call instead of treating
this alone as a stop condition. Recompute and compare the artifact-identity
digest both before dispatching each lens/canonicalization/exit-challenger
call and immediately after it completes; any mismatch means the reviewed
artifact is no longer current. If the elevated-assurance resolution is
missing or ambiguous, any required lens fails to return, that late-lens recovery
itself cannot establish terminal state or ledger completeness, canonical
latest-thread ownership still cannot be established after recovery, an
artifact-identity digest mismatch is detected at any of those checkpoints, the
digest cannot be constructed/recomputed or equality cannot be proven, the
required exit challenger cannot run, or the persisted Codex review/debate
call budget would be exceeded, stop and report instead of silently
downgrading to standard CRITIQUE, skipping a required call, discarding the
mismatch, or invoking --resume-last ambiguously. If no usable quality-gate resolution exists and
no explicit opt-out was given, or one activation reaches the absolute cap
of 3 failed QUALITY GATE runs, stop and report instead of continuing. If
PRE-FLIGHT's elevated-assurance risk-trigger evaluation matches and no
decision from me is available, stop before the first CRITIQUE and escalate
instead of proceeding under either standard or elevated mode.
At any node, stop and report immediately on an environmental failure
(timeout, out-of-memory, read-only filesystem, or a missing command/
dependency), or if PRE-FLIGHT aborts for a dirty working tree, wrong branch,
or no usable safety precondition.
```

## Notes

- The standard-mode iteration cap (3, used in the templates above) is a
  recommendation, not a fixed value: raise it for large/multi-file tasks,
  lower it to 1-2 for small changes. Elevated mode uses its own separate cap
  (5 CRITIQUE passes / 13 calls) documented in `elevated-assurance.md` and
  the elevated templates — don't conflate the two or combine them in one run.
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
- `/goal` is a per-turn stop-gate and doesn't survive closing the session.
  Some Claude Code environments offer `/loop` for running across turns
  instead of (or alongside) `/goal`, but its availability, persistence
  guarantees, and security semantics for unattended `--write` work have not
  been independently verified or stress-tested for this skill (see
  `sources.md` — it only confirms turn-level persistence, not that it
  survives closing the session) — it is the highest-risk way to run this
  cycle, since no human reviews the contract or findings as they happen.
  Treat it as
  known-to-exist, not validated-safe, and prefer supervised `/goal` runs
  until it's been exercised deliberately.
- Elevated assurance (the three templates above) is opt-in and never implied by
  any of the full 8-node write-cycle, refactor-only, or review-only templates
  elsewhere in this file — don't hand-edit a standard-mode template to add "3
  lenses" without also copying its full stop-clause set; use the dedicated
  elevated templates instead so the permission and escalation contract stays
  complete. The clean structural floors are 5 review calls / 6 total for the
  full 8-node write cycle, 5 review/total for refactor-only, and 4
  review/total for review-only. The 13-call/5-pass defaults are documented in
  `elevated-assurance.md` as adjustable, unbenchmarked ceilings — not as a
  validated optimum.
