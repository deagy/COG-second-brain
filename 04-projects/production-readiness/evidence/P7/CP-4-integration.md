## VERDICT: PASS
## CLAIMS_CHECKED: 5

## EVIDENCE
EVIDENCE AC-7 | CP-4 | PASS | Reproduced clean-machine install independently: `docker run --rm node:22-bookworm-slim` (aarch64), no ~/sdk, no Go, claude via npm only; ran documented `curl ... install.sh \| sh` unmodified, then both criterion commands. `cadre sdlc --version` -> `0.14.4`, exit 0. `cadre knowledge search` -> `query is required`, exit 2 (the passing shape per evidence/P5/ac7-clean-machine.log). Kernel resolved from cadre-kernel with no 404; the six deleted cadre releases are not on this path | /tmp/claude-1000/ac7-cp4-verify-out.log
EVIDENCE AC-2 | CP-4 | PASS | Re-derived fetch set from ~/sdk/cadre/internal/generators/plugin_generation.go at HEAD 5c40d6e: kernel from deagy/cadre-kernel/releases/download/v$VERSION (line 303), CLI archives from deagy/cadre/releases/download/cli-v$VERSION (lines 480-481). Both repos public/Apache-2.0 (gh repo view). Both a live kernel asset URL and a live cli-v0.7.5 asset URL resolve HTTP 200 through redirect | gh repo view, curl -sIL
EVIDENCE AC-6 | CP-4 | PASS | Commit distance re-measured against `gh release list`, not tags: cadre cli-v0.7.5..HEAD=0, plugin-v0.24.5..HEAD=0; cadre-kernel v0.14.4..HEAD=0; recall v0.3.3..HEAD=0; gloop zero releases, stated reason unchanged in README. The deleted kernel-v* releases were never cadre's AC-6 release line (cli-v*/plugin-v*), so the deletion does not touch this criterion | git log --oneline <tag>..HEAD in each of 4 repos
EVIDENCE AC-8 | CP-4 | PASS | Re-observed rather than trusted: `gh api repos/deagy/cadre/releases --paginate` returns 0 kernel-v* releases; kernel-v0.14.2 tag still resolves as a git ref (kept) but 404s via releases API and asset URL. Matches P7's own CP-5 claim, independently reproduced | gh api, git ls-remote --tags
FINDING | CP-4 | pre-existing, not a P7 regression | docs/lifecycle-and-plugin-operations.md:33 and its duplicate plugin/suite/docs/lifecycle-and-plugin-operations.md:35 still document `pipx install "git+https://github.com/deagy/cadre.git@kernel-v<version>#subdirectory=kernel"` — a live instruction fetching a kernel from the cadre repo rather than cadre-kernel. Unaffected by P7's release deletion (git+subdirectory clone uses the kept tag, not a Release), but the kernel/ directory it points into was already deleted from cadre at 11eefd47 (Aug 28), and the doc itself was last touched Aug 8 (#141) — both predate P7. The instruction is currently broken but the break is inherited, not introduced | ~/sdk/cadre/docs/lifecycle-and-plugin-operations.md, git log -- kernel/

## FAILURES
(none)

## FIX_HINTS
- docs/lifecycle-and-plugin-operations.md and its plugin/suite duplicate still point at the deleted in-repo kernel/ via a pipx git+subdirectory install; repoint both to cadre-kernel's own README/install instructions (out of P7's scope, predates it, but will keep surfacing on any future kernel-reference sweep)

## Acted on: the finding CP-4 flagged as "doesn't cost the verdict"

The verifier reported, as context rather than a failure, that
`docs/lifecycle-and-plugin-operations.md:33` and its `plugin/suite/` duplicate still
told a reader to
`pipx install "git+https://github.com/deagy/cadre.git@kernel-v<version>#subdirectory=kernel"`.

**It is in AC-8's scope, so it was fixed rather than listed.** The criterion says the
kernel has one release home. A live instruction telling a reader to obtain the kernel
from this repository *is* a second home, whatever the Releases API says — the API
answers where artifacts are served, and a document answers where a person goes.

Enumerated across all tracked files rather than fixing the two the report named, on
AI-16. Four distinct routes, nine documents:

| Route | Sites |
|---|---|
| `pipx install "git+…/cadre.git@kernel-v<version>#subdirectory=kernel"` | `docs/lifecycle-and-plugin-operations.md`, `plugin/suite/docs/` copy |
| `pipx install ./kernel` from this checkout | 3 `lifecycle-onboarding` skill copies, `.agents/` skill, both `RUNBOOK.md` copies |
| a wheel attached to a `kernel-v*` release | `docs/INSTALL.md`, `plugin/suite/docs/` copy |
| pin a reviewed `kernel-v*` tag, filtering this repository's releases | `README.md` quick start and its component/tag table |

All four are broken as well as misdirected: `kernel/` was deleted at `11eefd47`, the
kernel is a Go binary rather than a Python distribution, and every asset those
instructions reach for 404s.

**The three `lifecycle-onboarding` copies were corrected together**, which is the case
`internal/generators/plugin_duplication_health_test.go` was written for — its own
comment records a previous correction landing in `lifecycle-onboarding` alone while
both forge copies kept pointing at a repository that no longer existed. That guard
passes, as does the full suite.

Fixed in cadre `cd836b95`, pushed. Left alone deliberately: stale
`see kernel/README.md` cross-references, `in-tree kernel/` in `AGENTS.md`'s test
instructions, and historical run records. Those are broken links, not release homes,
and sweeping them is an audit this goal has no criterion for.

EVIDENCE AC-8 | CP-4 | PASS | No tracked file tells a reader to obtain the kernel from `deagy/cadre` by any of the four routes; the enumeration returns zero, counted rather than eyeballed. `go test ./internal/generators/` passes, including the three-copy duplication guard, and the full suite is green | cadre `cd836b95`
