# P4 — CP-5 acceptance (AC-7, AC-9)

EVIDENCE AC-9 | CP-5 | PASS | 10 then 20 concurrent `recall upload` invocations as **real OS processes** against one shared database, from the released `recall-0.3.6-linux-arm64`, three rounds: no `database is locked` or `SQLITE_BUSY` in 30+ process logs, and `store info` reported exactly the expected chunk counts each round (60, 80, 100) — no lost write, no double count | CP-3v, `/tmp/claude-1000/p4-cp3v/load2-out-*.log`
EVIDENCE AC-9 | CP-5 | PASS | The fix is the whole-transaction retry plus connection-string pragmas, and both halves were falsified independently: removing the retry fails the concurrency test under load, removing the pragmas fails the structural one. `go test ./store/... -race -count=3` green under load | CP-3v; `~/sdk/recall/store/sqlite.go`
EVIDENCE AC-7 | CP-5 | PASS | Two scoped keys against a running `recall-server v0.3.6`: `/whoami` returns distinct subjects and distinct namespaces per credential; distinct content seeded in each namespace so a null result could not be satisfied by an empty store; cross-namespace searches returned only the querying credential's own content, never empty and never leaked | CP-3v, `/tmp/claude-1000/p4-cp3v/server.log`
EVIDENCE AC-7 | CP-5 | PASS | Isolation was attacked rather than confirmed. `POST /upload` naming another tenant's namespace → 403; `?namespace=` and `?ns=` query parameters → ignored, still scoped to the caller; crafted `namespace`/`namespaces`/`filters` fields in a hybrid-search body → ignored, the server injecting its own filter from the authenticated request; `/graph/{entity}` for the other tenant's document → 404. No path reached cross-tenant content | CP-3v; `~/sdk/recall/api/handlers.go`
EVIDENCE AC-7 | CP-5 | PASS | Concurrency holds across the seam into P5: a live `delete-ingested` run concurrently with five parallel `recall upload --server` writes against the same physical file completed with no lock error and no lost write, confirmed by an independent count | CP-4, `/tmp/claude-1000/p345-cp4.md`

## The boundary this criterion does and does not claim

AC-7 says two credentials sharing one store **through `recall-server`** stay
within their namespaces, and that is what was verified and what holds.

It does not claim that two people sharing a store **through cadre** are
isolated, and CP-4 established that they are not: cadre's data path opens the
local database directly, so recall's enforcement never applies to it. That is
recorded as a documented limitation rather than a failure of this criterion —
see `evidence/P3/` and the note in `roster/knowledge-store/SECURITY.md` — on
the operator's decision to state the limit rather than half-close it.

Keeping those two sentences apart is the point. A criterion that quietly grew
to cover the composition would have been marked FAIL; one that quietly shrank
to avoid it would have been dishonest.
