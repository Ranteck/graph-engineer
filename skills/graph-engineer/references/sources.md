# Sources and provenance

This skill is built entirely on verified, real pieces — no invented commands,
no fabricated official features. This file documents what's official and what
isn't, because "graph engineering" got confused with several things during
this skill's design.

## What's official

- **Orchestrator-Workers** and **Evaluator-Optimizer** are real Anthropic
  workflow patterns, documented in
  [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents).
  Verbatim from that article:
  - Orchestrator-workers: "a central LLM dynamically breaks down tasks,
    delegates them to worker LLMs, and synthesizes their results."
  - Evaluator-optimizer: "one LLM call generates a response while another
    provides evaluation and feedback in a loop."
  This skill nests an Evaluator-Optimizer loop (Codex implements, Codex
  critiques, Claude arbitrates) inside an Orchestrator-Workers structure
  (the user/Claude session orchestrates, Codex is the worker).
- The **Codex plugin for Claude Code** is official and owned by OpenAI:
  [github.com/openai/codex-plugin-cc](https://github.com/openai/codex-plugin-cc),
  marketplace name `openai-codex`, plugin `codex`, author `OpenAI`. This
  skill orchestrates that plugin's real commands (`rescue`, `review`,
  `adversarial-review`, `status`, `result`, `cancel`) — it does not
  reimplement or replace them.
- **`/goal`** is a genuine Claude Code built-in (confirmed present in the CLI
  binary): `/goal [<condition> | clear]`, "Set a goal — keep working until
  the condition is met." It's a stop-gate evaluated when the model tries to
  end a turn, not a scheduler.

## What is NOT official

- **"Graph Engineering"** as a term is not used by Anthropic or OpenAI in any
  official documentation. It's a community/marketing label that started
  circulating in mid-2026, applied loosely to any multi-agent orchestration
  setup. This skill implements the underlying official patterns, not a
  product with that name.
- `/codex:review --adversarial` does not exist as a flag — the real, separate
  command is `/codex:adversarial-review`.
- The Codex plugin is not a community integration; be skeptical of any
  writeup claiming so — it ships from OpenAI's own GitHub org.

## Adjacent but unrelated projects (don't confuse with this skill)

- `launchdarkly/agent-skills@agent-graphs` — despite the name, this manages
  **LaunchDarkly AI Configs** (prompt/model configuration graphs hosted on
  LaunchDarkly's platform), not orchestration between coding agents. Not
  related to this skill's approach.

## Verification method

These claims were checked directly against the installed binaries and plugin
sources rather than trusted secondhand — reading plugin `commands/*.md`
frontmatter, grepping the Claude Code CLI binary for built-in command
strings, and checking the installed marketplace's `marketplace.json` for
plugin ownership. Re-verify against your own installed versions before
relying on exact flag names, since plugin internals can change between
releases.
