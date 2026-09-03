# P3 — CP-3 build

Five of six tasks built across two repositories. T-06, the release, waits on CI.

## The chain, end to end

```
recall-server authenticates a credential
        │
        ▼  GET /whoami  (recall 1752d29)
reports the subject it decided that credential names
        │
        ▼  ResolveActorObserver  (cadre da77a3fb)
cadre records  subject:<x>  instead of  os:deagy git:…
        │
        ▼  DispositionStagedRecord  (cadre 91de0130)
refuses when the same subject stages and approves
```

**Without the middle link the whole thing was decorative.** `/whoami` did not
exist: the server resolved a subject into the request context and never told
the caller, so cadre could hold a credential and still only know what it had
sent — not what the server decided that meant. The `subject:` branch of the
check would have been unreachable, which is a guard that cannot fail, which is
the defect this project keeps finding in other people's work.

## T-05 first, and it failed as it should

The guard was written before any fix existed and reproduced the defect exactly:

```
staged_by   "alice@example.com"   observed_actor "os:deagy git:test@example.com"
decided_by  "bob@example.com"     observed_actor "os:deagy git:test@example.com"
→ accepted
```

## T-03: the check, and the decision it forced

Comparing observed actors unconditionally worked, and broke 18 existing tests
— every one of them staging and dispositioning from a single process, which is
exactly what one operator does today by typing two names.

That is not a fixture problem. It is AC-6 and AC-1 pulling against each other:
the criterion wants a verified actor, and P1 just closed a criterion saying the
local path keeps working. **Put to the user rather than decided here**, and the
answer was to enforce only where identity is verified.

So the check distinguishes two kinds of observation:

| Observation | Means | Enforced |
|---|---|---|
| `os:deagy git:…` | which *machine* acted. The caller owns the OS user and git config alike | no |
| `subject:alice@corp` | what a server decided a presented credential names | yes |

A local store cannot produce the second and is not asked to. What it must not
do is present the first as though something checked it — so `show-staged` now
reports `actor_verification` saying, at the point of use, that the observed
actor records which machine acted and not which person.

## T-01, T-02: the wiring

A knowledge config gains an optional `server` block: a URL and the **name** of
an environment variable holding the credential, never a value. Config files
here already refuse secret-shaped keys outright, so a token in a committed or
synced file is prevented by construction.

Three fallbacks, each deliberate and each tested:

- **No server** — today's local observation, unchanged.
- **Configured but unreachable** — warn, fall back. Refusing to stage a record
  because a server is down trades a real capability for an attribution
  guarantee nobody asked for at that moment.
- **A server authenticating nobody** — not a subject.

None may record a local observation as though something confirmed it, which is
why the two kinds differ by prefix rather than by the reader's diligence.

## Falsification

| Mutation | Result |
|---|---|
| identity comparison disabled | alice/bob guard fails; both over-refusal guards still pass |
| `/whoami` reports a constant instead of the request's subject | 3 of 4 endpoint tests fail, including the two-credential one |
| two credentials against one server | two different subjects — proves the answer is the server's, not the caller's |

## A defect CI found that no single repository could

recall's build went red on a file in **cadre**. recall checks cadre out into
`.cadre-origin/` for its fail-closed contract guard and runs `gofmt -s -l .`
across the result; cadre's own CI ran plain `gofmt`. Simplification differences
passed in cadre and failed in recall, surfacing in the repository that did not
write the file. Both now check `-s` (cadre `5582d42c`).

Worth recording because it is the shape this goal exists for: a property that
only becomes visible when a second consumer exists, which is the whole
difference between one operator and a team.

## Commits

| Repo | Commit | What |
|---|---|---|
| recall | `1752d29` | `GET /whoami` |
| cadre | `91de0130` | the identity check, the guards, `actor_verification` |
| cadre | `da77a3fb` | server config, `ResolveActorObserver`, the wire |
| cadre | `5582d42c` | `gofmt -s` symmetry |

T-06 remains: a release, so AC-6 is verifiable against an installed artifact
rather than a checkout — the position this goal exists to leave.
