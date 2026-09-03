#!/usr/bin/env bash
# Checkpoint recorder for V-model evidence trail.
# Usage:
#   checkpoint.sh init <run-dir>
#   checkpoint.sh record <run-dir> <CP-id> PASS|FAIL|SKIP "<note>"
#   checkpoint.sh record_reentry <run-dir> <amend_attempt> "<reentry-criteria>" "<invalidated-criteria>" "<reason>"
#   checkpoint.sh record_approval <gate> <authority> <approver> "<artifact>" [run-dir]
#   checkpoint.sh status <run-dir>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
LOG="$ROOT/.claude/logs/checkpoint-ledger.tsv"
APPROVAL_LOG="$ROOT/.claude/logs/approval-ledger.tsv"
mkdir -p "$ROOT/.claude/logs"

cmd="${1:-}"
shift || true

init_run() {
  local dir="$1"
  mkdir -p "$dir/evidence"
  if [[ ! -f "$dir/evidence/ledger.md" ]]; then
    cat > "$dir/evidence/ledger.md" <<'LEDGER'
# Evidence ledger

One row per verify pass. The observation records what was observed in the
artifact, never what a worker reported.

```text
EVIDENCE <AC-id> | <checkpoint> | PASS|FAIL | <observation> | <artifact-path-or-command>
```

## Rows

LEDGER
  fi
  echo "initialized: $dir/evidence/"
}

record_cp() {
  local dir="$1" cp_id="$2" result="$3" note="${4:-}"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$dir/evidence"
  printf '%s\t%s\t%s\t%s\n' "$ts" "$cp_id" "$result" "$note" >> "$dir/evidence/checkpoints.tsv"
  [[ -f "$LOG" ]] || printf '%s\t%s\t%s\t%s\t%s\n' timestamp cp result note run_dir >> "$LOG"
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$cp_id" "$result" "$note" "$dir" >> "$LOG"
  echo "recorded: ${cp_id} ${result} → ${dir}/evidence/checkpoints.tsv"
}

record_reentry() {
  # Per-task amend/re-entry record, mirroring the run-record re_entry_history /
  # invalidation def. A denial (invalidation) and its re-entry (reset) are two
  # separate claims: a run may sit in "no longer valid" before it is "being redone".
  local dir="$1" attempt="$2" reentry="$3" invalidated="$4" reason="${5:-}"
  local ts hist
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$dir/evidence"
  hist="$dir/evidence/re_entry_history.tsv"
  [[ -f "$hist" ]] || printf '%s\t%s\t%s\t%s\t%s\n' timestamp amend_attempt reentry invalidates reason >> "$hist"
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$attempt" "$reentry" "$invalidated" "$reason" >> "$hist"
  # Also land it in the cross-run ledger: an amend cycle burned against
  # AMEND_BOUND is the thing an operator looks for, and the per-run file is
  # not where they look.
  [[ -f "$LOG" ]] || printf '%s\t%s\t%s\t%s\t%s\n' timestamp cp result note run_dir >> "$LOG"
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" CP-3v REENTRY \
    "amend ${attempt}: reentry=${reentry} invalidates=${invalidated} ${reason}" "$dir" >> "$LOG"
  echo "recorded re-entry amend ${attempt} → ${hist}"
}

record_approval() {
  # An approval is a moment-fact; a run-record is an end-of-run document. Writing
  # the first into the second is impossible before Phase 7 creates the file, and
  # impossible outright in a plain /publish-to-confluence session that has no run.
  # So record it here, the way record_cp already records checkpoints: append at the
  # moment it happens, and let Phase 7 fold the run's rows into the matching gate's
  # human_approvals if a run-record is being written. The ledger always exists, so
  # "recorded before the mutation" is satisfiable in every session.
  local gate="$1" authority="$2" approver="$3" artifact="${4:-}" dir="${5:-}"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  [[ -f "$APPROVAL_LOG" ]] || printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    timestamp gate authority approver artifact run_dir >> "$APPROVAL_LOG"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' \
    "$ts" "$gate" "$authority" "$approver" "$artifact" "$dir" >> "$APPROVAL_LOG"
  if [[ -n "$dir" ]]; then
    mkdir -p "$dir/evidence"
    local appr="$dir/evidence/approvals.tsv"
    [[ -f "$appr" ]] || printf '%s\t%s\t%s\t%s\t%s\n' \
      timestamp gate authority approver artifact >> "$appr"
    printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$gate" "$authority" "$approver" "$artifact" >> "$appr"
  fi
  echo "recorded approval: ${gate} by ${approver} (${authority}) → ${APPROVAL_LOG}"
}

status_run() {
  local dir="$1"
  if [[ -f "$dir/evidence/checkpoints.tsv" ]]; then
    column -t -s $'\t' "$dir/evidence/checkpoints.tsv" 2>/dev/null || cat "$dir/evidence/checkpoints.tsv"
  else
    echo "no checkpoints yet: $dir"
  fi
  if [[ -f "$dir/evidence/re_entry_history.tsv" ]]; then
    echo
    echo "re-entry history (amend bound 3):"
    column -t -s $'\t' "$dir/evidence/re_entry_history.tsv" 2>/dev/null || cat "$dir/evidence/re_entry_history.tsv"
  fi
  if [[ -f "$dir/evidence/approvals.tsv" ]]; then
    echo
    echo "approvals:"
    column -t -s $'\t' "$dir/evidence/approvals.tsv" 2>/dev/null || cat "$dir/evidence/approvals.tsv"
  fi
}

case "$cmd" in
  init) init_run "${1:?run-dir}" ;;
  record) record_cp "${1:?run-dir}" "${2:?CP-id}" "${3:?PASS|FAIL|SKIP}" "${4:-}" ;;
  record_reentry)
    if [[ $# -lt 4 ]]; then
      echo "FAIL: record_reentry needs <run-dir> <amend_attempt> <reentry> <invalidates>" >&2
      echo "      A denial that names nothing to invalidate is incomplete (task-verifier.md):" >&2
      echo "      pass \"none\" deliberately if the amend really invalidates no criterion." >&2
      exit 2
    fi
    record_reentry "$1" "$2" "$3" "$4" "${5:-}" ;;
  record_approval)
    if [[ $# -lt 3 ]]; then
      echo "FAIL: record_approval needs <gate> <authority> <approver> [artifact] [run-dir]" >&2
      exit 2
    fi
    record_approval "$1" "$2" "$3" "${4:-}" "${5:-}" ;;
  status) status_run "${1:?run-dir}" ;;
  *)
    echo "usage:" >&2
    echo "  checkpoint.sh init <run-dir>" >&2
    echo "  checkpoint.sh record <run-dir> <CP-id> PASS|FAIL|SKIP \"<note>\"" >&2
    echo "  checkpoint.sh record_reentry <run-dir> <amend_attempt> \"<reentry-criteria>\" \"<invalidated-criteria>\" \"<reason>\"" >&2
    echo "  checkpoint.sh record_approval <gate> <authority> <approver> \"<artifact>\" [run-dir]" >&2
    echo "  checkpoint.sh status <run-dir>" >&2
    exit 1
    ;;
esac
