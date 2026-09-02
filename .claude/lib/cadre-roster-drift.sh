#!/usr/bin/env bash
# cadre-roster-drift.sh — verify COG's vendored kadre roster package has not
# drifted from the revision it was vendored from.
#
# This is the enforcement for Change 4's "roster vendored first" prerequisite:
# the roster is kadre's single source of truth for the 159 specialists, so COG
# vendors it and must fail (not silently dispatch on a stale or hand-edited
# copy) if the vendored package diverges. Same shape as run-record-lint.sh's
# drift check, adapted from one file to a directory tree.
#
# Usage:
#   bash .claude/lib/cadre-roster-drift.sh
#
# Exit codes:
#   0  the vendored roster matches its recorded digest
#   1  drift detected (a file was added, removed, or changed by hand)
#   2  environment error (roster or manifest missing)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"
ROSTER_DIR="${ROOT_DIR}/05-knowledge/cadre-roster"
MANIFEST="${ROOT_DIR}/.claude/lib/cadre-roster.manifest.sha256"

[ -d "$ROSTER_DIR" ] || { echo "FAIL: vendored roster not found at $ROSTER_DIR" >&2; exit 2; }
[ -f "$MANIFEST" ] || { echo "FAIL: roster manifest not found at $MANIFEST" >&2; exit 2; }

EXPECTED="$(head -n1 "$MANIFEST")"
ACTUAL="$(cd "$ROSTER_DIR" && find . -type f -print0 | sort -z | xargs -0 sha256sum | sha256sum | awk '{print $1}')"

if [ "$EXPECTED" != "$ACTUAL" ]; then
  echo "FAIL: vendored kadre roster has drifted" >&2
  echo "      recorded digest $EXPECTED" >&2
  echo "      current digest  $ACTUAL" >&2
  echo "      A file was added, removed, or edited by hand under $ROSTER_DIR." >&2
  echo "      Re-vendor from the source revision recorded in" >&2
  echo "      05-knowledge/cadre-roster/PROVENANCE.md and regenerate the manifest." >&2
  exit 1
fi

echo "PASS: vend kadre roster un-drifted ($ACTUAL)"
exit 0
