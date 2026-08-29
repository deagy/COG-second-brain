# P1 / T-01 — build record: freeze the fingerprint agreement

Commit `1f0d226b` on `feat/freeze-fingerprint-agreement-fixture`, cadre.

## What was built

`internal/canonicaljson/testdata/fingerprint-agreement.json` holds the plan, a variant differing only in the three excluded keys (`generated_at`, `dispatch_fingerprint`, `provenance`), and the single fingerprint both implementations produce for both:

```
sha256:924ca52daf6ca36e23b7b9fd6345361b517baae02883a7ea5c0d16d103ef7f6f
```

Two tests:

- `TestTheCommittedFixtureMatchesBothImplementations` regenerates the fixture from live code and fails when the committed copy differs. It refuses to freeze anything if the two sides disagree, or if changing only the excluded keys moves a fingerprint. Imports both implementations, so it does not survive the split — it is the generator, and it only has to work while both are in the room.
- `TestTheSelectorMatchesTheFrozenFingerprint` imports only `internal/selector`. This is the half that survives; the kernel repository takes its mirror with `kernel.DispatchFingerprint` substituted.

## Falsification, observed

Dropped `provenance` from `internal/selector/canonical.go`'s `FingerprintExcludedKeys` and re-ran. The single-sided test — the one that must work without seeing the kernel — failed on both plans:

```
--- FAIL: TestTheSelectorMatchesTheFrozenFingerprint
    plan: selector computed sha256:999749fac672d6a3ca11f4583c7d49ed0471b78aaab6f443da71f091cabe66dc,
          fixture froze  sha256:924ca52daf6ca36e23b7b9fd6345361b517baae02883a7ea5c0d16d103ef7f6f
    plan_with_excluded_keys_changed: selector computed sha256:cc657d66a6fb2641032efb5cb694b97b2e37d50d6fb2a0157349a815494326dc,
          fixture froze  sha256:924ca52daf6ca36e23b7b9fd6345361b517baae02883a7ea5c0d16d103ef7f6f
```

The mutation was reverted and the suite returned green. This is the property the split depends on: a side that changes its exclusion set fails at home, against the frozen contract, without needing the other implementation.

## Open

Where the fixture physically lives after the split is still undecided (spec risk, and an open question in the extraction plan). Today it sits at `internal/canonicaljson/testdata/`; the likely answer is that it travels with the contracts under T-03's drift check, so both repositories read bytes that are provably the same rather than two copies that happen to agree.

## Status

Awaiting CP-3v. No PASS row is recorded here — the verifier's rows go in `ledger.md`.
