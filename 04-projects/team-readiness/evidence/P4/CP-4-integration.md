# P3 + P4 + P5 — CP-4 integration verify

One verification across three phases, because the question spans them and sits
inside none: P5's deletion evidence takes its actor from the resolver P3 built,
and P4's namespace scoping decides whether two people sharing that store can
reach each other's records.

**It should have run before the phases were called built, and did not.**
`STATUS.md` said this verification was running. There was no row and no file, so
`phase-gates.sh` reported all three as never having run CP-4 — the correct
report. This is the failure the ultragoal skill records from the
capability-parity goal, repeated: an absent checkpoint leaves the same evidence
bundle behind as a clean one.

Round 1 returned FAIL:fixable on two findings, both cross-phase, both passed
over by every per-phase check.

## Round 1 evidence

EVIDENCE AC-6 | CP-4 | PASS | JWT-authenticated identity is reachable on the real deletion path against released `cli-v0.7.9` and recall-server `v0.3.6`: `observed_actor` = `subject:alice@example.com`, `actor_verification` = "verified" | verifier transcript
EVIDENCE AC-6 | CP-4 | PASS | A scoped-key credential, where subject equals credential, is refused by the resolver and falls back to local observation with an accurate warning and an accurate "unverified" description. The trail never claims verified while storing unverified | verifier transcript
EVIDENCE AC-7 | CP-4 | PASS | Namespace isolation holds on recall-server's HTTP layer with distinct content seeded under each of two credentials, so "found nothing" could not be satisfied by an empty store. Cross-namespace upload is refused 403 | verifier transcript
EVIDENCE AC-7,AC-8 | CP-4 | FAIL→FIXED | `delete-ingested` and `deletion-evidence` open the SQLite file directly and never reach recall-server, so a scoped credential does not scope them: alice's team-a credential deleted bob's team-b document, and bob's credential read alice's deletion of his own content. Reproduced on released binaries | cadre `68095d81`
EVIDENCE AC-9,AC-8 | CP-4 | FAIL→FIXED | The evidence INSERT had no busy-retry. Reproduced with two real concurrent processes: content removed, evidence INSERT lost the lock, command exited 1, zero evidence rows. Content gone, evidence absent | cadre `68095d81`
EVIDENCE CI | CP-4 | PASS | cadre at `f81f8ec1` (`cli-v0.7.9^{commit}`) and recall at `cbccb179` (`v0.3.6^{commit}`) both green. The verifier peeled the annotated tags rather than using the tag-object sha, which is the difference between checking the release and checking a tag | gh run list

## The scoping finding

Not a bug in the scoping, which holds where it was built: on recall-server's
HTTP path, under attack, P4 verified it. It is a property of where cadre's
deletion path sits — beneath the server, in the file.

The charter already decided this one: AC-7 was scoped to what was built and the
limit stated plainly. `docs/the-three-repositories.md` says it, and says it was
demonstrated with two credentials against the released binaries — a claim CP-4
has now made true rather than merely plausible.

What was wrong is where it was written. The limit lived in a source comment and
in a document, and nowhere a colleague configuring a scoped key would meet it.
`delete-ingested` and `deletion-evidence` now say it in their own output when a
server credential is configured.

## The lost-evidence finding, and why the first fix was not one

The reading that suggests itself — the INSERT lacks the retry the schema
creation beside it has — produces a change that does nothing. The connection
string already sets `busy_timeout(5000)`, so the driver blocks for the whole
budget inside the first `Exec` and the retry loop finds its deadline spent.
**A retry whose budget is consumed before its first check is decoration.**

The budget is the fix. Evidence gets its own, twelve times the ordinary one,
because the two answer different questions: an ordinary write that loses a race
can be re-run, and this one cannot — the content it describes is already gone,
and re-running refuses because there is nothing left to delete.

**I know that only because the test failed to tell my mutations apart.** It
passed with the longer budget removed, passed again with the retry removed
entirely, then failed on unmodified code. That signature — a guard surviving the
mutations it exists to catch — named the third defect: `CREATE TABLE IF NOT
EXISTS` is the first statement to want the lock on a fresh store, so it absorbed
the contention, and which call failed depended on whether an earlier command had
made the table.

The test now isolates the INSERT by pre-creating the table, and holds the lock
past two attempts, because the loop checks its deadline only after a blocking
`Exec` and so always gets a second one. Both mutations fail, twice each.

Two wrong theories before the right one, and falsification is the only reason
any of them were distinguishable.

## Round 2

Pending: re-verification against the release cut from `68095d81`.
