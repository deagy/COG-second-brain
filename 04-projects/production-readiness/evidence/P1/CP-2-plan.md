# P1 — CP-2 plan · AC-1, AC-2, AC-3

Licensing and identity. Legal before technical, because releasing an unlicensed artifact is worse than not releasing.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Licence the lifecycle kernel | AC-1, AC-2 |
| T-02 | Gather the evidence that settles gloop's public/internal question, and put the decision to the user | AC-3 |
| T-03 | Make gloop's README true of gloop as it then stands | AC-3 |
| T-04 | Sweep all four repositories for licence claims against what they carry | AC-1 |
| T-05 | Enumerate what cadre's installer actually fetches, and check each source is licensed | AC-2 |

## T-01 — which licence, and why it is not an open question

The kernel is public with no `LICENSE`, which is all-rights-reserved by default. GitHub's own description of the repository settles the choice:

> *"Portable Agentic SDLC lifecycle kernel… **Extracted from deagy/cadre**."*

cadre is Apache-2.0. The kernel is code lifted out of it by the same sole author — `git log` shows one name — and cadre still consumes it at install time. **Apache-2.0**, matching the parent it came from and the project that depends on it.

This is recorded as reasoning rather than presented as a choice because the alternative readings are weak: MIT would make the kernel's terms differ from the repository it was extracted from and from the CLI that fetches it, for no stated reason; anything copyleft would be a change in intent that nothing in the history supports.

If that reading is wrong it is the author's to correct, and it costs one file to change.

## T-02 — what evidence would settle gloop, and what needs approval

The question is whether gloop is an SDK for others or internal tooling wearing an SDK's clothes. Evidence gathered so far, all falsifiable:

- **Nothing imports it.** Not cadre, not recall, not the kernel — checked across all three.
- **The only caller of its deprecated selectors is its own CLI**, `cmd/gloop/cmd/select.go:91`.
- **Its deprecation notice has never shipped** — it lives only in `[Unreleased]`, 39 commits past `v0.2.0`.
- **Its README asserts what the repository cannot support**: an MIT badge with no `LICENSE` file, and Go Report Card and pkg.go.dev badges while `pkg.go.dev/github.com/deagy/gloop` returns 404.

That evidence points one way, but **making a repository public is not reversible in the way most of this goal's work is** — published code stays published, and anything ever committed to it becomes readable. So T-02 ends at a recommendation and the decision goes to the user, whichever way the evidence leans.

## T-05 — bounding AC-2

AC-2 says "nothing installable resolves an unlicensed dependency", which is a universal negative unless the set is named. The set is what cadre's generated installer actually fetches by name or version — read out of `internal/generators/plugin_generation.go`, not guessed. Anything it does not fetch is out of scope for this criterion.

## What would falsify this phase

Licensing the kernel and declaring AC-1 met. AC-1 is about **all four** repositories and every claim each makes, not the two offenders already known — and the sweep is what makes it a criterion rather than a fix. T-04 exists to find the third one nobody has looked for.

## Not in scope

The kernel has no README either. That is a real gap for a public repository and it is not a false claim, which is what AC-1 covers. Recorded here so it is not lost, and left for the phase that owns discoverability.
