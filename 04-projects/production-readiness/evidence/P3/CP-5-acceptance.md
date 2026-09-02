# P3 — CP-5 acceptance · AC-4

**EVIDENCE AC-4 | CP-5 | PASS** — every command taking an actor flag records what the process observed beside what the caller asserted, and neither can overwrite the other.

Four call sites, not four flags: `propose` beside `staged_by`, `disposition-staged` beside `decided_by`, `delete-staged` beside `deleted_by` and `authorized_by`, `import-staged` beside the `--authorized-by` it requires. Verified end to end on a fresh store, a hand-built pre-change store, and a pre-file-split legacy store, with `USER` and `LOGNAME` spoofed. Artifact: `CP-3v-round4.md`, cadre `4da28060`, CI run 33643385856.

**EVIDENCE — | CP-4 | PASS** — 15 claims. The dependency direction `internal/knowledge` → `internal/platform` is sound and non-cyclic against the repository's own boundary tests; the generated mirrors are idempotent and match; every read path surfaces the column; nothing P3 did touches what P1 or P2 depend on.

## What "derived" turned out to mean

Nothing on a single-operator machine is unforgeable — `git config` is a file the caller owns, `$USER` a variable they set. So the target was never an identity that cannot be faked. It was **a record that cannot present an assertion as an observation**:

```
deleted_by (asserted): claimed-name
observed_actor       : os:deagy git:daniel.eagy@sqs.world
```

The OS user comes from `os/user.Current()` — process credentials, not the environment. Git identity is recorded as context rather than proof. Every rendering carries its source so it cannot be read as a name.

## Four rounds, three failures, one root cause

| Round | Found |
|---|---|
| 1 | Only the deletion path. I had covered *flags*, and the criterion is about call sites |
| 2 | `DEFAULT ''` does not retrofit onto an existing table — **every pre-change store broke**, and CI was green because every test builds a fresh one |
| 3 | `MigrateStagedRecords`'s `SELECT *` broke against an older schema and then **silently stranded the data** |
| 4 | PASS, after enumerating every consumer of the four tables in one pass |

**The root cause is one thing: I under-estimated the blast radius of adding a column, three times.** Rounds 1–3 each fixed what the report named; round 4 passed because the method changed to enumerating outward from the change itself.

That method already existed in the backlog as `AI-16` — *enumerate by concept before editing* — and I had been applying it only to prose. A schema change is the same shape, and the concept is "everything that reads this table's shape." Enumerating that first would have found all three at once.

## Two near-misses worth recording

**I nearly contradicted a correct finding.** Reproducing round 3's defect, I called `MigrateStagedRecords` directly and saw it error on both runs — which would have refuted the "silently strands" claim. My repro bypassed the caller's migrate-only-if-absent guard: I was testing the function, the verifier was testing the path. Second time this session a self-written test almost overruled a true report.

**Round 2's defect and round 3's shared a cause the tests could not see.** The existing legacy-migration test builds its "old" store *from the current schema constant*, so it can never disagree with the code. It passed through both defects. The new tests hardcode their fixtures — a migration test whose old world is defined by the new world is testing nothing.

## The third attempt was authorised, not self-authorised

`AI-18` caps fixes at two before the decision becomes the user's. That budget was spent at round 3, the situation was put to them with the data-stranding risk stated, and they authorised the fix. Recorded because the rule's value is precisely that it is not the worker's to waive.

## What this does not do

It does not close the separation-of-duties gap. Two of the four checks still compare caller-asserted strings, now recorded beside an observation — strictly better evidence, identical enforcement. `SECURITY.md` says so explicitly rather than letting the change read as larger than it is.
