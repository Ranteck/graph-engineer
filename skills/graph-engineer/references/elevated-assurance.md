# Elevated assurance: optional multi-lens CRITIQUE

Elevated assurance is an **optional variant of node 4 (CRITIQUE)** — not a new
node. It never activates by default and never activates silently: it requires
either an explicit user request or user confirmation after Claude reports a
matched risk trigger with concrete evidence. Standard single-thread CRITIQUE
(the behavior described in `../SKILL.md`) remains what every cycle uses unless
this reference's activation rule fires and the user agrees.

## Why this exists

Standard CRITIQUE already starts a fresh thread on its first call, so it does
not inherit the IMPL conversation. But it is still one Codex thread reviewing
its own family of outputs across the cycle: `--resume-last` gives it memory of
its own prior findings and Claude's triage decisions (valuable — it stops
Codex from restating findings already ruled debatable or false-positive), but
that same continuity can anchor the thread to its own earlier framing instead
of re-examining a REFACTOR'd artifact with fresh eyes. Nobody currently
reviews the final artifact "cold."

Elevated assurance adds two things standard CRITIQUE does not have: an initial
sweep of independent fresh-thread lenses with different angles, and a fresh
holistic reviewer ("exit challenger", rerun fresh whenever its own findings
change the artifact) before the cycle is allowed to reach VERIFY. It does
**not** add a fourth triage verdict, and it does **not** treat
lens agreement as a substitute for evidence — see "What this explicitly does
not do" below.

## What this explicitly does not do

- It does not make N-lens agreement a requirement for validity, and it does
  not make lens *disagreement* grounds for automatic dismissal. A defect a
  single lens found with concrete evidence is exactly as valid as one three
  lenses found. Never adopt "majority of lenses agree" as a classification
  tier alongside valid/debatable/false-positive — it stays exactly the three
  verdicts defined in `../SKILL.md` node 5.
- It does not turn N same-model Codex lenses into independent verification.
  They reduce single-thread anchoring and add angle diversity, but they share
  the same underlying model and its blind spots. Do not present a multi-lens
  pass as a substitute for genuinely independent review.
- It does not become the default. If no trigger matches and the user has not
  explicitly requested it, standard CRITIQUE runs, full stop.
- It does not change the node count. The cycle is still exactly 8 nodes
  (PRE-FLIGHT → SPEC → IMPL → QUALITY GATE → CRITIQUE → DEBATE → REFACTOR →
  VERIFY). Every lens call, the canonicalization call, and the exit challenger
  are all visits to node 4.

## Activation

### Recommendation triggers

Recommend elevated assurance when at least one of these is true, **backed by
concrete evidence** — an affected path, symbol, contract field, schema, or a
measured statistic. "This seems risky" is not evidence and does not qualify.

- The feature touches authentication, authorization, sessions, tokens,
  credentials, secrets, cryptography, signing, key handling, payments,
  balances, financial transfers, security-sensitive database queries, or
  migrations.
- The feature can delete, overwrite, publish, deploy, migrate, transfer, or
  otherwise irreversibly mutate user or external-system data.
- The feature introduces or changes concurrency, locking, idempotency,
  retries, distributed coordination, or external side effects.
- The contract changes a public API, a serialized or persisted schema, a
  protocol, a CLI contract, or a producer/consumer boundary shared by more
  than one component or workspace.
- SPEC's contract anticipates at least 8 changed implementation files, or the
  actual pre-CRITIQUE diff reaches at least 8 changed implementation files or
  500 added-plus-deleted non-generated lines (excluding vendored code,
  generated artifacts, and lockfiles).
- QUALITY GATE's persisted resolution is `mode: skipped`, or the feature has
  no executable functional verification able to exercise its critical
  behavior.
- The user explicitly asks for diverse lenses or elevated assurance.

### Decision timing

- **Full 8-node write cycle:** PRE-FLIGHT evaluates explicit authorization and
  any scope-level trigger visible before SPEC. At the end of SPEC, once the
  contract exists, Claude re-evaluates the triggers against the actual
  contract. Before IMPL runs, persist a final `standard` or `elevated`
  resolution — never leave it implicit.
- **Refactor-only:** there is no SPEC. PRE-FLIGHT decides from the requested
  scope and the code already on disk.
- **Review-only:** never writes `PROJECT_CONTEXT.md`. Record the opt-in
  decision and call budget in the user's prompt, the Claude turn, and the
  final report instead.

### User decision outcomes

- Explicit user request → persist `mode: elevated`, `resolution:
  user-requested`.
- Trigger matched, user confirms → persist `mode: elevated`, `resolution:
  user-confirmed-trigger`.
- Trigger matched, user declines → persist `mode: standard`, `resolution:
  user-declined-trigger`, and keep the declined trigger's evidence in the
  record.
- No trigger matched → persist `mode: standard`, `resolution:
  default-standard-no-trigger`, automatically, no user prompt needed.
- Trigger matched but no user decision is available yet (e.g. an autonomous
  `/goal` run with no one to ask) → **stop before IMPL and escalate.** Never
  silently elevate and never silently treat an unanswered trigger as
  declined.

### Persisted schema

Store this under the active feature's section in `PROJECT_CONTEXT.md`,
alongside (not replacing) `### Quality gate`:

```markdown
### Critique assurance
- mode: standard | elevated
- resolution: default-standard-no-trigger | user-requested | user-confirmed-trigger | user-declined-trigger
- trigger matches: <none, or the matched trigger identifiers>
- trigger evidence: <paths, symbols, contract fields, or measured diff facts>
- lens count: 1 | 3
- lens set: standard | correctness-contracts; integration-state-reproducibility; security-abuse-data-loss
- exit challenger: disabled | required-before-verify-or-done-rerun-until-clean
- CRITIQUE pass cap: <positive integer; default 3 standard / 5 elevated>
- Codex review/debate call budget: not-applicable (standard) | <positive integer; default 13 elevated>
```

Only the final resolution belongs here — this is not a runtime progress log.
Do not write intermediate states like "lens 1 completed" or "exit pending";
track those in the Claude turn instead, since a `PROJECT_CONTEXT.md` write per
lens would itself be an unrelated tree mutation between QUALITY GATE runs.

If the scope changes materially after IMPL and the persisted resolution no
longer fits (e.g. a trigger newly applies): stop before the next CRITIQUE,
get any newly required user authorization, update `### Critique assurance`,
treat that update as a tree mutation like any other, and run a fresh QUALITY
GATE before CRITIQUE resumes (see the amendment in
`quality-gate-detection.md`).

### Budgets: what's derived vs. what's a guess

- **The clean elevated call floors are structural, not guesses:** the full
  8-node write cycle has 5 Codex review calls — 6 Codex calls total counting
  IMPL: 3 lenses + 1 canonicalization + 1 exit challenger are the review
  calls. Clean refactor-only has the same 5-call review/total floor because
  it has no IMPL.
  Clean review-only instead has a 4-call review/total floor (3 lenses + 1
  canonicalization) because it has neither IMPL nor an exit challenger; its
  recommended 5-call budget allows at most 1 batched debatable reinjection.
  If the exit challenger itself finds a valid defect, its REFACTOR and the
  required re-run exit challenger add further calls beyond the applicable
  floor — this is expected, not a budget violation, and is exactly why the
  cap below exists as a real ceiling rather than a formality.
- **`CRITIQUE pass cap: 5` and `Codex review/debate call budget: 13` are
  template defaults, not derived or benchmarked values.** They exist so an
  autonomous `/goal` run has *some* documented ceiling instead of none —
  elevated assurance is the mode that multiplies Codex calls, which makes an
  unbounded run the worst possible default. Treat them as adjustable
  starting points: raise or lower them explicitly in your `/goal` text.
  Whichever number a user's `/goal` states overrides these defaults; if none
  is stated, these are what apply.
- The anti-loop cutoff (see the "Elevated-assurance pass accounting" addition
  in `../SKILL.md`'s Anti-loop cutoff section) can still stop the cycle earlier
  than either budget.

## The three lenses

Each lens receives the same feature contract, the same frozen artifact
identity, and the same read-only instruction. It does **not** receive the
builder's (IMPL's) narrative, and it does not see another lens's output. Each
lens may report a concrete defect outside its assigned angle — the angle is a
minimum responsibility, not a blindfold.

**Artifact identity.** `git rev-parse HEAD` plus `git status
--porcelain=v1 -uall` alone do **not** identify content: editing the bytes of
an already-modified tracked file, or of an already-untracked file, leaves
both unchanged (` M path` and `?? path` don't move), and neither one covers
tracked-file *content* at all. The identity is one deterministic digest: a
SHA-256 over the fixed-order concatenation of `git rev-parse HEAD`, the raw
`git status --porcelain=v1 -uall` output, `git diff HEAD --binary`, and a
NUL-delimited SHA-256 content-hash manifest of initially-untracked paths
built with the exact hashing protocol in `quality-gate-detection.md`'s
"Execute without hidden side effects" section, steps 3-4 (same hashing
rules — symlink/non-regular escalation, the 500-file/50-MiB limits — reused
here, not a separate weaker implementation). `Artifact identity: [digest]`
everywhere below refers to this one value; SHA-256 is collision-resistant,
not collision-proof, but sufficient for detecting accidental drift, which is
this protocol's actual purpose.

**Every time this digest is needed, compute it fresh by re-reading git state
and re-hashing current untracked-file bytes at that moment — never treat an
earlier computation, including QUALITY GATE's own snapshot, as reusable
without recomputing it.** The one narrow exception: if QUALITY GATE just
passed with `mode: check-only` (not `skipped`), its own after-execution
snapshot (`quality-gate-detection.md` step 7) was itself a fresh read of
current state — use it as the baseline the very first time it's needed,
immediately after, without a redundant extra read. `mode: skipped` produces
no snapshot at all (see `quality-gate-detection.md`'s no-op short-circuit)
and must never be treated as a baseline source — for a skipped gate, and for
every other capture point, compute the digest fresh from disk:

- **Full 8-node write cycle with a `mode: check-only` gate that just
  passed:** use its fresh after-execution snapshot as the baseline for the
  lens dispatch.
- **Full 8-node write cycle with `mode: skipped`, and refactor-only's initial
  sweep** (no preceding QUALITY GATE run — see `../SKILL.md`'s refactor-only
  entry path): compute the digest fresh, specifically for this purpose,
  immediately before dispatching the lenses.
- **Refactor-only after its first REFACTOR:** same rule as the full 8-node
  write cycle — use QUALITY GATE's fresh after-execution snapshot if `mode:
  check-only` just passed; compute fresh if `mode: skipped`.
- **Review-only** (never runs QUALITY GATE at all): compute the digest fresh
  immediately before dispatching the lenses.
- **Every exit-challenger call, including reruns:** compute the digest fresh
  immediately before that specific call — never reuse an earlier lens
  sweep's or canonicalization's digest, which is stale by construction.

**Comparisons are required both before dispatch and after completion — a
citation in the prompt with no check either side is not a guarantee.** Each
comparison recomputes the digest fresh (per the rule above) and checks it
against the digest captured for that step:

- Before dispatching each lens, canonicalization, or exit-challenger call,
  recompute and compare against the digest just captured for that call.
  Mismatch means a write landed in the gap the barrier is designed to
  prevent — stop and escalate instead of dispatching against a moving
  target.
- After all 3 lenses terminate (a single comparison covering the set, not
  one comparison per individual lens, since they run concurrently), before
  fan-in/canonicalization, recompute and compare against the digest used
  for the lens dispatch. Mismatch means the reviewed artifact is no longer
  current — discard the lens results and escalate rather than normalizing
  findings about a superseded artifact.
- After every canonicalization call, including a late-lens replacement one,
  recompute and compare before accepting its output as canonical. Mismatch
  escalates instead of adopting a ledger for an artifact that changed
  mid-review.
- After every exit-challenger call, recompute and compare before accepting
  its findings or clearing entry to VERIFY/DONE. Mismatch escalates instead
  of letting a changed artifact silently pass on the strength of a review of
  what it used to be.
- **If the digest cannot be constructed or recomputed at any checkpoint —
  an unreadable or non-regular untracked path, a safety-limit breach, or a
  failed underlying git/hash operation — or equality cannot be conclusively
  proven either way, treat that identically to a mismatch: stop and
  escalate.** Absence of proof is not proof of a match.

This is sampled identity validation, not an immutability guarantee: a
before/after digest comparison cannot detect a write-then-restore race that
happens entirely inside the gap between two checks and leaves the digest
unchanged. An actual immutable snapshot (e.g. a dedicated worktree or a
locked checkout) would be required to close that specific gap; this protocol
does not claim to. Treat it as "no undetected persistent drift," not "no
possible interference."

1. **`correctness-contracts`** — contract compliance, core invariants,
   inputs/outputs/errors, acceptance criteria, incorrect assumptions, missing
   behaviors.
2. **`integration-state-reproducibility`** — cross-file and cross-component
   behavior, state transitions, concurrency, retries, idempotency,
   environmental assumptions, reproducibility, regression/compatibility
   risk.
3. **`security-abuse-data-loss`** — authorization boundaries, secret
   handling, injection, abuse, privilege escalation, irreversible
   operations, unsafe failure modes, migration and data-integrity hazards.

Each lens call:

```
Agent(subagent_type: "codex:codex-rescue", prompt: "Adversarially review the
current implementation of [feature] against PROJECT_CONTEXT.md, focused on
[lens angle], but report any other severe defect you notice too. Challenge
the approach, design choices, and assumptions — don't just list defects.
Artifact identity: [digest].
Read-only: do not fix anything, just report findings. --fresh --wait")
```

## Dispatch and fan-in sequence (the barrier)

This ordering exists because of a concrete, verified property of the pinned
`openai-codex` v1.0.6 plugin: `--resume-last` resolves to whichever tracked
task has the newest `updatedAt`, there is no resume-by-thread-ID in the
callable `task` interface, and **a `--resume-last` call specifically is
rejected outright while another tracked task is still `queued`/`running`**
(this guard lives in the `--resume-last` resolution path; a fresh, non-resumed
call is not blocked by it and can run concurrently with an in-flight tracked
task). That means a lens that finishes *after* the canonicalization call
starts can silently become the "latest" thread the next `--resume-last`
resolves to — corrupting continuity without any error being raised, and
nothing in the runtime stops a stray fresh call from being started
concurrently by mistake either. The barrier below exists specifically to
prevent both.

1. Dispatch all 3 fresh, read-only lens `Agent` calls together, in the
   foreground and waiting for each to finish — pass `--fresh --wait` on
   every lens call, never `--background`. `--wait` is not implied by
   `--fresh` alone; the underlying `codex-rescue` wrapper may otherwise
   choose background execution for a request it judges complex, and
   background execution is exactly what this barrier cannot tolerate.
2. Do not start any other Codex task in this repository while the lenses are
   in flight.
3. Wait for all 3 to reach a terminal state (report received) before doing
   anything else. If any lens fails, times out, or returns no final report:
   **stop elevated assurance and escalate.** Do not silently continue with 2
   lenses, and do not silently downgrade to standard CRITIQUE.
4. Claude performs fan-in and normalization (see below) once all 3 are
   terminal.
5. Only then start one fresh, read-only **canonicalization** call. Give it
   the contract, the same artifact identity used for the lenses, **the 3
   raw lens reports verbatim** (not only the normalized ledger — without the
   raw reports it has no way to judge whether Claude's normalization merged
   or dropped something incorrectly), and the normalized ledger built from
   them, with an instruction to challenge the normalization against the raw
   reports and adopt the resulting ledger as its own continuity state:

   ```
   Agent(subagent_type: "codex:codex-rescue", prompt: "Three independent
   read-only reviews of [feature] against PROJECT_CONTEXT.md were just
   completed. Raw reports below, followed by Claude's normalization of them
   into one finding per underlying claim. Challenge the normalization
   against the raw reports — does it accurately represent them, did
   anything get merged that shouldn't have been, did anything get dropped?
   Then adopt the (corrected, if you found an error) ledger as your own
   continuity state for future review rounds in this cycle.
   Artifact identity: [digest].
   Raw lens reports: [correctness-contracts report], [integration-state-
   reproducibility report], [security-abuse-data-loss report].
   Normalized ledger: [normalized finding records].
   Read-only: do not fix anything. --fresh --wait")
   ```

6. Await its completion. From this point on, no other fresh Codex task may
   intervene before a deliberate thread replacement (the exit challenger).
7. Every later DEBATE-driven reinjection, REFACTOR, and subsequent ordinary
   CRITIQUE call in this cycle uses `--resume-last` as in standard mode —
   now targeting the canonicalization thread.

The 3 lens calls, Claude's fan-in, and the canonicalization call together
count as **one** CRITIQUE pass (see the accounting rule this reference's
integration adds to `../SKILL.md`'s Anti-loop cutoff section).

### Late-lens rule

If, despite the barrier, a lens is discovered to have completed *after*
canonicalization began or completed:

- Treat the canonical thread as invalid — the late completion may now be what
  `--resume-last` actually resolves to.
- Do not issue `--resume-last` until this is resolved.
- Wait until every lens is confirmed terminal.
- Merge the late result into the finding ledger.
- Start a **replacement** fresh canonicalization call after all lenses are
  terminal, and treat the earlier canonicalization as superseded.
- If terminal state cannot be proven (e.g. status is ambiguous), stop and
  escalate rather than guessing.

## Normalized finding record

Claude clusters lens reports by the underlying claim they make, not by
wording, and produces one record per distinct claim:

```text
finding_id
title
severity
underlying_claim
evidence
reported_by_lenses
corroboration_count
conflicting_assessments
triage_status
triage_reason
```

Rules:

- Three differently-worded reports of the same underlying claim are one
  finding, not three.
- `corroboration_count` increases confidence but never determines validity by
  itself.
- A single-lens finding with concrete evidence can be `valid`. Corroboration
  from other lenses is not a precondition.
- Explicit disagreement between lenses about the same claim normally routes
  that finding to `debatable`, not to automatic dismissal.
- Apply the existing DEBATE classification (`../SKILL.md` node 5) to each
  record: valid / debatable / false positive. There is no fourth verdict.

For cost containment, batch all `debatable` records from one CRITIQUE pass
into a single reinjection call using stable `finding_id`s, rather than paying
one Codex round-trip per duplicate report.

## Exit challenger

Gates entry to the cycle's terminal step — **VERIFY** in the full 8-node
write cycle, or **DONE** in refactor-only, which has no VERIFY node. Runs after
DEBATE first reaches "no valid findings remain."

- Must be fresh and read-only; confirm no other Codex task is active first.
- Give it the original contract (or, in refactor-only, the requested scope
  and criteria — there is no SPEC contract), the current final artifact, and
  any user-supplied criteria — but **not** the prior finding ledger. Its
  value is a cold, holistic read of the result, not a continuation of the
  prior triage.
- When it completes, it **intentionally** becomes the new latest/canonical
  thread — this is expected, not a bug.
- If it reports **no valid findings**, the gate is satisfied: proceed to
  VERIFY (or DONE in refactor-only).
- If it reports findings that DEBATE classifies as valid, they go through
  REFACTOR/QUALITY GATE like any other valid finding, resuming its thread
  with `--resume-last` and carrying a concise inline continuity summary of
  the relevant prior findings and triage decisions (this thread did not see
  the prior lens findings). **Because REFACTOR can change the artifact the
  exit challenger already blessed, run one more fresh exit challenger after
  that REFACTOR before the cycle may proceed to VERIFY/DONE** — repeat until
  one exit challenger pass reports no valid findings on the then-current
  artifact. Each such re-run is a distinct CRITIQUE pass and consumes budget
  like any other; it is bounded by the same CRITIQUE pass cap and anti-loop
  cutoff as the rest of the cycle, not exempt from them.
- "One exit challenger per cycle" is not the rule — the rule is: **the last
  exit challenger to run must report no valid findings against the artifact
  that is about to enter VERIFY/DONE.** Do not proceed to VERIFY/DONE on the
  strength of an earlier exit challenger pass whose approved artifact has
  since changed.

```
Agent(subagent_type: "codex:codex-rescue", prompt: "Review the current final
implementation of [feature] against PROJECT_CONTEXT.md (or the requested
scope/criteria in refactor-only) and these criteria if any: [criteria]. You
have no prior review history for this — treat this as a first, cold look at
the finished result.
Artifact identity: [digest].
Challenge the approach, design choices, and assumptions — don't just list
defects. Read-only: do not fix anything, just report findings. --fresh --wait")
```

## Review-only variant

- Uses the existing lighter review-only PRE-FLIGHT (no clean-tree or
  writable-filesystem requirement); still does not write
  `PROJECT_CONTEXT.md`.
- Runs the 3 fresh lenses, Claude fan-in, and one canonicalization call — but
  no REFACTOR, no QUALITY GATE, no VERIFY, and no exit challenger (there is
  no final artifact distinct from what was just reviewed).
- Canonicalization exists here only to support at most one batched DEBATE
  reinjection for debatable findings.
- Recommended reviewer budget: 5 calls (3 lenses + canonicalization + at most
  1 batched reinjection).
- The final report includes the normalized findings, their lens provenance,
  and all three classifications (valid/debatable/false-positive) — never
  degrade to reporting only one reviewer's output because a lens failed;
  an incomplete lens sweep escalates instead.

See `goal-templates.md` for the ready-to-use `/goal` templates
(write-authorized and review-only) that authorize this mode.
