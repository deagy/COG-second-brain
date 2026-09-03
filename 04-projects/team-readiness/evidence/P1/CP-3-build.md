# P1 — CP-3 build

Six tasks, three repositories, no shipped code changed. All three suites green
and cadre's generated `plugin/` tree regenerated and in step.

## T-01 — authentication (cadre `docs/INSTALL.md`)

A new **Authenticating your runner** section, placed before *Verifying* because
that is where a reader arrives having installed successfully and about to fail.

**P0's inference was wrong and the plan says so.** It recorded "no headless path
documented" and concluded none exists. `claude --help` states that in simple
mode *"Anthropic auth is strictly `ANTHROPIC_API_KEY` or `apiKeyHelper` via
`--settings` (OAuth and keychain are never read)"*, there is a `claude
setup-token` subcommand for subscription users, and `claude auth status` reports
what is in effect. Three paths, tabled by situation, with the simple-mode
sentence quoted for the container and CI case.

The silent hang is documented as a symptom with its diagnosis: *"An invalid or
expired key does not produce an error. It hangs… If a first task produces
silence rather than a refusal, check the key rather than the installation."*
That is the failure a colleague cannot diagnose alone, and it costs two lines.

The section opens by saying installing Cadre does not sign you in and nothing
Cadre does can — the runner holds its own credentials. A reader who believes the
installer should have handled it stops looking in the wrong place.

## T-02 — prerequisites before the command (cadre `docs/INSTALL.md`)

A table immediately under the front matter, before the first command rather than
after it, naming `curl`, `git`, Python 3.10+, network egress to `github.com`,
and the `PATH` entry, each with the check that confirms it.

Two things P0 hit are stated explicitly. **`curl` is needed to fetch the
installer at all** — a chicken-and-egg the old text could not have surfaced,
because it described what `install.sh` needs after you have run it. And the
`PATH` entry is now a step you take *before* installing, with both shell forms,
rather than a note the installer prints when it finishes and a reader skips.

## T-03 — cadre's front page routes to install

`README.md`'s "Choose your path" table gains a first row linking
`docs/INSTALL.md`. It previously listed six destinations, none of them the
install guide; its only two links to that file sat further down inside a
runner-comparison table, scoped to individual runners rather than labelled as
how to install.

## T-04 — cadre-kernel gains a `README.md`

The repository had none: an outsider arriving directly saw a blank front page.
The new file states what the kernel is, that it records and validates rather
than driving, how to install from a release with checksum verification, what is
in the repository, and where the full reference lives.

**Four claims in the first draft were false, and running them is what found it.**

- `--profile secure-cloud`, copied from cadre's own documentation, returns
  `{"error": "unknown profile: secure-cloud"}`.
- `--profile quick`, which `detect` *proposes*, is equally unknown to `init`.
- The reason is that **the kernel bundles no provider**: `agentic-sdlc profile
  list` returns `[]` on a bare install.
- So the documented `validate` example was wrong too — a standalone kernel
  returns `1` with `"project profile is not installed"`, not the `0` or `2` the
  exit-code paragraph implies.

The section now shows only what the binary can do alone, and states plainly that
`validate` needs a provider that cadre contributes. Both quoted strings —
`[]` and `"project profile is not installed"` — are the binary's verbatim
output, and every command in the file was executed: `show-contract`, `detect`,
`init --dry-run`, `plan`, `status`, `profile list`, all exit 0.

**cadre's docs use `--profile secure-cloud` too, and there it is correct.**
Checked before assuming otherwise: `cadre sdlc profile list` returns
`["generic", "secure-cloud"]`, because cadre *is* the provider that supplies
them. Nine live cadre documents use the flag and none of them is wrong.

The defect was mine and was specific to context — a profile name lifted from a
document about cadre into a document about the kernel standalone, where no
provider exists. Recording this because the first version of this note said
cadre carried "the same false example", which would have sent P2 to correct
nine documents that are telling the truth.

## T-05 — recall gains an Install section

recall's README had no installation section at all; its only build instruction
sat inside the CLI section, presupposing a clone nobody mentioned and a Go
toolchain with no version. It never named the prebuilt binaries that exist.

The new section separates the three cases — library, prebuilt binary, source
build — and says which needs Go. It names `recall-server` alongside `recall`,
because both ship in every release and the second is the one nobody knew was
there. Asset names, the `checksums-sha256.txt` filename, the `--server` flag and
the `go 1.26.5` directive were each checked against the release and the tree
rather than written from memory.

## T-06 — GitHub descriptions

cadre and recall had none; the kernel already did. Set via `gh repo edit` and
re-fetched afterwards rather than trusting the command's return.

## Checks

| Check | Result |
|---|---|
| cadre `generate-plugin --check` | current |
| cadre `go test -tags sqlite_fts5 ./...` | exit 0 |
| cadre-kernel `go test ./...` | exit 0 |
| recall `go test ./...` | exit 0 |
| Every command in the new kernel README | executed, all exit 0 |

Local exit codes are evidence about this machine. CI at the pushed commits is
CP-5's to record with run ids.

---

## CP-3v round 1: FAIL:fixable, and the finding was in this phase's own new file

The verifier ran cadre-kernel's new "Using it" block the way a reader would —
copy-pasted in order, from one location, one project path — and needed a step
the document did not state.

```
detect --root $PROJ    ok
init   --root $PROJ    ok
plan   --task-id T-1 --task "..."
  {"error": "open /work/.agentic-sdlc/project.json: no such file or directory"}
status --task-id T-1
  {"error": "open /work/.agentic-sdlc/runs/T-1/run-record.json: no such file or directory"}
```

`--root` is not sticky. `plan` and `status` accept it and I had not passed it,
so they read the working directory instead. **It worked in my own testing
because I had `cd`-ed into the project without noticing**, which is the whole
reason a fresh pair of eyes runs this rather than the person who wrote it.

Fixed at `381b2bb`: every command in the block carries `--root`, and the
paragraph beneath states that the flag is not sticky and quotes the error a
reader gets when they mix the two forms. Re-run literally from an unrelated
directory, all five commands complete without an `"error"` key.

**This phase exists to close exactly this defect, and the phase committed it.**
Worth stating plainly rather than filing as a fix: writing a command sequence
and running a command sequence are different acts, and only the second is
evidence.

## Noted, not fixed here

`plan` and `status` **print an error object and exit `0`**. A script checking
the exit code sees success:

```
$ agentic-sdlc plan --task-id T-1 --task x   # from the wrong directory
{"error": "open .../project.json: no such file or directory"}
$ echo $?
0
```

That is a code defect, not a documentation one, and P1 is documentation-only by
charter — fixing it would oblige a release this phase does not owe. Carried to
CP-7 for disposition rather than absorbed silently.

---

## CP-4: two rounds, one defect, and a method that had to change

**Round 1 — FAIL:fixable.** cadre's `README.md` asserted both that the lifecycle
kernel is in-tree and, further down the same file in bold, that it is not.
CP-3v could not have found this: it checks each document against its criterion,
and each half of a contradiction passes on its own. Only reading documents
against each other surfaces it.

The cause was a partial remediation of my own. An earlier commit fixed every
document that told a reader to *install* a kernel from this repository, and
touched none that said the kernel *lives* here — an adjacent concept, which is
what AI-16 says to enumerate by.

**Round 2 — FAIL:fixable again, nine more instances across five files**, three
of them in files the round-1 fix commit claimed to have addressed. Same cause:
I widened the pattern rather than changing how the enumeration was built.

**Round 3 inverted the method.** The enumeration is now generated from the tree
rather than from a guess about wording: every markdown link target and every
backticked path in every live document, resolved against the filesystem.
`kernel/` does not exist, so a document placing the kernel here necessarily
names a path that is not there. That is AI-25's shape — generate the expected
state from the source of truth instead of parsing prose for it — and it is the
same inversion that ended P6's three-round loop.

It found **114 dead references across 492 live files**, of which kernel-location
claims are one class. Fixed at `1e611426`: `docs/INSTALL.md`,
`docs/adopt-cadre-quickstart.md`, `README.md`, `CLAUDE.md` (two sites),
`roster/RUNBOOK.md` (two sites), `cline-plugins/cline-lifecycle/README.md`.
Confirmed by a check that counts and exits rather than one a person reads.

### What this hands to P2

75 of the 114 sit in documents that are records by nature, where a dead path is
correct *as history*:

| Document | Dead refs |
|---|---|
| `CHANGELOG.md` | 23 |
| `PYTHON_ELIMINATION_PLAN.md` | 15 |
| `docs/proposals/` | 10 |
| `ADR-001-CLI-GO-REFACTOR.md` | 8 |
| `DISPATCH_CORE_ROADMAP.md`, `CADRE_CLI_GO_ARCHITECTURE.md` | 10 |
| `roster/knowledge-store/proposed-knowledge/` | 5 |
| `docs/migration/` | 4 |

So AC-5 is mostly a bannering decision and roughly 39 live fixes, not 114 edits
— and the script belongs in the repository as the criterion's instrument rather
than staying a scratch tool.

### Two errors of my own worth recording

- **A verification echo that printed `(none above = gone)` unconditionally.**
  A check that cannot fail, written by the session that has spent all day
  building checks that can. The replacement counts and branches on the count.
- **A CI failure I nearly attributed to a markdown change.** `cline-lifecycle`'s
  suite went red at `abb55f4c`; the log showed `Test timed out in 5000ms` in a
  case that shells out to the kernel binary, with 46 of 47 passing. Re-run
  rather than assumed either way.
