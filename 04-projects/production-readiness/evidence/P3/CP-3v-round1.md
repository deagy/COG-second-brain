# AC-4 Verification Report — production-readiness P3

Artifacts: `/home/deagy/sdk/cadre` at `b174bfea` (CI run 33637679330 claimed green).
Build record: `/home/deagy/cog-second-brain/04-projects/production-readiness/evidence/P3/CP-3-build.md`.

## Verdict

**FAIL:fixable**

## Scope question — answered

AC-4 names four flags: `--staged-by`, `--decided-by`, `--deleted-by`, `--authorized-by`. The build covers only
the deletion path (`--deleted-by`, `--authorized-by` on `delete-staged`). **This does not satisfy AC-4 as
written.** AC-4's primary sentence gives exactly two options per command: derive the value from a verifiable
source, or refuse to run. The clarifying gloss adds a second phrasing — "the value cannot be chosen by the
caller at the moment of the call, or the command says plainly that it was" — but "the command says plainly"
cannot be read as satisfied by a separate document (`SECURITY.md`) that the caller never sees at the point of
the call. The same acceptance-criteria table settles this by contrast: **AC-5, one row below AC-4, explicitly
requires disclosure "at the point of use... not only in `SECURITY.md`."** The spec author is demonstrably aware
of the difference between runtime disclosure and documentation-only disclosure, and drew that line deliberately
for a neighboring criterion. Reading AC-4's looser gloss as silently exempting `SECURITY.md`-only disclosure
would make AC-5's explicit carve-out redundant.

Checked directly: `cadre knowledge propose --from-finding ...` and `cadre knowledge disposition-staged ...`
give zero runtime signal — no flag help text, no output field, no note — that `staged_by`/`decided_by` are
caller-asserted and unverified (evidence rows below). Only `SECURITY.md` says so, in prose describing the
whole knowledge-store's limitations. `--deleted-by`/`--authorized-by`, by contrast, get both: a runtime signal
(the `observed_actor` field sits beside them in every command output and evidence row, visibly distinct) *and*
the derivation the primary sentence asks for. That is not "documentation happens to mention it" — it is the
command's own output making the asserted/observed split visible at the moment of the call, which is what AC-4
is actually after.

**Conclusion: the deletion path (`--deleted-by`, `--authorized-by`) meets AC-4 on its own merits, verified by
falsification below. `--staged-by` and `--decided-by` do not meet it — no derivation, no refusal, and no
runtime disclosure, only a security document nobody reading `--help` or the command's JSON output would see.**
This is the builder's own flagged scope question, and the answer is: AC-4 requires the other two paths, or at
minimum a runtime-visible disclosure on `propose`/`disposition-staged` equivalent to what AC-5 demands of the
retention refusal. The gap is bounded — see FIX_HINTS — not a design overhaul, so this is FAIL:fixable rather
than FAIL:escalate.

## Evidence

EVIDENCE AC-4 | CP-3v | PASS | Deletion path: `cadre knowledge delete-staged -deleted-by "Definitely Not A Real Person <fake@nowhere.example>"` produced evidence row with `deleted_by` = that false string and `observed_actor` = `"os:deagy git:daniel.eagy@sqs.world"` — distinct, both present. Command: scratch run at `/tmp/v4-scratch`, output captured in session transcript.
EVIDENCE AC-4 | CP-3v | PASS | Environment is not the source: rerun with `env -i USER=someone-else LOGNAME=someone-else` still produced `observed_actor = "os:deagy git:daniel.eagy@sqs.world"`, unchanged. `internal/platform/identity.go:84-86` confirmed: `user.Current()` (syscall against process credentials), not `os.Getenv("USER")`.
EVIDENCE AC-4 | CP-3v | PASS | Falsification 1 (observed user falls back to `$USER`): mutated `/tmp/v4-clone` (clone of real repo at `b174bfea`) to read `os.Getenv("USER")` first. `go test ./internal/platform/... -run TestTheObservedUserIgnoresTheEnvironment` failed with message naming exactly this defect. Clone discarded; real repo untouched (`git status --short` clean at `b174bfea`).
EVIDENCE AC-4 | CP-3v | PASS | Falsification 2 (observation echoes assertion): mutated `internal/knowledge/staged_store.go:749` to `observed := input.DeletedBy` (kept `platform.ObserveActor()` called-but-discarded to preserve the build, matching the build record's own account of this step). `go build ./...` succeeded; `go test ./internal/knowledge/... -run TestAnAssertedActorDoesNotReplaceTheObservedOne` failed with "the observation equals the assertion". Confirms the build record's claim that the naive substitution breaks compilation first, and the rewritten one is caught by assertion, not accident.
EVIDENCE AC-4 | CP-3v | PASS | `--authorized-by` recordable as asserted, never presented as observed: accepted a staged record via `disposition-staged`, then deleted it with `-authorized-by "Second Person Not At Keyboard <auth@example.com>"`. `deletion-evidence-staged` output carried `authorized_by` verbatim alongside a separate, differently-labeled `observed_actor` field. `internal/knowledge/staged_store.go:156,169,175` — struct comment at line 172 states `DeletedBy and AuthorizedBy above are caller-asserted [as distinct from] an observation`.
EVIDENCE AC-4 | CP-3v | PASS | `roster/knowledge-store/SECURITY.md` verified against build-record claims: "There is still no caller identity: `--decided-by`, `--deleted-by` and `--authorized-by` are free-text strings authenticated by nobody" (line 29); "`observed_actor` does not change that sentence. It is recorded on deletion, not consulted by any check... strictly better evidence, identical enforcement" (line 60). No softening found versus the described intent — the document explicitly extends the same "caller-asserted, unverified" characterization to `staged_by`/`decided_by` too (line 58: "The remaining two compare two **caller-asserted strings**, authenticated by nobody, exactly as `--deleted-by`/`--authorized-by` are above").
EVIDENCE AC-4 | CP-3v | PASS | Generated mirror `plugin/suite/roster/knowledge-store/SECURITY.md` matches the canonical source verbatim (only diff: a 2-line "GENERATED FILE" banner). No `provider/` copy of this file exists (`find provider -iname SECURITY.md` empty). `build/wheel/.../SECURITY.md` is gitignored (`.gitignore:128`, not tracked by git) — a stale local build artifact out of the task's named scope, and correctly ignored.
EVIDENCE AC-4 | CP-3v | FAIL | `--staged-by`/`--decided-by` get no derivation, no refusal, and no runtime disclosure. `cadre knowledge propose --from-finding ...` output (`internal/cli/knowledge_staged.go:369-378`) carries only `status`/`id`/`record_status`/`content_digest`/`note` — no mention that `staged_by` is unverified. `disposition-staged`'s `-decided-by` flag help text (`internal/cli/knowledge_staged.go:786`) reads only "the steward deciding; must not be the record's staged_by (required)" — no verification-status disclosure. Live run confirmed both commands accept and silently record arbitrary caller strings with zero runtime signal.
EVIDENCE AC-4 | CP-3v | PASS | Build reproducibility: `go build ./...`, `go vet ./...` clean; `CGO_ENABLED=1 go test -tags sqlite_fts5 ./...` — all packages `ok`, including `internal/knowledge` (21.9s) and `internal/platform`.

## FAILURES

- AC-4 | "every command accepting `--staged-by`, `--decided-by`, `--deleted-by` or `--authorized-by` derives the value... or refuses to run" | `propose` (`--staged-by`, via `staged_by` finding/frontmatter field) and `disposition-staged` (`--decided-by`) do neither: no derived value is written to any evidence row for these paths, the commands do not refuse to run, and — per AC-5's explicit precedent in the same spec distinguishing runtime disclosure from `SECURITY.md`-only disclosure — a security document is not "the command says plainly."

## FIX_HINTS

- AC-4 | Cheapest bounded fix: no schema change needed. Add a `note`/warning field to `propose`'s and `disposition-staged`'s JSON output (and their `--help` text) stating plainly, at the point of the call, that `staged_by`/`decided_by` are caller-asserted and unverified — mirroring the existing code comment at `internal/knowledge/staged_store.go:172` and the `SECURITY.md` language already written for `--deleted-by`/`--authorized-by`. This satisfies the "command says plainly" disjunct without the two-table schema work the builder flagged as out of scope. A stronger (not required) fix would add an `observed_actor`-style companion field to the `propose`/`disposition-staged` evidence rows, matching the deletion path's treatment exactly.
