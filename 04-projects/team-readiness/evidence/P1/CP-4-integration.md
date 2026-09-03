# P1 + P2 — CP-4 integration verify

Two rounds. Round 1 FAILED; round 2 PASS.

## Round 1: the guard's own claim about itself was false

`docs/terminology.md` still said the kernel is a directory in this repository,
twice — in prose ("These are directories within one repository… the repository
boundary that used to enforce it is gone") and in a mermaid node
`K["portable Agentic SDLC kernel (kernel/)"]`. Neither carried backticks nor
link syntax, so `TestNoOperationalDocPointsAtAPathThatIsGone` could not see
either, and passed.

Worse, `docs/the-three-repositories.md` — P2's own deliverable — asserted that
*"a test now fails if another appears."* False in both halves at once: a
document still made the claim, and the test could not have caught it.

**A guard built from one syntax cannot see the same claim written in another.**
Backticked path, markdown link, mermaid label and bare prose are four ways to
say one false thing; two were covered.

Fixed at `b68e58f7` by making the claim true rather than softening it: a
`bareDirectoryToken` pattern, anchored so `internal/kernel/` and a reader's own
`~/.claude/plugins/data/<id>/kernel/` do not match. It immediately found a third
instance — `CLAUDE.md` telling contributors to run `go test ./internal/kernel/`
and `cd engine && uv sync`, two packages this repository no longer has.

## Round 2 evidence

EVIDENCE AC-4 | CP-4 | PASS | `docs/terminology.md` prose and mermaid node both now name `deagy/cadre-kernel`; `README.md`, the overview page and terminology agree the kernel is a separate repository | terminology.md:32-56, README.md:58
EVIDENCE AC-5 | CP-4 | PASS | The verifier built its own 30-syntax probe rather than reusing the guard's regexes — the finding was a blind spot, and reusing my list would have reproduced it. Caught: table cell, fenced-code comment, blockquote, YAML value, list item, HTML comment, footnote, DOT label, mermaid label quoted and unquoted, heading, sentence-initial and sentence-final prose, tab-preceded | standalone harness, outside the repo
EVIDENCE AC-5 | CP-4 | PASS | No over-reach, checked against three real documents a naive extension would trip: `internal/knowledge/README.md`'s `internal/engine/executor` (a path that exists), `README.md:154`'s `bin/agentic-sdlc` (another repository's layout, via the elsewhere-map), `docs/enterprise.md:135`'s reader-environment `kernel/`. All pass | dead_path_references_test.go:213
EVIDENCE AC-5 | CP-4 | PASS | `CLAUDE.md` and `CONTRIBUTING.md` name no package that is gone: `git ls-files \| grep -c "^internal/kernel/"` → 0, same for `^engine/` | CLAUDE.md, CONTRIBUTING.md
EVIDENCE AC-1,AC-3 | CP-4 | PASS | All three runners green at the verified heads: cadre validate run `33711699184` success at `b68e58f7`, including the generator-parity job; cadre-kernel validate run `33700984992`; recall Go run `33708008711` and Tag-release run `33708280072` | gh run view

## What the probe found that the guard still misses

Six syntaxes, none of which occurs in any live document today:

`<code>kernel/</code>` and `<td>kernel/</td>` (angle brackets are outside the
anchor's character class), `*kernel/*` and `**kernel/**` (asterisks likewise),
a tight table cell `|kernel/|desc|` with no surrounding space, a double-backtick
span, and a token pressed against `;` or `:`.

Recorded rather than closed. The guard is regex-per-line and not
markdown-aware, so this list is a property of the approach and not an oversight
in the extension — the honest statement is that it catches the syntaxes people
have actually used here, which is weaker than "catches the claim" and stronger
than what existed this morning. Carried to the retro.
