# P1 — CP-2 plan

**The first hour.** Everything a colleague hits between deciding to try this and
doing something useful. All of it is documentation and repository metadata; no
shipped code changes, which is why it needs no release (spec § *Which phase
publishes the artifacts*).

## What P0 observed, and what it means for the plan

P0 installed into a clean container as someone who had never seen the
repositories. The failures, in the order they arrive:

| Observed | Task |
|---|---|
| `curl`, `git`, `python3` absent; the documented first command cannot be typed | T-02 |
| `cadre` not on `PATH`; the note is printed *after* install, and the next documented step fails | T-02 |
| `Not logged in · Please run /login`, an interactive OAuth flow, documented nowhere | T-01 |
| A bad key hangs silently for 90+ seconds and exits `0` | T-01 |
| cadre's "Choose your path" table links six documents, none of them the install guide | T-03 |
| cadre-kernel has no `README.md` — the repo front page is blank | T-04 |
| recall has no installation section, and never mentions its released binaries | T-05 |
| cadre and recall have no GitHub description | T-06 |

**The authentication finding changed on investigation, and that changes T-01.**
P0 recorded the symptom — an interactive login wall with "no headless path
documented" — and inferred no headless path exists. It does. `claude --help`
states that in simple mode *"Anthropic auth is strictly `ANTHROPIC_API_KEY` or
`apiKeyHelper` via `--settings`"*, there is a `claude setup-token` subcommand
for subscription users, and `claude auth status` reports what is in effect.

So T-01 documents a path that exists rather than recording a blocker. The
distinction matters: P0's evidence was an accurate observation of a symptom and
a wrong inference about its cause, and writing the inference into a criterion
would have made the goal chase a problem nobody has.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Document authentication in `docs/INSTALL.md`: the three paths (`ANTHROPIC_API_KEY`, `claude setup-token`, interactive `claude auth login`), `claude auth status` as the check, and that an invalid key hangs rather than failing | AC-1, AC-2 |
| T-02 | State every prerequisite before the command that needs it — `curl` to fetch the installer at all, `git`, Python 3.10+, the `PATH` entry as a step rather than an after-the-fact note, and required network egress | AC-2 |
| T-03 | cadre's README "Choose your path" table gains an install route as its own row | AC-3 |
| T-04 | cadre-kernel gains a `README.md` at the repository root | AC-3 |
| T-05 | recall gains an installation section naming its released binaries and the Go version a source build needs | AC-2, AC-3 |
| T-06 | Set the GitHub description on cadre and recall | AC-3 |

Six tasks, so CP-4 is owed.

## How each is falsified

- **T-01, T-02** — the AC-1 container run. A clean container, following only the
  published documentation, with nothing supplied from outside it. If the run
  needs a step the docs do not state, the task failed regardless of what the
  documents now say.
- **T-03, T-04, T-05** — fetch each repository's front page as an outsider sees
  it (`gh api repos/<r>/readme`), not the local checkout, and confirm a
  newcomer is routed to an install path within it.
- **T-06** — `gh repo view --json description` returns a non-empty value.

**T-05 carries the risk of being satisfied narrowly.** recall's release assets
are real and already published; the criterion is that the README *names* them,
so a reader knows they exist. Adding a `go build` line would satisfy "has an
installation section" and leave the original defect — a newcomer compiling from
source because nobody told them binaries exist — exactly where it was.
