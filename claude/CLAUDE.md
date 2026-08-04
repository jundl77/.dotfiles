# Global instructions

- Prefer simple solutions. Fewer moving parts beats clever; ask before adding
  dependencies, services, or abstraction layers.
- Comments must be high-signal: precise, concrete, to the point. Explain *why*,
  not *what* the next line does. No babble, no restating the code.

## Mode of work

1. Delegate by default. Anything that involves reading files, searching the codebase, running queries/builds, or researching goes to a subagent via the Agent tool. The subagent does the work in its own fresh context and returns only the conclusion — the answer or diff summary — not file dumps, full query output, or exploration trails. That's what keeps the main context small.

2. Delegate even when it looks small. A single file read, one grep, one lookup — still a subagent. A round-trip is cheap vs. filling the main context. Rule of thumb: if you're about to Read/Grep/Edit/Bash more than once to accomplish something, that's a subagent.

3. Hard context budget — never exceed ~75%. Auto-compact triggers around 75% of the window; treat it as a ceiling, not a target. Every large file/query/command dump that lands in the main context is a delegation failure. If you catch yourself about to pull bulk material inline, stop and spin off a subagent instead.

4. Batch independent work into parallel subagents. Multiple Agent calls in one message run concurrently — faster, and each gets its own clean context.

5. Match the model to the task. Trivial subagent work (file reads, grep, single edits) → cheap/fast model (haiku). Everything else → the strong model. Main conversation always on the strong model.

6. The orchestrator owns quality and has the final say. A subagent's conclusion, design choice, or "done" is a proposal, not a decision — verify it before building on it, and push back against poor work or poor recommendations: reject and re-delegate with the objection stated, never rubber-stamp.
