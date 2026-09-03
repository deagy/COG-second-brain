# P3 — CP-5 acceptance (AC-6)

Every row observes a released artifact. The criterion took three verification
rounds and each found a different reason the mechanism was unreachable, so the
rows that matter are the ones from the round that could finally run the
sequence the criterion names.

EVIDENCE AC-6 | CP-5 | PASS | Against released `cli-v0.7.9` and `recall-server v0.3.6` in JWT mode, both checksum-verified: staging a record as `alice@example.com` and dispositioning it as `bob@example.com` from one process under a single JWT credential is refused — *"the same authenticated subject (alice@example.com) staged this record and is dispositioning it … this compares the credential each command authenticated with, not what the caller typed"*. Refusal on identity, not on string inequality | CP-3v round 3, `/tmp/claude-1000/p3-cp3v-r3.md`
EVIDENCE AC-6 | CP-5 | PASS | The same sequence under two *different* JWT credentials, with the same asserted names, is allowed — so the check distinguishes people rather than refusing everything | same
EVIDENCE AC-6 | CP-5 | PASS | The caller cannot choose the recorded subject. With an API-key server, whose `/whoami` names the credential itself, cadre refuses to persist it and falls back to the local observation; `grep -r key-alice` across the whole store tree found zero matches, so the credential appears nowhere in the record or the audit log | CP-3v round 2
EVIDENCE AC-6 | CP-5 | PASS | The local path is unchanged and says what it is: with no server configured, one process may still stage and disposition under two typed names, and `show-staged` reports `actor_verification: "unverified: the observed actor is this machine's OS user and git config, which the caller owns"` | CP-3v rounds 2 and 3
EVIDENCE AC-6 | CP-5 | PASS | Malformed configuration fails closed rather than being ignored: `{"server":"not-an-object"}` exits 1 naming the type, and `api_key_env` with no `url` exits 1 with *"a credential with nowhere to send it authenticates nothing"* | CP-3v round 2

## What the three rounds cost, and why it is recorded here

Round 1: `LoadConfig` never parsed the `server` block, so the branch could not
be reached from a released binary. My three tests passed because they built
`&Config{Server: …}` in Go — they proved the function worked and nothing about
whether anything could call it.

Round 2: cadre refused to persist a credential-as-subject, correctly, and that
closed the API-key path — while the JWT path, the one the refusal message
directs operators to, was never reached because cadre sent only `X-API-Key`
and recall's JWT authenticator reads only `Authorization: Bearer`.

Round 3: PASS.

Each round's method found what the previous one structurally could not, which
is the argument for a fresh verifier over a second pass by the author.
