---
name: blind-naming-test
description: Review important identifier names with fresh blind readers. Compare names-only predictions with implementation, then rename and retest misleading names. Use during requested naming or code reviews.
---

# Blind naming test

Cap the review at important concepts: public interfaces, domain decisions,
protocols, ownership, timing and units, buffer bounds, telemetry and data
contracts. Include private names when misunderstanding them could cause a bug.
Skip routine locals, loop indices, framework names and stylistic preferences.
A repository-wide pass covers these important concepts across components;
it does not require an exhaustive identifier inventory.

Choose a bounded, source-grounded list before starting. Prioritize misleading
names over merely terse ones. Do not expand the pass indefinitely or delay
shipping a validated change to rename low-impact symbols. Group occurrences
only when they mean the same concept.

1. The main reviewer independently reads implementation and relevant callers,
   recording the actual meaning with file/line evidence. Include distinguishing
   effects, units, polarity or invariants where material.
2. Spawn a **fresh, low-reasoning agent for each concept and every retry**.
   In Codex use `fork_turns="none"`, `reasoning_effort="low"`; in Claude use
   a fresh lightweight Agent with equivalent isolation. No inherited conversation,
   project instructions or repository access; no tools. If this cannot be ensured,
   report the limitation and leave the test pending. Never reuse or resume a reader.
3. Give only exact identifier names and this neutral prompt:

   > Infer the likely meaning or behavior from these identifier names alone.
   > Explain ambiguities or unclear abbreviations. Do not use tools or assume a
   > project domain. Names: `<names>`

   Related names may accompany one concept only when readers encounter them
   together. Never include paths, code, signatures, comments, domain hints,
   expected meanings or previous attempts. Discard contaminated attempts.
4. Compare the verbatim prediction with the independent implementation meaning.
   A generic guess missing distinguishing behavior is insufficient. Keep aligned
   names; rename unclear/misleading ones within authorized scope, check references
   and behavior, then retest with another fresh agent. Preserve failed attempts
   and rename reasons. Check compatibility before changing external contracts.

Record contextual exceptions for mandatory language/protocol/framework names,
fixed external contracts, or conventional mathematical/loop names justified by
their immediate use. For example, `i` as a short local loop index is a contextual
exception, not a blanket exemption. Exceptions are not blind passes.

Keep a compact record per concept in the review's existing notes or artifact:

```yaml
concept: stable identity with all scoped occurrence locations
implementation: actual meaning and supporting implementation/caller file:line references
attempts: # append; never overwrite failed attempts
  - names: exact names shown for this attempt
    reader: fresh agent ID, isolation configuration, low reasoning
    prediction: verbatim blind response
    comparison: source-grounded agreement or mismatch; aligned / unclear / misleading
    rename: replacement and reason, when needed; next attempt must test the replacement
disposition: aligned / contextual exception with reason / pending with reason
```

After edits, reconcile the selected names and locations while retaining attempt history. Close
when the important selected concepts are aligned or explicitly excepted. If retries stop
improving names, a safe rename is blocked, or the review budget is exhausted,
record unresolved coverage honestly. Report scope, renames, exceptions, checks and
remaining important gaps concisely; do not claim exhaustive coverage.
