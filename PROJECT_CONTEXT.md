# Project Context

This file is written and maintained exclusively by Claude during
graph-engineer cycles in this repo. Each feature's contract lives under its
own `## <feature-name>` heading — read and write only the section matching
the feature currently in progress.

## backend-selection — added opt-in per-cycle backend selection (`codex` default; `claude` same-session subagents; `claude:<account-alias>` and `claude-writer:<account-alias>` cross-session options) for IMPL/CRITIQUE/REFACTOR, culminating in the `claude-writer:<account-alias>` cross-session-writer/local-reviewer split; completed 2026-08-27; archive: `PROJECT_CONTEXT.archive/backend-selection.md`; archive-sha256: `ae037b27fddd36ec7b4430bf01a66eeb500e1beadeb70ff77cbede52225f2596`; finished-work checkpoint: `4f4f190`

## project-context-scoped-disclosure — split active feature sections into a bounded Current state and an append-only Round log, added node-scoped disclosure defaults for reviewers/writers, and added a terminal archival transition for completed features; completed 2026-08-31; archive: `PROJECT_CONTEXT.archive/project-context-scoped-disclosure.md`; archive-sha256: `64a2826823076e1bb0bdac2b948c1b4ceadd23137492bb0612a641b9886b1a05`; finished-work checkpoint: `be1cd57`
