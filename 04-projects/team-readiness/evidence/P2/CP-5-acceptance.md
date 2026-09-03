# P2 — CP-5 acceptance (AC-4, AC-5)

EVIDENCE AC-4 | CP-5 | PASS | `docs/the-three-repositories.md` exists, is linked from all three repositories' front pages as fetched by `gh api repos/<r>/readme`, and a fresh verifier reading only that page could state back what each tool is for, how they connect, and the adoption order | CP-3v rounds 1–4
EVIDENCE AC-4 | CP-5 | PASS | The page's structural claims verified against code, not against another document: cadre imports `github.com/deagy/recall` as a Go module and builds on `recall/govern`; the kernel is reached by exec from four named sites; the boundary is enforced by cadre-kernel being a separate module absent from `go.mod`, so cadre cannot import it | CP-3v rounds 2–3
EVIDENCE AC-4 | CP-5 | PASS | The glossary checked term by term against the code and the kernel contract rather than against prose: `roster`, `catalog`, `routing`, `dispatch plan`, `gate`, the ten G-names read from `lifecycle-gates.json`, `provider` against the provider bundle's file list, `overlay` against `const Overlay = ".agentic-sdlc"`, `human gate` against G9's `human_only: true`. All ten hold | CP-4
EVIDENCE AC-5 | CP-5 | PASS | `TestNoOperationalDocPointsAtAPathThatIsGone` passes over 291 live documents, its set discovered from `git ls-files` minus generated trees and records rather than curated — so a document added after the guard is in scope automatically | CP-4
EVIDENCE AC-5 | CP-5 | PASS | All 13 fenced Go blocks in recall's README compile against the real source — 5 as full files, 8 as minimally wrapped fragments — verified twice including after a cache clean | CP-3v round 4
EVIDENCE AC-5 | CP-5 | PASS | The package-README count agrees between `README.md` and `ROADMAP.md` and matches an independent count: 33 of 36, the exceptions being `govern/`, `example/e2e/` and `example/production/` | CP-3v round 4

## Where AC-5 nearly closed on a false claim

The overview page asserted that a test fails if any document still places the
kernel in this repository. CP-4 found that false in both halves: `terminology.md`
still claimed it, in prose and in a mermaid label, and the guard's regexes —
backticked paths and markdown links — could not see either syntax.

Fixed by making the claim true rather than softening it: the guard reads bare
directory tokens as well, anchored so `internal/kernel/` and a reader's own
environment paths do not match. It then found a third instance, in `CLAUDE.md`,
instructing contributors to test packages this repository no longer has.

**A guard built from one syntax cannot see a claim written in another.**
Backticked path, markdown link, mermaid label and plain prose are four ways to
say the same false thing; two were covered.
