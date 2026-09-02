# PROVENANCE — vendored kadre roster

This directory is a **vendored copy** of the kadre roster package, not COG
content. It is COG's single source of truth for the domain specialists that
Change 4 ("roster dispatch") resolves and dispatches. It is vendored, never
edited by hand; if it drifts, the drift check fails and the package must be
re-vendored.

## Source

| Field | Value |
|---|---|
| Repo | `cadre` — `https://github.com/deagy/cadre` (`/home/deagy/sdk/cadre`) |
| Path in repo | `roster/` |
| Source revision | `5c40d6eceb44cf52789eacf364e7ba47d33d4bb5` |
| Vendored on | 2026-09-02 |
| Combined digest | `d2e69624b3846ffd2ab2291692c726c6b5a3dd34b5bf44939c467947796af8f5` |

## What it is

The kadre roster package: the catalog of ~159 specialist roles, their
`AGENT.md` definitions, the routing rules, the shared policy, and the context
packs. `roster.json` declares the package's own layout, which is why the copy
is self-contained — the manifest's paths (`catalog`, `routing`, `role_root`,
`shared_policy_root`) are relative to this directory's root.

Roles are grouped by domain (`architecture/`, `authority/`, `engineering/`,
`security/`, `testing/`, …); `shared/` holds policy the roles read
(`library-standards.yaml`, `output-schemas/denial.schema.json`,
`output-schemas/finding.schema.json`); `workflows/` holds the phase-level
workflows. This is the roster Change 4 dispatches from.

## Drift check

```bash
bash .claude/lib/cadre-roster-drift.sh
```

Recomputes the combined digest of every file under this directory and compares
it to the digest recorded in
`.claude/lib/cadre-roster.manifest.sha256`. A mismatch means a file was added,
removed, or hand-edited — the check fails and the package must be re-vendored
from the source revision above. The digest is stored **outside** this directory
(`.claude/lib/`) so the manifest does not hash itself.

## Re-vendoring

```bash
rm -rf 05-knowledge/cadre-roster
mkdir -p 05-knowledge/cadre-roster
cp -a /home/deagy/sdk/cadre/roster/. 05-knowledge/cadre-roster/
# PROVENANCE.md is excluded from the hash (it records the digest itself);
# regenerate it after re-vendoring, then hash only the roster package.
( cd 05-knowledge/cadre-roster && find . -type f ! -name PROVENANCE.md -print0 \
    | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}' \
  > ../../.claude/lib/cadre-roster.manifest.sha256 )
bash .claude/lib/cadre-roster-drift.sh   # must PASS
```
