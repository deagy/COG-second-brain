#!/usr/bin/env bash
# Checkpoint recorder for V-model evidence trail.
# Usage:
#   checkpoint.sh init <run-dir>
#   checkpoint.sh record <run-dir> <CP-id> PASS|FAIL|SKIP "<note>"
#   checkpoint.sh status <run-dir>
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
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
  echo -e "${ts}\t${cp_id}\t${result}\t${note}" >> "$dir/evidence/checkpoints.tsv"
  [[ -f "$LOG" ]] || echo -e "timestamp\tcp\tresult\tnote\trun_dir" >> "$LOG"
  echo -e "${ts}\t${cp_id}\t${result}\t${note}\t${dir}" >> "$LOG"
  echo "recorded: ${cp_id} ${result} → ${dir}/evidence/checkpoints.tsv"
}

record_reentry() {
  # Per-task amend/re-entry record, mirroring the run-record re_entry_history /
  # invalidation def. A denial (invalidation) and its re-entry (reset) are two
  # separate claims: a run may sit in "no longer valid" before it is "being redone".
  local dir="$1" attempt="$2" reentry="$3" invalidated="$4" reason="${5:-}"
  local ts
  ts=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
  mkdir -p "$dir/evidence"
  echo -e "${ts}\t${attempt}\t${reentry}\t${invalidated}\t${reason}" >> "$dir/evidence/re_entry_history.tsv"
  echo "recorded re-entry amend ${attempt} → ${dir}/evidence/re_entry_history.tsv"
}

status_run() {
  local dir="$1"
  if [[ -f "$dir/evidence/checkpoints.tsv" ]]; then
    column -t -s $'\t' "$dir/evidence/checkpoints.tsv" 2>/dev/null || cat "$dir/evidence/checkpoints.tsv"
  else
    echo "no checkpoints yet: $dir"
  fi
}

case "$cmd" in
  init) init_run "${1:?run-dir}" ;;
  record) record_cp "${1:?run-dir}" "${2:?CP-id}" "${3:?PASS|FAIL|SKIP}" "${4:-}" ;;
  record_reentry) record_reentry "${1:?run-dir}" "${2:?amend_attempt}" "${3:?reentry}" "${4:?invalidates}" "${5:-}" ;;
  status) status_run "${1:?run-dir}" ;;
  *)
    echo "usage:" >&2
    echo "  checkpoint.sh init <run-dir>" >&2
    echo "  checkpoint.sh record <run-dir> <CP-id> PASS|FAIL|SKIP \"<note>\"" >&2
    echo "  checkpoint.sh record_reentry <run-dir> <amend_attempt> \"<reentry-criteria>\" \"<invalidated-criteria>\" \"<reason>\"" >&2
    echo "  checkpoint.sh status <run-dir>" >&2
    exit 1
    ;;
esac
