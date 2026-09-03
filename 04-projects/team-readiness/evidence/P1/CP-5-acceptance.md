# P1 — CP-5 acceptance (AC-1, AC-2, AC-3)

EVIDENCE AC-1 | CP-5 | PASS | A clean `node:22-bookworm-slim` container, no `~/sdk`, following only cadre's published documentation: `apt-get` the stated prerequisites, `curl … | sh`, the `PATH` entry, then `cadre select --task "smoke test" --files README.md --task-id SMOKE-1` — exit 0 with valid JSON | CP-3v, container transcript
EVIDENCE AC-1 | CP-5 | PASS | recall's documented release path run literally: download `recall-0.3.4-linux-arm64`, verify against `checksums-sha256.txt` (`OK`), `chmod +x`, `--help` — all exit 0, no Go toolchain involved | CP-3v
EVIDENCE AC-1 | CP-5 | PASS | The kernel README's five "Using it" commands, copy-pasted in order from an unrelated working directory with no `cd` into the project, all exit 0 with no `"error"` key. Round 1 failed here: `--root` was carried by `detect` and `init` and not by `plan` and `status`, and the block only worked from inside the project | CP-3v rounds 1 and 2
EVIDENCE AC-2 | CP-5 | PASS | `docs/INSTALL.md` states `curl`, `git`, Python 3.10+, network egress and the `PATH` entry at lines 6–13, before the first command at line 30; the `PATH` step is flagged "before you install, not after"; the Authentication section precedes Verifying. recall states Go 1.26.5 before both `go get` and the source build | CP-3v
EVIDENCE AC-3 | CP-5 | PASS | Fetched as an outsider sees them (`gh api repos/<r>/readme`): cadre's "Choose your path" table opens with an install row; cadre-kernel has a `README.md` where it had none; recall has an `## Install` section naming `recall` and `recall-server` and `checksums-sha256.txt`. All three carry a non-empty GitHub description | CP-3v
EVIDENCE AC-3 | CP-5 | PASS | Every release asset the documents name exists: kernel `v0.14.4` ships `agentic-sdlc-v0.14.4-{os}-{arch}` plus `SHA256SUMS`; recall ships `recall-*`, `recall-server-*` and `checksums-sha256.txt` | CP-3v

## The authentication finding, corrected in the phase that inherited it

P0 recorded "no headless path documented" and inferred none existed. One does —
`ANTHROPIC_API_KEY`, `claude setup-token`, and `claude auth status` as the check
— so T-01 documented a path rather than recording a blocker. An accurate
observation with a wrong inference attached, and writing the inference into the
work would have sent the phase chasing a problem nobody has.
