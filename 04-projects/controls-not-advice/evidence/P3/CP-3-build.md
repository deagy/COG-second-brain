# P3 — CP-3 build · AC-3, AC-6

## The five advice items, landed where they load

| ID | Home | The reason it carries |
|---|---|---|
| AI-2 | `CLAUDE.md` § Before you assert it, check it | The defect is in a message to the user; there is no artifact to inspect, and by the time one exists the wrong claim is made |
| AI-9 | same section | Scriptable in one line, but nothing would invoke it — the defect is a reasoning step, not a gate |
| AI-14 | same section | Most environment notes are not version-pair-shaped, so the general stance is judgment |
| AI-7 | `CLAUDE.md` § Git | A `PreToolUse` hook would enforce it; COG ships no hook infrastructure. **A cost decision, said plainly as one** |
| AI-6b | `WORKFLOW.md` § Reading a criterion you are about to be judged by | The criterion is unedited and the verdict is a judgment; nothing syntactically distinguishes a generous reading from a correct one |

AI-2, AI-9 and AI-14 share a section because they share a limitation, and the section says so once in its own words rather than three times in three places: **each defect happens in a message rather than in a file.**

Every rule carries its originating incident — the `cadre-lifecycle` name proposed off a misread citation, the archived-but-installable repository, the "installed 0.13.2, repository 0.14.2" note filed as trivia, the archived file offered as a defence at AC-04's gate. A rule without its incident is a maxim, and a maxim gets skimmed.

## AC-6 — the backlog now distinguishes three things

Header rewritten to define `control`, `advice` and `landed`, and to say what closes each. All twenty rows carry one, including the six from the earlier retro that had been marked `done` — a fourth label that undercut the very distinction AC-6 asks for. Those are now `control` (AI-17, which built a check) or `advice` (the rest, which landed rules).

The header states two things the P1 triage had to learn the hard way:

- an `advice` reason must answer **what a check would have to observe, and why that is unobservable** — a reason that would fit several items is not a reason for one of them;
- a **cost** argument must say so plainly rather than dressing itself as impossibility, or nobody can revisit it when the cost changes.

## What this phase nearly got wrong

The six rows labelled `done` would have left the file with four vocabularies where AC-6 asks for three, and `done` is exactly the uninformative label the criterion exists to remove — it says the row is finished and nothing about whether a check now stands behind it. Caught by counting dispositioned rows against total rows rather than by reading the file, which would not have shown it.
