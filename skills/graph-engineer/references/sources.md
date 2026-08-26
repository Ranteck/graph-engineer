# Sources and provenance

This skill is built on pieces checked directly against installed
binaries/plugin sources at design time (see Verification method below) — no
invented commands, no fabricated official features, as far as that check
could confirm. It's a verification claim about how these facts were
established, not a claim that they're permanently guaranteed to hold: plugin
internals and CLI builtins can change between releases, so treat this as
"verified once, against a specific version" rather than an absolute
certainty. This file documents what's official and what isn't, because
"graph engineering" got confused with several things during this skill's
design.

## What's official

- **Orchestrator-Workers** and **Evaluator-Optimizer** are real Anthropic
  workflow patterns, documented in
  [Building Effective Agents](https://www.anthropic.com/engineering/building-effective-agents).
  Verbatim from that article:
  - Orchestrator-workers: "a central LLM dynamically breaks down tasks,
    delegates them to worker LLMs, and synthesizes their results."
  - Evaluator-optimizer: "one LLM call generates a response while another
    provides evaluation and feedback in a loop."
  By default, this skill nests an Evaluator-Optimizer loop (Codex implements,
  Codex critiques, Claude arbitrates) inside an Orchestrator-Workers structure
  (the user/Claude session orchestrates, Codex is the default worker).
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
- **`general-purpose` and `Explore` agents, plus `ListAgents` and
  `SendMessage`,** are official Claude Code built-in agent/tool primitives,
  not third-party integrations. `backend-selection.md` uses them for the
  opt-in Claude routing paths and documents their materially different
  authority, continuity, and isolation properties. Their built-in status was
  verified from the current Claude Code session's own agent/tool listing,
  which exposes them directly to the session rather than through a
  third-party or plugin-provided namespace. This was session-surface
  inspection, not binary or source inspection.

## Observed, but not independently verified for this skill's use case

Real and not fabricated, but weaker evidence than the "What's official"
entries above — don't treat these as validated for unattended `--write`
work just because they exist.

- **`/loop`** exists in at least some Claude Code environments as a way to
  keep a session running across turns, independent of `/goal`. This has
  been observed directly (not just referenced) in at least one session.
  Its exact availability, persistence guarantees, and security semantics
  for unattended `--write` work have not been independently verified or
  stress-tested for this skill's use case — treat any `/loop` mention
  elsewhere in this project as "known to exist," not "validated safe for
  unattended graph-engineer cycles."
- **`npx skills add <owner>/<repo>`** is a real, third-party installation
  pattern from the [`skills` CLI](https://www.skills.sh/)
  (`vercel-labs/skills`), not a Claude Code builtin. It writes into
  `~/.claude/skills/`. Confirmed via the tool's own documentation/issues at
  design time — re-verify against your installed version, since community
  tooling around skills is young and moving.

## Community design inputs whose full text was not independently verified

The elevated-assurance mode
(`skills/graph-engineer/references/elevated-assurance.md`) originated from a
2026-07-30 design discussion prompted by two posts on X the user brought in:

- Akshay Pachaar, "Graph Engineering Clearly Explained," dated 2026-07-25
  ([x.com/akshay_pachaar/status/2081089131808243999](https://x.com/akshay_pachaar/status/2081089131808243999)).
- angel/@angeldot_, "GRAPH ENGINEERING CON OPUS 5," dated 2026-07-25
  ([x.com/angeldot_/status/2081061068516798931](https://x.com/angeldot_/status/2081061068516798931)).

Claude retrieved and read both posts' full text directly (via browser, not
`WebFetch` — X blocks that tool's scraping with an HTTP 402). Codex, in its
own separate read-only design-discussion session, could not fetch the URLs
itself and worked from a written description of the relevant pattern
(diverse-lens/adversarial verification, "never let the same agent grade its
own homework") rather than the raw post text — its recommendation should be
read as evaluating that described pattern, not as independent confirmation
that these specific posts say what they're summarized as saying here.

Neither post is claimed to have originated the diverse-lens-verification
pattern, and neither is treated as proof that this specific implementation is
effective — that would overstate what a social-media post, however fully
read, can establish. What's actually adopted here is narrower than and
different from both posts' broader roadmaps: most of what they describe
(parallel research fan-out, JS routers, per-node model staggering) does not
apply to this skill's default single-Codex-worker design and was explicitly
rejected during the design discussion; only the "reviewer node with teeth, one
agent writes" principle carried over, and even that was adopted with a
**rejection** of the majority-vote survival rule both posts describe — see
`elevated-assurance.md`'s "What this explicitly does not do" section for why.

## What is NOT official

- **"Graph Engineering"** as a term is not used by Anthropic or OpenAI in any
  official documentation. It's an unsourced, undated community/marketing
  label, applied loosely to any multi-agent orchestration setup — no
  specific origin or timeframe for its circulation is claimed here. This
  skill implements the underlying official patterns, not a product with
  that name.
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

Methods differ by claim, not uniform across this whole file: the Codex
plugin and `/goal` were checked directly against installed binaries and
plugin sources — reading plugin `commands/*.md` frontmatter, grepping the
Claude Code CLI binary for built-in command strings, and checking the
installed marketplace's `marketplace.json` for plugin ownership. `/loop`
was confirmed by direct observation in a live session, not binary
inspection. `npx skills add` was confirmed via the `skills` CLI's own
documentation and issue tracker, not by inspecting its source. Re-verify
against your own installed versions before relying on exact flag names or
behavior, since plugin internals and third-party tooling can change between
releases.

The `--resume-last` "latest thread" semantics that `elevated-assurance.md`'s
fan-in barrier depends on were verified directly by reading the plugin's own
source, not inferred or taken from Codex's word: `sortJobsNewestFirst` in
`plugins/codex/scripts/lib/job-control.mjs` sorts tracked jobs by `updatedAt`
descending, and `resolveLatestTrackedTaskThread` in `codex-companion.mjs`
resolves `--resume-last` to the newest one — there is no resume-by-thread-ID
in the model-callable `task` interface. The same code path throws if another
tracked task is still `queued` or `running`, which blocks a resumed call from
running concurrently with lenses but does not by itself prevent a lens that
finishes *after* canonicalization from becoming the next "latest" thread —
which is exactly the gap the barrier and late-lens rule exist to close.

Verified against `openai-codex` plugin **v1.0.6** specifically (same pin as
`README.md` and `skills/graph-engineer/SKILL.md`).
