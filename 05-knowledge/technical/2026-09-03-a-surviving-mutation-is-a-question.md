---
type: knowledge
domain: technical
project: recall — conversation loader (chat-export ingestion)
topic: A Surviving Mutation Is A Question, Not An Answer
created: 2026-09-03
last_updated: 2026-09-03
source: session — recall/cadre/gloop releases, conversation loader build
version: "1.0"
tags: ["#knowledge", "#testing", "#mutation-testing", "#go"]
related:
  - 05-knowledge/technical/2026-09-01-verification-that-depends-on-the-room.md
  - 05-knowledge/technical/2026-09-03-instructions-that-were-never-run.md
---

# A Surviving Mutation Is A Question, Not An Answer

## Overview
Two mutation checks on the conversation loader appeared to survive in one session, and both times the surviving mutation meant something other than "the test is weak." Once it meant the test never ran at all — `go test` served a cached result — and once it meant the test covered a real but different gap than the one assumed. Treating a surviving mutation as an immediate verdict ("weak test, rewrite it") would have produced a worse test both times; investigating why it survived produced a better one both times.

## Current State
- **`go test` caches results, and a cached "ok" looks identical to a real pass.** A mutation on the conversation loader appeared to survive; the run had actually printed `ok (cached)` and never executed the test binary at all. Only after adding `-count=1` did the mutation genuinely survive, which then exposed a real test gap. From the outside, "survived because the test is weak" and "survived because it never ran" produce the same terminal output — the fix is mechanical: every mutation check must pass `-count=1`, unconditionally, or the result is not evidence of anything. [Source: session, recall conversation loader mutation check | 2026-09-03 | confidence: high]
- **A surviving mutation pointed at the wrong guard, not a missing one.** A second mutation — breaking a field-mapping check — survived for a different reason: the "wrong mapping" case failed on the Turns guard before the Text check ever ran, so half of the matching logic was untested even though the suite as a whole looked complete. The surviving mutation was correct evidence, just not evidence of what it was assumed to mean. [Source: session, recall conversation loader mutation check | 2026-09-03 | confidence: high]

### Key Details
- **The generalization:** a surviving mutation is a question — "why did this not get caught?" — not an answer. It can mean the test is weak, but it can also mean the test never ran, or that it validates something adjacent to what the mutation changed (an upstream guard short-circuits before the assertion under test). Concluding "weak test" and rewriting blindly answers none of these; tracing the actual execution path answers all of them.
- **Practical checklist before trusting a surviving mutation:** confirm the test binary actually executed (`-count=1`, or otherwise defeat the cache) before reading anything into the result; then trace which assertion the mutated code path actually reaches, rather than assuming the nearest-looking assertion is the one that should have caught it.

## History
| Date | Version | Change | Source |
|------|---------|--------|--------|
| 2026-09-03 | 1.0 | Initial entry from harvest staging, recall conversation loader session | harvest-curator |

## Related
- [Verification that depends on the room](./2026-09-01-verification-that-depends-on-the-room.md)
- [Instructions that were never run](./2026-09-03-instructions-that-were-never-run.md) — adjacent but distinct family: that note is prose review substituting for execution of written instructions; this note is a test runner silently substituting a cached result for execution.
