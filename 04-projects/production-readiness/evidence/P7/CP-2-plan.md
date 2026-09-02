# P7 — CP-2 plan

Opened by the north-star gate's FAIL on AC-8 (`/tmp/claude-1000/northstar-gate.md`,
2026-09-02). Eight criteria passed against directly observed artifacts; AC-8 did not.

AC-8 has three clauses. The gate confirmed the first and failed the other two:

| Clause | P2's verdict | The gate's finding |
|---|---|---|
| `#249` fixed with a test that fails without the fix | verified | genuinely fixed — `998ad425` is an ancestor of HEAD, the tests pin the walk, the defect was reproduced against the Go binary |
| the issue body corrected where it describes deleted Python | verified | **false** — the body still narrates `find_project_local_config`, `roster/knowledge-store/src/config.py` and a `python3 -c` reproduction as current. Only a closing *comment* explains the drift, and the issue timeline carries no `edited` event |
| the lifecycle kernel has one release home, not two | verified | **false** — `gh release list -R deagy/cadre` still returns six live kernel releases with downloadable assets |

**Both failures are the same shape, and it is the shape this whole goal kept
producing: the check observed a narrower thing than the criterion demanded.** P2
verified that `release.yml`'s job graph no longer *publishes* kernel releases. The
criterion is about the kernel having one release *home*, which is a claim about the
artifacts, not the workflow that made them. A workflow that has stopped publishing
and a repository that serves nothing look identical from inside the workflow file.
The same is true of the issue: a comment correcting a body and an edited body look
identical to anyone who reads the thread top to bottom, and different to anyone who
reads only the body — which is what a search result or a link lands you in.

## Tasks

| ID | Task | AC |
|---|---|---|
| T-01 | Correct `#249`'s body so a reader does not take the Python it names as current, keeping the original report readable as the record of what was observed | AC-8 |
| T-02 | Retire the kernel's second release home in the `cadre` repository | AC-8 |

T-02 is an irreversible outward-facing mutation on a public repository, so it went to
the user at CP-6 rather than being decided here. What the decision needed, established
by reading the artifacts first:

- Nothing at cadre HEAD fetches a kernel from the `cadre` repo. `plugin_generation.go`
  fetches the kernel from `deagy/cadre-kernel/releases/download/v$AGENTIC_SDLC_VERSION`
  and uses the `cadre` repo only for `cli-v*` archives.
- Eight *published* CLI releases do. `git show cli-v0.6.5^{commit}:internal/generators/plugin_generation.go`
  line 274 reads `BASE="https://github.com/deagy/cadre/releases/download/kernel-v$AGENTIC_SDLC_VERSION"`.
  `cli-v0.5.0` through `cli-v0.6.5` all predate `1ed3169a`, the commit that repointed
  the shim. Deleting the kernel releases breaks their kernel install path.
- The three `kernel-v0.13.x` releases carry Python wheels — artifacts of the
  implementation `b418031e` deleted.

The user chose to delete the six releases and keep the git tags, on the charter's
grounds that the bar is one operator running HEAD.
