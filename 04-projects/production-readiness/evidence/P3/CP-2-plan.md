# P3 — CP-2 plan · AC-4

**AC-4:** every command accepting `--staged-by`, `--decided-by`, `--deleted-by` or `--authorized-by` derives the value from a verifiable local source, or refuses to run. The evidence row it writes carries the derived value, and a caller-supplied override is either rejected or recorded as unverified.

## What "derived" can honestly mean here

The spec's own warning is the constraint: *"an environment variable the caller also sets is not verification. The criterion is met when the value cannot be chosen by the caller at the moment of the call, or the command says plainly that it was."*

Nothing on a single-operator machine is unforgeable. `git config user.name` is a file the caller owns; `$USER` is an environment variable. **So the honest target is not an identity that cannot be faked — it is a record that cannot present an assertion as an observation.**

Two fields, not one:

- **observed** — what the process could see without being told: the OS user, and the git identity configured for the repository it ran in. Recorded always, never supplied by a flag.
- **asserted** — what the caller passed. Recorded when given, and labelled as claimed.

A record then answers "who did this" with both, and a reader can tell which half the system stands behind. That is the whole win for one operator: today a deletion record names a string, and afterwards it names a string *plus what the machine saw*.

`--authorized-by` is the case that matters most, because it names a **second** person vouching for a decision. It is asserted by construction — the authorizing human is not at the keyboard. It must stay recordable and must never read as observed.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | An identity source: OS user + git identity, resolved once, no flag can set it | AC-4 |
| T-02 | Record `observed` alongside every existing actor field, in the tables that already store them | AC-4 |
| T-03 | Every command accepting an actor flag records both, and labels the asserted half | AC-4 |
| T-04 | `show-staged` and `deletion-evidence-staged` surface both, so the distinction is visible where the record is read | AC-4 |
| T-05 | `SECURITY.md` restated: what is now observed, what remains asserted, and what that still does not give | AC-4 |

## What would falsify this phase

**Deriving the actor and then letting a flag override it silently.** If `--deleted-by alice` replaces the observed value rather than sitting beside it, the record is exactly as unverified as before and now looks authoritative. The override must be additive or refused.

**Calling `$USER` verification.** It is an environment variable; a caller who sets it chooses the value. Whatever is recorded as observed must come from a syscall or a file the command did not take from the caller's environment — `os/user.Current()`, not `os.Getenv("USER")`.

**Claiming this closes the separation-of-duties gap.** It does not. `SECURITY.md` says two of the four checks compare caller-asserted strings, and after this they compare caller-asserted strings *recorded beside an observation*. That is strictly better evidence and the same enforcement. The document has to keep saying so.

## Not in scope

Authentication. There is no identity provider, no tenant, and one operator; building one would be inventing a requirement the bar explicitly does not have. The spec's own framing: with one caller there is nobody to impersonate, and what breaks without this is the evidence trail.
