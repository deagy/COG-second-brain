# Retro — team-readiness (CP-7)

Nine criteria, five phases, all verified. Seven cadre releases and three recall
releases. The goal shipped what it set out to ship, and what it is worth
recording is how nearly it shipped several things that were not true.

## Checkpoint audit

| CP | Owed | Ran | Gap |
|---|---|---|---|
| CP-1 | P0 | yes | — |
| CP-2 | every phase | yes | — |
| CP-3 | every phase | yes | **P2's ran unrecorded.** The build happened and CP-3v passed over it four times; no row and no file existed until `phase-gates.sh` reported it never ran |
| CP-3v | every phase | yes | — |
| CP-4 | every phase (all multi-task) | yes, eventually | **P3, P4 and P5 never ran it.** `STATUS.md` said the verification was running; there was no row and no artifact |
| CP-5 | every phase | yes | — |
| CP-6 | every phase | yes | — |

Both gaps were found by `phase-gates.sh`, neither by a person reading the
ledger, and one of them was recorded in `STATUS.md` as in progress. That is the
whole argument for counting rows rather than reading the file that describes
them: **a checkpoint that never ran and one whose result was never written leave
the same evidence bundle behind**, and a narrative can assert either.

CP-4, once it ran, returned FAIL on both attempts and found two defects that
every per-phase check had passed over. It is not a formality.

## The defects worth carrying

### A fix verified on the path it changed, not the path the failure takes

CP-4 round 1 found that deletion evidence could be lost while the content was
already gone. The obvious fix — give the INSERT the retry the schema creation
beside it has — does nothing, because the connection string already sets
`busy_timeout(5000)` and the driver consumes the whole budget inside the first
`Exec` before the retry loop checks its deadline.

I found that only because **the test failed to distinguish its own mutations**:
it passed with the longer budget removed, passed again with the retry removed
entirely, then failed on unmodified code. Round 2 then found the fix was still
uneven — a cold store failed at five seconds where a warm one waited sixty —
because the failing call was in `initStagedSchema` at store open, a path I had
not changed and had not tested. The brief had named the cold-versus-warm axis;
the verifier was right about the axis and I was wrong about which code sat on it.

### A guard that cannot see the claim it exists to catch

`docs/the-three-repositories.md` asserted that a test fails if any document
still places the kernel in cadre's repository. False in both halves at once:
`terminology.md` still said so, in prose and in a mermaid label, and the guard's
regexes read only backticked paths and markdown links.

The round-2 verifier, asked to build its own list of syntaxes rather than reuse
mine, probed thirty and found six the extended guard still cannot see. None
occur in any live document, so it is a coverage statement rather than a defect —
but the honest form of the claim is "catches the syntaxes people have used
here", not "catches the claim".

### Three checks that reported the wrong reason

`citation-lint` read every eleven-digit CI run id as a commit sha — a collision
guaranteed by the skill requiring run ids in the ledger. `ci-status` and
`release-hygiene` took a bare `cadre` where `deagy/cadre` was meant, 404'd on
every call, and reported three green, licensed repositories as having neither CI
nor a licence, because `gh` writes a 404 body to *stdout* and the error JSON
passed an emptiness check.

All three failed closed. None invented a pass. What they did was send the reader
to the runner instead of to the argument, and I spent a diagnostic cycle there.

### A hand-made tag defeats a self-tagging release workflow

`cli-v0.7.10` was created by hand before checking how cadre releases. The
workflow tags and publishes itself on a version bump and skips any version
already tagged, so the tag both failed to trigger a release and prevented one.
`release-hygiene.sh` correctly reports it and **the goal is not closing it with
an exception**, because an exception entry would file my own mistake as a stated
reason. It needs the operator.

## Evidence quality

Every criterion carries a PASS row observed against a released artifact or a
clean container, not a checkout. Two rows are worth singling out for the shape
of the observation rather than the result:

- The isolation check proved each credential finds its **own** content before
  concluding anything about what it cannot see, then ran a deliberately broad
  query under a scoped key and against an admin key to show the store was not
  simply empty.
- The cold-path re-check reported the **numbers**, not whether the two states
  agreed. "The same in both states" is satisfied by equalising at the short
  budget as much as the long one; intermediate durations succeeding is what
  distinguishes them.

## Action items

| ID | Item | Where | Disposition |
|---|---|---|---|
| AI-31 | A retry whose budget is consumed by a blocking call before its first deadline check is decoration. Where a driver already waits, the app-level budget must exceed the driver's or it buys nothing. | cadre `internal/knowledge/` | **advice** — the arithmetic is visible only by reading the DSN and the loop together; no artifact states the relationship |
| AI-32 | A schema change that runs after an irreversible mutation is a lock race you cannot retry. Create tables at open, not beside the write that needs them. | cadre `internal/knowledge/staged_db.go` | **control** — `TestTheEvidenceTableExistsFromOpen`, commit `ce57aa6a`. Falsified: reverting to lazy creation fails it. Structural, so it depends on no lock, clock or competing process |
| AI-33 | A CI run id is decimal and eleven digits, so it sits inside `[0-9a-f]{7,40}` and reads as a sha. | `.claude/lib/citation-lint.sh` | **control** — `citation-lint.sh`, commit `f7a6524`. Refuses a run id written in commit-citation syntax rather than skipping it, so it stays visible. Falsified: the bare form fires, the `run` form passes, and repo-consolidation's 37 citations are unaffected |
| AI-34 | `gh` writes a 404 body to stdout, so an unresolvable argument leaves a non-empty value that passes an emptiness check and produces a plausible wrong reason. | `.claude/lib/ci-status.sh`, `release-hygiene.sh` | **control** — commit `f7a6524`. Both now say the argument names no repository. Falsified: a bare name reports it, a slug and a directory both still resolve |
| AI-35 | A test that passes under the mutation it exists to catch is worse than no test — it advertises a guarantee it does not check. Mutate before believing a green test, and mutate more than once. | `.claude/skills/closed-loop/SKILL.md` § CP-3v | **advice** — `mutation-verify` already exists as a skill; what failed was not running it. A check cannot know which mutation is the meaningful one, since that is the claim the test is making |
| AI-36 | An agent that batches its notes to the end loses everything when it stalls. Three verifiers on this goal were killed having written nothing. | `.claude/skills/ultragoal/SKILL.md` § verifiers | **control — unbuilt** — observable: a verifier brief could be required to name an incremental notes path, and the dispatcher could refuse one that does not. The stall itself is not observable; the missing instruction is |
| AI-37 | `TestAStandaloneBinaryAnswersTheBasics` shells out to an untagged `go build`, which cannot reuse the `sqlite_fts5` cache the suite compiles with. Cold, that CGO build ran 8m49s and blew Go's default ten-minute package timeout; warm the package takes 14s. It also runs with `context.Background()` and no timeout. | cadre `internal/cli/standalone_test.go` | **control — unbuilt** — both halves are observable: assert the build command carries the same tags as the suite, and assert the exec carries a timeout |
| AI-38 | A hand-made tag defeats a workflow that tags and publishes itself, and leaves a tag with no release. Check how a repository releases before tagging it. | working practice | **advice** — `release-hygiene.sh` already catches the *result*; nothing can catch the intent at the moment of tagging, and the check that would have prevented it is reading one workflow file |

## Open for the operator

- **`cli-v0.7.10` must be deleted.** `git -C ~/sdk/cadre push origin :refs/tags/cli-v0.7.10`. It points at `68095d81`, nothing references it, and `release-hygiene.sh` is red until it is gone. Deleting a remote tag is a human-approval action and is blocked in-session.
- **Four scratch worktrees remain registered** from earlier phases. Deregistering a worktree is likewise the operator's to do.
