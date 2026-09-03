# Team readiness — spec

**North-star:** a colleague who has never seen these repositories can install cadre, the lifecycle kernel and recall unaided, learn from the documentation how the three fit together, and read a record of who did what that names a person the system actually verified.

Three properties, in the order a colleague meets them: **installable by someone else**, **legible as a set**, **attributable to a real person**.

gloop is deliberately out of scope. Nothing imports it — not cadre, not the kernel, not recall — and its coupling to cadre is a dispatch-plan file rather than a code dependency, so its private, unreleased state blocks nothing here. Whether to share it at all is a separate decision.

## The bar this goal is written to

**Colleagues on an internal team.** Real second users, trusted, inside the same company. They install on their own machines, run real work, and read the audit trail. Chosen at charter over two heavier bars, and the exclusions are as load-bearing as the inclusions:

- **Not anonymous internet users.** No stability or semver promise is owed, no issue-triage expectation, no assumption of hostile input. A document that assumes the reader can walk over and ask a question is acceptable here and would not be for public release.
- **Not customer or regulated data.** Deletion on request is in scope because a colleague's notes are a third party's content relative to the person who ingests them — but retention windows driven by a legal obligation, and any policy review, are not.
- **No uptime or support SLA.** These are tools people run, not a service that is up.

**The previous goal was written to a different bar and said so**: *"your own multi-agent work, run daily. One operator."* Two of its decisions were justified by that fact and expire here, which is the reason this goal exists rather than being a continuation:

- *"With one operator there is nobody to impersonate."* True then. With colleagues, an approval record naming a person nobody verified is a record of a string.
- *"No third party's content enters the store."* True then. A colleague's content is a third party's content.

Neither was wrong when written. Both were conditional on a fact this goal changes.

## Baseline, measured 2026-09-02

From a clean-container install as someone who had never seen the repositories, live commands against binaries built at HEAD, and the GitHub API. Full findings: [assessment.html](assessment.html), with working notes in `ready-install.md`, `ready-multiuser.md`, `ready-docs.md`.

| | cadre | lifecycle kernel | recall |
|---|---|---|---|
| Licence | Apache-2.0 | Apache-2.0 | MIT |
| Latest release | `cli-v0.7.5` | `v0.14.4` | `v0.3.3` |
| CI at HEAD | green | green | green |
| Test functions | 1,616 | 167 | 1,451 |
| GitHub description | **missing** | set | **missing** |
| Front page routes a newcomer to install | **no** | **no README at all** | **no install section** |
| Live false or dangling doc claims | 9 | 3 | 5 |

What a colleague hits, in order: `curl`, `git` and `python3` absent on a bare image with no doc warning; `cadre` not on `PATH` unless they read a note printed after install; and then the first real task stopping at `Not logged in · Please run /login`, an interactive OAuth flow documented nowhere, with a bad key hanging silently for ninety seconds rather than failing.

What already works and must not be rebuilt: concurrent writes to the staged store (six parallel proposals, none lost), evidence-tracked deletion of staged records that outlives its subject by design, secret hygiene enforced by a hard error rather than convention in both cadre and gloop, and `cadre doctor` reporting install kind, which binary ran, and where the kernel came from.

**The finding that shapes the phases:** recall already ships `recall-server` as a released binary on six platforms with API-key, namespace-scoped and JWT authentication behind 37 tests, and its `Authenticate` returns a *subject*. cadre never wires to it — `internal/retrieval` opens a local SQLite file directly. Identity is an integration, not an auth system to design.

## Acceptance criteria

| ID | Criterion | How it is falsified |
|---|---|---|
| AC-1 | A colleague installs all three unaided | On a machine with none of these repositories, a person following only the published documentation reaches a working `cadre`, `agentic-sdlc` and `recall` from published artifacts, and completes the first task each repo presents as primary. Run in a container, from the docs alone, with no step supplied from outside them |
| AC-2 | Every prerequisite is stated before the command that needs it | The docs name `curl`, `git`, Python and its version, Go and its version, the `PATH` entry, required network egress, and the authentication step — each before, not after, the command that fails without it. Checked by reading the docs in order and by the AC-1 container run producing no surprise |
| AC-3 | Each repository's front page routes a newcomer | cadre's first screen links its install guide; cadre-kernel has a `README.md`; recall has an installation section naming the released binaries that exist. All three carry a GitHub description |
| AC-4 | One document explains the three together | A single page states what each tool is for, that the kernel records and validates while cadre drives, that recall is the knowledge backend, and in what order to adopt them — linked from all three front pages, with a glossary defining roster, catalog, routing, dispatch plan, gate, G1–G10, provider, lane and kernel |
| AC-5 | No live document makes a false or dangling claim | The eighteen counted claims are corrected, and the enumeration re-run finds none. Every markdown link, referenced path and documented command in a live document resolves or exists in the binary's help. Records carrying a historical banner are exempt and stay unedited |
| AC-6 | The recorded actor is a verified subject, not a chosen string | cadre obtains identity from an authenticated source and a caller cannot choose it. Falsified by the sequence that succeeds today: stage a record as one name and disposition it as another from a single process, and observe the refusal — on identity, not on string inequality |
| AC-7 | Two people can share one store | Two callers with distinct credentials use one store through `recall-server`, each recorded under their own subject, and neither can read or write outside the namespace their credential scopes them to. Demonstrated with two credentials against a running server, not inferred from the auth package |
| AC-8 | Ingested content can be deleted on request | A shipped command removes ingested content and writes deletion evidence that survives the removal. Run end to end: ingest, delete, confirm absent, read the evidence back |
| AC-9 | Concurrent use does not lose or refuse writes | recall's store carries connection-string pragmas and busy-retry equivalent to the staged store's, demonstrated by two concurrent processes against one store completing without a locked-database error or a lost write |

**Which phase publishes the artifacts AC-1 and AC-3 are checked against?** Neither is
published by a phase of this goal. **AC-1 and AC-3 are checked against artifacts published by the production-readiness goal's P5** — that is, `cli-v0.7.5`, `v0.14.4` and `v0.3.3`. They exist at charter: `cli-v0.7.5`, `v0.14.4` and `v0.3.3` are all released and green, and
P1 and P2 change documentation rather than code. `install.sh` is fetched from `main`,
so a documentation fix reaches a colleague without a release.

That stops being true at P3. Wiring cadre to `recall-server` changes shipped code, so
**P3, P4 and P5 each owe a release before their criteria can be verified against an
installed artifact** — verifying them from a checkout would be the exact position this
goal exists to leave. Run `ci-status.sh` against the commit before tagging it, not only
before the gate.

**AC-6 is the criterion most at risk of a generous reading.** "Verified" is met when the value cannot be chosen by the caller at the moment of the call. An environment variable the caller also sets is not verification; neither is comparing two strings the caller supplied. The existing `observed_actor` is written and never consulted by any check — writing it more places would satisfy the words and not the criterion.

**AC-1 is the only criterion a person other than the author can run**, and it is first for that reason. Everything else is checkable from a machine that already has everything, which is the position that cannot see an onboarding defect. The container run is the harness's substitute for a colleague; handing it to an actual colleague and watching is the confirmation no automated check replaces.

## Phases

| Phase | Scope | AC | State |
|---|---|---|---|
| P0 | Measure the baseline from a clean machine before committing to criteria | — | **done** |
| P1 | The first hour: prerequisites, the authentication path, front pages that route | AC-1, AC-2, AC-3 | pending |
| P2 | The map: one document explaining the three, a glossary, and the false claims corrected | AC-4, AC-5 | pending |
| P3 | Identity: wire cadre to `recall-server` and derive the actor from its authenticated subject | AC-6 | pending |
| P4 | Two people on one store, and concurrency that survives them | AC-7, AC-9 | pending |
| P5 | Deletion of ingested content, with evidence | AC-8 | pending |

**Documentation first, before any code, chosen at charter.** It is days rather than weeks, it unblocks a colleague immediately, and it makes every later phase testable by someone other than the author — which is the only honest test of whether a person who is not the author can use this.

**P3 before P4 and P5** because both depend on it. A shared store without per-caller identity is a worse position than a local one, and deletion evidence naming an unverified actor is the defect AC-6 exists to close, reproduced in a new place.

## What would falsify this goal

That a colleague, handed the three repositories and their documentation, fails to reach working software without asking the author a question. Every criterion above is a specific way that happens; AC-1 is the general case.

## Traceability

| AC | Phase | Evidence | Status |
|---|---|---|---|
| AC-1 | P1 | evidence/P1/ CP-3v, CP-5, CP-6 | verified |
| AC-2 | P1 | evidence/P1/ CP-3v, CP-5 | verified |
| AC-3 | P1 | evidence/P1/ CP-3v, CP-5, CP-6 | verified |
| AC-4 | P2 | evidence/P2/ CP-3v, CP-4, CP-5 | verified |
| AC-5 | P2 | evidence/P2/ CP-3v, CP-4, CP-5 | verified |
| AC-6 | P3 | evidence/P3/ CP-3v, CP-4, CP-5 | verified |
| AC-7 | P4 | evidence/P4/ CP-3v, CP-4, CP-5 | verified |
| AC-8 | P5 | evidence/P5/ CP-3v, CP-4, CP-5 | verified |
| AC-9 | P4 | evidence/P4/ CP-3v, CP-4, CP-5 | verified |

## Checkpoint log

| CP | Phase | Verdict | Note |
|---|---|---|---|
| CP-1 | P0 | — | charter |
