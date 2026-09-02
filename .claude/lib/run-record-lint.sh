#!/usr/bin/env bash
# run-record-lint.sh — validate a harness run's run-record against COG's vendored
# run-record schema and verify the vendored copy has not drifted from its origin.
#
# This is the enforcement behind Change 1 (run-record as the shared object):
#   AC-2  a run-record validates against the vendored schema (with no schema edits)
#   AC-3  the drift check fails when the vendored schema is hand-edited away from
#         its stated origin revision
#
# Usage:
#   bash .claude/lib/run-record-lint.sh <run-dir|run-record.json>
#
# Exit codes:
#   0  run-record present and well-formed, and the vendored schema is un-drifted
#   1  a check failed (missing record, schema violation, or drift)
#   2  usage / environment error
#
# The vendored schema lives at 05-knowledge/run-record.schema.json. Its provenance
# (origin repo, path, git revision, sha256) and the COG-CP -> lifecycle-phase
# mapping live in 05-knowledge/run-record.provenance.json — the single source of
# truth for both, so the schema is never re-declared in a skill or note (AC-5).
#
# The drift check has two layers:
#   1. sha256(05-knowledge/run-record.schema.json) must equal the sha256 recorded
#      in the provenance sidecar. A mismatch means someone edited the vendored
#      copy by hand -> hard FAIL (this is AC-3).
#   2. If the origin repo is present, its current sha256 is compared to the
#      recorded one. A mismatch there means origin moved past the vendored
#      revision -> re-vendor WARN (the vendored copy is still valid on its own).

# Resolve repo root: this script lives at <root>/.claude/lib/, so root is two
# directories up from it.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

SCHEMA_FILE="${ROOT_DIR}/05-knowledge/run-record.schema.json"
PROVENANCE_FILE="${ROOT_DIR}/05-knowledge/run-record.provenance.json"
ORIGIN_REPO_PATH="${ORIGIN_CADRE_KERNEL_PATH:-/home/deagy/sdk/cadre-kernel}"
ORIGIN_SCHEMA_PATH="${ORIGIN_REPO_PATH}/kernel/contracts/run-record.schema.json"
RUN_RECORD_NAME="run-record.json"

die() { echo "FAIL: $*" >&2; exit 1; }

[ -f "$SCHEMA_FILE" ] || die "vendored schema not found at $SCHEMA_FILE"
[ -f "$PROVENANCE_FILE" ] || die "provenance sidecar not found at $PROVENANCE_FILE"

# --- Locate the run-record to validate ---
TARGET="${1:-}"
[ -n "$TARGET" ] || { echo "usage: bash .claude/lib/run-record-lint.sh <run-dir|run-record.json>" >&2; exit 2; }
if [ -f "$TARGET" ]; then
  RUN_RECORD_PATH="$(cd "$(dirname "$TARGET")" && pwd)/$(basename "$TARGET")"
elif [ -d "$TARGET" ]; then
  RUN_RECORD_PATH="$(cd "$TARGET" && pwd)/${RUN_RECORD_NAME}"
else
  echo "usage: bash .claude/lib/run-record-lint.sh <run-dir|run-record.json>" >&2
  exit 2
fi
[ -f "$RUN_RECORD_PATH" ] || die "no ${RUN_RECORD_NAME} at $RUN_RECORD_PATH"

# --- Drift check (AC-3): vendored copy must equal its stated origin sha256 ---
EXPECTED_SHA="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["schema"]["origin_sha256"])' "$PROVENANCE_FILE")"
ACTUAL_SHA="$(sha256sum "$SCHEMA_FILE" | awk '{print $1}')"
if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
  echo "FAIL: vendored schema drifted from its stated origin revision" >&2
  echo "      expected sha256 $EXPECTED_SHA, found $ACTUAL_SHA" >&2
  echo "      Someone edited ${SCHEMA_FILE} by hand. Restore it from the origin revision." >&2
  exit 1
fi

# --- Drift check (best-effort forward-drift): has origin moved past vendored rev? ---
if [ -f "$ORIGIN_SCHEMA_PATH" ]; then
  ORIGIN_SHA="$(sha256sum "$ORIGIN_SCHEMA_PATH" | awk '{print $1}')"
  if [ "$ORIGIN_SHA" != "$EXPECTED_SHA" ]; then
    echo "WARN: origin run-record.schema.json has moved past the vendored revision" >&2
    echo "      vendored $EXPECTED_SHA vs origin $ORIGIN_SHA — re-vendor from origin." >&2
  fi
fi

# --- Schema validation (AC-2): does the run-record satisfy the vendored schema? ---
python3 - "$SCHEMA_FILE" "$RUN_RECORD_PATH" <<'PY'
import json, sys
try:
    from jsonschema import Draft202012Validator
except ImportError:
    sys.stderr.write("FAIL: python3 jsonschema is required (pip install jsonschema)\n")
    sys.exit(2)

schema = json.load(open(sys.argv[1]))
try:
    instance = json.load(open(sys.argv[2]))
except json.JSONDecodeError as e:
    sys.stderr.write(f"FAIL: {sys.argv[2]} is not valid JSON: {e}\n")
    sys.exit(1)

errors = sorted(Draft202012Validator(schema).iter_errors(instance),
                key=lambda e: list(e.absolute_path))
if errors:
    sys.stderr.write(f"FAIL: {sys.argv[2]} does not validate against the vendored schema:\n")
    for e in errors:
        loc = "/".join(str(p) for p in e.absolute_path) or "<root>"
        sys.stderr.write(f"  {loc}: {e.message}\n")
    sys.exit(1)
print(f"PASS: {sys.argv[2]} validates against the vendored schema")
PY
status=$?
[ "$status" -eq 0 ] || exit "$status"

echo "PASS: run-record lint clean (schema valid, vendored copy un-drifted)"
exit 0
