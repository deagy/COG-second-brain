# P4 — CP-5 acceptance · AC-5

**EVIDENCE AC-5 | CP-5 | PASS** — a retention or erasure request is refused where it is reached for, naming the gap.

CP-3v enumerated ~15 reach-paths independently — both dispatch routes, flag-before and after the verb, `--x=y` and single-dash forms, retired and Python-era verbs, the staged route — and every one names what was removed, the commit, that nothing rebuilt it, where content lives now, and that the decision is open. None falls to a parser error. Artifact: `CP-3v-round1.md`, cadre `0e249942`, CI run 33648430913.

**EVIDENCE — | CP-4 | PASS** — 15 claims, round 2. Artifact: `CP-4-integration.md`.

## The gap was the flags, not the verbs

Measured before building: `retention-report`, `delete-ingested` and `deletion-evidence` already refused by name. `search --retention-days 30` answered `flag provided but not defined`. True, and useless — a parser fact at the moment someone is trying to honour an obligation.

The flag names came from `git show b418031e~1:roster/knowledge-store/src/cli.py`, not from memory. A refusal firing on a flag nobody would type is a refusal nobody sees.

## What CP-4 caught, and why it mattered more than the feature

Round 1 found `delete-staged --id X --reason "--retention-days" --deleted-by t` **refused instead of deleting the record**. A good deletion reason, on a working command, mentioning the capability the reason was about.

That is worse than the parser error the refusal replaced. The justification for a pre-parse hook is that `flag provided but not defined` tells a steward nothing; refusing work they are entitled to do tells them something false. **A message improvement that breaks a command is not an improvement.**

I named this exact risk when dispatching CP-4 and shipped it anyway — the reasoning was in the brief and not in the code.

## The boolean list, and its deliberate failure direction

The fix tracks which tokens are values, which needs to know that a boolean flag's successor is not one. `booleanKnowledgeFlags` is hardcoded from the `fs.Bool` declarations, and it will drift.

Its failure mode is one-directional by design: a boolean flag *missing* from the list makes the refusal skip the token after it, degrading a real request to the parser error — exactly the pre-refusal behaviour. **An out-of-date list can never refuse work someone was entitled to do.** CP-4 confirmed that direction live in a scratch clone rather than taking the argument.

My own test caught the first attempt: handling values but not booleans let `search --all-sources --trigger x` fall through, a case I had predicted in a comment and asserted against in the same commit.

## Two directions, both pinned

A value that looks like a refused flag is not a request. The same token in flag position still is. Falsifying by disabling the refusal reproduces `flag provided but not defined: -retention-days` verbatim — the message this exists to replace.

## The standard was set against this project

CP-3v round 1 of P3 used AC-5's own wording — *"not only in `SECURITY.md`"* — to rule that prose could not satisfy AC-4. The phase owning that sentence had to meet it, and a document would not have.

## What this does not do

It does not build retention or erasure. `capability-parity` decided to declare rather than build, and the bar has not changed. This makes the declaration **reachable at the moment of the reach**, not the capability real.
