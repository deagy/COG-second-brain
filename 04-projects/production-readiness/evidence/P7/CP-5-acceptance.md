# P7 — CP-5 acceptance (AC-8, reopened)

Every row below observes the artifact after the mutation, not the mutating command's
return value.

## T-01 — the body

```
$ gh api repos/deagy/cadre/issues/249 --jq '{updated: .updated_at, len: (.body|length)}'
{"len":6490,"updated":"2026-09-02T19:35:17Z"}
```

Re-fetched body opens with `> **Corrected 2026-09-02.** This issue was filed against
the Python implementation, which no longer exists.` The Python the body names is now
introduced as a description of code as it stood on 2026-08-07.

## T-02 — the release home

```
$ gh api repos/deagy/cadre/releases --paginate \
    --jq '[.[] | select(.tag_name|startswith("kernel-v"))] | length'
0

$ gh api repos/deagy/cadre/releases/tags/kernel-v0.14.2
{"message":"Not Found", "status":"404"}

$ curl -sIL .../cadre/releases/download/kernel-v0.14.2/agentic-sdlc-v0.14.2-linux-arm64.tar.gz
HTTP 404

$ curl -sIL .../cadre-kernel/releases/download/v0.14.4/agentic-sdlc-v0.14.4-linux-arm64.tar.gz
HTTP 200
```

**One observation is worth recording because it would have been read wrong, and the
gate that opened this phase read it exactly that way.** `curl` on
`https://github.com/deagy/cadre/releases/tag/kernel-v0.14.2` still returns **HTTP 200**,
because the git tag was kept and GitHub renders a page for a bare tag. That 200 was
part of the original FAIL's evidence, and it is not evidence of a release: the same URL
returns 200 for a tag that never had one. Checked rather than assumed —

```
$ curl -sL .../releases/tag/kernel-v0.14.2 | grep -c 'releases/download/kernel-v0.14.2'
0
```

Zero asset links on the rendered page, and the releases API returns 404 for the tag.
The API is the authority; the HTML page answers a different question.

```
$ gh api repos/deagy/cadre/git/matching-refs/tags/kernel-v --jq '.[].ref'
refs/tags/kernel-v0.13.0 … refs/tags/kernel-v0.14.2   (all six, kept by decision)
```

## Known cost, accepted at CP-6

`cli-v0.5.0` through `cli-v0.6.5` generate an installer whose kernel `BASE` is
`https://github.com/deagy/cadre/releases/download/kernel-v$AGENTIC_SDLC_VERSION`,
observed at `git show cli-v0.6.5^{commit}:internal/generators/plugin_generation.go:274`.
Their kernel fetch now 404s. The user was shown this before deciding and chose deletion
on the charter's grounds: the bar is one operator running HEAD.

EVIDENCE AC-8 | CP-5 | PASS | `#249` body re-fetched after edit — 6,490 bytes, opens with a correction stating the named Python was deleted by `b418031e` and that the body describes 2026-08-07 code; the original report kept verbatim below it as the record of what was observed | `gh api repos/deagy/cadre/issues/249`
EVIDENCE AC-8 | CP-5 | PASS | The kernel has one release home. `cadre` serves zero kernel releases (releases API, paginated, count 0; `releases/tags/kernel-v0.14.2` → 404; a known asset URL → 404). `cadre-kernel` serves `v0.14.2`–`v0.14.4` and its assets fetch 200. The six git tags are kept deliberately — a tag points into history, a release is a place software is fetched from | `gh api repos/deagy/cadre/releases`, `curl` on both hosts
EVIDENCE AC-8 | CP-5 | PASS | The `releases/tag/<tag>` HTML page returning 200 does not indicate a release — GitHub renders that page for a bare tag. Confirmed: zero `releases/download/` links in the page body, and the releases API returns 404 for the same tag. This is recorded because the FAIL that opened the phase cited that 200 as evidence of a live release | `curl -sL .../releases/tag/kernel-v0.14.2`
