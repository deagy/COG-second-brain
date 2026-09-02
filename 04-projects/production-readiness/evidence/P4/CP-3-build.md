# P4 — CP-3 build · AC-5

| Task | Outcome | Artifact |
|---|---|---|
| T-01 | The flags recovered from `b418031e~1`, not from memory | `internal/cli/knowledge_absent_capability.go` |
| T-02 | A live `knowledge` command receiving one refuses by name | cadre `bb35c49e` |
| T-03 | Both dispatch routes covered — `KnowledgeCmd` and `KnowledgeStagedCmd` | same |
| T-04 | Tested by running the dispatch and reading stderr; falsified by bypass | `knowledge_absent_capability_test.go` |

## The gap was measured before anything was built

| Reached for as | Before |
|---|---|
| `knowledge retention-report` | refused by name ✓ |
| `knowledge delete-ingested` | refused by name ✓ |
| `knowledge deletion-evidence` | refused by name ✓ |
| `knowledge search --retention-days 30` | **`flag provided but not defined: -retention-days`** |
| `knowledge propose --retention-days 30` | same |
| `knowledge delete-staged --purge` | same |

**The verbs were covered; the flags were not.** That message is true and useless — it reports a parser fact at the moment someone is trying to honour a retention or erasure obligation, and says nothing about the obligation having no tool behind it here.

## What the refusal now says

It names the flag, what it used to do, that the capability was removed in `b418031e` and never rebuilt, that ingested content lives in a recall store whose CLI exposes no delete either, that rebuilding or declaring it out of scope is an open decision, and that deleting the store file is not the same act — unscoped, unrecorded, and it removes everything else too.

That is the content `SECURITY.md` carries, delivered where the reach happens.

## Two checks that stopped this being worse than the parser error

**The flag names came from history.** `git show b418031e~1:roster/knowledge-store/src/cli.py` gives `--retention-days`, `--trigger`, `--as-of` as the retention- and erasure-shaped flags whose capability went with them. A refusal firing on a flag nobody would type is a refusal nobody sees.

**`--scope` and `--as-of` are live on the context store.** Checked before wiring: the context store has real expiry and four live `--scope` uses. Refusing these globally would have broken working commands to improve a message, so the refusal is namespaced to `cadre knowledge`. That is the second time in this goal that verifying a flag's liveness before asserting it stopped a regression.

## Falsification

The plan named "grepping for the string instead of running the command" as a way this phase could pass while failing. Every case invokes the real dispatch and reads stderr. Bypassing the refusal reproduces `flag provided but not defined: -retention-days` verbatim, which is the message it exists to replace.

A negative case pins the other direction: a live invocation must not be refused as an absent capability.

## The standard was set against this project

CP-3v round 1 of P3 used AC-5's own wording — *"not only in `SECURITY.md`"* — to rule that prose about `staged_by` and `decided_by` could not satisfy AC-4. The phase that owns that sentence had to meet it, and a document would not have.

## Not in scope

Building retention or erasure. `capability-parity` decided to declare rather than build, and the bar has not changed: one operator, no third party's content in the store. This makes the declaration **reachable**, not the capability real.
