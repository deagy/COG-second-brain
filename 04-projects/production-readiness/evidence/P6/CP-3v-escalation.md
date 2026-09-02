# P6 — escalation after the third CP-3v failure of AC-3b

Stopping here rather than fixing again, under `AI-18`:

> The two-attempt fix budget is not the worker's to extend on the grounds that its
> method changed. On a third failure of the same criterion, stop and put it to the
> user: state the pattern, the proposed new method, let them spend the attempt.

That rule exists because I extended the budget once before, in `capability-parity`,
by telling myself each attempt was a first attempt at a new method.

## The pattern, which is the same defect getting one level deeper each round

| Round | What was wrong |
|---|---|
| 1 | The README said `handoff`. `handoff list` ignores `--config`; `handoff get` and `handoff prune` refuse it |
| 2 | The guard checked that a subcommand's **name** appeared in the table, not the **row** it sat under. A bucket flip passed |
| 3 | The guard's table parser **silently skips rows it cannot read**. `` `dispatch <plan>` `` and `` `run <plan>` `` do not match its regex, so the two rows the README's own prose singles out are excluded from classification. Moving both to the wrong bucket passes |

Measured, not summarised — the regex over the Honoured row's cell yields
`['config show', 'config setup', 'config update']` and drops the other two.

**Every one is a silent omission**, and each fix produced a new surface for the same
thing. That is not three unrelated bugs; it is one shape, and I have now failed to
close it three times by strengthening the same design.

The design is the problem. **A guard that parses prose can always fail to parse
something, and the failure looks exactly like coverage.** Round 3 found two more ways
in — a stray character in a bucket label drops the whole row, a name losing its
backticks drops one entry — and there will be more, because the space of ways a
markdown table can fail to match a regex is not bounded by my imagination.

## The proposed method, which is a change in kind

**Stop reading the table. Generate it.**

A test that:

1. enumerates every subcommand from the binary's own help output, not from a list in
   the test or a table in the README;
2. classifies each by running it, as it does now;
3. renders the table from that;
4. asserts `README.md` contains exactly that rendering, byte for byte.

There is then no parser to skip a row, no regex to miss a placeholder, and no way for
a subcommand to be absent from both the doc and the check — because the doc is
derived from the enumeration rather than compared against it. A mismatch prints the
diff and the fix is to paste the generated block in.

Its own failure mode is enumeration: if the binary stops listing a subcommand in
help, the table loses it silently. That is a smaller and namable surface, and it is
guarded by a count assertion against the dispatcher's command registry.

## What is not in question

AC-3b's substance held under all three rounds. The documentation defects this phase
found are fixed and independently confirmed: the help text, the records' banners,
`config show`'s three states, the provider list, the architecture paths, the roster
docs, the plugin interface, the web UI, the metrics, and the `config.toml` example.
Round 3 re-checked a sample of each directly and they stand.

What is open is **whether the guard on the `--config` table is trustworthy**, and
three rounds say the current design is not.
