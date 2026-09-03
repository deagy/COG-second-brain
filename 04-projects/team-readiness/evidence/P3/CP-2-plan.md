# P3 — CP-2 plan

**Identity.** AC-6: the recorded actor is a verified subject, not a chosen
string. The first phase in this goal that changes shipped code, so it owes a
release before its criterion can be verified against an installed artifact.

## The defect, reproduced

One process, one keyboard, staged a record as one person and dispositioned it
as another. Both were accepted, and the observed actor was byte-identical on
each row:

```
staged_by   "alice@example.com"   observed_actor "os:deagy git:test@example.com"
decided_by  "bob@example.com"     observed_actor "os:deagy git:test@example.com"
→ accepted
```

Separation of duties is enforced by comparing two caller-supplied strings for
inequality. `roster/knowledge-store/SECURITY.md` says so in its own voice:
*"an actor that stages as one name and decides as another satisfies both"*, and
`observed_actor` is *"recorded on deletion, not consulted by any check"*.

That was correct under the previous goal's bar of one operator — *"with one
operator there is nobody to impersonate"* — and stops being correct with
colleagues.

## What already exists, and what does not

| | State |
|---|---|
| `recall-server`, released for six platforms | exists |
| `api.Authenticator` — `Authenticate(r) (subject string, ok bool)` | exists |
| `APIKeyAuth`, `ScopedAPIKeyAuth` (per-key namespaces), `JWTAuth` | exist, 37 tests |
| `recall/client` — a Go client, `client.New(cfg)` | exists |
| cadre's `internal/retrieval` opening a **local** `store.NewSQLiteStore` | this is the gap |
| cadre's `ObserveActor()` reading `os/user` + `git config` | this is the other gap |

So the work is wiring, not design. `Authenticate` already returns exactly the
thing the actor fields lack: a subject the caller did not choose.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Teach `internal/retrieval` to open a store through `recall/client` against a `recall-server` URL, keeping the local-file path as the default when no server is configured | AC-6 |
| T-02 | Carry the authenticated subject into `ObservedActor`, so a record written through a server names the subject the server authenticated rather than the local OS user | AC-6 |
| T-03 | Make the self-approval check consult the observed actor rather than comparing two asserted strings — refuse when the *same subject* stages and dispositions, whatever names they typed | AC-6 |
| T-04 | Refuse, or mark unverified, an asserted actor that disagrees with an authenticated subject — a caller may not quietly claim to be someone else | AC-6 |
| T-05 | A guard that fails if the self-approval check can be satisfied by two different strings from one subject — the exact sequence that succeeds today | AC-6 |
| T-06 | Release cadre, so AC-6 is verifiable against an installed artifact rather than a checkout | AC-6 |

Six tasks, so CP-4 is owed.

## What must not regress

**The local-file path stays the default and stays working.** A colleague who
has not set up a server must keep the behaviour they have. The criterion is
that identity is *verified when there is a server*, not that a server becomes
mandatory — making it mandatory would fail AC-1, which P1 just closed.

So the honest shape is two modes with different guarantees, and the tool saying
which it is in. A local store with no server has no authenticated subject and
cannot have one; what it must not do is present a caller-supplied name as
though something checked it.

## Where this is most likely to go wrong

**AC-6's weak reading is available and cheap.** `observed_actor` already exists
and is already written beside every asserted name. Writing it in more places,
or comparing two strings the caller supplied, would satisfy the sentence and
leave the defect. The criterion is met when *the value cannot be chosen by the
caller at the moment of the call* — which is true of a server-authenticated
subject and false of anything derived from the local machine, since a caller
who owns the machine owns every source of identity on it.

**T-05 is the task that decides whether this phase meant anything.** The guard
must fail against today's behaviour. If it passes before the fix, it is testing
something else.
