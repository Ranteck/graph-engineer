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

The purpose is to keep the current contract bounded while preserving a
lossless decision history, and to disclose that history only to actors that
need it. These rules do not authorize the orchestrating Claude to edit
implementation files.

## Active feature-section shape

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

##### <round-id>

- **Node**: <SPEC | IMPL | CRITIQUE | DEBATE | REFACTOR>
- **Actor/backend**: <orchestrator or selected backend>
- **Commit**: <checkpoint ref, or `none`>
- **Outcome**: <one line>
- **Decision notes**: <optional, concise round-scoped rationale>
```

The resolution blocks are conceptually part of current state even though
their `###` heading level and position remain unchanged. `#### Current state`
contains the feature contract as it stands now, not a sequence of revisions.
Rewrite it in place when understanding changes. It contains no latest-round
marker or outcome summary: when the orchestrating Claude needs the latest
completed round for DEBATE or the anti-loop cutoff, it reads the last
`#### Round log` entry directly. Dispatched actors never need that marker.

`#### Round log` is append-only and chronological. Append one bounded entry
after each completed SPEC revision, IMPL, CRITIQUE pass, DEBATE triage batch,
and REFACTOR round. Use the cycle's stable round labels so entries align with
checkpoint commits—for example, `IMPL-r00` and `REFACTOR-r04`. A node without
its own checkpoint still uses the applicable cycle round in its id and records
`Commit: none`. QUALITY GATE and VERIFY do not add round-log entries; their
results remain represented by checkpoint or terminal-commit evidence.

Each entry records its round id, node, actor/backend, checkpoint ref when one
was made, and a one-line outcome. Keep any design-decision rationale, rejected
alternative, or DEBATE false-positive justification in that round's optional
decision notes rather than weaving history into `#### Current state`. Do not
copy raw transcripts or unbounded command output into an entry. Never copy a
secret, credential, or token verbatim into an outcome or decision note;
identify its location and nature instead. As with cross-session payloads, this
lifecycle does not redact or scan content automatically, so the orchestrator
must keep sensitive values out of the log.

SPEC reads and writes the full feature section. After other nodes complete,
the orchestrating Claude performs the bounded current-state update and
round-log append; a dispatched writer or reviewer does not need access to the
log in order for its completed round to be recorded.

Node completion and round-log persistence are a **best-effort protocol**, not
an atomic or idempotent transaction. An interruption can occur after an actor
finishes but before Claude appends the corresponding entry. On resume, before
advancing, Claude re-derives any missing entry from available evidence such as
checkpoint commit messages and conversation history, records only what that
evidence supports, and escalates if it cannot reconstruct the state safely.
Discovering a missing or duplicate round id later is itself a signal to stop
and double-check the cycle state; never silently renumber, deduplicate, or
continue as if the ledger were authoritative.

For refactor-only, which has no SPEC node, PRE-FLIGHT creates the same
scaffolding when it persists the feature metadata. `#### Current state`
records only the current scope and user-supplied criteria; it must not pretend
that a new functional contract was authored. The first completed CRITIQUE then
starts the round log.

Existing feature sections created before this lifecycle are grandfathered and
need not be retrofitted merely because a later feature uses the new shape.

## Default disclosure by node

These are instruction-based disclosure defaults. Resolve the active feature
heading first and instruct each actor not to read or write another feature's
section. They are **not sandbox-enforced read boundaries**: the default Codex
sandbox blocks writes during CRITIQUE, not reads, and Claude `Explore`
reviewers retain shell access despite lacking direct editor tools. A
dispatched actor can still read other content or, on a non-Codex route,
indirectly mutate it. The artifact-identity checks in `backend-selection.md`
detect some drift but do not turn this disclosure policy into confinement.

| Node or reader | Default feature context | `#### Round log` access |
|---|---|---|
| SPEC | Full feature section; authors/rewrites `#### Current state` and appends its completed revision | Full read/write |
| IMPL | Quoted `#### Current state` block | Prompt omits it and instructs no log read |
| First standard fresh CRITIQUE | Quoted `#### Current state` block | Prompt omits it and instructs no log read |
| Ordinary resumed CRITIQUE, including an elevated resumed canonical round | Quoted `#### Current state` block plus the review session's own `--resume-last` memory | Prompt omits it; continuity comes from the session |
| Elevated fresh lenses | Quoted `#### Current state` block | Prompt explicitly omits it to reduce prior finding/outcome anchoring |
| Elevated canonicalization | Quoted `#### Current state`, the three raw lens reports, and the normalized ledger | Prompt omits it; its job is to audit fan-in, not consume prior round history |
| Exit challenger, including reruns | Quoted `#### Current state`: current contract/scope, artifact, and criteria | Prompt explicitly omits it to preserve a cold-review default |
| DEBATE / orchestrating Claude triage | Current state and the specific implementation evidence needed to rule on findings | May read the full log when needed, including to compare consecutive CRITIQUE passes for the anti-loop cutoff |
| REFACTOR | Triaged fix list plus quoted `#### Current state` block | Prompt explicitly omits it |
| Human or future-cycle investigator | The round ids needed to answer the historical question | Reads the log directly by round id |

The feature contract explicitly names ordinary resumed CRITIQUE but does not
give the first standard fresh CRITIQUE a different source. Therefore the
smallest disclosure default is the same `#### Current state` text. This is an
instruction the actor can violate, not a capability boundary. Review-only and
refactor-only's first CRITIQUE continue to judge the requested scope directly
when no functional contract exists.

For IMPL, CRITIQUE, and REFACTOR, the orchestrator must extract the active
feature's `#### Current state` text and include it inline in the prompt as a
quoted block. The prompt must name the active feature, identify that quoted
block as the permitted context, and instruct the actor not to open or read
`#### Round log`; do not merely tell the actor to read a subsection from
`PROJECT_CONTEXT.md`. This reduces accidental discovery but does not enforce a
read boundary. On the default Codex path, resumed review relies on
`--resume-last`; do not reconstruct continuity by disclosing the round log.

## Terminal archival

Archival is a terminal transition inside the existing cycle, never a ninth
node. It runs only after the cycle's existing success condition has already
been met:

- after VERIFY passes in the full 8-node write cycle; or
- after the final DONE-clearing CRITIQUE or exit-challenger pass in
  refactor-only.

There is one refactor-only no-op exception: if the first CRITIQUE finds no
valid findings and the final DONE-clearing pass is reached with **zero
REFACTOR rounds** (after an exit challenger too, when elevated mode requires
one), no finished implementation work exists to archive. Skip the archival
transition and enter DONE after confirming the PRE-FLIGHT metadata commit
described below exists. Append the completed CRITIQUE entry or entries under
`#### Round log`, commit that bounded context-only completion update
separately, and confirm the tree is clean; do not treat the absence of a
finished-work checkpoint as an error in this exact zero-REFACTOR case.

The archive path is
`PROJECT_CONTEXT.archive/<feature-slug>.md`, a sibling of
`PROJECT_CONTEXT.md` in the consuming repository. One file represents one
feature. Derive `<feature-slug>` deterministically from the exact
`## <feature-name>` heading: lowercase ASCII `A-Z`, replace each maximal run
of characters outside `[a-z0-9]` with one `-`, trim leading/trailing `-`, and
require a non-empty result matching `[a-z0-9-]+`. Before writing, reject and
escalate if the derived slug contains `/` or `..`, starts with `.`, or if the
canonicalized target does not remain an immediate child of the resolved
archive directory.

If `PROJECT_CONTEXT.archive/` is absent, create it as an ordinary directory
and then validate it. If it exists, require it to be a real directory, never a
symlink or another file type; refuse and escalate otherwise. Resolve the
repository root and archive directory with `realpath`, canonicalize the target
from that resolved directory, and require containment within the resolved
archive directory and repository. This is a defense-in-depth check even though
the slug grammar itself excludes separators. If the validated target already
exists, stop and escalate rather than overwrite or merge it.

### Lossless move and pointer

Move the entire active `## <feature-name>` section, from its heading through
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
3. Inspect the staged diff and verify that the archived section is byte-for-
   byte identical to the section removed from `PROJECT_CONTEXT.md`, and that
   the pointer names the same feature, archive path, completion date, outcome,
   archive SHA-256, and finished-work checkpoint.
4. Immediately before `git commit`, re-run `git rev-parse HEAD` and require it
   to equal the starting HEAD. Also inspect the staged name set with a NUL-safe
   command and require it to contain exactly the two intended paths:
   `PROJECT_CONTEXT.md` and the validated archive file. If either identity
   check fails, abort without committing and escalate; do not retry blindly.
5. Create one terminal commit containing both file changes. Never commit one
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
limited to that feature's metadata/scaffolding, and commit it as its own local
PRE-FLIGHT metadata step before the first CRITIQUE. If that exact commit
cannot be made safely, stop before dispatch instead of leaving metadata
pending. This commit is required even if checkpoint commits for later writer
rounds were not authorized; it prevents a zero-REFACTOR run from poisoning the
next cycle's clean-tree check.

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
