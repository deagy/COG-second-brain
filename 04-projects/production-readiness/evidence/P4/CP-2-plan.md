# P4 — CP-2 plan · AC-5

**AC-5:** an absent capability is refused where it is reached for. A retention or erasure request is refused at the point of use, naming the gap — not only in `SECURITY.md`. Falsified by running the command and reading what it says.

## The standard this phase is held to was set against this project

CP-3v round 1 of P3 used AC-5's own wording — *"not only in `SECURITY.md`"* — to rule that prose about `staged_by` and `decided_by` could not satisfy AC-4. The same standard now applies to the phase that owns the sentence. A document is not a refusal.

## What already refuses, and what does not

Measured, not assumed:

| Reached for as | Today |
|---|---|
| `knowledge retention-report` | refused by name, cites `b418031e` ✓ |
| `knowledge delete-ingested` | refused by name ✓ |
| `knowledge deletion-evidence` | refused by name, says which half exists ✓ |
| `knowledge delete` | retired by name, points at recall ✓ |
| `knowledge search --retention-days 30` | **`flag provided but not defined: -retention-days`** |
| `knowledge propose --retention-days 30` | same |
| `knowledge delete-staged --purge` | same |

**The verbs are covered; the flags are not.** A steward who knows retention used to exist reaches for it as a flag on a command that still works, and gets a parser error — which says the flag is unknown, not that the capability was removed, never rebuilt, and is an open decision. That is silence at the exact moment someone is trying to honour an obligation.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Name the retention and erasure flags the Python CLI accepted, from history rather than memory | AC-5 |
| T-02 | A live `knowledge` command receiving one refuses by name, saying what was removed and where content lives now | AC-5 |
| T-03 | The same for the context store, which copies the knowledge store's shape deliberately | AC-5 |
| T-04 | Tests that run the command and read the message, falsified by removing the refusal | AC-5 |

## What would falsify this phase

**Grepping for the string instead of running the command.** AC-5 says falsified by running it and reading what it says. A test asserting the source contains a message proves the message exists, not that anyone reaching for retention ever sees it.

**Refusing on a flag nobody would type.** T-01 is not optional: the flags have to come from what the Python CLI actually accepted, recovered from `b418031e`'s parent, or the refusal fires on a guess and misses the word a real steward uses.

**Turning a refusal into a suggestion.** "Not supported" is a parser message with better manners. The refusal has to name the capability, the commit that removed it, that nothing rebuilt it, and that the decision to rebuild or declare it out of scope is open — the same content `SECURITY.md` carries, at the moment of use.

## Not in scope

Building retention or erasure. `capability-parity` decided to declare rather than build, and this project's bar — one operator, no third party's content in the store — has not changed. This phase makes the declaration reachable, not the capability.
