## VERDICT: COMPLETE
## CRITERIA_CHECKED: 9
## NORTH-STAR CLAIM: FALSE (narrowly) — <one paragraph below>

The sentence is true for three of its four named subjects and false, by the
project's own documented decision, for the fourth. cadre, the lifecycle
kernel, and recall each install from their own published GitHub Releases —
independently reproduced live (cadre+kernel, via a genuine clean-machine
Docker install; recall, via its release asset list carrying platform
binaries: `recall-0.3.3-linux-arm64` etc). gloop does not: its README states
in its own voice, "There is no release workflow here and no published
release for any tag... The one consumer builds from a checkout," and its
Installation section instructs `git clone` + `make install`, explicitly
rejecting `go install .../gloop@latest` because the module proxy 404s on a
private repo. That is the *honest* fix AC-3 required — gloop stopped
claiming public installability it never had — but it means gloop is
installed from a checkout, not a published artifact, and none of the nine
acceptance criteria requires otherwise: AC-6 accepts "a stated reason" in
place of a release and gloop's stated reason is "no release, by decision";
AC-7 exercises only cadre and the kernel's clean-machine path. The goal's own
charter narrows "honest" and "attributable" for gloop with explicit
reasoning ("The bar this goal is written to") but never narrows
"installable" for it in the same way — so the north-star sentence, read
literally against its own four subjects, oversells gloop's status relative
to the other three even though every criterion built to test it passes.

## MACHINE POSITION

Checks made from a working checkout (this developer machine, `~/sdk/*`):
AC-1, AC-2, AC-3, AC-3b, AC-4, AC-5, AC-6, AC-8, plus all five harness lint
gates and `ci-status.sh`. For AC-4 and AC-5 I did not stop at reading the
evidence trail — I built the `cadre` binary from HEAD myself
(`CGO_ENABLED=1 go build -tags sqlite_fts5`) and ran the actual refusal
commands and read `internal/platform/identity.go` directly to confirm the
derivation source is `os/user.Current()`, not `$USER`/`$LOGNAME`. For AC-8's
`#249` clause I copied the repo to a scratch tree
(`/tmp/claude-1000/verify-cadre`, not `~/sdk`), disabled the home-bound guard
by mutation, and watched `TestTheProjectWalkStopsBelowHome` fail exactly as
claimed while the sibling test kept passing — a genuine falsification, not a
re-read of the evidence file.

**AC-7 was run for real, not read.** `docker run --rm --platform linux/arm64
node:22-bookworm-slim`, no `~/sdk`, no Go, `claude` installed via `npm
install -g @anthropic-ai/claude-code` only (curl/git/ca-certificates
bootstrapped via apt, matching what a bare `node:22-bookworm-slim` needs
before it can even fetch the installer). Ran the documented one-liner
unmodified (`curl -fsSL .../install.sh | sh -s -- --with-lifecycle`), then
both criterion commands. This is a fresh container run independent of P5's
and P7's own logs, not a re-execution of their transcripts.

The releases claim for AC-8 was checked against the **releases API**, not a
rendered tag page: `gh api repos/deagy/cadre/releases --paginate` (all ~60
releases enumerated, zero `kernel-v*` among them) and
`repos/deagy/cadre/releases/tags/kernel-v0.14.2` → 404. I did not rely on
`curl -sI` against `releases/tag/kernel-v0.14.2`, which the P7 evidence
itself flags as the previous gate's mistake (a bare git tag still renders a
200 HTML page with zero `releases/download/` links on it).

## EVIDENCE
EVIDENCE AC-1 | CP-3v | PASS | GitHub-reported licence matches every README/doc claim for all four: cadre Apache-2.0 (claims match), cadre-kernel Apache-2.0 with a `LICENSE` file present and no root README to make a false claim (only `kernel/README.md`, which makes no licence claim), recall MIT (claims match), gloop `license:null`/private with its README explicitly stating "carries no licence" and the prior MIT/badge claims recorded as removed | `gh api repos/deagy/{cadre,cadre-kernel,recall,gloop}`, `grep` on each README
EVIDENCE AC-2 | CP-3v | PASS | Re-derived cadre's generated-installer fetch set from `internal/generators/plugin_generation.go` at current HEAD myself: only `github.com/deagy/cadre-kernel/releases/download/v$VERSION` (kernel) and `github.com/deagy/cadre/releases/download/cli-v$VERSION` (CLI). Both repos public and licensed (Apache-2.0 each, confirmed above). No `recall` or `gloop` URL anywhere in the generator | `grep -n "releases/download" internal/generators/plugin_generation.go`
EVIDENCE AC-3 | CP-3v | PASS | No public-indexing badge in gloop's README; `pkg.go.dev/github.com/deagy/gloop` independently curled → HTTP 404; README states plainly it is "private and internal," carries no licence, and records the prior MIT/badge claims as retracted, not repaired | `curl -sI https://pkg.go.dev/github.com/deagy/gloop`, `grep` on gloop README
EVIDENCE AC-3b | CP-3v | PASS | Spot-verified three of the 22 fixed claims independently: `go build -tags integration ./pkg/roster/...` now compiles (was broken per P6's finding); no stray `gloop` binary sits in the package root (`ls` on `~/sdk/gloop` shows only source dirs, matching the "16MB binary" fix); README's routing language now attributes selection to cadre rather than claiming gloop itself selects/routes. Full 22-claim audit not re-run in full — bounded by time, the nine-round CP-3v/CP-4 trail with a user-resolved escalation and a mutation-caught silently-deleted guard is unusually deep already | `go build -tags integration`, `ls ~/sdk/gloop`, `grep` on README
EVIDENCE AC-4 | CP-3v | PASS | Built cadre from HEAD and read `internal/platform/identity.go` directly: `ObserveActor()` calls `user.Current()` (process credentials) for `OSUser`, never reads `$USER`/`$LOGNAME` — the exact weak reading the spec calls out by name. No field on `ObservedActor` is settable by a flag; the type's own doc comment states this. `observed_actor` is a separate DB column from the caller-asserted `staged_by` in frontmatter, confirmed in `internal/knowledge/staged_store.go`'s schema comment | `go build`, direct read of `internal/platform/identity.go`, `internal/knowledge/staged_store.go`
EVIDENCE AC-5 | CP-3v | PASS | Ran the built binary directly, not the evidence log: `cadre knowledge search --retention-days 30` → refuses by name (exit 2, names `b418031e`, names where content lives now, names the open decision). `cadre knowledge retention-report --as-of ...`, `delete-ingested --trigger ...`, `deletion-evidence` all refuse identically. `delete-staged --id X --reason "--retention-days" --deleted-by t` does **not** falsely refuse — it proceeds to the real "no staged record with that id" error, confirming the value/flag distinction the P4 evidence claims | direct binary execution, all four commands and exit codes reproduced
EVIDENCE AC-6 | CP-3v | PASS | `git log <tag>..HEAD` per repo: cadre `cli-v0.7.5..HEAD` = 3 commits, `plugin-v0.24.5..HEAD` = 0; cadre-kernel `v0.14.4..HEAD` = 0; recall `v0.3.3..HEAD` = 0; gloop 0 releases, README states the reason. cadre's 3 post-release commits (`cd836b95`, `4697eb68`, `bffec5cc`) are a doc-only diff — `git diff --stat cli-v0.7.5..HEAD` touches only `.md` files and generated skill mirrors, zero `.go` files, matching the "stated reason" of documentation/generated-content fixes | `git log --oneline <tag>..HEAD` × 4, `git diff --stat`
EVIDENCE AC-7 | CP-3v | PASS | Fresh `docker run --rm --platform linux/arm64 node:22-bookworm-slim` (aarch64), no `~/sdk`, no Go, `claude` via `npm install -g @anthropic-ai/claude-code` only. `curl -fsSL .../install.sh \| sh -s -- --with-lifecycle` — installed cadre, kernel resolved 0.14.4 with no 404. `cadre sdlc --version` → `0.14.4`, exit 0. `cadre knowledge search` → `query is required`, exit 2. `cadre doctor` confirms the running binary is the freshly-fetched `cadre-v0.7.5-linux-arm64` and the kernel came from the packaged plugin, not a stale path | this session's own container run, not P5/P7's logs
EVIDENCE AC-8 | CP-5v | PASS | Three independent checks, one per clause. (1) Issue body: `gh api repos/deagy/cadre/issues/249` re-fetched fresh — body opens `> **Corrected 2026-09-02.**...the Python implementation, which no longer exists`, 6,490 bytes, `updated_at: 2026-09-02T19:35:17Z`, matching the spec's traceability citation exactly. (2) Test genuinely detects the bug: mutated `internal/platform/paths.go` in a scratch copy (`if false &&` on the home-bound guard) and re-ran `go test ./internal/platform/...` — `TestTheProjectWalkStopsBelowHome` FAILs with the exact message the source predicts; `TestAProjectLocalFileBelowHomeIsStillFound` still PASSes, showing the fix isn't over-broad. (3) One release home: `gh api repos/deagy/cadre/releases --paginate` returns zero `kernel-v*` tags among ~60 releases; `releases/tags/kernel-v0.14.2` → 404 via the releases API (the authority, not the rendered tag page, which still 200s on a bare kept git tag — checked and dismissed for the same reason P7's own evidence dismisses it: 0 `releases/download/` links in that page's body). `cadre-kernel`'s `v0.14.4` asset resolves 200. Doc-fix clause (found by CP-4, fixed in scope): searched cadre HEAD for the four broken install routes CP-4 enumerated (pipx git+subdirectory, pipx ./kernel, kernel-v* wheel, kernel-v* tag pin) — zero live hits; remaining `kernel-v` mentions in cadre are explicitly historical ("kernel-v* is history", SECURITY.md's past-tense description) | fresh `gh api` fetch, scratch-tree mutation test, `git grep` on cadre HEAD
EVIDENCE — | GATE | PASS | `spec-lint.sh`, `evidence-lint.sh`, `citation-lint.sh` (31 commit citations, 43 vault paths, all resolve), `phase-gates.sh` (P1–P7 all recorded), `backlog-lint.sh` all exit 0, run directly in this session | `.claude/lib/*.sh` output above
EVIDENCE — | GATE | PASS | CI green at HEAD for all four by exact run id: cadre `bffec5cc` run 33676558157, cadre-kernel `d4fb0894` run 33652192373, recall `3bef2354` run 33651612476, gloop `1f37de47` run 33672766023 — resolved by `ci-status.sh`, cross-checked against each repo's own `git log -1` HEAD sha | `bash .claude/lib/ci-status.sh ~/sdk/{cadre,cadre-kernel,recall,gloop}`
EVIDENCE — | GATE | PASS | `spec.md`'s only AC-definition change across its full history (`git log -p --follow`) is the P1→P6 split of AC-3 into a narrower AC-3 (licensing/visibility/removed-commands) plus AC-3b (every other doc claim, deferred not dropped). Combined scope after the split equals or exceeds the original wording, and AC-3b was later closed with a 22-false-claim, nine-round audit — not a relaxation to make the goal satisfiable. No other AC's criterion text changed, only status/traceability columns | `git log -p --follow -- 04-projects/production-readiness/spec.md`

## OPEN
(none)

## NOTES

**The gloop gap above is the main finding of this gate and is not covered by
any AC.** It is not a defect in the sense the goal's other findings were —
the project's own charter reasoning ("gloop's public/internal question is
P1's to settle on evidence... nothing imports it today") is sound, and
publishing a release nobody consumes would itself be a form of the dishonesty
this goal exists to remove. But the north-star sentence names gloop
alongside three subjects that genuinely do install from published artifacts,
without the same explicit carve-out the spec gives licensing ("A private
repo with no licence and no claim is not [a defect]"). Fixing the sentence
rather than gloop is the smaller, honest move: e.g. "cadre, the lifecycle
kernel and recall install from their own published artifacts; gloop, by
decision, installs from a checkout" — or scope the goal to say so explicitly
in "The bar this goal is written to."

**A known, accepted cost from P7 worth carrying forward.** `cli-v0.5.0`
through `cli-v0.6.5`'s generated installers still point their kernel fetch at
`github.com/deagy/cadre/releases/download/kernel-v$VERSION`, which now 404s
since those six releases were deleted. This was put to the user at CP-6 and
accepted deliberately (bar = one operator on HEAD, `cli-v0.7.5` is current),
but it means anyone who still has an old `cli-v0.5.0`–`v0.6.5` installer
script cached will get a broken kernel fetch. Not an AC-8 gap — AC-8 is about
HEAD's release home — but worth stating plainly since it's a real behavior
change the goal's own evidence already disclosed.

**`~/sdk/cadre-kernel/kernel/README.md` still documents Python in its lower
half**, independently confirmed: it opens with a correct warning that the
kernel is a Go binary now, but lines 44, 51, 176, 383 and 421 still instruct
`python3 -m agentic_sdlc`, name `kernel/agentic_sdlc/` as the entry point,
and tell a reader to `python3 -m pip install -r
kernel/requirements-validation.txt` — none of which exist (zero `.py` files
in the repository, confirmed by `find`). STATUS.md already records this as
"found, deliberately not fixed — no criterion covers it," and that
self-assessment holds up: no AC in this spec reaches `cadre-kernel`'s own
documentation (AC-3/AC-3b are scoped to gloop). It is a real, live falsehood
in a public Apache-2.0 repository's landing document, outside this goal's
traceability matrix entirely.

**Harness self-check.** All five lint gates and the CI-status script were
run directly by this gate, not read from a prior report. `ultragoals.md`'s
registry row for this goal still reads "in progress — gate re-run pending on
cadre CI," which is stale relative to STATUS.md's latest edit (made
concurrently with this gate's own run — the file changed under me mid-session
and I re-read it rather than trusting the earlier version). That staleness is
cosmetic, not a criterion gap, and is the orchestrating session's to update.

---

## Orchestrator's record of what happened after this gate

**VERDICT COMPLETE, nine of nine, none open — and the north-star sentence judged
false.** Both were acted on.

The sentence was amended to name gloop's exception, and the amendment's reasoning is
in `spec.md` § *The north-star was amended at its own gate*. It was put to the user
as a decision rather than taken by the session that wrote the evidence, because the
north-star is theirs, and because a worker rewriting the sentence it is judged by is
the exact failure the harness has a rule against.

The two unscoped findings this gate names are recorded and not fixed:

- **Old installers 404 on the kernel fetch.** `cli-v0.5.0`–`cli-v0.6.5` point at the
  deleted `kernel-v*` releases. Put to the user at P7's CP-6 with those eight releases
  named, and accepted deliberately on the charter's bar of one operator running HEAD.
- **`cadre-kernel/kernel/README.md` still documents Python below its own correct
  warning** — lines 44, 51, 176, 383, 421 instruct `python3 -m agentic_sdlc` and
  `pip install -r kernel/requirements-validation.txt` in a repository with zero `.py`
  files. AC-3b's shape applied to a repository AC-3b does not cover. Recorded in
  `STATUS.md` § *Found, and deliberately not fixed*, and worth its own small goal:
  `cadre-kernel` is public, Apache-2.0, and this is the file someone lands on.

The gate's note about `ultragoals.md` being stale was correct at the moment it read
the file, and is resolved by the same commit that files this report.

**This gate found, in its first run, a criterion that had carried a PASS row for six
phases while two of its three clauses were false.** That is the argument for the
north-star gate existing at all: every check between P2 and here was scoped to its
own phase, and a phase cannot see what it already believes it verified.
