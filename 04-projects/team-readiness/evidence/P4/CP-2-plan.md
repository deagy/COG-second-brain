# P4 — CP-2 plan

**Two people on one store, and concurrency that survives them.** AC-7 and AC-9.
Changes shipped code in recall, so it owes a release.

## What P0 measured, and what P3 changed

P0 found the store is a local SQLite file with no sharing story in the path
cadre uses, and that recall's own `SQLiteStore` sets its pragmas in a way
cadre's staged store had already had to fix:

```
recall  store/sqlite.go:  db.SetMaxOpenConns(1)
                          db.Exec("PRAGMA journal_mode=WAL")     ← per connection
cadre   staged_db.go:     file:…?_pragma=busy_timeout(…)&_pragma=journal_mode(WAL)
                                                                 ← connection string
```

cadre's comment records why it moved: *"a busy_timeout set that way is absent
on the next connection… two concurrent writers failed with 'database is
locked'"*. recall has the earlier shape, no `busy_timeout` at all, and no
retry — and `SetMaxOpenConns(1)` serialises within one process while saying
nothing about two.

P3 made the sharing question answerable rather than solving it: `recall-server`
now reports the subject it authenticated, and cadre records it. So AC-7 is
about whether two credentials on one server actually stay in their own
namespaces, which is a property `ScopedAPIKeyAuth` claims and nothing has
exercised end to end.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Give recall's `SQLiteStore` connection-string pragmas including `busy_timeout`, matching the shape cadre already had to adopt | AC-9 |
| T-02 | Retry on `SQLITE_BUSY` where a lock upgrade can still fail inside a transaction, which `busy_timeout` alone does not cover | AC-9 |
| T-03 | A guard that fails on the old shape: two processes against one store, both completing without a locked-database error or a lost write | AC-9 |
| T-04 | A guard that two credentials on one `recall-server` read and write only their own namespaces — the property `ScopedAPIKeyAuth` asserts | AC-7 |
| T-05 | Demonstrate two callers with distinct credentials against one running server, each recorded under their own subject | AC-7 |
| T-06 | Release recall, so both criteria are verifiable against an installed artifact | AC-7, AC-9 |

Six tasks, so CP-4 is owed.

## Where this is most likely to go wrong

**T-03 is the task that decides whether AC-9 meant anything.** A concurrency
test that passes on the current code is testing something other than the
defect. It must fail against `db.Exec("PRAGMA …")` with no busy timeout, and
pass after — and the failure has to be the real one, `database is locked`,
rather than a timeout I chose.

**AC-7's weak reading is "the auth package has tests".** It does — 37 of them.
The criterion asks whether two credentials on *one running server* stay
separated, which is an integration property the unit tests cannot show. The
evidence has to be two clients, one server, one store, and a read that returns
nothing from the other's namespace.

**recall is the dependency here, so a change is not free.** cadre pins
`github.com/deagy/recall`, so a release that changes `SQLiteStore`'s
connection handling reaches cadre the next time it bumps. Anything that alters
behaviour rather than robustness needs saying out loud in the changelog.
