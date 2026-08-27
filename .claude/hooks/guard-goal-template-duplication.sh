#!/usr/bin/env bash
# PreToolUse guard: blocks re-introducing the elevated-write-goal template
# markers into README.md. CLAUDE.md says that prompt must live only in
# goal-templates.md; README.md should link to it, never embed a copy.

set -euo pipefail

input="$(cat)"
file_path="$(printf '%s' "$input" | grep -o '"file_path"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed -E 's/.*"file_path"[[:space:]]*:[[:space:]]*"([^"]*)"/\1/')"

case "$file_path" in
  *README.md) ;;
  *) exit 0 ;;
esac

new_content="$(printf '%s' "$input" | grep -o '"content"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 || true)"
new_content2="$(printf '%s' "$input" | grep -o '"new_string"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 || true)"

if printf '%s%s' "$new_content" "$new_content2" | grep -q 'elevated-write-goal:start'; then
  echo "Blocked: README.md must not embed the elevated-write-goal template (marker <!-- elevated-write-goal:start -->). Per CLAUDE.md, that prompt lives only in goal-templates.md — link to it instead." >&2
  exit 2
fi

exit 0
