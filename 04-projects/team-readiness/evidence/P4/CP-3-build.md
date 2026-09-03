# P4 — CP-3 build

AC-7 and AC-9, both in recall. Committed at `378cd92`; release pending.

## AC-9: the first fix was not enough, and how it failed is the finding

`SetMaxOpenConns(1)` serialises writers inside one process and says nothing
about two, which is what a shared store means. The pragmas were set with
`db.Exec`, so they configured whichever pooled connection ran them, and there
was no busy timeout at all.

**Moving them into the connection string made the test pass in isolation and
fail under full-suite load.** That is the whole lesson of this task:

```
$ go test ./store/ -run Concurrent      → ok
$ go test ./...                         → FAIL: inserting chunk: database is locked (SQLITE_BUSY)
```

`busy_timeout` applies while *acquiring* a lock, not to *upgrading* one
already held. SQLite defers the write lock until the first write, so a second
writer begins its transaction happily and gets `SQLITE_BUSY` on its opening
INSERT — inside a transaction that is then dead. Retrying the begin cannot
help; retrying the statement runs against a transaction SQLite has already
rolled back.

So the unit of retry is the transaction. That is only safe because the body is
idempotent — `INSERT OR REPLACE` keyed by chunk id — which is a property worth
stating rather than assuming, since a retried transaction that was not
idempotent would double-write rather than fail.

**A test run only in isolation would have called this fixed.** The load came
from running the whole suite, which is not a technique so much as an accident
that happened to be pointed the right way.

## AC-7: the mechanism was tested; the property was not

`ScopedAPIKeyAuth` asserts that a credential sees only its own namespaces, and
37 tests exercise the authenticator — none of them through a server. Those
check that a key resolves to a subject and a subject maps to namespaces, which
is the mechanism. The property is that a search made with one credential does
not return another's documents, and only a request through the whole stack
shows it.

Now tested end to end: alice's document seeded in her namespace, found by her
credential, absent from bob's search. The test asserts alice can find her own
document first — without that, "bob found nothing" is satisfied by a store
that contains nothing.

## Falsification

| Mutation | Fails |
|---|---|
| retry removed (single attempt) | the concurrency test, under load |
| pragmas out of the connection string | the structural test |
| `RequestNamespaces` ignored in handlers | the isolation test |

Three independent mutations, three different tests. None of them fails all
three, which is what says they are testing different things.

## Carried, not fixed

**recall's CI checks out `deagy/cadre` with no ref**, so it builds against
cadre's default branch. A push to cadre can turn recall red without recall
changing — which is how a `gofmt -s` difference in a cadre file failed recall's
build earlier in this phase. That is a coupling decision about recall's CI
rather than a false claim, so it goes to the retro's dispositions rather than
being changed mid-phase.

---

## CP-3v: PASS, and it tested more than the implementation did

Verified against the released `v0.3.6` binaries, not a checkout.

**AC-9 was proved with real processes.** My own test opens two `*SQLiteStore`
handles in one process — goroutines, not processes — which is not quite the
claim the criterion makes. The verifier spawned 10 then 20 concurrent `recall
upload` invocations against one shared database, three rounds, and found no
locked-database error in 30+ process logs and exactly the expected chunk
counts each round: no lost write, no double count.

That gap was mine and worth recording: a test that demonstrates something
adjacent to the claim reads as proof of the claim.

**AC-7 was attacked rather than confirmed.** Two scoped keys against a running
server, distinct subjects from `/whoami`, distinct content seeded in each
namespace so "found nothing" could not be satisfied by an empty store — and
then deliberate escape attempts:

| Attempt | Result |
|---|---|
| `POST /upload` with `"namespace":"team-alice"` under bob's key | 403 |
| `GET /search?namespace=team-bob` under alice's key | scoped to alice |
| `?ns=team-bob` | scoped to alice |
| crafted `namespace`/`namespaces`/`filters` in a hybrid-search body | ignored; the server injects its own filter from the authenticated request |
| `/graph/{entity}` for the other tenant's document | 404 |

No path reached cross-tenant content.

## Carried, not fixed: an ops endpoint enumerates tenants

`GET /diagnostics` is unauthenticated by design — its comment says so — and
returns `namespaces: ["team-alice", "team-bob"]` to any caller, credential or
not. Tenant *names*, never content, and the verifier was right to place it
outside AC-7, which is about read and write under a credential's scope.

It is still a real thing to decide, and it only became one when P4 made
multi-tenant use possible: under this goal's bar — colleagues inside one
company — knowing which teams exist is close to harmless, and on a
`recall-server` exposed more widely it is an enumeration surface. Recorded for
the retro rather than fixed here, because changing an endpoint's auth posture
to close a leak nobody has asked about is a product decision and not this
phase's.
