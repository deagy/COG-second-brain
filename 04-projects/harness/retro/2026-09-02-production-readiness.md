# Retro: production-readiness (all seven phases)

> Date: 2026-09-02 · Goal: `04-projects/production-readiness/` · Lane: `full` · Outcome: shipped

## What happened

Eight phases against nine criteria, closing the gap between what cadre, the lifecycle
kernel, recall and gloop claimed and what they did. P1 licensed the kernel and settled
gloop as internal; P2 closed `#249` and removed the kernel's second release home; P3
made four actor fields derive or refuse; P4 made ~15 reach-paths refuse an absent
retention capability by name; P5 released all four and then ran the install on a clean
machine; P6 audited gloop's documentation claim by claim against a built binary.

The phase that mattered most was P5, and not for the reason it was planned. Six of the
nine criteria are checkable from a working checkout — the exact position that cannot see
an installation defect. AC-7 put the software on a machine that had none of it, and each
of six container runs moved the failure to a new one: no AI runner on PATH; a
`SHA256SUMS` format the install shim had never been able to match, in every kernel
release since the extraction; a Go toolchain the instructions never mention; no
`linux/arm64` binary published while the diagnostic listed `linux/arm64` among its
platforms; a cached kernel that four separate resolvers could not find; and `cadre doctor`
reporting no kernel while `cadre sdlc` was running one.

**Then the north-star gate failed AC-8, six phases after P2 closed it**, and P7 was
opened to fix it. Two of AC-8's three clauses were false: `#249`'s *body* still
narrated deleted Python as current (only a closing comment addressed the drift), and
six `kernel-v*` releases with downloadable assets were still live in the `cadre` repo,
so the kernel had two release homes. P2's own CP-3v and CP-4 rows had checked that
`release.yml` no longer *publishes* kernel releases — the machinery, not the artifacts
the criterion actually names. That gap is why the goal ends at eight phases and not six.

## Evidence quality

| AC | Had a PASS row | Observed the artifact | Notes |
|---|---|---|---|
| AC-1 | yes | yes: `gh api` licence field for each of four, against each README | A repository with no licence makes no claim — gloop's case, settled by decision not omission |
| AC-2 | yes | yes: the fetch set read out of `plugin_generation.go`, each source repo's licence checked | Bounded to what the installer names, as the criterion says |
| AC-3 | yes | yes: every badge URL fetched, every live document read end to end | |
| AC-3b | yes | yes: 20 guards run against a built binary; each command and flag executed | Nine CP-3v rounds. The audit found two falsehoods that predate this goal |
| AC-4 | yes | yes: each command run, its written evidence row read back from the store | The criterion's weak reading was named at charter and refused at the gate |
| AC-5 | yes | yes: each refusal path executed and its message read | CP-4 caught a refusal reading a flag's *value* as a request |
| AC-6 | yes | yes: `gh release list` vs `git rev-parse <tag>^{commit}` per repo | Measured against releases, not tags — recall carries three tags with no release behind them |
| AC-7 | yes | yes: `docker run --rm` aarch64, Go absent, `~/sdk` absent, full install transcript | The only criterion an outside party could run |
| AC-8 | **only after P7** | eventually: the body re-fetched, and the releases API and asset URLs on both repos | P2's PASS was false in two of three clauses. See below — this is the goal's most important finding about its own harness |

No PASS rested on a worker's summary. Two came close: P5's first AC-7 claim was written
from a container log that recorded a *failure*, and the row was not written until a run
succeeded; P6's guard count was asserted from memory as fourteen when the tree held twenty,
caught by counting the tree.

## What the gates caught

| CP | Verdict | What it caught, or why it was silent |
|---|---|---|
| CP-1 | PASS | `spec-lint.sh` clean. AC-7 was placed in the last phase because the phase publishing its artifacts had to run first — the shape AI-4 exists for |
| CP-3v | 19 rounds across 7 phases, 16 of them FAIL | The single most productive gate in the goal. P3 failed 3 times on one root cause (a column addition's blast radius); P6 failed 9 times, three of them on the same shape, which triggered the escalation |
| CP-4 | PASS ×7 | P4: a refusal that read a flag's value as a request. P6: a guard I had built and falsified, deleted by my own scripted rewrite at `7a5a3dd`, unnoticed for five rounds. Nothing else would have found it — a deleted test leaves no failing artifact |
| CP-5 | PASS ×9 | Held the line on AC-7 through five failing container runs |
| CP-6 | PASS | All four repositories green at HEAD: cadre `5c40d6ec`, cadre-kernel `d4fb0894`, recall `3bef2354`, gloop `1f37de4`. Also the gate that stopped P7: deleting six published releases went to the user, with the eight CLI releases it would break named first |
| **North-star** | **FAIL, then PASS** | The gate earned its place. It found AC-8 false six phases after the phase that closed it, on the one clause nobody had looked at: P2 verified the workflow, the criterion named the artifacts. Nothing between P2 and the gate would have caught it — every intervening check was scoped to its own phase |
| CP-7 | this document | |

## Friction

- **P6's escalation was the right call and it took three rounds to make.** Three attempts
  failed on the same shape: a guard that parsed the README's `--config` table and kept
  disagreeing with it for a new reason each time. AI-18 says stop at the third. Stopping
  produced the method that worked — generate the table from the binary and assert the
  README contains it — which inverts the guard's direction rather than refining it.
- **Fixing the citation instead of the concept, twice in P6.** AI-16 is my own rule and I
  broke it in the phase that most needed it. The provider list drifted in six places and
  took five rounds because each guard covered the list in front of it. It stopped when the
  guard began *finding* enumerations rather than naming them.
- **Guards that do not cover their own defect.** The go-command guard scanned line-starts;
  both `go doc ./...` defects were inline, and it passed when the defect was put back. The
  coverage check searched the whole README instead of the table, so deleting a row left it
  green. Both were found by re-introducing the defect, which is the only way they could be.
- **A shared fixture overwritten between subcommands** produced an empty Honoured row in
  P6 that I nearly believed, and path normalisation erased the config writers' only signal.
  Both are the same error: a fixture that destroys the evidence it exists to produce.
- **`cli-v0.7.0` and `plugin-v0.24.0` published from a red validate run.** Release and
  validate run on the same push and neither waits.
- **A criterion closed for six phases was false the whole time.** AC-8 said the
  kernel has one release home; P2 checked that the workflow no longer publishes to
  the second one. A workflow that has stopped publishing and a repository that serves
  nothing are indistinguishable from inside the workflow file, and P2 never left it.
  The same phase read a *comment* correcting an issue body as the body being corrected
  — indistinguishable to anyone reading the thread top to bottom, and different to
  anyone who lands on the body from a search result.
- **The gate's own evidence contained the same class of error it caught.** Its FAIL
  cited `curl -sI .../releases/tag/kernel-v0.14.2` returning 200 as proof a release was
  live. After the releases were deleted that URL still returns 200, because GitHub
  renders a page for a bare git tag. The verdict was right; one of its four citations
  proved something narrower than it appeared to. Checked by fetching the page and
  counting asset links (zero) against the releases API (404).
- **I built a 16MB binary into a package directory** by running the README's own build
  command, and committed it. The instruction was wrong; the commit was mine.

## Actions

| ID | Action | Target file | Disposition |
|---|---|---|---|
| AI-19 | A tag with no release behind it. recall carries three (`v0.3.0`–`v0.3.2`). This is the check that would have caught P5's opening finding without a person looking. | each of the four repos | **control — unbuilt** — observable as `gh release list` vs `git tag` per repository; needs a home that runs it |
| AI-20 | A repository with no `LICENSE` of its own. Nothing in any of the four gates on it; recall's `go-licenses` checks *dependency* licences and would not notice. | each of the four repos | **control — unbuilt** — observable as a file-existence assert in each repo's own suite, gloop excepted by recorded decision |
| AI-21 | A release job that publishes from a commit whose validate run is red. | `.github/workflows/release.yml` ×4 | **advice** — the release job *could* require the validate conclusion, so this is a cost argument, not an impossibility: it serialises every release behind a full matrix. Landed as the practice of checking `ci-status.sh` before cutting |
| AI-22 | A guard deleted by a later edit leaves no failing artifact. P6's `TestDispatchHasNoUnlistedSpecialCase` was removed by my own scripted rewrite and went unnoticed for five rounds. | gloop `internal/docguard/` | **control** — gloop `TestTheGuardSetOnlyGrows`, commit `1f37de4`. It names all 20 guards by hand, which is the point: adding one requires editing the list, and removing one fails |
| AI-23 | A hand-kept list beside a contract that could generate it. Three instances in P5 alone — the launcher's platform message, the wheel here-doc, `CADRE_KERNEL_REF` — each with a comment claiming it was kept in step. | cadre | **control** — `TestTheWheelPlatformsMatchTheContract` and `TestTheWorkflowKernelPinMatchesTheProviderPin`, commit `5c40d6ec`; the launcher's list now renders from `release.PlatformsFor` |
| AI-24 | A recorded exclusion carries its own expiry. `linux/arm64` was excluded with the reason "needs either a native arm64 runner or a cross toolchain"; the runner arrived and the reason lapsed silently. | working practice | **advice** — a check cannot evaluate whether a prose reason still holds. What it *can* do is refuse a bare exclusion with no reason attached, which is why the reason was there to lapse |
| AI-25 | A guard that parses a document to check it will keep disagreeing with the document. Generate the expected artifact from the source of truth and assert the document contains it. | working practice | **advice** — the direction of a guard is a design judgment, not a pattern; landed in `.claude/skills/closed-loop/SKILL.md` § CP-3 alongside AI-16, with the three-round `--config` incident attached |
| AI-26 | A test fixture shared across subcommands, or a normaliser applied to output, can erase the signal the test exists to read. | working practice | **advice** — indistinguishable from a legitimately empty result at the point a check could look. What separates them is whether the *absence* was ever falsified, which is the CP-3v discipline already in place |
| AI-28 | Verify the class of artifact the criterion names. AC-8 says the kernel has one release *home*; P2 checked the *workflow* that publishes to it, and was wrong for six phases. A criterion about artifacts is not answered by the machinery that produces them, and the two are indistinguishable from inside the machinery. | `.claude/skills/closed-loop/SKILL.md` § CP-5 | **control — unbuilt** — partially observable: a CP-5 row whose cited artifact is a source file, workflow, or config, for a criterion whose text names a published or external thing, is a detectable mismatch. It would not have caught the issue-body clause, where both the comment and the body are the same kind of artifact |
| AI-29 | An HTTP 200 is evidence that a URL renders, not that the thing behind it exists. `releases/tag/<tag>` returns 200 for a bare git tag with no release; the gate's own FAIL cited that 200 as proof of a live release. Where an API can answer the question, the HTML page cannot. | working practice | **advice** — landed in `.claude/skills/closed-loop/SKILL.md` § CP-5. No check reaches it: the defect is choosing the weaker of two available observations, and the weaker one returns a plausible success |
| AI-27 | `TestDispatchSDLC_UsesInTreeFallback` built its fake kernel at a path the production code read and the repository never had; test and code moved together, neither moved with the repository. | cadre `internal/cli/` | **advice** — a path a resolver treats as in-tree *could* be asserted to exist in the real checkout, but most such paths are legitimately absent until something creates them, and the check would be wrong more often than right. Cost argument: the general form is not worth it; the specific fixture is fixed |

Two proposed patches, applied:

- `.claude/skills/closed-loop/SKILL.md` § CP-3 gains AI-25 beside AI-16.
- No `CLAUDE.md` change proposed. The rules this goal broke were already written there.
