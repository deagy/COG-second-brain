# CP-6 — ship

What this goal published, and what was observed after publishing it rather than
inferred from the call that published it.

## The artifacts

| Repository | Release | Assets | Draft |
|---|---|---|---|
| `deagy/cadre` | `cli-v0.7.12` | 14, including a checksum file and an SBOM | no |
| `deagy/recall` | `v0.3.6` | 13, including `checksums-sha256.txt` | no |
| `deagy/cadre-kernel` | `v0.14.4` | 6, including `SHA256SUMS` | no |

Seven cadre releases and three recall releases were cut over this goal, each
before the criteria that depended on it were checked, per the charter: verifying
an installed-artifact criterion from a checkout is the position this goal exists
to leave.

## Post-conditions, fetched as an outsider

EVIDENCE AC-3 | CP-6 | PASS | All three repositories are `PUBLIC` and each carries a non-empty GitHub description | `gh repo view --json visibility,description`
EVIDENCE AC-3 | CP-6 | PASS | Each front page was fetched through `gh api repos/<r>/readme` — the rendered page an outsider sees, not the file in a checkout — and each links `docs/the-three-repositories.md` | 442, 99 and 1087 lines respectively
EVIDENCE AC-1 | CP-6 | PASS | Every release is published rather than draft, and each carries the checksum file its documentation tells a reader to verify against | `gh release view --json assets,isDraft`
EVIDENCE AC-1 | CP-6 | PASS | The released `cli-v0.7.12` binary was downloaded, checksum-verified against the release's own `SHA256SUMS`, and run: `cadre 0.7.12` | CP-4 cold-path re-check

## The tag that should not exist

`cli-v0.7.10` was created by hand before checking how this repository
releases. cadre's Release workflow tags and publishes *itself* when a version
bump lands on `main`, and skips any version already tagged — so a hand-made tag
does not trigger a release and prevents the one that would have happened.

It is therefore a tag with no release behind it, which is exactly what
`release-hygiene.sh` refuses, and the check is right to refuse it. Deleting a
remote tag is a human-approval action and is blocked here, so it is recorded as
an open item for the operator rather than quietly excepted. **An exception list
entry would have hidden my own mistake behind a stated reason**, which is the
failure mode that script's header warns about.

The release went out as `0.7.11` and then `0.7.12` instead, so nothing was
blocked by it.
