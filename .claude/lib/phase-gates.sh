#!/usr/bin/env bash
# Which checkpoints a goal's phases actually recorded.
#
# Usage:
#   phase-gates.sh <goal-dir>
#
# Reads every evidence/P*/evidence/checkpoints.tsv under a goal folder and
# reports, per phase, which required checkpoints have no row. Exits non-zero
# if any phase is missing one.
#
# Why this exists. The capability-parity ultragoal shipped all five phases
# and passed two north-star gates without ever running CP-4. Nothing noticed,
# because the gates check acceptance criteria and CI, and a checkpoint that
# was never run leaves no failing artifact behind -- only an absent row, which
# reads exactly like a row nobody looked for.
#
# That matters because CP-4 is not a formality. In the preceding ultragoal it
# ran five times and found: recall's CI red on the tag its criterion pinned,
# silent corpus corruption on store upgrade, cadre and gloop red since the
# commits their criteria cited, a criterion closed against an implementation
# that was still installable, and a stale interpreter shadowing the kernel on
# PATH. Every one of those was a cross-phase defect invisible to the
# per-phase component checks that had already passed.
#
# The failure this guards against is therefore not "a gate failed". It is
# "a gate was never asked", which produces the same evidence bundle as a
# clean run right up until someone greps for it.
#
# Required set is per the lane in WORKFLOW.md. Ultragoal phases are `full`.
set -euo pipefail

if [ "$#" -ne 1 ]; then
  echo "usage: phase-gates.sh <goal-dir>" >&2
  exit 2
fi

goal="${1%/}"
[ -d "$goal" ] || { echo "no such goal directory: $goal" >&2; exit 2; }

# CP-1 is chartered once for the goal, not per phase; CP-2 is skipped for a
# phase built straight from the spec; CP-7 is advisory. The blocking set that
# every `full` phase owes is CP-3, CP-3v, CP-4 and CP-5.
required="CP-3 CP-3v CP-4 CP-5"

missing_total=0
unrecorded_total=0
found_any=0

for dir in "$goal"/evidence/P*/; do
  [ -d "$dir" ] || continue
  phase="$(basename "$dir")"
  tsv="$dir/evidence/checkpoints.tsv"

  if [ ! -f "$tsv" ]; then
    # P0 is the charter phase and owes no build checkpoints.
    if [ "$phase" = "P0" ]; then continue; fi
    printf '%-6s %s\n' "$phase" "NO checkpoints.tsv -- nothing was recorded for this phase"
    missing_total=$((missing_total + 1))
    found_any=1
    continue
  fi
  found_any=1

  [ "$phase" = "P0" ] && continue

  # Two different failures, deliberately distinguished. A checkpoint with no
  # row AND no evidence file was never asked -- that is the real gap. A
  # checkpoint with an artifact but no row ran and went unrecorded, which is a
  # bookkeeping gap: the gate did its work, but nothing greppable says so, and
  # an evidence trail nobody can query is not an evidence trail.
  unrun=""
  unrecorded=""
  for cp in $required; do
    if awk -F'\t' -v c="$cp" '$2 == c { found = 1 } END { exit !found }' "$tsv"; then
      continue
    fi
    if ls "$dir"/${cp}-*.md >/dev/null 2>&1 || ls "$dir"/${cp}.md >/dev/null 2>&1; then
      unrecorded="$unrecorded $cp"
    else
      unrun="$unrun $cp"
    fi
  done

  if [ -n "$unrun" ]; then
    printf '%-6s NEVER RUN:%s\n' "$phase" "$unrun"
    missing_total=$((missing_total + 1))
  fi
  if [ -n "$unrecorded" ]; then
    printf '%-6s ran but unrecorded:%s (evidence file present, no checkpoints.tsv row)\n' "$phase" "$unrecorded"
    unrecorded_total=$((unrecorded_total + 1))
  fi
  if [ -z "$unrun" ] && [ -z "$unrecorded" ]; then
    printf '%-6s all required checkpoints recorded\n' "$phase"
  fi
done

if [ "$found_any" -eq 0 ]; then
  echo "no phase evidence found under $goal/evidence/" >&2
  exit 2
fi

echo
if [ "$missing_total" -gt 0 ]; then
  echo "phase-gates: $missing_total phase(s) never ran a required checkpoint."
  echo "  An absent checkpoint is not a pass. It means the gate was never asked,"
  echo "  which leaves the same evidence bundle behind as a clean run."
  [ "$unrecorded_total" -gt 0 ] && \
    echo "  A further $unrecorded_total phase(s) ran a checkpoint without recording it."
  exit 1
fi

if [ "$unrecorded_total" -gt 0 ]; then
  echo "phase-gates: every required checkpoint ran, but $unrecorded_total phase(s) left one"
  echo "  unrecorded. The work was done; the trail cannot be queried for it."
  echo "  Record with: bash .claude/lib/checkpoint.sh record <phase-dir> <CP> PASS <note>"
  exit 1
fi

echo "phase-gates: every phase ran and recorded its required checkpoints."
