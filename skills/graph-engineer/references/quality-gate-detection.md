# QUALITY GATE detection and execution

Use this reference during PRE-FLIGHT to resolve a project's real local
mechanical gate, and before every QUALITY GATE run to revalidate and execute
that resolution safely. The gate covers lint, formatting, type checking, and
build checks. Functional tests and acceptance criteria belong to VERIFY.

The core invariant is: no CRITIQUE call may run on a tree that has not passed
QUALITY GATE since the last write, or for which a currently-valid persisted
user-confirmed opt-out exists.

## Resolution order

Stop at the first safe, usable resolution in this order:

1. **Current feature cache.** Reuse a still-valid resolution already stored
   under `### Quality gate` in the current feature's
   `PROJECT_CONTEXT.md` section. Do not search another feature's section.
2. **PR/push CI local wrapper.** Inspect the project's own GitHub Actions,
   GitLab CI, CircleCI, Azure Pipelines, or Jenkins configuration. Look for
   jobs or steps named quality, checks, lint, test, or build, then resolve
   what they invoke to an underlying local wrapper. Never copy a raw CI
   `run:` line verbatim: its shell, cwd, matrix values, secrets, services, or
   other CI-only context may not exist locally.
3. **Documented command.** Use a local command documented in
   `CONTRIBUTING.md` or the project's developer documentation.
4. **Project-defined aggregator.** Prefer aggregators before isolated checks:
   - `package.json` scripts named `quality`, `check`, `validate`, `ci`, or
     `verify` before individual `lint` or `test` scripts.
   - Makefile or justfile targets named `check`, `quality`, `ci`, `verify`,
     or `lint`.
   - Python equivalents in `tox.ini`, `noxfile.py`, or `pyproject.toml`.
   - Rust `xtask` commands or Cargo aliases.
5. **Bare ecosystem convention.** Treat conventions such as an ecosystem's
   default test or check command as candidates only. Present the candidate to
   the user and never run it without confirmation.

Do not hardcode a command learned from another repository.

## Candidate eligibility before ranking

Apply these rules to each candidate's resolved transitive implementation
before ranking it, autoselecting it, or presenting it as a safe default:

- The command must contain identifiable mechanical checks—lint, formatting,
  type checking, or build—as at least part of its behavior. A command that is
  purely functional or acceptance tests with no mechanical content is not a
  valid QUALITY GATE candidate under any circumstance. Reject it outright and
  leave it in VERIFY; there is no mechanical subcommand to split out.
- The command must not run in mutating, auto-fix, or write mode. Inspect the
  whole resolved wrapper chain for flags or patterns such as `--write`,
  `--fix`, `-w`, and `--in-place`, and for tools known to write by default,
  such as a bare `prettier` invocation without `--check`. Such a command is
  categorically ineligible by default and is never eligible for autoselection
  or presentation as a safe default. Prefer or require the check-only variant
  when one exists—for example, `prettier --check` instead of
  `prettier --write`, or `eslint` without `--fix`. The only exception is a
  project-specific need with no safe alternative, explicitly confirmed by the
  user after both the mutation and an appropriate non-mutating follow-up
  verification command have been identified. If either cannot be identified,
  reject the mutating candidate; an opt-out is safer than treating an
  unverifiable write as a passed gate.

Commands that mix mechanical checks with functional tests are handled by the
existing split rule below: isolate a mechanical subcommand when it can be
proved safe. That mixed-command case is distinct from a pure functional-test
command, which must be rejected outright.

## Automatic selection threshold

Autoselect only when exactly one unambiguous high-confidence candidate meets
all of these conditions:

- The project's own PR/push CI invokes it.
- The CI path resolves to a local wrapper, not a raw CI-only command.
- Its working directory is determinate.
- It has no unresolved secret, service, or matrix dependency.
- It does not publish, deploy, run migrations, or install dependencies as a
  side effect.
- Its CI step is not marked `continue-on-error` or an equivalent soft-fail
  setting.
- Its transitive implementation is non-trivial and is not a no-op
  placeholder.

If there are multiple candidates, missing context, or any safety doubt, ask
the user once. Persist the answer so later cycles do not ask again while the
resolution remains valid.

## Validate the real implementation

Resolve aliases and wrapper chains transitively before accepting a candidate:

- Expand script bodies that call other scripts. Track visited definitions,
  detect cycles, and reject cyclic or unresolved chains.
- Reject empty bodies and known placeholders such as `echo "no tests"`.
- Inspect the actual body of Make and Just recipes; target names alone are
  not evidence.
- Exclude deploy, release, migration, publishing, and dependency-install
  jobs, plus jobs gated behind unresolved secrets, services, or matrices.
- Verify that the resolved executable, cwd, referenced script or target, and
  required target files actually exist before execution.
- If a candidate bundles mechanical checks with functional tests, isolate a
  fast mechanical subcommand. If that cannot be proved safe, ask the user how
  to split the commands. Never let a test failure enter QUALITY GATE's fast
  fixer route.

Do not infer success from quiet or empty output. The process exit code is
authoritative.

## Persist the resolution

Store the resolution, never the result of a prior run, inside the current
feature's section in `PROJECT_CONTEXT.md`:

```markdown
### Quality gate
- command: <resolved command>
- cwd: <resolved working directory>
- provenance: <e.g. .github/workflows/ci.yml -> job "checks" -> package.json#scripts.quality>
- resolution: auto-high-confidence | user-confirmed
- definition sources: <files inspected to resolve this>
```

An explicit user instruction to skip the quality gate for this project is
allowed. Persist it with the same fields, using `command: skipped`,
`cwd: <project root>`, `resolution: user-confirmed`, provenance that records
the user's opt-out, and `definition sources: PROJECT_CONTEXT.md
(user-confirmed opt-out)`. Never infer an opt-out from the absence of a
candidate.

Before each run, cheaply revalidate that the cached cwd, executable, script
or target body, provenance path, and definition sources still match the
files on disk. Re-resolve from the priority list only when that check fails.

If there is no usable candidate and no persisted explicit opt-out, stop and
ask the user before IMPL runs. `git diff --check` may be extra hygiene, but it
is never a substitute gate. In an autonomous or `/goal`-driven run, failure
to resolve is an escalation condition, not permission to degrade silently.

## Execute without hidden side effects

First revalidate the persisted resolution. If it has `command: skipped` and
the user-confirmed opt-out is still current, QUALITY GATE is a no-op
short-circuit: execute nothing, treat it as immediately satisfied for allowing
CRITIQUE to proceed, and consume none of the 3-failure retry counter because
there is nothing to fail.

For every non-skipped QUALITY GATE run:

1. Revalidate the cached resolution.
2. Confirm the cwd, executable, referenced scripts/targets, and target files.
3. Snapshot both `git status --porcelain=v1 -uall` and
   `git diff HEAD --binary` before execution. From that status snapshot, also
   record a collision-resistant content hash (prefer SHA-256) for every path
   already reported as untracked (`??`) at gate start. If hashing all of those
   paths is impractical, record size and modification time as an explicitly
   weaker fallback. Scope this identity map only to paths that were already
   untracked; do not scan all repository content.
4. Run the exact resolved local command in the persisted cwd with a timeout.
5. Capture stdout, stderr, and exit code without rewriting them.
6. Capture both Git snapshots again after execution. Re-hash the same
   initially-untracked paths (or repeat the recorded fallback), and escalate
   if any identity differs or can no longer be read. Also escalate on any
   unexpected delta in either Git snapshot. The status comparison continues
   to detect new or deleted untracked paths, while the identity comparison
   detects in-place content changes whose `??` status is unchanged.
7. Report stdout, stderr, and exit code verbatim.

A user-confirmed mutating exception never passes QUALITY GATE merely because
its command exits zero and produces only the expected delta. Its mutation is a
new write event, so the gate remains pending for the now-mutated tree. Run the
preidentified non-mutating verification command against that tree—prefer the
same tool's check-only mode; otherwise use the explicitly agreed appropriate
mechanical check—and apply the same snapshots and initially-untracked-content
identity checks to that pass. This mechanically required follow-up does not
consume a retry attempt merely by running. If it fails mechanically, that
failure consumes one normal failed-run attempt in the current activation; if
it is environmentally blocked, escalate immediately without consuming an
attempt. If no suitable non-mutating follow-up can run, the mutating command
cannot establish a pass.

The before/after `git diff` and `git status` comparison is a secondary
defense-in-depth measure. It detects an unexpected mutation only after it has
happened, so it never replaces the resolution-time rejection or explicit
confirmation of mutating commands.

Never auto-install a missing dependency. Treat command-not-found, missing
dependency, timeout, out-of-memory, and read-only-filesystem failures as
environmental.

## Retry cap and escalation

An **activation** begins **only** on the graph transition from SPEC into IMPL
or from DEBATE into REFACTOR. An IMPL or REFACTOR invocation made specifically
to fix a QUALITY GATE failure remains in the same activation and shares its
counter; it does not open a new activation or reset anything. Allow at most
**3 failed QUALITY GATE runs total per activation**. The first failed run
counts, so at most two mechanical fix attempts remain.

This cap is absolute. Never extend it because the number of raw errors fell.
A diagnostic signature may include the tool name, rule or error code,
canonical file, and normalized message, but use signatures only to classify
the final state as reduced, frontier moved, stuck on the same error,
oscillating, or environmental.

Environmental failures escalate immediately and consume none of the three
attempts. Reset the failed-run counter only after QUALITY GATE passes. After
that pass, a subsequent REFACTOR entered from a fresh DEBATE decision begins
a new activation with its own counter; a gate-failure retry does not.

Mechanical failure routes directly back to the writer that opened the
activation, never to CRITIQUE. Cap exhaustion escalates to the user with the
verbatim command results and diagnostic classification.
