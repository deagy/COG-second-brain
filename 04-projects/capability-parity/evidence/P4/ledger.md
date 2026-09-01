# P4 — the enforcement claims, mutation-proven

Covers AC-5: every enforcement claim is exercised by a test that fails when its check is removed.

## The criterion's premise was slightly wrong

AC-5 said the two PARTIAL claims should each **gain** a mutation-proven test. They already had tests. The inventory marked them PARTIAL because the worker doing it had not exercised them — `import-staged`'s self-approval refusal was recorded from the tool's own `--help` text, and `ingest-accepted`'s stager/decider match rested on a passing case where the names did not match.

So what was missing was not coverage. It was **proof that the coverage would notice**.

## What was proven

Each call site neutered independently, because the documents claim these are separate checks and that `ingest-accepted` "does not assume the two earlier checks held". A shared predicate that everything routes through would make one test look like four.

| Mutation | Result |
|---|---|
| `StagedRecordIsSelfApproved` always returns false | **killed** — 4 tests, across both packages |
| `ingest-accepted`'s call site alone disabled | **killed** — `TestIngestRefusesASelfApprovedRecord` |
| `import-staged`'s call site alone disabled | **killed** — `TestAuthorizationCannotLaunderASelfApproval` |

The second and third are the ones that matter. Each path refuses on its own, and removing either is caught by a test naming that path — so the claim of independent checks is true rather than an artifact of one shared helper.

## Why this is recorded rather than assumed

The session that produced this trail found two tests of its own that passed for the wrong reason, both caught only by mutation. A test asserting a refusal can pass because a *different* refusal fired first; a test can pass because its setup fails before reaching the code under test. Neither is visible in a green run.

**A green test proves the test ran. Killing the thing it guards proves it was watching.**
