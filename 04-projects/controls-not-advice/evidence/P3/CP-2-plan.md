# P3 — CP-2 plan · AC-3, AC-6

**AC-3:** every `advice` item states why it cannot be a control, specific to that item, and lives where it loads — `CLAUDE.md` or a skill body, read at session start, not only in the backlog.
**AC-6:** the backlog distinguishes the three dispositions, so a reader can tell an unfixable rule from an unbuilt one without opening a retro.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Land AI-2 and AI-9 together in `CLAUDE.md`. They share one limitation and must say so in the same words: a decision made in conversation leaves no artifact to lint | AC-3 |
| T-02 | Land AI-7 in `CLAUDE.md` § Git, next to the rules it sits beside | AC-3 |
| T-03 | Land AI-14 in `CLAUDE.md`, with the note that AI-13's control covers its originating instance and this row is struck when that is demonstrated | AC-3 |
| T-04 | Land AI-6b in `WORKFLOW.md`, beside § "Amending a gated criterion" which covers its other half | AC-3 |
| T-05 | Restructure `BACKLOG.md`: a disposition column, a header explaining the three, and each row carrying its reason | AC-6 |

## What "states why" has to mean

The reason must answer **what a check would have to observe, and why that is unobservable**. Round 1 of P1 failed by writing reasons that sounded like reasons — "a judgment about worth" for an item that never asked a check to judge worth. A reason that would fit several items is not specific to one.

Each landed rule carries the originating incident with it. A rule without its incident is a maxim, and a maxim is what gets skimmed.

## What would falsify this phase

A rule landed somewhere nothing reads. `CLAUDE.md` is loaded every session; a retro is not. If an item ends up in a document that is only opened deliberately, it has not been landed — it has been moved.

The second falsification is subtler: a reason that is really an excuse. AI-7's reason is a **cost** argument (a hook would work; COG ships no hook infrastructure), not a feasibility one, and it must say so plainly rather than implying no check could exist. A reader who cannot tell "impossible" from "not worth it" cannot revisit the decision when the cost changes.

## Not in scope

Building any check. Reopening a disposition — P1 closed those and P2 tested them. AI-13's control shipped, but striking AI-14's covered half requires demonstrating the coverage, which is P4's business if it happens at all.
