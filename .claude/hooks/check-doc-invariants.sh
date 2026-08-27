#!/usr/bin/env bash
# PostToolUse guard: warns (never blocks) when an edit to the graph-engineer
# docs breaks one of the cross-file invariants documented in CLAUDE.md.
# Reads the tool-call JSON from stdin, per Claude Code's hook contract.

set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]*)"/\1/')"

case "$file_path" in
  *SKILL.md|*README.md|*references/sources.md|*references/backend-selection.md|*references/elevated-assurance.md) ;;
  *) exit 0 ;;
esac

repo_root="$(cd "$(dirname "$0")/../.." && pwd)"
skill="$repo_root/skills/graph-engineer/SKILL.md"
readme="$repo_root/README.md"
sources="$repo_root/skills/graph-engineer/references/sources.md"

warnings=()

# 1. Pinned Codex plugin version must match everywhere it's cited.
versions="$(grep -hoE 'openai-codex[^v]*v[0-9]+\.[0-9]+\.[0-9]+' "$skill" "$readme" "$sources" 2>/dev/null \
  | grep -oE 'v[0-9]+\.[0-9]+\.[0-9]+' | sort -u)"
if [ "$(printf '%s\n' "$versions" | wc -l)" -gt 1 ]; then
  warnings+=("openai-codex version pin mismatch across SKILL.md/README.md/sources.md: $(printf '%s ' $versions)")
fi

# 2. The 8-node cycle name/order must appear consistently.
expected='PRE-FLIGHT.*SPEC.*IMPL.*QUALITY GATE.*CRITIQUE.*DEBATE.*REFACTOR.*VERIFY'
for f in "$skill" "$readme"; do
  if ! grep -Pzo "(?s)$expected" "$f" >/dev/null 2>&1; then
    warnings+=("$(basename "$f") may be missing/reordering the 8-node cycle (PRE-FLIGHT→SPEC→IMPL→QUALITY GATE→CRITIQUE→DEBATE/TRIAGE→REFACTOR→VERIFY)")
  fi
done

# 3. Single entry point claim: no other /codex:* command should be described
# as invoked/called/dispatched/run by the skill (mere mentions of them as
# out-of-scope/typed-by-human-only are fine and expected).
invocation_hits="$(grep -hnPi '(invoke|invokes|dispatch|dispatches)[^.]*\/codex:(?!codex-rescue)[a-zA-Z_-]+' "$skill" "$readme" 2>/dev/null \
  | grep -vPi 'out of scope|typed-by-human-only|not invoked|never invoked|without.*invok' || true)"
if [ -n "$invocation_hits" ]; then
  warnings+=("possible non-codex-rescue /codex:* invocation described: $invocation_hits (check the single-entry-point invariant)")
fi

if [ "${#warnings[@]}" -gt 0 ]; then
  {
    echo "⚠️  doc-invariant check (non-blocking) on $file_path:"
    for w in "${warnings[@]}"; do echo "  - $w"; done
  } >&2
fi

exit 0
