# P1 / CP-5 — acceptance, observed at the binary

Built from cadre `e752376e`. CI green: `bash .claude/lib/ci-status.sh /home/deagy/sdk/cadre` → `deagy/cadre e752376e success run 33557815235`.

## AC-1 — no governance document sends a reader nowhere

The six verbs that returned `unknown subcommand`, run against the built binary:

```
$ cadre knowledge retention-report
cadre knowledge retention-report: shipped in the Python CLI, removed in the Go rewrite
(b418031e) and never rebuilt.
  per-message retention windows were a Python-era capability; this binary records none,
  so there is nothing to report on. Whether that is restored or declared absent is an
  open decision
exit=2
```

All six answer in that shape. Each names what happened and, where one exists, what to use instead — verified independently against the binary rather than read from the message.

**The claim they make is the load-bearing part.** Replacing silence with a positive statement is only an improvement if the statement is true, and the first version's was not: it said "never built in this CLI", which is true of the Go binary and false to anyone who used these. They were real, tested commands in `roster/knowledge-store/src/cli.py`, with handler code and dedicated test modules, removed wholesale in `b418031e`. Someone who remembers running `cadre knowledge list-staged` was not imagining it.

## AC-7 — the property is enforced, not restored

`TestEveryDocumentedKnowledgeVerbIsAnswerable` walks three hand-authored surfaces — `roster/`, `.agents/skills/`, and the CHANGELOG's `[Unreleased]` section — and fails on any `cadre` verb they name that the CLI would meet with silence, citing file and line.

Falsified in seven directions across the phase:

| Mutation | Result |
|---|---|
| Phantom top-level verb in a roster document | killed |
| Phantom `cadre knowledge` verb in a roster document | killed |
| Phantom verb in `.agents/skills/` | killed |
| Phantom verb in the CHANGELOG's `[Unreleased]` | killed, cited by line |
| A verb dropped from the answerable set while documents name it | killed |
| A top-level verb removed from `bin/subcommands.tsv` | killed |
| Ordinary prose — "the cadre binary", "a cadre role" | correctly ignored |
| The same phantom inside a **dated** CHANGELOG release | correctly ignored |

The bar is deliberately low: running, naming a replacement, or admitting the capability went away all pass. "The documents are correct" is not a property a test can decide. "A document cannot send a reader nowhere" is, and it is the one worth enforcing mechanically.

## What the phase found beyond its own criteria

- **`schema-validate` runs and `cadre help` lists it, but `bin/subcommands.tsv` did not.** The table and the help text disagreed about what exists, and the test that reads the table never covered it.
- **`packagedSubcommandExclusions` excluded `version`** from the packaged plugin — a rule guarding a subcommand already deleted.
- **`.agents/skills/` is a generator input root**, not an output, and two of its `SKILL.md` files instruct agents to run a removed verb. A guard scoped to `roster/` would have reported parity while live instructions pointed at a dead command.

## The caveat this row carries

Round-two verification independently confirmed the classification, all three corrected pointers, the scan roots and the guard's behaviour. The final delta — the CHANGELOG scanner and one stale identifier, cadre `e752376e` — was falsified by its author only, because the loop budgets two verify cycles and both were spent. Accepted at that bar deliberately, with the distinction recorded rather than smoothed away: an evidence trail that stops noting which claims were self-checked is how this repository acquired four criteria resting on local exit codes.
