# P5 — CP-5 acceptance · AC-6, AC-7

**EVIDENCE AC-7 | CP-5 | PASS** — a machine with none of the four checked out, no Go
toolchain and no `~/.cadre`, installed from the documented command, answers both
criterion commands. Artifact: `ac7-clean-machine.log`, `docker run --rm` on
`node:22-bookworm-slim`, aarch64, against `cli-v0.7.5` / `plugin-v0.24.5` /
kernel `v0.14.4`.

```
### AC-7 command 1: cadre sdlc --version
0.14.4
  -> exit 0

### AC-7 command 2: cadre knowledge search
cadre knowledge search: query is required
  -> exit 2
```

**EVIDENCE AC-6 | CP-5 | PASS** — measured against *published releases*, not tags.
cadre `cli-v0.7.5` and `plugin-v0.24.5` at `HEAD`; cadre-kernel `v0.14.4` at `HEAD`;
recall `v0.3.3` at `HEAD`; gloop none, by a decision written into its own README.

## The criterion took five attempts, and every one moved the failure

The first run refused to install at all — `install.sh` requires a runner on PATH.
The next four each got further and stopped somewhere new:

| Run | Where it stopped |
|---|---|
| 1 | `no supported runner found` — no AI runner installed |
| 2 | `agentic-sdlc-v0.14.3-linux-arm64.tar.gz is not listed in the release's SHA256SUMS`, and `Go is required to build this checkout's CLI` |
| 3 | `could not obtain the cadre binary for this platform` — no `linux/arm64` CLI published, and the message named `linux/arm64` among the platforms it covers |
| 4 | `install Agentic SDLC v0.14.4+` — with the kernel downloaded, verified and cached |
| 5 | both commands answer; `cadre doctor` reports no kernel while `cadre sdlc` runs one |
| 6 | passes |

**Six phases of green suites across four repositories, and the first container run
found two defects.** Every one of them was invisible from a machine that already had
a kernel, a Go toolchain and four checkouts — which is what the spec said would
falsify this goal, written before any of it happened:

> Declaring it done from a developer machine. Every criterion except AC-7 is
> checkable from a working checkout with all four repositories present, which is the
> exact position that cannot see an installation defect.

## What the run proves beyond its own two commands

The container is the only place this project has ever run the whole chain, so it
carries the other phases' work as well:

- **P4 survives packaging.** `cadre knowledge search --retention-days 30 foo` refuses
  by name at exit 2, with the full text — the commit that removed it, that nothing
  rebuilt it, where content lives now, that the decision is open. The same token as a
  `--reason` *value* is not refused: it reaches the store-partition error, which is a
  different command failing for a different reason.
- **`cadre doctor` and `cadre sdlc` agree**: `lifecycle kernel: 0.14.4 via packaged
  plugin /root/.cadre/dist/plugin/plugins/lifecycle/bin/agentic-sdlc`. They did not
  in run 5, and doctor exists to be believed.
- **The kernel resolved by checksum**, which no release before `v0.14.4` could do.

## AC-6's clause, and where the reason lives

Three of the four have zero commits between their latest release and `HEAD`. gloop
rests on "or a stated reason", and the reason is in `README.md`:

> `main` is what you install. There is no release workflow here and no published
> release for any tag; `v0.1.0` and `v0.2.0` are markers in the history, not
> artifacts you can download. […] a tag that produces no release is
> indistinguishable from one that failed to.

That last clause is not rhetoric. recall carries `v0.3.0`, `v0.3.1` and `v0.3.2` with
nothing published behind any of them, and measuring AC-6 with `git describe` would
have reported recall released at `v0.3.1` and hidden the defect the criterion exists
to catch.

## What this does not claim

The install still needs an AI coding runner on `PATH`; `install.sh` refuses without
one, and `docs/INSTALL.md`'s table assumes you have one. That is a documented
dependency of a plugin suite for AI runners, not a defect — but it means "a clean
machine" here is a machine with a runner and nothing else, and the run above installs
one first and says so.
