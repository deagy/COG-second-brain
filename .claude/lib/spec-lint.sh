#!/usr/bin/env bash
# Two shapes of acceptance criterion that cannot be satisfied inside the
# phase that owns them.
#
# Usage:
#   spec-lint.sh <goal-dir>...
#
# From AI-4, whose wording names both: "Words like 'released' and 'no other
# definition exists' import dependencies on later phases."
#
#   released   A criterion verified against a published artifact -- an
#              installed release, a registry download, a tag -- depends on
#              whichever phase publishes it. AC-11 of the repo-consolidation
#              goal read "accepted by an installed released kernel", and the
#              release it needed was produced by a phase that had not run.
#              The criterion was not wrong; it was unsatisfiable where it sat.
#
#   negative   A universal negative -- "no third definition survives", "no
#              X exists outside Y" -- is a claim about everywhere. It can be
#              verified only against a named, bounded set. AC-05 asserted one
#              and was later closed against a filename search, while an
#              executable implementation survived in an archived-but-
#              installable repository.
#
# Both are lexical, because the defect is lexical: the words carry the
# dependency. Neither decides whether the criterion is *good*, only whether
# it says where it can be checked.
set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: spec-lint.sh <goal-dir>..." >&2
  exit 2
fi

findings=0
negatives="$(mktemp)"
trap 'rm -f "$negatives"' EXIT

for goal in "$@"; do
  goal="${goal%/}"
  spec="$goal/spec.md"
  [ -f "$spec" ] || { echo "no spec.md under $goal" >&2; exit 2; }

  while IFS= read -r entry; do
    line="${entry%%:*}"
    row="${entry#*:}"
    id=$(printf '%s' "$row" | sed -nE 's/^\| *(AC-[0-9a-z]+) *\|.*/\1/p')
    [ -n "$id" ] || continue

    # A criterion the traceability matrix records as verified has answered
    # this question by demonstration: it *was* satisfied, so asking whether
    # it could be is moot. This is a charter-time check, and without this
    # skip it fires forever on every closed goal -- repo-consolidation's
    # AC-05 and AC-11 read exactly as they did before their amendment,
    # because the amendment moved the criterion to a later phase rather than
    # rewording the row. A lint that cries wolf on shipped work gets turned
    # off, and then it is advice again.
    if grep -qE "^\| *$id *\|.*\| *verified *\|" "$spec"; then
      continue
    fi

    # ---- released: verified against something a phase has to publish ----
    if printf '%s' "$row" | grep -qiE 'installed released|released [a-z]+|from the registry|gh release|pip install|npm install|docker pull|published (artifact|release|package)'; then
      # Discharged when the row, or a line naming the id, says which phase
      # publishes it.
      if ! grep -qiE "$id.*(published (by|in)|shipped (by|in)|released (by|in) P[0-9]|after P[0-9])" "$spec"; then
        printf '%s:%s  %s verified against a published artifact, and no line says which phase publishes it\n' \
          "$spec" "$line" "$id"
        printf '    A criterion checked against an installed release depends on whichever phase\n'
        printf '    produces that release. Name it, or move the criterion to that phase.\n'
        findings=$((findings + 1))
      fi
    fi

    # ---- negative: a universal negative with no bounded set ----
    #
    # Per clause, not per row. AC-05 carried both "anything salvaged exists in
    # exactly one other repository" -- bounded -- and "no `run-record`
    # definition exists outside the kernel" -- not. Discharging the whole row
    # on the first clause let the second through, and the second is the one
    # that was later closed against a filename search while an executable
    # implementation survived elsewhere.
    # The verify method is the table's fourth field. Parameter expansion is
    # greedy here and strips through the last delimiter, leaving nothing --
    # which silently disabled this whole check until it was noticed.
    verify=$(printf '%s' "$row" | awk -F'|' '{print $4}')
    # `|| [ -n "$clause" ]` catches the final clause: tr leaves it without a
    # trailing newline and `read` discards an unterminated last line. The
    # dropped clause was "no `run-record` definition exists outside the
    # kernel" -- the only unbounded one in the row, and the one the goal was
    # later closed against on a filename search.
    printf '%s' "$verify" | tr ';' '\n' | while IFS= read -r clause || [ -n "$clause" ]; do
      printf '%s' "$clause" | grep -qiE 'no (other|third|second|further) [a-z]|nothing else|no [a-z`_-]+ (definition|copy|implementation) (exists|survives)|survives (anywhere|outside)|exists outside' || continue
      if printf '%s' "$clause" | grep -qiE 'exactly one|in (each|all) of|across (the )?(four|five|three|two|[0-9]+) repositor|count|enumerat|\bgrep\b|searched'; then
        continue
      fi
      printf 'UNBOUNDED\t%s\n' "$clause" >> "$negatives"
    done
    if [ -s "$negatives" ]; then
      if true; then
        while IFS=$'\t' read -r _ clause; do
          printf '%s:%s  %s asserts a universal negative with no bounded set to check it against\n' \
            "$spec" "$line" "$id"
          printf '    clause: %s\n' "$(printf '%s' "$clause" | sed 's/^[[:space:]]*//')"
          printf '    "No X exists" is a claim about everywhere. Name the set: which repositories,\n'
          printf '    which paths, counted how. AC-05 was closed on a filename search while an\n'
          printf '    executable implementation survived in an archived, still-installable repo.\n'
          findings=$((findings + 1))
        done < "$negatives"
      fi
      : > "$negatives"
    fi
  done < <(grep -nE '^\| *AC-[0-9a-z]+ *\|' "$spec" | grep -vE '\| *(verified|pending|open|deferred) *\|')
done

echo
if [ "$findings" -gt 0 ]; then
  echo "spec-lint: $findings finding(s)."
  exit 1
fi
echo "spec-lint: clean."
