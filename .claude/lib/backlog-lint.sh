#!/usr/bin/env bash
# Every backlog row says what kind of item it is.
#
# Usage:
#   backlog-lint.sh [backlog.md]        (default: 04-projects/harness/BACKLOG.md)
#
# A backlog where every row reads `open` cannot distinguish a rule nobody has
# built yet from one nobody can build. Both wait, and the second waits
# forever. Fourteen rows accumulated that way before anyone asked which of
# them anything could enforce -- and one of them, AI-5, named the exact
# error the next ultragoal then committed.
#
# This is a shape check and says so. It verifies that a row answers the
# question, not that the answer is true: a `control` citing a file that does
# not exist, or a commit that does not resolve, passes here. Two rows with
# perfect shape and wrong content were found by a human cross-check at P3's
# CP-4, and closing that gap is a goal of its own, not a flag on this script.
set -uo pipefail

backlog="${1:-04-projects/harness/BACKLOG.md}"
[ -f "$backlog" ] || { echo "no backlog at $backlog" >&2; exit 2; }

findings=0

while IFS= read -r entry; do
  line="${entry%%:*}"
  row="${entry#*:}"
  id=$(printf '%s' "$row" | sed -nE 's/^\| *(AI-[0-9]+) *\|.*/\1/p')
  [ -n "$id" ] || continue

  # The disposition is the last column.
  disposition=$(printf '%s' "$row" | sed -E 's/.*\|([^|]*)\|[[:space:]]*$/\1/')

  case "$disposition" in
    *"**control**"*|*"**advice**"*|*"**landed**"*) ;;
    *)
      printf '%s:%s  %s has no disposition\n' "$backlog" "$line" "$id"
      printf '    Every row is control, advice or landed. "open" says a row is unfinished\n'
      printf '    and nothing about whether anything could ever finish it.\n'
      findings=$((findings + 1))
      continue
      ;;
  esac

  # A control has to say where its check lives, or that it has none yet.
  case "$disposition" in
    *"**control**"*)
      if ! printf '%s' "$disposition" | grep -qE '`[0-9a-f]{7,}`|unbuilt|merged with'; then
        printf '%s:%s  %s is a control citing no commit and not marked unbuilt\n' "$backlog" "$line" "$id"
        printf '    A built control and an unbuilt one must not read the same. Cite the commit,\n'
        printf '    or write `control — unbuilt` while it waits.\n'
        findings=$((findings + 1))
      fi
      ;;
    *"**advice**"*)
      # Advice has to land somewhere read at session start, and say so.
      if ! printf '%s' "$disposition" | grep -qE 'CLAUDE\.md|WORKFLOW\.md|SKILL\.md|landed'; then
        printf '%s:%s  %s is advice that does not say where it landed\n' "$backlog" "$line" "$id"
        printf '    A rule only in the backlog is a rule nobody reads. Name the file that\n'
        printf '    carries it -- CLAUDE.md, WORKFLOW.md, or a skill body.\n'
        findings=$((findings + 1))
      fi
      ;;
  esac
done < <(grep -nE '^\| *AI-[0-9]+ *\|' "$backlog")

echo
if [ "$findings" -gt 0 ]; then
  echo "backlog-lint: $findings row(s) do not say what kind of item they are."
  exit 1
fi
echo "backlog-lint: every row carries a disposition."
