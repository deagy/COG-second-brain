# P4 / CP-6 — the four decisions that unblocked T-04

Decided by Daniel Eagy, 2026-08-31. Two were external mutations and are now executed and observed; two are scope calls that amend T-04 and T-05.

## D-1 — publish `recall/govern` as v0.3.0

**Decision:** push `main` and cut a minor tag, so cadre takes a normal versioned dependency rather than a `replace` directive.

Minor rather than patch because `govern` is a new public package; minor rather than major because nothing existing changed shape, and recall is pre-1.0 where the `distributed` breaking change already sitting in `[Unreleased]` is permitted in the same bump.

**Executed:**

| Step | Observation |
|---|---|
| Changelog | `[0.3.0] — 2026-08-31` section added covering `govern` and the `distributed` signature change; compare links corrected — they still pointed at `v0.1.0...HEAD` two releases on. Commit `675ad07`. |
| Push | `65dd3d0..675ad07 main -> main` on `git@github.com:deagy/recall.git`. |
| Tag | `gh workflow run tag.yml -f bump=minor` → run `33466274475` succeeded. `git ls-remote --tags origin` shows `refs/tags/v0.3.0 -> 675ad07`. |
| Suite | `go build ./... && go test ./...` green across all packages including `govern`, before the tag. |

**Post-condition, observed at the artifact rather than the tool return.** A scratch module outside both repositories resolved and compiled against the published version:

```
go: downloading github.com/deagy/recall v0.3.0
go: found github.com/deagy/recall/govern in github.com/deagy/recall v0.3.0
govern.New refused empty identity: govern: a searcher is required
```

`https://proxy.golang.org/github.com/deagy/recall/@v/list` lists `v0.3.0`. **The hard blocker is gone**: cadre can `go get github.com/deagy/recall@v0.3.0` and so can anyone else.

**Defect found while publishing, not fixed here.** `tag.yml` pushes the tag using the default `GITHUB_TOKEN`, and GitHub does not fire workflows from ref pushes made with that token — so `release.yml`, which triggers only on `push: tags`, did not run and no GitHub Release or platform binaries exist for v0.3.0. v0.2.0's release ran because that tag was pushed by a person. This does not affect P4: module consumers resolve through the proxy from the tag alone, and the release artifacts are for CLI users. Logged as recall's own defect.

## D-2 — T-04 narrows to governed retrieval (shape 1)

**Decision:** cadre keeps `knowledge search` and `knowledge delete` over `recall/govern`.

> **Corrected 2026-08-31, after T-04.** The `delete` half of this decision did not survive contact with recall's interface and is **not what shipped**. recall's `Store` deletes by chunk id or document id and cannot enumerate what matches a metadata scope, so cadre's four retention modes have no equivalent to route to. `delete` still runs on the retiring engine — and CP-3v established it is worse than unmigrated: it inherits the same `cfg.Database` the governed verbs now use, so against a recall-created store it fails with `cannot initialize schema: no such column: embedding_provider`. A verb advertised beside `search` with no caveat, failing with a SQL error. What it becomes is an open decision; see the ledger. The engine-maintenance verbs retire with the engine; the nine verbs recall's own CLI already serves retire naming their replacement. The retiring set is published as a list, not deleted quietly.

Shape 2 (port all fifty) is what the task title "cut over" implies and nothing requires — AC-08 asks for a governed path preserving six refusals and says nothing about fifty verbs. Shape 3 (retire the knowledge CLI entirely) removes the governed interface from the place operators meet it, which is the part this phase found was worth keeping.

Dispositions: `T-04-verb-disposition.md`.

## D-3 — `init` points at recall; `config` survives narrowed

**Decision:** cadre stops creating stores. An operator runs `recall store` and points cadre at it. `config` stays, reduced to what `govern.New` requires — store path and embedder identity.

This is the honest boundary once the engine is gone: cadre would otherwise own the lifecycle of a store it no longer implements. It changes cadre's setup instructions, which T-04 must carry.

`govern.New` requiring an embedder identity is what forces `config` to survive at all — it is the construction-time home of the sixth refusal, the one with no per-request equivalent.

## D-4 — cadre's T-02/T-03 commits pushed ahead of T-04

**Decision:** push now rather than batching with T-04, since T-01–T-03 stand independently of which shape T-04 took.

**Executed:** `CGO_ENABLED=1 go test ./...` green across cadre (the default `CGO_ENABLED=0` run fails in `internal/knowledge` concurrency tests with go-sqlite3's stub — the cgo wart P4 is retiring, not a regression). Pushed `13dd16a2..c95ed2ba`. `git ls-remote origin main` → `c95ed2ba` — both `892f7507` and `c95ed2ba` are on the remote.

## What T-04 now is

| Was | Is |
|---|---|
| Cut `cadre knowledge` (50 verbs) over to recall | Add the `github.com/deagy/recall@v0.3.0` dependency; route `search` and `delete` through `govern`; retire 22 verbs with a published disposition list; repoint `init` at recall and narrow `config` to the embedder identity and store path; update setup instructions |

T-05 (delete `internal/knowledge`'s retrieval engine) and T-06 (verify, including what cgo status actually became) are unchanged. `disaster_recovery.go`'s refusal still has to survive into T-05 — D-2 resolves how: recall's `backup` is real, so the refusal becomes unnecessary rather than lost.
