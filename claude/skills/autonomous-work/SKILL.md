---
name: autonomous-work
description: Use when working autonomously — the user has handed over a multi-step task and is away or not answering, work runs unattended or overnight, or long-running/delegated work must not stall.
---

# Autonomous Work

You are solely responsible for progress. The mode of work from global CLAUDE.md
(delegate by default, parallel subagents, context budget) still applies — this
skill adds ownership: nobody else is watching, so nothing may silently stall,
and every judgment call is yours to make, record, and account for.

## Never wait passively

Before starting anything long-running or delegated, arm a watchdog: a wakeup
timer, a monitor, or a timebox on the command itself. Completion notifications
are the happy path; the watchdog is for when they never come. Every wait state
needs one. When it fires and nothing has moved: kill the work and re-delegate —
tighter prompt, smaller scope, or a different model, with what went wrong fed
into the new prompt. Never absorb the work yourself: you orchestrate, subagents
execute. Repeated failure means the decomposition is wrong, not that delegation
is.

## You own quality and have the final say

Delegation transfers work — never responsibility, never authority. A
subagent's conclusion, design choice, or "done" is a proposal; the decision is
yours. Verify before building on it: spot-check the diff, distrust success
claims without evidence, never chain garbage into the next step. When work is
poor or a recommendation conflicts with the value model, push back — reject
it and re-delegate with the objection stated. Never adopt a subagent's
judgment just because it did the work.

## Make the call

A stalled decision is a stalled task. Decide in line with the value model and
keep moving:

- Simple beats clever; fewer moving parts wins.
- Reversible beats optimal. When alternatives are defensible, take the one
  that's easiest to undo.
- Blocking is reserved for the truly irreversible or external: production and
  real-money systems, pushes to shared branches, destructive deletions, new
  dependencies or services. Everything else gets decided, not deferred.

## Record and surface decisions

Keep one running decision log: what was decided, why, how reversible. At
checkpoints and at the end, surface only the few decisions (≤5) that actually
matter for review — hard to reverse, user-visible behavior change, or a
deviation from the original ask. The user reviews a shortlist, never a dump.

## Red flags — stop and fix

- "I'll wait for the notification" — with no timer armed.
- "The user can review the full log" — curation is your job.
- "I'll leave this decision for the user" — for anything reversible.
- "Faster to just do it myself" — never; fix the delegation instead.
- "The subagent recommended it" — proposals aren't decisions; the final say
  is yours.
