# P5 / AC-11 — the split pipeline runs end to end

> "A plan from `cadre select` is accepted by an installed released kernel's `agentic-sdlc validate` (exit 0), with that kernel wired to cadre's provider bundle."

Both halves observed. The kernel is the **released artifact**, downloaded from the GitHub release and checksum-verified, not a local build.

## The installed kernel

```
$ gh release download v0.14.2 --repo deagy/cadre-kernel --pattern "agentic-sdlc-v0.14.2-linux-arm64.tar.gz"
$ sha256sum agentic-sdlc-v0.14.2-linux-arm64.tar.gz
83185fbb5cd5b98e44c51ac00336d6982a42220167638af6ecf7c38c61ec6d84   ← matches SHA256SUMS
$ ./agentic-sdlc --version
0.14.2
```

## It loads cadre's provider bundle

```
$ agentic-sdlc --provider /home/deagy/sdk/cadre/provider/provider.json provider list
[{ "id": "cadre", "version": "0.3.0",
   "manifest_sha256": "sha256:678fc509…", "catalog_sha256": "sha256:79bed2ed…" }]
```

## The plan is enriched by that kernel, across the repository boundary

`PATH` scrubbed to `/usr/bin:/bin` in every run, so nothing resolves by accident.

**The exact invocation**, because the first version of this file recorded the numbers without the inputs and an auditor could not reproduce them. Gate sets depend on the task's matched routes, so a figure without its task is not evidence:

```sh
GOBIN=$(dirname $(command -v go))   # bin/cadre rebuilds itself; it needs go on PATH
T="Deploy the payment service to production"

# A — no kernel reachable
env -u AGENTIC_SDLC_BIN PATH="$GOBIN:/usr/bin:/bin" ./bin/cadre select \
  --task "$T" --files README.md --classification confidential \
  --task-id AC11-REPRO --format json

# B — the checksum-verified released kernel
env AGENTIC_SDLC_BIN=/path/to/agentic-sdlc-v0.14.2 PATH="$GOBIN:/usr/bin:/bin" ./bin/cadre select \
  --task "$T" --files README.md --classification confidential \
  --task-id AC11-REPRO --require-sdlc --format json
```

| Run | `lifecycle_tracking` | `required_quality_gates` |
|---|---|---|
| A, no kernel | `standalone`, reason: "Agentic SDLC executable not found; team dispatch is unaffected." | 2 — `G8, G9`, cadre's own routes |
| B, released kernel | `integrated` | 9 — `G1…G9`, the kernel's lifecycle sequence added seven |
| `--require-sdlc` with no kernel | — | **exit 1**, refuses rather than falling back |

Re-run 2026-09-01 after the audit, from a clean shell: identical result. The scrubbed `PATH` keeps the pipx `agentic-sdlc` out, and `$GOBIN` is in it because `bin/cadre` rebuilds itself and needs `go` — omitting that was why the first re-run attempt produced no JSON at all.

The seven-gate difference is the integration doing work. Each added gate carries its own reason and contributing route, e.g. `{"id": "G1", "contributing_routes": ["lifecycle-sequence"], "reason": "Required by the standalone lifecycle gate sequence.", "required": true}`.

## The same kernel validates a project built from cadre's profile

```
$ agentic-sdlc --provider .../provider/provider.json init --profile generic
{ "status": "initialized", "profile": "generic", "created": [".agentic-sdlc/project.json", …] }

$ agentic-sdlc --provider .../provider/provider.json validate --root <project>
{ "valid": true, "ready": true, "errors": [], "blockers": [] }
exit=0
```

`init` came from cadre's bundle — profile `generic`, one of the two the bundle publishes — and wrote Codex agent wrappers for cadre's roles alongside the project files.

Reaching exit 0 took resolving what the kernel refuses to assume: every applicable authority named to a human, the conditional ones marked not-applicable **with a rationale**, environment persistence and production status stated, and detected commands confirmed. Before that: `valid: true, ready: false`, 16 blockers, exit 2 — structurally valid against cadre's bundle, not yet ready. The distinction is the kernel's, and it is the right one.

## The measurement that was nearly wrong

The first run of this check reported `integrated` with **no kernel wired at all**. A pipx-installed `agentic-sdlc 0.13.2` — a Python build from before the Go extraction — was on `PATH`, and cadre found it.

Two consequences worth recording. The result would have been a false pass attributed to the released kernel. And that stale install is still on this machine, shadowing the released binary for any command that resolves by `PATH` rather than `AGENTIC_SDLC_BIN`.

Same shape as P4's "recall's full suite green": a local environment supplying something the claim did not account for. It is the second time in two phases, which makes it a pattern rather than a slip — **scrub the environment before believing an integration result.**

## A defect this check found

`cadre select --require-sdlc` with no kernel refuses correctly, then says:

```
Agentic SDLC v0.13.2 or newer (below v1.0.0) is required; set AGENTIC_SDLC_BIN
or install https://github.com/deagy/cadre
```

The kernel is published at `github.com/deagy/cadre-kernel`; P1 removed it from cadre. Four operator-facing messages carried the wrong repository while the download shim beside them already had the right one. Fixed in `232314fc`.
