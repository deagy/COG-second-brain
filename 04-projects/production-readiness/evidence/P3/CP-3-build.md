# P3 — CP-3 build · AC-4

| Task | Outcome | Artifact |
|---|---|---|
| T-01 | `platform.ObservedActor` — an identity source no flag can set | cadre `0c5c50ae` |
| T-02 | `observed_actor` recorded beside the asserted fields | same |
| T-03 | Both recorded on every deletion, neither able to overwrite the other | same |
| T-04 | The observation surfaced where the record is read and where it is made | cadre `b174bfea` |
| T-05 | `SECURITY.md` restated, including what did **not** change | same |

CI run 33637679330 green at `b174bfea`.

## What "derived" honestly means here, and what it cannot

The plan's constraint was the spec's own warning: *an environment variable the caller also sets is not verification.*

Nothing on a single-operator machine is unforgeable. `git config user.email` is a file the caller owns; `$USER` is a variable they set. So the target was never an identity that cannot be faked — with one operator there is nobody to impersonate, and building an auth system would be inventing a requirement the bar explicitly does not have.

**The target was a record that cannot present an assertion as an observation.** A deletion now reads:

```
deleted_by (asserted): claimed-name
observed_actor       : os:deagy git:daniel.eagy@sqs.world
```

Two fields, stored separately, neither able to overwrite the other. The OS user comes from `os/user.Current()` — process credentials, not `$USER`. The git identity is recorded as *context rather than proof*, because it is a file the caller owns. Every rendering carries its source prefix so it cannot be read as a name in a log line.

## Falsified both ways, and the first attempt was not good enough

| Mutation | Result |
|---|---|
| Observed user falls back to `$USER` | fails `TestTheObservedUserIgnoresTheEnvironment` |
| Observation echoes the asserted value | fails `TestAnAssertedActorDoesNotReplaceTheObservedOne` |

The second mutation initially broke the **build** — an unused import — which proves the call exists, not that the test detects a substitution. Rewritten to compile, it fails on the assertion that matters: *"the observation equals the assertion"*. A falsification that cannot fail is the same defect as a guard that cannot fail, one level up.

## The restraint in T-05 is the deliverable

`SECURITY.md` is the document that made the honest claim in the first place. The temptation on landing an identity change is to soften it. It now says three things, and the third is the one that matters:

- caller identity is **still** absent;
- what is observed, how it renders, and that no flag sets it;
- **`observed_actor` does not change the self-approval conclusion.** It is recorded on deletion, consulted by no check, and a comparison between two asserted names is exactly as strong as it was.

The original sentence — *"production integration must derive `staged_by` and `decided_by` from authenticated claims"* — still stands, because it is still true. What exists makes a wrong record **legible afterwards, not impossible at the time**.

## What was deliberately not done

`staged_by` and `decided_by` are unchanged. They live in record frontmatter and in `staged_record_dispositions`, and observing them would mean a schema change on two more tables for a criterion whose value is concentrated in deletion — the one act that destroys its own subject and leaves only the evidence row behind. Recorded rather than skipped silently: **AC-4's wording covers four flags, and this covers the deletion path.** Whether that satisfies the criterion is CP-3v's call, not the builder's.
