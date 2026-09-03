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

set -euo pipefail

# Resolve repo root: this script lives at <root>/.claude/lib/, so root is two
# directories up from it.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd "${SCRIPT_DIR}/../.." && pwd)"

SCHEMA_FILE="${ROOT_DIR}/05-knowledge/run-record.schema.json"
PROVENANCE_FILE="${ROOT_DIR}/05-knowledge/run-record.provenance.json"
# Optional: point this at a local cadre-kernel checkout to get a warning when the
# origin schema has moved past the vendored revision. Unset, the forward-drift
# check is skipped -- it is a convenience for whoever re-vendors, not a gate.
#   export ORIGIN_CADRE_KERNEL_PATH=~/sdk/cadre-kernel
ORIGIN_REPO_PATH="${ORIGIN_CADRE_KERNEL_PATH:-}"
if [ -n "$ORIGIN_REPO_PATH" ]; then
  ORIGIN_SCHEMA_PATH="${ORIGIN_REPO_PATH}/kernel/contracts/run-record.schema.json"
else
  ORIGIN_SCHEMA_PATH=""
fi
RUN_RECORD_NAME="run-record.json"

# Two failure kinds, two codes (see header). die() is for a broken environment --
# the vendored schema or its sidecar missing means the lint cannot run at all.
# fail() is for a check that ran and did not pass, which includes a missing
# run-record: that is the run being unfinished, not the tooling being unusable.
die()  { echo "FAIL: $*" >&2; exit 2; }
fail() { echo "FAIL: $*" >&2; exit 1; }

[ -f "$SCHEMA_FILE" ] || die "vendored schema not found at $SCHEMA_FILE"
[ -f "$PROVENANCE_FILE" ] || die "provenance sidecar not found at $PROVENANCE_FILE"

# Drift check (AC-3): the vendored copy must equal its stated origin sha256.
EXPECTED_SHA="$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["schema"]["origin_sha256"])' "$PROVENANCE_FILE")"
ACTUAL_SHA="$(sha256sum "$SCHEMA_FILE" | awk '{print $1}')"
if [ "$EXPECTED_SHA" != "$ACTUAL_SHA" ]; then
  echo "FAIL: vendored schema drifted from its stated origin revision" >&2
  echo "      expected sha256 $EXPECTED_SHA, found $ACTUAL_SHA" >&2
  echo "      Someone edited ${SCHEMA_FILE} by hand. Restore it from the origin revision." >&2
  exit 1
fi

# Best-effort forward-drift check: has origin moved past the vendored revision?
if [ -n "$ORIGIN_SCHEMA_PATH" ] && [ -f "$ORIGIN_SCHEMA_PATH" ]; then
  ORIGIN_SHA="$(sha256sum "$ORIGIN_SCHEMA_PATH" | awk '{print $1}')"
  if [ "$ORIGIN_SHA" != "$EXPECTED_SHA" ]; then
    echo "WARN: origin run-record.schema.json has moved past the vendored revision" >&2
    echo "      vendored $EXPECTED_SHA vs origin $ORIGIN_SHA — re-vendor from origin." >&2
  fi
fi

# Locate the run-record to validate.
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
[ -f "$RUN_RECORD_PATH" ] || fail "no ${RUN_RECORD_NAME} at $RUN_RECORD_PATH"

# Schema validation (AC-2): does the run-record satisfy the vendored schema?
python3 - "$SCHEMA_FILE" "$RUN_RECORD_PATH" <<'PY'
import json, os, sys


def _walk(node, path=()):
    if isinstance(node, dict):
        for k, v in node.items():
            yield from _walk(v, path + (k,))
    elif isinstance(node, list):
        for i, v in enumerate(node):
            yield from _walk(v, path + (i,))
    else:
        yield path, node
try:
    from jsonschema import Draft202012Validator, FormatChecker
except ImportError:
    sys.stderr.write("FAIL: python3 jsonschema is required (pip install jsonschema)\n")
    sys.exit(2)

schema = json.load(open(sys.argv[1]))
try:
    instance = json.load(open(sys.argv[2]))
except json.JSONDecodeError as e:
    sys.stderr.write(f"FAIL: {sys.argv[2]} is not valid JSON: {e}\n")
    sys.exit(1)

# Guard the FormatChecker to the RFC 3339 (date-time) validator only. A bare
# FormatChecker() pulls in every built-in format validator (email, uuid, uri,
# ...); run-record only carries date-time, and those extra checks can reject
# otherwise-valid records. Pin it to the rfc3339 date-time check (jsonschema's
# default date-time check delegates to the rfc3339_validator package).
_default_checkers = FormatChecker().checkers
if "date-time" not in _default_checkers:
    # jsonschema registers the date-time checker only when rfc3339-validator is
    # installed. Without it the filter below yields an empty checker set and
    # every date-time silently stops being validated while the lint still
    # prints PASS -- fail loudly instead.
    sys.stderr.write(
        "FAIL: jsonschema has no date-time format checker "
        "(pip install rfc3339-validator); refusing to lint without it\n"
    )
    sys.exit(2)
_format_checker = FormatChecker()
_format_checker.checkers = {
    k: v for k, v in _default_checkers.items() if k == "date-time"
}

validator = Draft202012Validator(schema, format_checker=_format_checker)
errors = sorted(validator.iter_errors(instance),
                key=lambda e: list(e.absolute_path))
if errors:
    sys.stderr.write(f"FAIL: {sys.argv[2]} does not validate against the vendored schema:\n")
    for e in errors:
        loc = "/".join(str(p) for p in e.absolute_path) or "<root>"
        sys.stderr.write(f"  {loc}: {e.message}\n")
    sys.exit(1)
placeholders = [
    "/".join(str(p) for p in path)
    for path, value in _walk(instance)
    if isinstance(value, str) and value.startswith("TODO")
]
if placeholders and not os.environ.get("ALLOW_TEMPLATE_PLACEHOLDERS"):
    sys.stderr.write(
        f"FAIL: {sys.argv[2]} still carries {len(placeholders)} TODO placeholder(s) "
        "-- a copied template is not a run-record:\n"
    )
    for loc in placeholders[:8]:
        sys.stderr.write(f"  {loc}\n")
    if len(placeholders) > 8:
        sys.stderr.write(f"  ... and {len(placeholders) - 8} more\n")
    sys.stderr.write(
        "  Set ALLOW_TEMPLATE_PLACEHOLDERS=1 to lint the template itself.\n"
    )
    sys.exit(1)
print(f"PASS: {sys.argv[2]} validates against the vendored schema")
PY

echo "PASS: run-record lint clean (schema valid, vendored copy un-drifted)"
exit 0
