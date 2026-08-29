# P3 evidence ledger

## T-01 — pin plan validity, not only plan shape (cadre `984314fe`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-06 | CP-3 | PASS | `conformance-plan.json` is one complete plan as emitted. Two guards, both falsified: dropping `dispatch_fingerprint` fails the required-field check and the redundancy check; setting the captured version to 7 fails the staleness check. |

**Why it was needed.** cadre's golden corpus records each case's *canonical* plan, which strips `dispatch_fingerprint`, `generated_at` and `provenance` because a golden carrying them would change every run. Measured: the schema requires 18 fields, the canonical form carries 16 — and the two absent are required. A producer could reproduce all twenty-five golden cases exactly and still emit documents the schema rejects, with nothing in the corpus noticing.

## T-02 — gloop reads cadre's governed plan (gloop `bb1fd81`)

| AC | CP | Result | Observation |
|---|---|---|---|
| AC-06 | CP-3 | PASS | `pkg/govplan` parses the real conformance plan: task_id read, agents block mapped, disposition read as `staffed`. |
| AC-06 | CP-3 | PASS | A plan declaring an unsupported `schema_version` is refused with an error naming both numbers. A document with no `schema_version` is refused rather than guessed at. |
| AC-06 | CP-3 | PASS | The vendored fixture is held to cadre's copy by a guard that skips locally and fails under CI. Falsified: hand-editing the copy fails it, naming both paths. |
| — | CP-3 | PASS | gloop's full suite green. |

### The design decision inside T-02

gloop is a consumer of cadre's contract, not a second author of it. Two approaches were rejected explicitly, in the package's own doc comment so the next reader finds the reasoning rather than re-deriving it:

- **Vendor `selection.schema.json` and compile it.** That places an unguarded copy of someone else's contract in gloop — the failure that produced four defects in cadre.
- **Hand-write Go structs for all eighteen required fields.** The same problem wearing a different hat: a second representation, free to drift, of a document this repository does not define.

What it does instead: pin the version, refuse anything else, and read only the fields execution consumes. A plan carrying fields gloop ignores is fine — that is forward compatibility from the consuming side. A plan carrying a version gloop does not know is not, and fails naming both numbers, which is what cadre's versioning rule was written to produce.

**This preserves gloop's immunity to the drift class.** It still has no `*.schema.json` and no schema compiler; its Go types remain its own contract, for the subset it consumes.

`human_gates` and `required_quality_gates` are carried rather than dropped despite gloop having no equivalent concept. An executor that silently ignores a human gate is the failure the gate exists to prevent. What it should *do* about one is T-03's open question.
