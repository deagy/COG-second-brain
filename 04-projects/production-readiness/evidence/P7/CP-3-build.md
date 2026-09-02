# P7 — CP-3 build

## T-01 — the `#249` body

Fetched the body (`gh api repos/deagy/cadre/issues/249 --jq .body`, saved at
`/tmp/claude-1000/249-body-orig.md`, 4,471 bytes) and read it. It describes, as
current behaviour: `find_project_local_config`, `MAXIMUM_WALK_DEPTH = 64`,
`roster/knowledge-store/src/config.py:91`, `roster/context-store/src/config.py:99`,
a `python3 -c` reproduction, and four `_enforce_*_scope` functions keyed on
`tier == TIER_GLOBAL_FALLBACK`. All were deleted by `b418031e`, the day after filing.

The correction is a banner prepended to the body, followed by the original report
kept verbatim under the heading *The report as filed (2026-08-07, against the Python
implementation)*. The banner states four things, each of which the closing comment
had established and the body contradicted:

- the named Python is deleted, and the body describes code as it stood on 2026-08-07;
- the defect is real, was reproduced against the Go binary, and is fixed in `998ad425`,
  pinned by two falsified tests in `internal/platform/paths_test.go`;
- **"Why it matters" does not apply to the Go implementation and should not be acted
  on** — the scope-gate bypass it argues depended on Python gates keyed to
  `tier == TIER_GLOBAL_FALLBACK`, and the Go gate is unconditional at every tier;
- the stated cause is slightly wrong (candidate-before-`.git` is the correct walk
  order; the defect is that the `.git` boundary only exists when a project root does),
  and the fix that shipped is not the Option 2 the body leans to.

The original text is kept rather than rewritten. A bug report is a record of what
someone observed, and editing the observation away would make the issue agree with
the present at the cost of being evidence of anything.

Body after the edit: 6,490 bytes, `updated_at` `2026-09-02T19:35:17Z`.

## T-02 — the kernel's second release home

Six releases deleted from `deagy/cadre` with `gh release delete <tag> --yes`, the
git tags deliberately kept (no `--cleanup-tag`). Recorded before deletion in
`deleted-kernel-releases.tsv`, because a deleted release leaves nothing behind to
enumerate afterwards:

| Tag | Assets | Downloads |
|---|---|---|
| `kernel-v0.14.2` | 6 (Go binaries, 5 platforms + SHA256SUMS) | 4 |
| `kernel-v0.14.1` | 6 | 4 |
| `kernel-v0.13.3` | 4 (Python wheel, sdist, SBOM, SHA256SUMS) | 6 |
| `kernel-v0.13.2` | 4 | 19 |
| `kernel-v0.13.1` | 4 | 9 |
| `kernel-v0.13.0` | 3 | 5 |

**The tags stay and the releases go, which is the distinction the criterion turns on.**
A tag is a pointer into this repository's own history and costs nothing to keep. A
release is a place the software can be fetched from, and the criterion is about how
many of those the kernel has.
