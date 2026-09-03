#!/usr/bin/env bash
# cadre-roster-resolve.sh — resolve a domain-specialist role from COG's vendored
# kadre roster and report its dispatch attributes.
#
# This is the COG-side half of Change 4's roster dispatch: given a role id (or
# --list), it resolves the role from the vendored catalog.yaml and reports what
# the dispatch skill needs to spawn it — the sandbox mode derived from the
# capability tier (per roster runner-capabilities.json capability_tiers), the
# model/effort, and the path to the role's AGENT.md. It does not dispatch; the
# dispatch skill reads this output and spawns the role through the runner.
#
# Usage:
#   bash .claude/lib/cadre-roster-resolve.sh <role-id>          # human-readable
#   bash .claude/lib/cadre-roster-resolve.sh --list             # all roles (TSV)
#   bash .claude/lib/cadre-roster-resolve.sh --key <field> <id> # one raw value
#
# Exit codes:
#   0  role resolved, listed, or key printed
#   1  role not found
#   2  usage error
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ROSTER_DIR="${ROOT_DIR}/05-knowledge/cadre-roster"
CATALOG="${ROSTER_DIR}/catalog.yaml"

[ -f "$CATALOG" ] || { echo "FAIL: catalog not found at $CATALOG" >&2; exit 2; }

MODE="resolve"
ARG=""
KEY=""
if [ "${1:-}" = "--list" ]; then
  MODE="list"
elif [ "${1:-}" = "--key" ]; then
  MODE="key"
  KEY="${2:-}"
  ARG="${3:-}"
elif [ -n "${1:-}" ]; then
  ARG="$1"
else
  echo "usage: bash .claude/lib/cadre-roster-resolve.sh <role-id|--list|--key <field> <id>>" >&2
  exit 2
fi

python3 - "$MODE" "$KEY" "$ARG" "$CATALOG" <<'PY'
import sys, yaml

mode, key, arg, catalog = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
agents = yaml.safe_load(open(catalog)).get("agents", {})

# capability -> sandbox_mode, from roster runner-capabilities.json
# capability_tiers (read_only is read-only; every authoring/operator tier is
# workspace-write). Kept explicit here rather than re-reading the JSON so the
# resolver has one place to edit when the runner contract changes.
SANDBOX = {
    "read_only": "read-only",
    "document_author": "workspace-write",
    "code_author": "workspace-write",
    "test_author": "workspace-write",
    "environment_operator": "workspace-write",
}

if mode == "list":
    for rid, role in agents.items():
        print(f"{rid}\t{role['phase']}\t{role['capability']}\t{role['model']}")
    sys.exit(0)

if arg not in agents:
    print(f"FAIL: role '{arg}' not found in catalog ({len(agents)} roles)", file=sys.stderr)
    sys.exit(1)

role = agents[arg]
attrs = {
    "role_id": arg,
    "phase": role.get("phase"),
    "capability": role["capability"],
    "sandbox_mode": SANDBOX[role["capability"]],
    "model": role.get("model"),
    "codex_model": role.get("codex_model"),
    "reasoning_effort": role.get("reasoning_effort"),
    "definition": role.get("definition"),
}

if mode == "key":
    if key not in attrs:
        print(f"FAIL: unknown field '{key}' (try: {', '.join(attrs)})", file=sys.stderr)
        sys.exit(1)
    print(attrs[key])
    sys.exit(0)

# human-readable, aligned
print(f"role_id:          {attrs['role_id']}")
print(f"phase:            {attrs['phase']}")
print(f"capability:       {attrs['capability']}")
print(f"sandbox_mode:     {attrs['sandbox_mode']}")
print(f"model:            {attrs['model']}")
print(f"codex_model:      {attrs['codex_model']}")
print(f"reasoning_effort: {attrs['reasoning_effort']}")
print(f"definition:       {attrs['definition']}")
sys.exit(0)
PY
