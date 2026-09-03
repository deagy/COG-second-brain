# P5 — CP-2 plan

**Deletion of ingested content, with evidence.** AC-8, the last criterion.
Changes shipped code, so it owes a release.

## The gap, in the system's own words

`roster/knowledge-store/SECURITY.md` states it plainly: `cadre knowledge
ingest`, `retention-report`, `delete-ingested` and `deletion-evidence` *"were
real, tested commands in the Python CLI and were removed in `b418031e`… None
was rebuilt."* Confirmed by running them — each refuses and names the gap:

```
$ cadre knowledge delete-ingested
deleting ingested content ... is not a capability this binary has
$ cadre knowledge retention-report
per-message retention windows were a Python-era capability; this binary records none
```

So today: nothing records a retention window at ingest, nothing ages out, and
no shipped command removes ingested content. Only *staged* records — proposals
not yet ingested — can be deleted, and that path is sound and evidence-tracked.

**Why this is in scope for a team and was not for one operator.** The previous
goal's charter said *"no third party's content enters the store"*. A
colleague's notes are a third party's content relative to the person who
ingests them, and the person who wrote something is the person who can ask for
it back.

## What exists to build on

`SECURITY.md` says recall's Go API *"deletes by document or chunk id"*, and
`store.SQLiteStore` has `DeleteDocument` and `DeleteChunk`. So the capability
exists as a library call and is absent from every shipped CLI — which is the
distinction that matters: *"technically yes, by someone willing to write Go,
and no for anyone using the tools."*

The evidence pattern also exists and is proven: `staged_record_deletions`
carries `deleted_by`, `observed_actor`, `reason` and a timestamp, with no
foreign key to the record it describes, deliberately, so the evidence outlives
its subject.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | `cadre knowledge delete-ingested` — remove ingested content by document id, through recall's delete API | AC-8 |
| T-02 | Deletion evidence for ingested content, following the staged pattern: no foreign key, so it survives what it describes | AC-8 |
| T-03 | `cadre knowledge deletion-evidence` — read that evidence back | AC-8 |
| T-04 | A guard that runs the whole cycle: ingest, confirm searchable, delete, confirm absent, read the evidence | AC-8 |
| T-05 | A guard that the evidence survives deletion of its subject — the property the missing foreign key exists for | AC-8 |
| T-06 | Release cadre, so AC-8 is verifiable against an installed artifact | AC-8 |

Six tasks, so CP-4 is owed.

## Deliberately out of scope, and why

**Retention windows are not in this phase.** The bar chosen at charter was
colleagues, not customer data: *"deletion on request is in scope because a
colleague's notes are a third party's content… but retention windows driven by
a legal obligation, and any policy review, are not."* Building an expiry
mechanism nobody has a policy for would be inventing a requirement, and
`retention-report`'s refusal already names its own absence honestly.

That leaves `retention-report` refusing after this phase, which is correct
rather than incomplete: the criterion is that content *can be deleted on
request*, not that it ages out on a schedule.

## Where this is most likely to go wrong

**T-04's weak reading is "delete returned nil".** A delete that reports success
and leaves the content searchable is the exact shape this project keeps
finding. The guard must search *after* deleting and get nothing, and must
confirm the content was findable beforehand — otherwise "not found" is
satisfied by a store that never had it.

**The actor on a deletion record is the AC-6 problem again.** A deletion
naming an unverified `--deleted-by` is a record of a string, and P3 established
when that is worth anything. This phase should record the same
`actor_verification` distinction rather than inventing a second answer to a
question already settled.
