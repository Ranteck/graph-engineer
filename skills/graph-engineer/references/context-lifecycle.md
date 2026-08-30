# `PROJECT_CONTEXT.md` lifecycle and scoped disclosure

This reference defines how write-authorized graph-engineer cycles structure,
read, update, and archive one feature's section in `PROJECT_CONTEXT.md`. It
applies to the full 8-node write cycle and to refactor-only. Review-only does
not create or require a feature section.

This lifecycle assumes **at most one active graph-engineer cycle per
repository at a time**. Concurrent cycles in the same repository are not
supported: they can race on `PROJECT_CONTEXT.md`, archive paths, the git index,
and branch state and can corrupt the shared lifecycle record. Stop and
coordinate externally rather than starting a second cycle; this document does
not define locking or compare-and-swap recovery.

This lifecycle also assumes feature names are unique by convention. The
orchestrating Claude chooses them; they are not accepted from untrusted or
adversarial input. Resolution uses an exact heading match but does not count or
mechanically verify heading uniqueness. A duplicate heading or an archived-name
collision is therefore a documented, accepted risk: no such collision has
occurred in this repository's feature history, and this lifecycle deliberately
does not add enforcement for that theoretical case.

That limitation also applies when binding a commit to inspected staged
content. For every commit flow below that inspects staged paths or a staged
diff, complete all other checks first, make that staged-content inspection the
last check immediately adjacent to `git commit`, and run no command between
the inspection and the commit invocation. This ordering narrows the residual
inspect-then-commit race window; it does not eliminate it or make the sequence
atomic. Every such invocation must be a content-inert `git commit` whose only
arguments supply the prescribed commit message: do not use `-a`/`--all`,
`--include`, `--only`, `--interactive`, `--patch`, or any pathspec argument.
The commit must record only the index produced by the preceding explicit
`git add`. The one-active-cycle precondition remains mandatory.

The purpose is to keep the current contract bounded while preserving a
lossless decision history, and to disclose that history only to actors that
need it. These rules do not authorize the orchestrating Claude to edit
implementation files.

## Active feature-section shape

Every lifecycle feature name must match the lowercase ASCII kebab-case grammar
`[a-z0-9-]+`, with no other characters. Validate the proposed feature name
before resolving or writing headings. A name that does not match is a
stop-and-escalate condition and must never be normalized into a different
heading.

Resolve the active feature section by exact match to a complete
`## <feature-name>` heading line. In a full 8-node cycle, SPEC creates
`PROJECT_CONTEXT.md` if it is missing and creates the named section for a new
feature. In refactor-only, which has no SPEC node, PRE-FLIGHT creates the named
section with its lifecycle scaffolding. Heading resolution performs no
file-wide cardinality check.

Every feature section created from this lifecycle onward keeps the existing
level-three resolution blocks in their existing form and position, then splits
`### Feature contract` into exactly two level-four subheadings:

```markdown
## <feature-name>

### Quality gate
...

### Critique assurance
...

### Backend
...

### Checkpoint commits
...

### Feature contract

#### Current state

<bounded contract or, in refactor-only, current scope and criteria>

#### Round log

##### <IMPL-r00 | REFACTOR-rNN | CRITIQUE-rNN-noop>

- **Actors/backend**: <orchestrator, reviewer, and writer roles / selected backend>
- **CRITIQUE outcome**: <one-line review result, or `not applicable` for initial IMPL>
- **DEBATE classifications**: <valid/debatable/false-positive decisions, or `not applicable`>
- **Resulting writer work**: <bounded IMPL/REFACTOR summary, or `none`>
- **Checkpoint**: <`locate-by-feature-and-round` or `none`>
- **Decision notes**: <optional, concise round-scoped rationale>
```

The resolution blocks are conceptually part of current state even though
their `###` heading level and position remain unchanged. `#### Current state`
contains the feature contract as it stands now, not a sequence of revisions.
Rewrite it in place when understanding changes. State only the present contract
and current resolutions: never narrate rejected alternatives, past actor
refusals, or prior review conclusions there. Those are historical decision
notes and belong in the applicable `#### Round log` entry. `#### Current state`
also contains no latest-round marker or outcome summary: when the orchestrating
Claude needs the latest completed round for DEBATE or the anti-loop cutoff, it
reads the last `#### Round log` entry directly. Dispatched actors never need
that marker.

`#### Round log` is append-only and chronological, with one **composite
record per writer iteration**, not one record per graph node. `IMPL-r00`
records the initial implementation and uses `not applicable` for the review
and triage fields because it precedes the first CRITIQUE. Each
`REFACTOR-rNN` record combines the CRITIQUE outcome and DEBATE classifications
that authorized that writer round with the resulting REFACTOR summary. A
CRITIQUE-only pass for which no REFACTOR follows uses
`CRITIQUE-rNN-noop`, records `Resulting writer work: none`, and is written in
the applicable terminal context commit. SPEC, CRITIQUE, and DEBATE never get
separate records; QUALITY GATE and VERIFY remain represented by checkpoint or
terminal-commit evidence.

For a checkpointed IMPL or REFACTOR iteration, Claude prepares the complete
composite record after QUALITY GATE passes and before staging. The record and
the implementation changes must land in the **same checkpoint commit**. The
staged-diff inspection must confirm both the expected writer paths and exactly
one new composite record under the active feature before commit. An
interruption before that commit means the iteration is not closed: inspect
the working tree, conversation evidence, and any existing commit before
retrying, and stop and escalate if they cannot be reconciled. A checkpoint
commit missing its corresponding composite record, or a duplicate round id,
is a protocol inconsistency; do not silently backfill, renumber, or proceed.
If checkpoint commits are not authorized, this model cannot close a writer
iteration atomically; stop and escalate rather than claim that the iteration
was durably recorded.

A one-time migration of an already-active legacy per-node ledger cannot place
reconstructed records retroactively inside commits that already exist. For
that migration only, rebuild composite records from verified first-parent
checkpoint metadata and available review/triage evidence, identify the
migration in the current writer iteration's decision notes, and land the whole
reconstruction with that current iteration. This exception does not permit a
future writer iteration to defer its own record.

`Checkpoint: none` unambiguously means no checkpoint was made for that
record. `Checkpoint: locate-by-feature-and-round` means the checkpoint is
self-identifying and stores no hash in the record. Resolve it only from the
current branch's first-parent ancestry, requiring exactly one commit whose
subject contains the literal delimited token
`graph-engineer(<feature-name>):` (including the parentheses and colon) and
whose full commit message contains exactly one line equal to
`Round: <record-heading round>` and exactly one line equal to
`Cycle-State: CHECKPOINT`. These are stable checkpoint-label lines;
the token match is collision-safe because the mandatory `[a-z0-9-]+` feature
name grammar excludes parentheses, colons, spaces, and other delimiter
injection characters. Validate that grammar before creating the heading or
using the locator.
Do not rely on `git interpret-trailers`, because legacy multiline `Findings:`
text means the existing messages are not necessarily parsed as formal Git
trailers. Zero or more than one matching commit is ambiguous: stop and
escalate instead of choosing by recency or loose grep. This locator eliminates
any placeholder or later backfill.

Keep any design-decision rationale, rejected alternative, actor refusal,
prior review conclusion, or false-positive justification in the applicable
composite record's optional decision notes rather than weaving history into
`#### Current state`. Do not copy raw transcripts or unbounded command output
into a record. Never copy a secret, credential, or token verbatim into an
outcome or decision note; identify its location and nature instead. As with
cross-session payloads, this lifecycle does not redact or scan content
automatically, so the orchestrator must keep sensitive values out of the log.

For refactor-only, which has no SPEC node, PRE-FLIGHT creates the same
scaffolding when it persists the feature metadata.
`#### Current state` records only the current scope and user-supplied criteria;
it must not pretend that a new functional contract was authored. The first
completed CRITIQUE starts a composite record only when it leads to a REFACTOR
checkpoint or closes as a CRITIQUE-only no-op pass.

Existing feature sections created before this lifecycle are grandfathered and
need not be retrofitted merely because a later feature uses the new shape.
Any feature activated under this lifecycle must still pass the feature-name
grammar before resolution.

## Default disclosure by node

These are instruction-based disclosure defaults. Resolve the active feature
heading first by exact match to `## <feature-name>`, then instruct each actor
not to read or write another feature's section. They are **not sandbox-enforced
read boundaries**: the default Codex
sandbox blocks writes during CRITIQUE, not reads, and Claude `Explore`
reviewers retain shell access despite lacking direct editor tools. A
dispatched actor can still read other content or, on a non-Codex route,
indirectly mutate it. The artifact-identity checks in `backend-selection.md`
detect some drift but do not turn this disclosure policy into confinement.

| Node or reader | Default feature context | `#### Round log` access |
|---|---|---|
| SPEC | Full feature section; authors/rewrites `#### Current state`; its work is summarized in the later `IMPL-r00` composite | Full read/write |
| IMPL | Byte-exact, dynamically fenced `#### Current state` block | Prompt omits it and instructs no log read |
| First standard fresh CRITIQUE | Byte-exact, dynamically fenced `#### Current state` block | Prompt omits it and instructs no log read |
| Ordinary resumed CRITIQUE, including an elevated resumed canonical round | Byte-exact, dynamically fenced `#### Current state` block plus the review session's own `--resume-last` memory | Prompt omits it; continuity comes from the session |
| Elevated fresh lenses | Byte-exact, dynamically fenced `#### Current state` block | Prompt explicitly omits it to reduce prior finding/outcome anchoring |
| Elevated canonicalization | Byte-exact, dynamically fenced `#### Current state`, the three raw lens reports, and the normalized ledger | Prompt omits it; its job is to audit fan-in, not consume prior round history |
| Exit challenger, including reruns | Byte-exact, dynamically fenced `#### Current state`: current contract/scope, artifact, and criteria | Prompt explicitly omits it to preserve a cold-review default |
| DEBATE / orchestrating Claude triage | Current state and the specific implementation evidence needed to rule on findings | May read the full log when needed, including to compare consecutive CRITIQUE passes for the anti-loop cutoff |
| REFACTOR | Triaged fix list plus byte-exact, dynamically fenced `#### Current state` block | Prompt explicitly omits it |
| Human or future-cycle investigator | The round ids needed to answer the historical question | Reads the log directly by round id |

The feature contract explicitly names ordinary resumed CRITIQUE but does not
give the first standard fresh CRITIQUE a different source. Therefore the
smallest disclosure default is the same `#### Current state` text. This is an
instruction the actor can violate, not a capability boundary. Review-only and
refactor-only's first CRITIQUE continue to judge the requested scope directly
when no functional contract exists.

For IMPL, CRITIQUE, and REFACTOR, the orchestrator must extract and serialize
the active feature's `#### Current state` text by this exact rule:

First resolve the active feature heading by exact match to
`## <feature-name>`.

1. Within that resolved active `## <feature-name>` section, require
   exactly one canonical sentinel line whose bytes are `#### Current state`
   followed only by its line ending, and exactly one later canonical sentinel
   line whose bytes are `#### Round log` followed only by its line ending (or
   EOF after the text). Missing, duplicate, reordered, indented, or suffixed
   sentinels are invalid; stop and escalate rather than infer a boundary.
2. Validate every intervening line. After zero through three ASCII space bytes,
   no line may contain two, three, or four `#` bytes followed by a space, tab,
   or line ending: equivalently, reject `^[ ]{0,3}#{2,4}([ \t]|$)`. Backtick
   and tilde runs are uninterpreted bytes, not fence syntax; there is no
   fence-tracking or fence-balance algorithm.
3. Extract the raw bytes strictly after the `#### Current state` sentinel's
   line ending through the byte immediately before the `#### Round log`
   sentinel. Preserve every byte exactly, including blank lines, Markdown,
   and backtick or tilde runs. Do not trim, indent, prefix, normalize line
   endings, or otherwise rewrite it.
4. Put those bytes inside a dedicated outer backtick-fenced code block in the
   dispatch prompt. Choose an outer fence whose run is at least three
   backticks and one byte longer than the longest run of backticks after zero
   through three leading spaces on any extracted line; use the identical run
   alone on the closing line. This makes the wrapper unambiguous without
   interpreting any payload line as Markdown fence syntax. If the preserved
   bytes do not end with a line ending, add one before the closing outer fence;
   that separator belongs to the prompt wrapper, not the extracted payload.

Run steps 1-2 as structural validation immediately after every context write
that creates or changes `#### Current state`, before ending that write, and
again immediately before every dispatch that inlines it. Any failure is a
generic cycle stop-and-escalate condition. Never dispatch a wider range or a
best-effort paraphrase.

The prompt must name the active feature, identify this fenced block as the
permitted context, and instruct the actor not to open `PROJECT_CONTEXT.md` or
read `#### Round log`; do not merely tell the actor to read a subsection from
the file. Prompt templates use `[raw Current state bytes extracted and fenced
per context-lifecycle.md]` as shorthand for this entire algorithm, never for a
blockquote or hand-copied paraphrase. This reduces accidental discovery but
does not enforce a read boundary. On the default Codex path, resumed review
relies on `--resume-last`; do not reconstruct continuity by disclosing the
round log.

## Terminal archival

Archival is a terminal transition inside the existing cycle, never a ninth
node. It runs only after the cycle's existing success condition has already
been met:

- after VERIFY passes in the full 8-node write cycle; or
- after the final DONE-clearing CRITIQUE or exit-challenger pass in
  refactor-only.

There is one refactor-only no-op exception, with this strict order:

1. The moment the first CRITIQUE reports no valid findings and its required
   post-review mutation check succeeds, before any context write, read
   `git rev-parse HEAD`, require `git status --porcelain=v1 -uall` to be empty,
   then read HEAD again. Both HEAD values must match; retain that value as the
   candidate baseline. Command failure, a dirty tree, or unequal HEAD values
   stops and escalates.
2. DEBATE confirms the no-valid-findings judgment as pure reasoning. Do not
   persist a record or make another file write. The same deferral applies to
   any required exit-challenger CRITIQUE/DEBATE pair.
3. If the final DONE-clearing pass is reached with **zero REFACTOR rounds**
   (after an exit challenger too, when elevated mode requires one), before any
   write, bracket cleanliness again: require HEAD to equal the baseline,
   require porcelain status to be empty, and require a second HEAD read to
   equal the same baseline. These commands are sequential, not an atomic
   snapshot; both HEAD checks are mandatory defenses against an intervening
   branch-tip change.
4. Only after those checks match, confirm the PRE-FLIGHT metadata commit exists
   and append one composite `CRITIQUE-rNN-noop` record covering all deferred
   CRITIQUE outcomes and DEBATE classifications in their actual chronology.
   Its writer-work field is `none` and its checkpoint field is `none`.
5. Stage exactly `PROJECT_CONTEXT.md`. Require no unstaged tracked change and
   no untracked residue, then re-read HEAD and require it still equals the
   baseline. Any residue, command failure, or HEAD mismatch aborts without
   committing and escalates.
6. As the last check, inspect the staged path set with a NUL-safe command and
   require exactly `PROJECT_CONTEXT.md`, then inspect the staged diff and
   require that its only semantic change is the expected composite record
   under the active feature. If either staged-content check fails, abort and
   escalate. If both pass, invoke `git commit` immediately as the next command,
   with no command between this final inspection and the commit. Use a
   content-inert invocation whose only arguments supply the prescribed commit
   message: no `-a`/`--all`, `--include`, `--only`, `--interactive`, `--patch`,
   or pathspec arguments.

After that commit, confirm the tree is clean and enter DONE. Do not treat the
absence of a finished-work checkpoint as an error in this exact HEAD-stable,
clean-tree zero-REFACTOR case.

The archive path is
`PROJECT_CONTEXT.archive/<feature-slug>.md`, a sibling of
`PROJECT_CONTEXT.md` in the consuming repository. One file represents one
feature. Because every lifecycle feature name already matches
`[a-z0-9-]+`, `<feature-slug>` is exactly the feature name from the resolved
`## <feature-name>` heading; do not normalize or transform it. Before
writing, reject and escalate if the slug contains `/` or `..`, starts with
`.`, or if the canonicalized target does not remain an immediate child of the
resolved archive directory.

If `PROJECT_CONTEXT.archive/` is absent, create it as an ordinary directory
and then validate it. If it exists, require it to be a real directory, never a
symlink or another file type; refuse and escalate otherwise. Resolve the
repository root and archive directory with `realpath`, canonicalize the target
from that resolved directory, and require containment within the resolved
archive directory and repository. This is a defense-in-depth check even though
the slug grammar itself excludes separators. If the validated target already
exists, stop and escalate rather than overwrite or merge it.

### Lossless move and pointer

Using the resolved exact heading required above, move the entire
active `## <feature-name>` section, from its heading through
the line before the next level-two heading (or end of file), verbatim into the
archive file. This includes all resolution metadata, `#### Current state`, and
`#### Round log`. Do not summarize, compact, reorder, or discard any content.

Replace that section in `PROJECT_CONTEXT.md` with one Markdown line in this
form:

```markdown
## <feature-name> — <one-line outcome>; completed <YYYY-MM-DD>; archive: `PROJECT_CONTEXT.archive/<feature-slug>.md`; archive-sha256: `<64-hex-sha256>`; finished-work checkpoint: `<short-hash>`
```

`<short-hash>` is the short hash of the last checkpoint commit before the
archival move—the commit holding the finished implementation—not the archival
commit's own hash. Resolve and verify that checkpoint before changing either
file. If checkpoint commits were authorized but no applicable finished-work
checkpoint exists, stop and escalate rather than substitute an unrelated
commit, except for the explicit zero-REFACTOR refactor-only no-op above.

`<64-hex-sha256>` is the SHA-256 of the complete archive file content, which
is the verbatim feature section. Compute it after writing the archive and
before staging the pointer; verify it again from the staged archive content.

The archival commit stores no self-hash. Locate it later by feature name and
its `Cycle-State: COMPLETE` message, for example with `git log --grep` using
both values.

### Atomic terminal commit

Archival requires checkpoint commits to have been authorized at PRE-FLIGHT.
If they were not authorized, do not create or rewrite either path; stop and
escalate to the user.

When authorized:

1. Confirm the terminal success condition and the applicable last checkpoint
   hash before modifying context files. Capture `git rev-parse HEAD` as the
   sequence's starting HEAD.
2. Prepare the verbatim archive and the one-line replacement pointer. Stage
   exactly `PROJECT_CONTEXT.md` and the matching archive file together; never
   stage unrelated paths.
3. Complete every other pre-commit validation, then re-run
   `git rev-parse HEAD` and require it to equal the starting HEAD. If this
   identity check fails, abort without committing and escalate; do not retry
   blindly.
4. As the last check, inspect the staged name set with a NUL-safe command and
   require it to contain exactly `PROJECT_CONTEXT.md` and the validated archive
   file. In the same final staged-content inspection, inspect the staged diff
   and verify that the archived section is byte-for-byte identical to the
   section removed from `PROJECT_CONTEXT.md`, and that the pointer names the
   same feature, archive path, completion date, outcome, archive SHA-256, and
   finished-work checkpoint. If any check fails, abort and escalate.
5. If that final inspection passes, invoke `git commit` immediately as the next
   command, with no command in between. Use a content-inert invocation whose
   only arguments supply the prescribed commit message: no `-a`/`--all`,
   `--include`, `--only`, `--interactive`, `--patch`, or pathspec arguments.
   Create one terminal commit containing both file changes; never commit one
   side separately or leave one side for a later commit. Use the existing
   checkpoint message mechanics, but set `Cycle-State: COMPLETE` and include
   the feature name in the subject so the archival commit is discoverable via
   `git log --grep`.

Git updates the branch tip atomically at commit time. An interruption before
that commit may still leave uncommitted filesystem changes; do not silently
resume, repair, or guess. The PRE-FLIGHT consistency check below detects that
state on the next cycle.

## Refactor-only PRE-FLIGHT metadata commit

Refactor-only has no SPEC commit to absorb PRE-FLIGHT's context scaffolding.
Immediately after PRE-FLIGHT writes the feature's `### Quality gate`,
`### Backend`, and `### Critique assurance` resolutions and the lifecycle
scaffolding, stage only `PROJECT_CONTEXT.md`, inspect that the staged diff is
limited to that feature's metadata/scaffolding as the last check, and commit it
immediately as its own local PRE-FLIGHT metadata step before the first
CRITIQUE. Use a content-inert `git commit` whose only arguments supply the
prescribed message: no `-a`/`--all`, `--include`, `--only`, `--interactive`,
`--patch`, or pathspec arguments. If that exact commit cannot be made safely,
stop before dispatch instead of leaving metadata pending. This commit is
required even if checkpoint commits for later writer rounds were not
authorized; it prevents a zero-REFACTOR run from poisoning the next cycle's
clean-tree check.

## PRE-FLIGHT archive consistency check

Every future **write-authorized full 8-node or refactor-only cycle** entering
PRE-FLIGHT in a repository that has either `PROJECT_CONTEXT.md` or
`PROJECT_CONTEXT.archive/` must check both directions before making its own
context write or dispatching an actor. Review-only retains its lighter
PRE-FLIGHT and does not run this check:

1. For every archived-feature pointer under a feature heading in
   `PROJECT_CONTEXT.md`, require a valid deterministic slug and relative path;
   require the target to be a regular file, not a symlink or directory; use
   `realpath` to prove it resolves within the repository and the resolved real
   archive directory; recompute SHA-256 and compare it with the pointer's
   `archive-sha256` value.
2. Require `PROJECT_CONTEXT.archive/` itself to be a real directory and not a
   symlink. Enumerate all descendants, including hidden entries and nested
   directories, rather than relying on the non-recursive
   `PROJECT_CONTEXT.archive/*.md` glob. Any archive-relative path containing a
   subdirectory separator is inherently invalid. Every remaining immediate
   regular `.md` file must have exactly one corresponding pointer in
   `PROJECT_CONTEXT.md`; symlinks, directories, other file types, and
   ambiguous duplicates are invalid.

A missing claimed archive, hash mismatch, path escape, symlink, nested archive
path, orphan archive, or ambiguous duplicate pointer is a stop-and-escalate
condition. Report the paths and mismatch; do not create, delete, relink,
merge, or otherwise repair archival state automatically. This check is what
makes an interruption between filesystem writes and the terminal commit
visible instead of silently lossy.

## Deliberate exclusions

This lifecycle does not authorize lossy round-log compaction, split active
features into separate primary files, retrofit grandfathered sections, alter
the elevated-assurance lens/fan-in mechanics, or change quality-gate
resolution. It changes context shape, disclosure, and terminal archival only.
