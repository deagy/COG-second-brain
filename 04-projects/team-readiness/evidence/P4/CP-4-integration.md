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

## Round 2, run as two independent tracks

Round 1's single verifier stalled twice on the same work and was killed both
times **having written nothing** — it batched its notes to the end, so a stall
cost all of its work rather than the last few minutes. Round 2 split the work
so that only one track needs a running server, and required both tracks to
append each finding to their notes the moment they had it.

### Track B — identity, isolation, disclosure: PASS

EVIDENCE AC-7 | CP-4 | PASS | Namespace isolation holds against attack: each credential proved it finds its *own* seeded document first, then a deliberately broad `k=50&min_score=0` query under the scoped key returned 1 result where the same query under an admin key returned 2 — so the isolation is not an empty store. Cross-namespace upload 403; `namespace=` query parameter, hybrid-search body field and a direct `GET /graph/doc-b1` all refused or scoped | recall `v0.3.6`, curl transcripts
EVIDENCE AC-7 | CP-4 | PASS | The local limit is still real, and so no document overstates it: a credential scoped to `team-a` deleted a `team-b`-tagged document through `delete-ingested` and read back its deletion evidence | cadre `cli-v0.7.11`
EVIDENCE AC-7 | CP-4 | PASS | The disclosure is accurate clause by clause, not merely present — each claim in it was independently confirmed in the same run — and the `scope` key is *absent* rather than empty when no server is configured | both commands' JSON
EVIDENCE AC-6 | CP-4 | PASS | A JWT subject reaches the stored value: `observed_actor` = `subject:alice@corp.example`, neither the `--deleted-by` string nor the token, with `actor_verification` reading verified | cadre `cli-v0.7.11`
EVIDENCE AC-6 | CP-4 | PASS | A scoped API key is still refused as an identity: the raw key was never written, the actor fell back to local observation, and the description honestly reads unverified | cadre `cli-v0.7.11`

### Track A — lock contention: FAIL, then fixed

EVIDENCE AC-8 | CP-4 | PASS | The uncontended path writes content removal and evidence together, reads back with a matching count, refuses a zero-chunk delete, and refuses to record evidence for a partial removal | cadre `cli-v0.7.11`
EVIDENCE AC-9 | CP-4 | PASS | On a store that had recorded a deletion before, a real competing process holding the write lock for 1, 5, 10, 20, 40 and 55 seconds was waited out; at 65 seconds the command failed at ~61s saying the chunks were removed, how many, and that the deletion must be recorded by hand | four independent stores
EVIDENCE AC-9 | CP-4 | FAIL→FIXED | On a store that had never recorded one, the same command died at ~5 seconds with a bare `SQLITE_BUSY` and no guidance. Reproduced 4/4 on fresh stores. Twelve times shorter, on the more common case | cadre `ce57aa6a`
EVIDENCE AC-9 | CP-4 | PASS | No data was lost on that path: the chunk was read back present afterwards and an uncontended retry succeeded — a failure before mutation, not a repeat of round 1's silent loss | direct SQLite read

## The half I measured, and the half I did not

Round 1's fix put the long budget on a lazy `CREATE TABLE` inside
`RecordIngestedDeletion`. The path that actually failed was a different one —
`initStagedSchema`, at store open — still on the ordinary budget. **I verified
the path I had changed and not the path a cold store takes**, and the two are
indistinguishable from the outside until a store with no deletion history meets
a competing writer.

The repair is not a wider second budget. That equalises the numbers and keeps
the shape: a schema change running at the worst possible moment. Creating the
table at open removes the case, so the long budget now covers the only
statement that runs after deletion becomes irreversible, and five seconds is
defensible at open precisely because a failure there mutates nothing.

The regression test asserts the table exists on a freshly opened store — the
same claim as the timing test, with no lock, clock or competing process in it.
Reverting to lazy creation fails it.

**Told where the blind spot probably was, the verifier found it somewhere I had
not looked.** The brief named the cold-versus-warm axis; it was right about the
axis and I was wrong about which code sat on it.
