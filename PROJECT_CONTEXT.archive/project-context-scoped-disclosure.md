## project-context-scoped-disclosure

### Quality gate

- **Resolution**: `mode: skipped`
- **Reasoning**: Same as `backend-selection` above — this repo has no build,
  lint, test, or CI tooling (no `package.json`, `Makefile`, CI config, or dev
  docs describing a command). `CLAUDE.md` states explicitly: "There is
  nothing to build, lint, or test." Per `quality-gate-detection.md`'s
  resolution order, this is a legitimate `skipped` resolution, not a
  no-usable-candidate stop condition.
- **Resolved by**: PRE-FLIGHT, this cycle.

### Critique assurance

- **mode**: `elevated`
- **resolution**: `user-confirmed-trigger`
- **trigger matches**: (1) QUALITY GATE resolved to `mode: skipped` — the
  feature has no executable functional verification able to exercise its
  behavior, a listed recommendation trigger in `elevated-assurance.md`. (2)
  The contract changes a protocol/schema shared by every repo that consumes
  this skill (the internal structure of each consuming repo's own
  `PROJECT_CONTEXT.md`) and touches this skill's own core safety invariants —
  CRITIQUE/exit-challenger cold-review independence (node 4,
  `elevated-assurance.md`) and the "`PROJECT_CONTEXT.md` is Claude's only
  writable artifact" boundary (`CLAUDE.md`'s Core design invariant, `SKILL.md`
  intro) — a broad blast radius analogous to "changes a public API/contract
  shared by more than one component."
- **trigger evidence**: `PROJECT_CONTEXT.md` `### Quality gate` above;
  `SKILL.md`'s node 4 CRITIQUE dispatch templates and node 0's writable-
  artifact invariant; this repo's own `CLAUDE.md` "Core design invariant"
  section; measured evidence from prior design discussion: real consuming
  repos' `PROJECT_CONTEXT.md` reached 3,168 lines (`trading-engine_v3`, one
  active feature section alone 1,753 lines / 112,060 characters) and 2,624
  lines (`trading-engine_v2`), and `SKILL.md`'s own section-scoping
  instruction (`SKILL.md:392-398`) was verified absent from the actual
  dispatch prompt templates (`SKILL.md:401-404`, `513-530`) — a design gap in
  the skill's own contract, not a hypothetical risk.
- **User decision**: User confirmed "Elevated" via `AskUserQuestion` at
  PRE-FLIGHT (scope-level, pre-SPEC), given this exact reasoning.
- **lens count**: 3
- **lens set**: correctness-contracts; integration-state-reproducibility;
  security-abuse-data-loss
- **exit challenger**: required-before-verify-or-done-rerun-until-clean
- **CRITIQUE pass cap**: 5 (template default)
- **Codex review/debate call budget**: 13 (template default)
- **Resolved by**: PRE-FLIGHT initial evaluation, confirmed unchanged at end
  of SPEC; this is the final settled elevated resolution for the cycle.

### Backend

- **backend**: `codex` (not specified by user for this cycle)
- **resolution**: `default-codex`
- **resolved session**: not-applicable
- **disclosure**: not-applicable (default backend)
- **Resolved by**: PRE-FLIGHT, this cycle.

### Checkpoint commits

- **Authorized**: yes (default).
- **Reasoning**: `commit.gpgsign` is unset, branch is `develop` (not detached
  HEAD, not `main`), and `.git/hooks/` contains no active hook that would
  mutate the tree or block on a passphrase (only the repo's own
  `PreToolUse`/`PostToolUse` Claude Code hooks, which are non-blocking or
  narrowly scoped — see `.claude/settings.json` and
  `.claude/hooks/*.sh`). No condition from `SKILL.md` node 0's checkpoint
  policy applies that would make a non-interactive local commit unsafe.

### Feature contract

#### Current state

**Problem.** `PROJECT_CONTEXT.md` grows without a lifecycle boundary when an
active feature mixes its present contract with every earlier revision and when
completed feature sections remain in the live file. A single active section
can itself become large (measured at 1,753 lines / 112,060 characters in a
consuming repository). Dispatched nodes also require different context:
continuity-aware triage needs history, while fresh lenses and the exit
challenger need a cold view of the current artifact. The disclosure policy is
instruction-based rather than a sandboxed read boundary.

**What it does.** Four coordinated changes to how every
write-authorized mode (full 8-node cycle, refactor-only) reads and writes a
feature's section in `PROJECT_CONTEXT.md`:

1. **Split every feature section into two named subheadings, enforced from
   SPEC onward:**
   - Every lifecycle feature name must already match lowercase ASCII
     `[a-z0-9-]+`; reject and escalate before writing any heading rather than
     normalizing an invalid name. Resolve the active feature heading by exact
     match to `## <feature-name>`. SPEC creates a new full-cycle feature
     section (and `PROJECT_CONTEXT.md` itself if needed); refactor-only
     PRE-FLIGHT creates its section and scaffolding because there is no SPEC.
     Feature names are unique by convention and chosen by the orchestrating
     Claude, not untrusted input. Heading uniqueness is not mechanically
     counted or verified; duplicate or archived-name collisions are a
     documented, accepted risk.
   - PRE-FLIGHT resolves Quality gate and Backend for every write-authorized
     full cycle and gives any mandatory non-Codex disclosure to the user before
     SPEC. If the feature section already exists, PRE-FLIGHT persists those
     values before SPEC. If it does not, SPEC persists them in its initial
     section-creation write with the contract—the earliest context write that
     is actually possible. This timing clarification adds no heading-count or
     cardinality enforcement.
   - The closed grandfathered feature-name list contains exactly
     `backend-selection`, the only section that predates this lifecycle. If that
     section lacks `#### Current state` and `#### Round log`, full-cycle SPEC or
     refactor-only PRE-FLIGHT first checks its existing `### Feature contract`
     body for a line matching the forbidden-heading pattern
     `^[ ]{0,3}#{2,4}([ \t]|$)`. Only when no line matches does it perform the
     one-time additive upgrade: the body becomes initial Current state
     byte-for-byte and an empty Round log is appended, then the ordinary
     sentinel validation runs. If a line matches, stop and escalate without
     attempting the upgrade or rewriting the body. A sentinel-less section
     whose feature name is not on that closed list is an ordinary
     missing-sentinel validation failure: it is not eligible for upgrade, so
     stop and escalate. Prior history is never reconstructed.
   - `#### Current state` — bounded and rewritten in place: the current
     contract or refactor-only scope/criteria. It contains no latest-round
     marker, rejected alternative, past actor refusal, prior-review conclusion,
     or other historical narrative. The existing `### Quality gate`, `###
     Critique assurance`, `### Backend`, and `### Checkpoint commits`
     resolutions remain in their current form and position as bounded current
     resolutions. Claude reads the last `#### Round log` entry when DEBATE or
     the anti-loop cutoff needs the latest completed iteration.
   - `#### Round log` — append-only and chronological, with one composite
     record per checkpointed writer iteration (`IMPL-r00` or
     `REFACTOR-rNN`), plus a `CRITIQUE-rNN-noop` record for a CRITIQUE-only
     terminal pass. Each record combines the CRITIQUE outcome, DEBATE
     classifications, resulting writer work (or `none`), actors/backend, a
     checkpoint locator, and optional decision notes. SPEC and individual
     CRITIQUE/DEBATE nodes do not get standalone entries.
     A checkpointed composite is written in the same commit as its writer
     changes. `Checkpoint: locate-by-feature-and-round` resolves uniquely from
     the current branch's first-parent ancestry using the literal subject token
     `graph-engineer(<feature-name>):` plus exact full-message lines
     `Round: <round>` and `Cycle-State: CHECKPOINT`; zero or multiple matches
     stop and escalate. The mandatory `[a-z0-9-]+` name grammar excludes the
     subject token's parentheses/colon delimiters, so a feature name cannot
     inject a forged token boundary.
     It does not rely on Git's formal trailer parser. `Checkpoint: none` means
     no checkpoint exists. No stored hash, placeholder, or later backfill is
     used. Design rationale and review history stay in `Decision notes`, and
     secrets are referenced only by nature/location. A missing or duplicate
     composite is a protocol inconsistency, not a best-effort repair cue.

2. **Node-specific instruction-based disclosure.** Codex's sandbox blocks
   CRITIQUE writes, not reads, and Claude `Explore` retains shell access and
   can read or indirectly mutate other content. IMPL, CRITIQUE, and REFACTOR
   prompts therefore inline the permitted `#### Current state` raw bytes in an
   unambiguous fenced block and instruct the actor not to open the context file
   or read `#### Round log`:
   - Resolve the active feature heading by exact match to
     `## <feature-name>` before sentinel validation, extraction, or dispatch.
   - The active feature must contain exactly one canonical `#### Current state`
     sentinel line and exactly one later canonical `#### Round log` sentinel
     line. The orchestrator extracts strictly between those exact lines.
   - Any intervening line matching `^[ ]{0,3}#{2,4}([ \t]|$)` is invalid and
     stops/escalates. Backtick and tilde runs are uninterpreted bytes; there is
     no fence parser or balance state.
   - The same count/order/body validation runs immediately after every write
     to Current state and immediately before every inlining dispatch. The
     extracted bytes are preserved exactly and dynamically outer-fenced;
     `context-lifecycle.md` is authoritative for serialization.
   - **SPEC**: reads and writes the full section, validates Current state after
     writing, and is summarized later in the `IMPL-r00` composite.
   - **IMPL**: receives the fenced `#### Current state` bytes inline.
   - **Ordinary resumed CRITIQUE** (`--resume-last`, standard mode or an
     elevated-mode resumed canonical round): receives fenced `#### Current
     state` bytes inline;
     relies on Codex's own session memory (`--resume-last`) for round
     continuity, not a re-read of `#### Round log`.
   - **Elevated fresh lenses**: receive fenced `#### Current state` bytes and
     no `#### Round log`, reducing shared-history anchoring.
   - **Exit challenger**: receives fenced `#### Current state` bytes (contract,
     current artifact, criteria) and no `#### Round log` or finding ledger.
   - **REFACTOR**: receives the triaged fix list plus fenced `#### Current
     state` bytes — never `#### Round log`.
   - **DEBATE/Claude's own triage** (not dispatched to a backend actor): may
     read `#### Round log` in full when needed — the anti-loop cutoff
     (`SKILL.md`) explicitly requires comparing consecutive CRITIQUE passes,
     which needs this history; Claude is not subject to the "stay cold"
     disclosure rule the dispatched reviewers are.
   - **A human or a future cycle** investigating a past decision reads
     `#### Round log` directly by round id.

3. **Archival at the terminal transition, as the sole second narrowly scoped
   writable path.**
   - New path: `PROJECT_CONTEXT.archive/<feature-slug>.md`, one file per
     archived feature, in the same consuming repo as `PROJECT_CONTEXT.md`
     (sibling directory, not inside `.git`).
   - **Trigger**: only at VERIFY's pass in the full 8-node write cycle, or at
     the final DONE-clearing CRITIQUE/exit-challenger pass in refactor-only —
     i.e. only once the cycle has already reached its existing terminal
     success condition. This is not a new node; it is folded into the
     existing terminal-commit step under node 3's checkpoint mechanics, using
     `Cycle-State: COMPLETE` instead of `CHECKPOINT`. Before either terminal
     edge declares DONE, `SKILL.md` explicitly invokes this transition.
   - **Zero-REFACTOR refactor-only exception**: when the first CRITIQUE finds no
     valid findings, bracket an empty porcelain-status check with two matching
     HEAD reads before any context write and retain that HEAD. DEBATE is pure
     reasoning. At the final clean pass, with zero REFACTOR rounds, repeat
     HEAD/status/HEAD before any write and require both HEAD values to match the
     baseline. Only then append one deferred composite no-op record. Stage
     exactly `PROJECT_CONTEXT.md`, reject unstaged/untracked residue, and
     recheck HEAD. As the last check, require the staged path/diff inspection
     to contain only that active-feature record, then invoke `git commit`
     immediately with no command in between. The invocation is content-inert:
     its only arguments may supply the prescribed message, with no
     `-a`/`--all`, `--include`, `--only`, `--interactive`, `--patch`, or
     pathspec arguments, so it records only the explicitly staged index. Any
     mismatch or command failure stops and escalates. The reviewer artifact
     digest remains available to elevated and non-Codex review paths but is
     not used for this gate.
   - **Slug/path safety**: because the feature name already matches lowercase
     ASCII `[a-z0-9-]+`, `<feature-slug>` is exactly that name; do not normalize
     it. Reject `/`, `..`, a leading `.`, an empty slug, any canonicalized path
     outside the resolved archive directory/repository, a symlinked archive
     directory, or a non-immediate-child target. PRE-FLIGHT recursively
     enumerates the archive tree and treats any archive-relative subdirectory
     separator as invalid.
   - **What moves**: the ENTIRE feature section — `#### Current state` and
     `#### Round log` — verbatim, losslessly. No summarization, no
     compaction. `PROJECT_CONTEXT.archive/<feature-slug>.md` is the full
     record; nothing is thrown away.
   - **What replaces it**: `PROJECT_CONTEXT.md`'s `## <feature-name>` heading
     is replaced with a one-line pointer: feature name, one-line outcome
     summary, completion date, the archive file's relative path, the SHA-256
     of the archived section, and the short hash of the **last checkpoint
     commit before this archival move** (the commit that holds the feature's
     finished work), never the archival commit's own self-referential hash. The
     archival commit itself needs no stored hash to be located: it is
     self-identifying via its own `Cycle-State: COMPLETE` message, exactly
     like every other checkpoint commit is located by its `Cycle-State`/round
     label — `git log --grep` for that trailer plus the feature name finds
     it directly.
   - **Atomicity**: the archive-file write, the `PROJECT_CONTEXT.md`
     rewrite, and the terminal `git commit` happen together as one commit —
     never as separate commits, and never with one landed and the other
     pending. If checkpoint commits were not authorized for this cycle (node
     0), skip the archival move entirely and escalate to the user instead of
     leaving an uncommitted archive write on disk. Capture HEAD when the
     sequence starts; after every other check, re-verify the same HEAD. Then,
     as the last check, inspect the staged path set and diff for exactly
     `PROJECT_CONTEXT.md` plus the intended archive file and the byte-exact
     move/pointer contents, and invoke `git commit` immediately with no command
     in between. Use a content-inert invocation whose only arguments supply the
     prescribed message: no `-a`/`--all`, `--include`, `--only`,
     `--interactive`, `--patch`, or pathspec arguments. Abort without
     committing and escalate on any mismatch; do not retry blindly.
   - **Interruption/inconsistency handling**: a future cycle entering
     PRE-FLIGHT on this repo must check, for every feature heading in
     `PROJECT_CONTEXT.md`, that a pointer's claimed archive is a regular
     non-symlink file resolving within the repository, exists, and matches the
     pointer's SHA-256, and that no archive descendant exists without exactly
     one valid pointer. Missing/hash-mismatched/orphan/nested/symlinked state
     is a stop-and-escalate condition at PRE-FLIGHT, not something to silently
     repair or guess about.

4. **Operational preconditions, identity, and continuity limits.** At most one
   active graph-engineer cycle may run per repository; concurrent cycles are
   unsupported and can corrupt shared context/index/branch state. In
   particular, making staged-content inspection the last command immediately
   before each applicable commit narrows but does not eliminate the residual
   race window; this protocol has no lock or compare-and-swap binding the
   inspected index to the commit. Every applicable commit is content-inert and
   records only the explicitly staged index; selection-changing flags and
   pathspecs are forbidden. In refactor-only, PRE-FLIGHT commits its own
   Quality gate/Backend/Critique
   assurance scaffolding immediately before the first CRITIQUE so a no-op run
   cannot leave it pending. Every resumed CRITIQUE, DEBATE reinjection, and
   REFACTOR prompt names the active feature and stops if the resumed memory is
   for another feature. This mitigates but does not eliminate the pinned
   plugin's recency-based `--resume-last` limitation.
   `elevated-assurance.md` defines one canonical artifact digest as a literal
   shell recipe over NUL-delimited HEAD, porcelain status, binary diff, and
   sorted untracked-file path/content hashes. Its plain `mktemp` call uses the
   environment/system temporary-path resolution rather than a fixed `/tmp`
   template. Both sides of every comparison must use that recipe. Its drift
   coverage is limited to Git-visible tracked final working-tree content and
   coarse index/working-tree status plus
   initially untracked, non-ignored regular files; it does not cover ignored
   files, submodule internals, or
   filesystem state outside Git's view, and it does not uniquely encode
   different partially staged index splits when HEAD, final working-tree bytes,
   and porcelain status are otherwise identical.

**Explicitly out of scope for this feature**: lossy compaction or summarization
of `#### Round log`; one-live-file-per-active-feature layout; rewriting a
grandfathered section's contract content or reconstructing its history beyond
the one-time additive envelope upgrade; changing the fixed 3-lens set, the
exit-challenger fan-in barrier, or elevated-assurance mechanics unrelated to
disclosure/identity; and changing `quality-gate-detection.md`'s resolver.

**Consistency requirement.** `context-lifecycle.md` is authoritative for the
two-subheading shape, one-time grandfathered-section envelope upgrade,
byte-exact prompt disclosure, round history, no-op rule, and archival mechanics.
`SKILL.md` links each affected node to it;
`elevated-assurance.md` owns the canonical artifact-identity recipe;
`backend-selection.md` reuses both contracts for every backend. The
orchestrator's archive write remains limited to the terminal transition. The
autonomous goal templates stop on Current-state sentinel/count/order or
forbidden-heading validation failure, and their completion conditions require
the terminal transition, the verified zero-REFACTOR no-op, or the
corresponding escalation.

#### Round log

##### IMPL-r00

- **Actors/backend**: Claude orchestrator and Codex writer / `backend: codex`
- **CRITIQUE outcome**: not applicable — initial implementation preceded the
  first review.
- **DEBATE classifications**: not applicable.
- **Resulting writer work**: Added the lifecycle reference, node-scoped
  disclosure, terminal archival protocol, and cross-file routing.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: The archive pointer stores the preceding finished-work
  checkpoint rather than the archival commit's impossible self-hash.

##### REFACTOR-r01

- **Actors/backend**: Elevated Codex reviewers, Claude triage, and Codex writer
  / `backend: codex`
- **CRITIQUE outcome**: Found cold-review disclosure, terminal-edge, path,
  identity, continuity, and archival-integrity gaps in IMPL-r00.
- **DEBATE classifications**: F1-F11 and F13 valid; F12 false-positive because
  the accepted pointer stores the preceding checkpoint, not a self-hash.
- **Resulting writer work**: Applied the first lifecycle, archival, disclosure,
  no-op, identity, and recovery corrections.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: A resumed write selected an unrelated cancelled session,
  confirming the named-feature memory check is a mitigation rather than
  resume-by-thread identity. A per-feature live-file split and lossy log
  compaction remained out of scope because neither bounds one active feature
  while preserving the full record.

##### REFACTOR-r02

- **Actors/backend**: Codex reviewer, Claude triage, and Codex writer /
  `backend: codex`
- **CRITIQUE outcome**: Confirmed F2, F4, F6-F11, and F13 closed; found F1, F3,
  and F5 residuals plus an underspecified digest encoding.
- **DEBATE classifications**: All four residual findings valid.
- **Resulting writer work**: Moved decision history out of Current state,
  strengthened the zero-REFACTOR identity gate, specified byte-exact inline
  extraction/serialization, and pinned the canonical digest recipe.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Pre-recipe digest strings used ad hoc delimiters and are
  not comparable to canonical values; the earlier clean-state conclusion was
  based on the three lenses' agreeing recomputations.

##### REFACTOR-r03

- **Actors/backend**: Codex reviewer, Claude triage, and Codex writer /
  `backend: codex`
- **CRITIQUE outcome**: Found F3 and F5 still partial, plus undefined
  checkpoint backfill and overclaimed digest coverage.
- **DEBATE classifications**: All four findings valid.
- **Resulting writer work**: Added fail-closed EOF extraction, reordered the
  no-op comparison before context writes, introduced checkpoint backfill, and
  scoped digest guarantees to Git-visible state.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: This iteration exposed that prose parsing, digest-gated
  no-op identity, and opportunistic hash backfill remained fragile even after
  their local edge cases were patched.

##### REFACTOR-r04

- **Actors/backend**: Codex design reviewer, Claude triage, and Codex writer /
  `backend: codex`
- **CRITIQUE outcome**: Confirmed F3 and F5 remained partial, checkpoint
  backfill was not followed by its introducing round, and the digest did not
  uniquely encode partially staged index state; challenged all three designs.
- **DEBATE classifications**: F3, F5, checkpoint-backfill ordering, and
  partial-index digest identity were valid under the corrected design; their
  root simplifications were exact sentinels, HEAD plus clean-tree for the no-op
  gate, immutable checkpoint locators, and composite iteration records.
- **Resulting writer work**: Replaced the fence parser, no-op digest gate,
  mutable checkpoint hash, and per-node best-effort ledger with the simplified
  present contracts; terminal archival mechanics remain unchanged.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Backtick and tilde runs are uninterpreted payload bytes.
  Structural validation runs after Current-state writes and before dispatch;
  generic autonomous goals stop on failure. This same checkpoint performs the
  one-time migration of pre-r04 per-node history into composites; future
  writer iterations may not defer their own record.

##### REFACTOR-r05

- **Actors/backend**: Prior Codex reviewer, user-confirmed triage, and Codex
  writer / `backend: codex`
- **CRITIQUE outcome**: Found feature-heading ambiguity, an overclaimed
  inspect-then-commit binding, a substring-collision-prone checkpoint locator,
  non-canonical migrated verdict vocabulary, and a fixed `/tmp` assumption in
  the canonical digest recipe.
- **DEBATE classifications**: All five findings valid.
- **Resulting writer work**: Required one exact active-feature heading, made
  staged-content inspection the last check adjacent to each applicable commit,
  delimited checkpoint subjects, normalized the migrated verdicts, and made
  temporary-file creation environment-aware.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Inspection adjacency narrows but does not eliminate the
  residual race window; the one-active-cycle precondition remains mandatory.

##### REFACTOR-r06

- **Actors/backend**: Prior Codex reviewer, user-confirmed triage, and Codex
  writer / `backend: codex`
- **CRITIQUE outcome**: Found that exact-one heading resolution prevented new
  feature creation, commit invocations could still expand the inspected index,
  unconstrained feature names could inject the checkpoint subject delimiter,
  and seven autonomous goal templates omitted the heading-resolution stop.
- **DEBATE classifications**: All four findings valid.
- **Resulting writer work**: Added the phase-limited SPEC/refactor-only
  bootstrap, made file-versus-heading creation explicit, required
  `[a-z0-9-]+` feature names, constrained every applicable commit to the
  explicitly staged index, and extended all seven goal-template stop clauses.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: The zero-match exception ends immediately after the
  initial section write; from then on, missing, zero, or duplicate resolution
  is fail-closed. The feature-name grammar makes the delimited subject token
  structurally non-injectable.

##### REFACTOR-r07

- **Actors/backend**: User-directed descope and Codex writer / `backend: codex`
- **CRITIQUE outcome**: Follow-on review found that the exact-one heading rule
  and its bootstrap exception could not distinguish new from prior malformed
  or archived identity, complicated disclosure ordering, and left
  grandfathered sections without a maintainable path.
- **DEBATE classifications**: All three follow-on findings valid; no finding
  was reclassified as false-positive. The user accepted the residual
  duplicate/archived-name collision risk and descoped mechanical uniqueness.
- **Resulting writer work**: Restored simple exact-heading resolution, removed
  the heading-count/bootstrap and goal-template stop machinery, and documented
  feature-name uniqueness as a convention and accepted risk. Retained the
  `[a-z0-9-]+` name grammar and all unrelated r01-r06 safeguards.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Feature names are selected by the orchestrating Claude,
  not untrusted input. This repository has had two feature identities and no
  observed name collision; the theoretical completeness gap is deliberately
  not enforced mechanically.

##### REFACTOR-r08

- **Actors/backend**: Prior Codex reviewer, user-confirmed triage, and Codex
  writer / `backend: codex`
- **CRITIQUE outcome**: Confirmed r07 removed the intended heading-cardinality
  mechanism but also removed two independent fixes: earliest-possible
  new-feature metadata persistence and one-time grandfathered-section
  structural upgrade. Also found README/governing timing drift, provisional
  assurance metadata, and inaccurate r07 provenance.
- **DEBATE classifications**: All five findings valid.
- **Resulting writer work**: Restored the additive legacy-section envelope
  upgrade, clarified conversation disclosure versus earliest possible
  persistence, synchronized README/CLAUDE/AGENTS, finalized Critique-assurance
  metadata, and recorded the provenance correction without restoring heading
  counts or a bootstrap exception.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Historical correction: exact-one/zero-or-multiple heading
  enforcement was introduced by REFACTOR-r05; REFACTOR-r06 added its
  phase-limited creation exception on top. R08 restores simple exact-match
  behavior from the pre-r05 period (IMPL-r00 through REFACTOR-r04), not behavior
  that remained in effect through r05. The two restored fixes are independent
  of heading uniqueness.

##### REFACTOR-r09

- **Actors/backend**: Prior Codex reviewer, user-confirmed triage, and Codex
  writer / `backend: codex`
- **CRITIQUE outcome**: Found the seven `/goal` templates' sentinel-stop clause
  could fire before a grandfathered section ever got the chance to upgrade;
  `backend-selection`'s own live contract text still stated the superseded
  absolute persistence-ordering wording; the upgrade's byte-for-byte claim
  didn't account for a legacy body containing legitimate subheadings; and
  README's worked-example intro had a stale "full template is in Usage"
  cross-reference.
- **DEBATE classifications**: All four findings valid.
- **Resulting writer work**: Sequenced all seven goal templates as
  recognize-grandfathered → attempt upgrade (pre-upgrade compatibility check
  first) → validate → dispatch; added a historical-contract note atop
  `backend-selection`'s section pointing to the authoritative current files
  without altering its body; narrowed the upgrade's scope to bodies with no
  forbidden-heading line, stopping and escalating otherwise; fixed README's
  cross-reference.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: The pre-upgrade compatibility check (no forbidden-heading
  line) is what makes the byte-for-byte preservation claim honest — a legacy
  body with a real subheading stops and escalates rather than being silently
  mangled or having its heading rewritten.

##### REFACTOR-r10

- **Actors/backend**: Prior Codex reviewer, user-confirmed triage, and Codex
  writer / `backend: codex`
- **CRITIQUE outcome**: Found this feature's own `#### Current state` (and its
  local summaries in SKILL.md/backend-selection.md) was never updated for
  r09's pre-upgrade compatibility limitation, so a cold exit challenger would
  see a superseded description; also found "grandfathered" identity had no
  fail-closed, reproducible definition — nothing distinguished a genuine
  pre-lifecycle section from a malformed modern one lacking sentinels.
- **DEBATE classifications**: Both findings valid.
- **Resulting writer work**: Updated Current state, SKILL.md, and
  backend-selection.md to state the compatibility branch locally rather than
  only linking out; defined the grandfathered set as a closed, explicit list
  (`backend-selection`, the only section predating this lifecycle) — a
  sentinel-less section whose name is not on that list is an ordinary
  missing-sentinel validation failure, never an upgrade candidate.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Grandfathering is closed and enumerable, not an open
  heuristic, because every feature created under this lifecycle from now on
  is authored with both sentinels from the start — there is no legitimate way
  for a future non-grandfathered section to lack them.

##### REFACTOR-r11

- **Actors/backend**: Prior Codex reviewer, user-confirmed triage, and Codex
  writer / `backend: codex`
- **CRITIQUE outcome**: Found all seven canonical `/goal` templates still
  instructed the orchestrator to "recognize a grandfathered shape that lacks
  the lifecycle sentinels," contradicting `context-lifecycle.md`'s
  r10-established rule that grandfathering is an exact feature-name identity
  check against the closed list, not an inference from shape or missing
  sentinels.
- **DEBATE classifications**: The finding was valid.
- **Resulting writer work**: Replaced all seven occurrences with "first check
  whether its exact feature name is on the closed grandfathered list," changing
  no other content in `goal-templates.md`.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: Grandfathering recognition now follows closed-list
  feature identity before upgrade eligibility is considered; sentinel absence
  or section shape alone cannot make a section an upgrade candidate.

##### REFACTOR-r13

- **Actors/backend**: Prior Codex reviewer, user-confirmed triage, and Codex
  writer / `backend: codex`
- **CRITIQUE outcome**: Found that the REFACTOR-r11 checkpoint commit lacked
  its own composite record and REFACTOR-r12 backfilled that record in a later
  commit instead of the same one; also found that REFACTOR-r12 itself lacked
  its own composite record.
- **DEBATE classifications**: Both findings were valid High findings.
- **Resulting writer work**: Added the non-repeatable historical-recovery
  clause to `context-lifecycle.md` and this REFACTOR-r13 record; both land
  together in the same checkpoint commit.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: The REFACTOR-r11 gap in `4ed54388` and REFACTOR-r12 gap
  in `95d652bc` are permanent, accepted historical facts because git history
  is immutable and never rewritten. This is the one-time use of the new
  exception clause; any future checkpoint missing its own composite record is
  a hard stop and escalation to the user, not a repeatable pattern.

##### REFACTOR-r14

- **Actors/backend**: Fresh cold Codex exit challenger, user-confirmed triage,
  and prior Codex writer / `backend: codex`
- **CRITIQUE outcome**: A fresh, cold exit-challenger review run after r13 at
  HEAD `b9070a81` found two findings. The valid finding was that README.md's
  status callout ("design-stage, adversarially reviewed, not yet dogfooded
  end-to-end" and "reviewed on paper") was stale: this repository's own
  graph-engineer skill had by then been dogfooded end-to-end across two real
  features, `backend-selection` and `project-context-scoped-disclosure`, the
  latter across 14 real REFACTOR rounds. The other finding claimed a
  contradiction between PROJECT_CONTEXT.md's "prior history is never
  reconstructed," scoped specifically to the grandfathered
  `backend-selection` section body, and `context-lifecycle.md`'s separate
  legacy-per-node-ledger reconstruction exception.
- **DEBATE classifications**: One finding valid and one false positive. The
  claimed contradiction was false: grandfathered-section body preservation
  and the unrelated legacy-per-node-ledger compatibility mechanism are
  disjoint, non-contradictory provisions. This project's own r04 round already
  used the latter once; otherwise it remains a compatibility path for other
  consuming repositories.
- **Resulting writer work**: Corrected README.md's status callout only.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: A fresh exit-challenger re-run is still required after
  this fix before VERIFY, per `elevated-assurance.md`'s rule that REFACTOR
  after an exit challenger requires one more fresh challenger pass.

##### REFACTOR-r15

- **Actors/backend**: Fresh cold Codex exit challenger, user-confirmed triage,
  and Codex writer using the documented fresh-session recovery / `backend:
  codex`
- **CRITIQUE outcome**: A fresh exit-challenger run after r14 at HEAD
  `477e3497` found that README.md's plugin-verification paragraph still said
  "not exercised end-to-end," contradicting the just-corrected Status callout
  and this repository's own real dogfooding evidence.
- **DEBATE classifications**: The finding was valid.
- **Resulting writer work**: Corrected that one README.md paragraph to state
  that the routing, flag, and sandbox assumptions were exercised end-to-end
  against `openai-codex` plugin v1.0.6 while retaining the version-pinning
  caveat.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: One more fresh exit-challenger re-run is still required
  after this fix before VERIFY, per `elevated-assurance.md`'s rule. This fix
  itself required the documented read-only-rejection recovery: the resumed
  session rejected the write, so a fresh session was used instead.

##### REFACTOR-r16

- **Actors/backend**: Fresh cold Codex exit challenger, user-confirmed triage,
  and fresh Codex writer / `backend: codex`
- **CRITIQUE outcome**: A fresh exit-challenger run after r15 at HEAD
  `8101f76` found four valid issues: README.md overclaimed disclosure
  confinement; README.md's diagram contradicted its prose about the
  debatable-reinjection loop; goal-templates.md's canonicalization digest
  timing risked silently re-baselining against drifted state; and sources.md
  overstated the plugin commands this skill invokes.
- **DEBATE classifications**: All four findings were valid.
- **Resulting writer work**: Corrected README.md's disclosure wording and
  diagram edge, required every elevated goal template's Codex canonicalization
  to reuse the initial lens-sweep digest as its before reference, and aligned
  sources.md with the single `codex:codex-rescue` programmatic entry point.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: One more fresh exit-challenger re-run is still required
  before VERIFY.

##### REFACTOR-r17

- **Actors/backend**: Fresh cold Codex exit challenger, user-confirmed triage,
  and fresh Codex writer / `backend: codex`
- **CRITIQUE outcome**: A fresh exit-challenger run after r16 at HEAD
  `64acfb8` found that r16's own fix to goal-templates.md's canonicalization
  digest timing introduced a regression: the word "only" in "recompute only
  after canonicalization completes" dropped the mandatory before-dispatch
  comparison checkpoint required by elevated-assurance.md.
- **DEBATE classifications**: The finding was valid.
- **Resulting writer work**: Restored both required checkpoints—before
  canonicalization dispatch, right after lens termination, and after
  canonicalization completes—while keeping r16's correct reused digest as the
  reference value.
- **Checkpoint**: locate-by-feature-and-round
- **Decision notes**: This was a genuine regression introduced by r16's own
  prior fix and caught by the very next cold exit-challenger pass,
  demonstrating the value of the fresh-eyes gate. One more fresh
  exit-challenger re-run is still required before VERIFY.
