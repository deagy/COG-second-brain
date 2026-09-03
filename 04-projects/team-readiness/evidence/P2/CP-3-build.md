# P2 — CP-3 build

**Recorded after the fact.** The build happened and CP-3v passed over it in four
rounds; the row and this file were never written, so `phase-gates.sh` reported
P2's CP-3 as never run. That is the correct report — an unrecorded checkpoint
leaves exactly the same evidence bundle behind as one that never happened, which
is the whole reason the gate counts rows rather than trusting a narrative. This
file is reconstructed from the artifacts and the commits, not from recollection.

Commits, in order:

| Commit | What |
|---|---|
| `57d714fa` | the dead-path guard, and the twenty-five references it found |
| `f0fd77e2` | scope inverted: scan every live document, not a curated list of 23 |
| `0b5e2df9` | `docs/the-three-repositories.md` — one page explaining the three |
| `63f36997` | the kernel boundary is enforced by the build, not by the test I named |
| `af602a4c` | four places exec the kernel, not the two I counted |
| `5582d42c` | check `gofmt -s`, and format the two files that were not |
| `0b6d0039` | a shared store is attributed, not access-controlled |
| `b68e58f7` | the guard could not see the claim it exists to catch |

## T-01, T-02 — the overview page and the glossary

`docs/the-three-repositories.md`, 128 lines, linked from all three front pages —
cadre's opens its "Choose your path" table with it (`README.md:33`).

Its structural claims are checked against code rather than against other
documents: cadre imports `github.com/deagy/recall` as a Go module; the kernel is
reached by exec from four named sites; the boundary holds because cadre-kernel
is a separate module absent from `go.mod`, so cadre *cannot* import it.

Two of those started wrong. I claimed the boundary was enforced by a test whose
filename looked right, and it was not — the truth turned out to be stronger than
my claim. And I named two exec sites when there are four, having read my own
grep output and picked rather than counted.

`lane` was struck from AC-4's list at CP-2: the word appears in none of the four
repositories, and defining it would have meant inventing vocabulary to satisfy a
criterion.

## T-03 — the instrument

`internal/cli/dead_path_references_test.go`. It resolves every path a live
document names against the tree, reporting `file:line`.

The design decision that matters is the scope. The first version checked a
curated list of 23 documents, which makes the guard's coverage a thing somebody
maintains by hand — a document added tomorrow is out of scope and nothing says
so. It now discovers its set from `git ls-files`, minus three generated trees
(`plugin/`, `cline-plugins/`, `provider/`) and minus records, so a new document
is in scope by default.

`if read < 100 { t.Fatalf(...) }` is a floor: a guard that reads nothing passes,
and a pass from an empty scan is indistinguishable from a pass from a clean one.

## T-04, T-05 — the corrections and the banners

The live corrections, and 80 documents bannered as records. Bannering is
judgment wearing a mechanical costume — it removes a document from AC-5's scope,
so a wrong call silently shrinks the criterion. The test applied was whether the
document describes a present state or records a past one, and the banner is a
self-declaration the guard reads (`recordBanner`), so the decision is visible in
the file rather than in a list somewhere else.

## T-06 — recall's five claims

`govern/` documented at top level; `cmd/recall/README.md` and `embedder/README.md`
linked; the two contradictory `reasoning.NewEngine` signatures reconciled; and
the package-README count corrected. That last one I got wrong twice: the README
said 34 of 36, I "corrected" it to 34, and the true figure is **33** — `govern/`,
`example/e2e/` and `example/production/` have none. I had counted README files
found rather than packages having one.

## Falsification

| Mutation | Fails |
|---|---|
| a dead path added to any live document | the guard, at `file:line` |
| the guard's document set emptied | the `read < 100` floor |
| a record's banner removed | the guard, since the document re-enters scope |

## Where CP-3v and CP-4 then found more

Each of the four CP-3v rounds found defects in the README Go blocks the round
before had not compiled — five distinct compile failures across three rounds,
because "the example looks right" and "the example builds" are different claims.

CP-4 then found the guard's own advertised property false: the overview page
claimed a test fails if any document still places the kernel in this repository,
and `terminology.md` still did, in prose and in a mermaid label the regexes could
not see. Recorded in `CP-4-integration.md`.
