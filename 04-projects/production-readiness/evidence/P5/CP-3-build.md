# P5 — CP-3 build record

## T-01 · kernel: the licence in the archive, then the checksum the shim can read

Two releases, because the first fix was not the whole defect.

**v0.14.3.** `release.yml` built each platform and ran `tar czf ... "$binary"` —
one file per archive. The repository carried Apache-2.0 and the thing an install
unpacks carried no licence text. STATUS carried this into P5 as "re-cut before it
is true of what people install"; reading the workflow corrected that. Re-cutting
would have published the same one-file archive. `LICENSE` now goes into both
formats, and a step asserts it is inside each archive rather than trusting the
packaging line. Falsified three ways locally under bash: with the licence exits 0,
without it exits 1, and with the licence only under `docs/` exits 1 — the tar check
is `grep -qx`, anchored.

**v0.14.4.** Found by T-05, not by reading: the shim resolves a checksum with
`grep " $ARCHIVE$"`, and every kernel release wrote `SHA256SUMS` with
`sha256sum ./*`, so each line named `./agentic-sdlc-…` and nothing matched. The
shim reported the archive as unlisted — which reads as a broken release rather
than a producer and its only consumer disagreeing about a format. **`cadre sdlc`
could not install a kernel at all, on any release since the extraction.** Bare
names now, plus a step that greps `SHA256SUMS` with the shim's own pattern before
publishing. Falsified: the old form does not match, the new one does.

I looked straight at this defect and did not see it. Verifying v0.14.3 I printed
`grep linux-amd64 SHA256SUMS` beside `sha256sum <file>`, saw `./agentic-sdlc-…`
against `agentic-sdlc-…`, and read the hashes.

## T-02 · recall: two reasons nothing published, and only one was the trigger

`tag.yml` pushed an annotated tag and echoed `release workflow will pick it up`.
It does not: a ref pushed with the workflow's own `GITHUB_TOKEN` raises no further
workflow run. v0.3.0 and v0.3.1 were tagged this way, both runs green, neither
published. v0.2.0 has a release only because that tag was pushed by hand.

`tag.yml` now calls `release.yml` directly. `release.yml` gains `workflow_call`
and a `workflow_dispatch` taking an existing tag — the recovery path for this
exact shape. Both new triggers need a tag name `github.ref_name` does not carry,
so the job resolves one `TAG` and refuses any ref that is not `vX.Y.Z`; a dispatch
from `main` would otherwise publish a release called `main`.

**Then the first run that reached the release job failed.** `govern`'s fail-closed
contract is vendored from cadre and `TestTheContractMatchesItsOrigin` hard-fails
under CI rather than skipping, so it needs a cadre checkout. `go.yml` has carried
one since v0.3.0 was tagged with that job red — and says so in its own comment.
`release.yml` never got the same two steps. Two workflows needed the same fix and
one got it.

v0.3.3 published: 13 assets, `recall-0.3.3-linux-arm64` downloaded and run,
reports `recall version v0.3.3`.

v0.3.2 is a third tag that published nothing — but loudly, on a red run, which is
the whole difference the trigger fix bought.

## T-03 · cadre: one constant, five places

55 commits sat between `cli-v0.6.5` and `main`: the licensing sweep, `#249`, the
observed actor, the capability refusal. None of it was installable.

Moving `provider.KernelVersion` dragged four other things with it, each found by a
guard rather than by me: `provider/provider.json`'s floor (a test requires floor ==
pin), three `kernel-compatibility.json` manifests, two versions quoted in
`plugin/README.md`, and `CADRE_KERNEL_REF` in `validate.yml`.

**The fifth was found after publishing.** `cli-v0.7.0` and `plugin-v0.24.0` went
out from a commit whose `validate` run was red: the workflow still built the old
kernel and the provider window no longer admitted it. The release job and the
validate job run on the same push and neither waits for the other.

So `TestTheWorkflowKernelPinMatchesTheProviderPin` now reads `validate.yml` and
compares its pin to the constant. It fails locally, before the push, instead of on
a runner after it. Falsified both ways: reverting the pin fails with both versions
named; renaming the variable fails rather than passing over a pin nothing checks.
`validate.yml`'s own comment says "the compatibility guard below is what tells you
it needs bumping" — and that guard tells you by going red after the release.

`TestEveryDocumentedKnowledgeVerbIsAnswerable` caught this phase's CHANGELOG prose,
reading `cadre knowledge staged` as a verb the dispatcher does not answer.
`TestHardcodedReleaseTagsAreConfinedToHistoricalRecords` caught two release tags in
the new guard's own comment. Both were right about the shape; both sentences were
reworded.

## T-04 · gloop: the documented install does not work

Two lines below "publishes no releases for outside consumers", the README said to
run `go get github.com/deagy/gloop` and
`go install github.com/deagy/gloop/cmd/gloop@latest`. Measured: `proxy.golang.org`
and `pkg.go.dev` both answer 404 for it, and the direct fallback asks for a GitHub
username and gives up with no terminal to ask. Replaced with clone and
`make install`, which is what the one consumer does.

AC-6 allows "a stated reason", and gloop is where that clause is tempting as the
whole answer. The reason is now in the repository rather than only in this ledger:
`main` is what you install, `v0.1.0` and `v0.2.0` are markers in the history, and
a tag that produces no release is indistinguishable from one that failed to —
which this phase has now seen three times in another repository.

## T-05 · the container found two things nothing else could

Covered in `CP-5-acceptance.md`. Both defects it found were invisible from a
machine that already had a kernel, a Go toolchain and four checkouts.

## T-06 · arm64 Linux, added after the container refused to install

Not in the CP-2 plan. Added because AC-7 could not pass on the machine this
project is written on, and the reason was not a bug — it was a recorded decision
whose reason had expired.

The container installed cleanly, fetched kernel 0.14.4, and then:

```
cadre: could not obtain the cadre binary for this platform.
  platform:  Linux/aarch64
  version:   0.7.1
  * an unsupported platform -- released binaries cover linux/amd64,
    linux/arm64, darwin/amd64, darwin/arm64 and windows/amd64
```

`cli-v0.7.1` publishes no `cadre-v0.7.1-linux-arm64.tar.gz`. **The message names
`linux/arm64` and `darwin/amd64` — the exact two platforms the CLI deliberately
excludes.** It was the repository's general matrix, typed by hand into the shim,
so it sent the only people who see it looking for a network fault. It is now
rendered from `release.PlatformsFor(release.ProgramCLI)`.

The exclusion itself was honest and documented: the CLI links sqlite, so arm64
needed cgo, which on a cross build meant an aarch64 toolchain installed with
`apt` — and `apt-get` stalled against the mirror on four releases running,
burning the job budget with every other platform already built. **The entry
named what would end it**: "either a native arm64 runner or a cross toolchain".
GitHub's `ubuntu-24.04-arm` is that native runner. The leg being added is not the
leg that kept failing.

Without the reason stored beside the exclusion there would have been nothing to
notice had expired. A bare list of unsupported platforms outlives its own
justification; this one carried its own expiry condition and met it.

Two more guards fired on the change, both correct:
`TestThisRepositorysChangelogHasAnEntryForItsCurrentVersion` (a release cut then
would have published an empty body) and `TestEveryRunnerLabelIsReviewed`, which
refused `ubuntu-24.04-arm` until it was added to the approved list with a note —
pinned to a version rather than a floating arm label, because this leg builds cgo
against the runner's glibc and the wheel it produces claims `manylinux_2_17`.

### The arm64 leg failed once, at the last job, on a number

Every build in the matrix succeeded — including the new `ubuntu-24.04-arm` leg —
and then `Publish Cadre CLI release` failed:

```
cadre-0.7.2-py3-none-macosx_11_0_arm64.whl: 0 python, binary present, 159 roles
cadre-0.7.2-py3-none-manylinux_2_17_x86_64.whl: 0 python, binary present, 159 roles
cadre-0.7.2-py3-none-win_amd64.whl: 0 python, binary present, 159 roles
expected 4 wheels, found 3
```

The wheel step builds one wheel per platform from a here-doc list, because pip
needs a PEP 425 tag per platform and the contract has no opinion about those. The
list is hand-kept, and its comment said "kept in step with the build matrix above
and with `internal/release/platforms.go`" — which is a description of an intention,
not a mechanism.

**This is the second time in one phase that a hand-kept list diverged from the
contract**, after the launcher's platform message. And the third place where one
constant's move had to be chased outward by hand.

`TestTheWheelPlatformsMatchTheContract` now reads the same here-doc and compares
its pairs to `PlatformsFor(ProgramCLI)`. Falsified three ways: a missing row fails,
an extra row the CLI does not publish fails, and renaming the here-doc marker fails
rather than passing over a list nothing checks. The tags stay unchecked on purpose —
they are pip's vocabulary, and a wrong one has its own guard in the wheel-contents
step.

The count check was right and in the wrong place: correct, and reached only after
a twenty-minute build matrix. Nothing was tagged, because the tag step runs after
the wheel verification — so the failure cost time and published nothing wrong.
