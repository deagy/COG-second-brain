#!/usr/bin/env bash
# Checkpoint recorder for V-model evidence trail.
# Usage:
#   checkpoint.sh init <run-dir>
#   checkpoint.sh record <run-dir> <CP-id> PASS|FAIL|SKIP "<note>"
#   checkpoint.sh record_reentry <run-dir> <amend_attempt> "<reentry-criteria>" "<invalidated-criteria>" "<reason>" [denier]
#   checkpoint.sh status <run-dir>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"

# TSV fields are separated by tabs and rows by newlines, so a literal tab or
# newline in caller-supplied text (a verifier reason quoting a snippet, a note
# holding a path) silently splits the row. These files carry the amend count, so
# a split row miscounts it. Collapse both to spaces at the boundary.
tsv() { printf '%s' "$1" | tr '\t\n' '  '; }
LOG="$ROOT/.claude/logs/checkpoint-ledger.tsv"
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
  printf '%s\t%s\t%s\t%s\n' "$ts" "$(tsv "$cp_id")" "$(tsv "$result")" "$(tsv "$note")" >> "$dir/evidence/checkpoints.tsv"
  [[ -f "$LOG" ]] || printf '%s\t%s\t%s\t%s\t%s\n' timestamp cp result note run_dir >> "$LOG"
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" "$(tsv "$cp_id")" "$(tsv "$result")" "$(tsv "$note")" "$dir" >> "$LOG"
  echo "recorded: ${cp_id} ${result} → ${dir}/evidence/checkpoints.tsv"
}

record_reentry() {
  # Per-task amend/re-entry record, mirroring the run-record re_entry_history /
  # invalidation def. A denial (invalidation) and its re-entry (reset) are two
  # separate claims: a run may sit in "no longer valid" before it is "being redone".
  local dir="$1" attempt="$2" reentry="$3" invalidated="$4" reason="${5:-}"
  # The denier is the run-record's invalidation.actor. It defaults to task-verifier
  # because that is the only agent that issues FAIL:fixable; pass it explicitly when
  # a differently-named verifier denied, so the fold does not have to guess.
  local denier="${6:-task-verifier}"
  local ts hist prev
  local AMEND_BOUND=3

  if ! [[ "$attempt" =~ ^[0-9]+$ ]]; then
    echo "FAIL: amend_attempt must be a positive integer, got '$attempt'" >&2
    exit 2
  fi
  if (( attempt > AMEND_BOUND )); then
    echo "FAIL: amend_attempt ${attempt} exceeds AMEND_BOUND (${AMEND_BOUND})." >&2
    echo "      The loop is past its budget: record a terminal FAIL:escalate and" >&2
    echo "      put the criterion to the user. Do not extend the bound here." >&2
    exit 1
  fi
  # The count is only meaningful if it advances. A worker convinced this attempt
  # differs in kind from the last will record it as a first attempt, and a count
  # that accepts that agrees with them -- which is the judgment the bound distrusts.
  hist="$dir/evidence/re_entry_history.tsv"
  if [[ -f "$hist" ]]; then
    prev=$(awk -F'\t' 'NR>1 && $2+0>m {m=$2+0} END{print m+0}' "$hist")
    if (( attempt <= prev )); then
      echo "FAIL: amend_attempt ${attempt} does not advance the count (last was ${prev})." >&2
      echo "      Each amend cycle increments; re-recording an earlier attempt hides" >&2
      echo "      a burned round against AMEND_BOUND (${AMEND_BOUND})." >&2
      exit 1
    fi
  fi
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$dir/evidence"
  [[ -f "$hist" ]] || printf '%s\t%s\t%s\t%s\t%s\t%s\n' timestamp amend_attempt reentry invalidates reason denier >> "$hist"
  printf '%s\t%s\t%s\t%s\t%s\t%s\n' "$ts" "$attempt" "$(tsv "$reentry")" "$(tsv "$invalidated")" "$(tsv "$reason")" "$(tsv "$denier")" >> "$hist"
  # Also land it in the cross-run ledger: an amend cycle burned against
  # AMEND_BOUND is the thing an operator looks for, and the per-run file is
  # not where they look.
  [[ -f "$LOG" ]] || printf '%s\t%s\t%s\t%s\t%s\n' timestamp cp result note run_dir >> "$LOG"
  printf '%s\t%s\t%s\t%s\t%s\n' "$ts" CP-3v REENTRY \
    "$(tsv "amend ${attempt}: reentry=${reentry} invalidates=${invalidated} ${reason}")" "$dir" >> "$LOG"
  echo "recorded re-entry amend ${attempt} → ${hist}"
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
    record_reentry "$1" "$2" "$3" "$4" "${5:-}" "${6:-task-verifier}" ;;
  status) status_run "${1:?run-dir}" ;;
  *)
    echo "usage:" >&2
    echo "  checkpoint.sh init <run-dir>" >&2
    echo "  checkpoint.sh record <run-dir> <CP-id> PASS|FAIL|SKIP \"<note>\"" >&2
    echo "  checkpoint.sh record_reentry <run-dir> <amend_attempt> \"<reentry-criteria>\" \"<invalidated-criteria>\" \"<reason>\" [denier]" >&2
    echo "  checkpoint.sh status <run-dir>" >&2
    exit 1
    ;;
esac
