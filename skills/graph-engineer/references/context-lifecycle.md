# `PROJECT_CONTEXT.md` lifecycle and scoped disclosure

This reference defines how write-authorized graph-engineer cycles structure,
read, update, and archive one feature's section in `PROJECT_CONTEXT.md`. It
applies to the full 8-node write cycle and to refactor-only. Review-only does
not create or require a feature section.

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

Latest completed round: `<round-id>` — <one-line outcome>.

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
Rewrite it in place when understanding changes. Replace its single "Latest
completed round" paragraph after each logged round; never append a second
latest-outcome paragraph.

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
copy raw transcripts or unbounded command output into an entry.

SPEC reads and writes the full feature section. After other nodes complete,
the orchestrating Claude performs the bounded current-state update and
round-log append; a dispatched writer or reviewer does not need access to the
log in order for its completed round to be recorded.

For refactor-only, which has no SPEC node, PRE-FLIGHT creates the same
scaffolding when it persists the feature metadata. `#### Current state`
records only the current scope and user-supplied criteria; it must not pretend
that a new functional contract was authored. The first completed CRITIQUE then
starts the round log.

Existing feature sections created before this lifecycle are grandfathered and
need not be retrofitted merely because a later feature uses the new shape.

## Default disclosure by node

These are default reads, not suggestions. Resolve the active feature heading
first and do not read or write another feature's section.

| Node or reader | Default feature context | `#### Round log` access |
|---|---|---|
| SPEC | Full feature section; authors/rewrites `#### Current state` and appends its completed revision | Full read/write |
| IMPL | `#### Current state` only | Excluded |
| First standard fresh CRITIQUE | `#### Current state` only | Excluded |
| Ordinary resumed CRITIQUE, including an elevated resumed canonical round | `#### Current state` plus the review session's own `--resume-last` memory | Excluded; continuity comes from the session |
| Elevated fresh lenses | `#### Current state` only | Explicitly excluded so prior finding/outcome history cannot anchor independent lenses |
| Elevated canonicalization | `#### Current state`, the three raw lens reports, and the normalized ledger | Explicitly excluded; its job is to audit fan-in, not consume prior round history |
| Exit challenger, including reruns | `#### Current state` only: current contract/scope, artifact, and criteria | Explicitly excluded; it must not see the finding ledger or earlier REFACTOR outcomes |
| DEBATE / orchestrating Claude triage | Current state and the specific implementation evidence needed to rule on findings | May read the full log when needed, including to compare consecutive CRITIQUE passes for the anti-loop cutoff |
| REFACTOR | Triaged fix list inline plus `#### Current state` | Explicitly excluded |
| Human or future-cycle investigator | The round ids needed to answer the historical question | Reads the log directly by round id |

The feature contract explicitly names ordinary resumed CRITIQUE but does not
give the first standard fresh CRITIQUE a different source. Therefore the
smallest safe default is the same current-state-only disclosure: no dispatched
reviewer may read `#### Round log` unless a rule above expressly allows it.
Review-only and refactor-only's first CRITIQUE continue to judge the requested
scope directly when no functional contract exists.

Prompts must name the active feature and the permitted subsection. Do not use
the ambiguous instruction "read the contract in `PROJECT_CONTEXT.md`" for
IMPL, CRITIQUE, or REFACTOR. On the default Codex path, resumed review relies
on `--resume-last`; do not reconstruct continuity by disclosing the round log.

## Terminal archival

Archival is a terminal transition inside the existing cycle, never a ninth
node. It runs only after the cycle's existing success condition has already
been met:

- after VERIFY passes in the full 8-node write cycle; or
- after the final DONE-clearing CRITIQUE or exit-challenger pass in
  refactor-only.

The archive path is
`PROJECT_CONTEXT.archive/<feature-slug>.md`, a sibling of
`PROJECT_CONTEXT.md` in the consuming repository. One file represents one
feature. The feature slug is the active section's established slug; do not
invent a second identity during archival. If the target path already exists,
stop and escalate rather than overwrite or merge it.

### Lossless move and pointer

Move the entire active `## <feature-name>` section, from its heading through
the line before the next level-two heading (or end of file), verbatim into the
archive file. This includes all resolution metadata, `#### Current state`, and
`#### Round log`. Do not summarize, compact, reorder, or discard any content.

Replace that section in `PROJECT_CONTEXT.md` with one Markdown line in this
form:

```markdown
## <feature-name> — <one-line outcome>; completed <YYYY-MM-DD>; archive: `PROJECT_CONTEXT.archive/<feature-slug>.md`; finished-work checkpoint: `<short-hash>`
```

`<short-hash>` is the short hash of the last checkpoint commit before the
archival move—the commit holding the finished implementation—not the archival
commit's own hash. Resolve and verify that checkpoint before changing either
file. If checkpoint commits were authorized but no applicable finished-work
checkpoint exists, stop and escalate rather than substitute an unrelated
commit. This is the fail-closed interpretation for a refactor-only cycle that
reaches DONE without ever producing a writer checkpoint.

The archival commit stores no self-hash. Locate it later by feature name and
its `Cycle-State: COMPLETE` message, for example with `git log --grep` using
both values.

### Atomic terminal commit

Archival requires checkpoint commits to have been authorized at PRE-FLIGHT.
If they were not authorized, do not create or rewrite either path; stop and
escalate to the user.

When authorized:

1. Confirm the terminal success condition and the applicable last checkpoint
   hash before modifying context files.
2. Prepare the verbatim archive and the one-line replacement pointer. Stage
   exactly `PROJECT_CONTEXT.md` and the matching archive file together; never
   stage unrelated paths.
3. Inspect the staged diff and verify that the archived section is byte-for-
   byte identical to the section removed from `PROJECT_CONTEXT.md`, and that
   the pointer names the same feature, archive path, completion date, outcome,
   and finished-work checkpoint.
4. Create one terminal commit containing both file changes. Never commit one
   side separately or leave one side for a later commit. Use the existing
   checkpoint message mechanics, but set `Cycle-State: COMPLETE` and include
   the feature name in the subject so the archival commit is discoverable via
   `git log --grep`.

Git updates the branch tip atomically at commit time. An interruption before
that commit may still leave uncommitted filesystem changes; do not silently
resume, repair, or guess. The PRE-FLIGHT consistency check below detects that
state on the next cycle.

## PRE-FLIGHT archive consistency check

Every future cycle entering PRE-FLIGHT in a repository that has either
`PROJECT_CONTEXT.md` or `PROJECT_CONTEXT.archive/` must check both directions
before making its own context write or dispatching an actor:

1. For every archived-feature pointer under a feature heading in
   `PROJECT_CONTEXT.md`, confirm that the exact claimed archive file exists.
2. Enumerate `PROJECT_CONTEXT.archive/*.md` and confirm that every file has
   exactly one corresponding pointer in `PROJECT_CONTEXT.md`.

A missing claimed archive, an orphan archive, or an ambiguous duplicate
pointer is a stop-and-escalate condition. Report the paths and mismatch; do
not create, delete, relink, merge, or otherwise repair archival state
automatically. This check is what makes an interruption between filesystem
writes and the terminal commit visible instead of silently lossy.

## Deliberate exclusions

This lifecycle does not authorize lossy round-log compaction, split active
features into separate primary files, retrofit grandfathered sections, alter
the elevated-assurance lens/fan-in mechanics, or change quality-gate
resolution. It changes context shape, disclosure, and terminal archival only.
