#!/usr/bin/env bash
# Three properties of a harness evidence bundle, each from a defect that
# already got through.
#
# Usage:
#   evidence-lint.sh <goal-dir>...
#
# Exits non-zero if any check fires. Each check is independent; they share a
# file because they read the same artifacts, not because they are one check.
#
#   inventory  An enumeration piped through `head` with no total beside it.
#              A P3 inventory reported eleven matches from `grep ... | head
#              -10` when the real count was thirty-one. Truncation leaves no
#              mark in the output: ten results look like ten results, and
#              the reader has no way to tell a complete list from a prefix.
#
#   salvage    A retire/archive verdict with no working-tree state beside it.
#              A repository was assessed for salvage from committed state
#              alone while 209 uncommitted lines sat in the working tree,
#              including the one artifact that turned out to be worth
#              keeping. The verdict is judgment; looking before judging is
#              not.
#
#   axes       A port or extraction plan missing one of its five inventory
#              axes. The originating defect was not a badly filled axis but
#              an absent one: four axes were run against the source
#              repository and none against the destination, so "what does
#              the destination already do" was never asked.
#
# Scoped to evidence and plan documents under a goal folder. These patterns
# are ordinary and correct in most prose; it is only inside an artifact
# claiming to be an inventory, a verdict, or a plan that they are defects.
set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: evidence-lint.sh <goal-dir>..." >&2
  exit 2
fi

findings=0
hits="$(mktemp)"
trap 'rm -f "$hits"' EXIT

note() {
  printf '%s:%s  %s\n' "$1" "$2" "$3"
  findings=$((findings + 1))
}

for goal in "$@"; do
  goal="${goal%/}"
  [ -d "$goal" ] || { echo "no such goal directory: $goal" >&2; exit 2; }

  # ---- inventory: a truncated enumeration with no total ----
  while IFS= read -r doc; do
    [ -f "$doc" ] || continue
    # Only look inside fenced blocks: prose describing `| head` is not a
    # truncated inventory, it is a sentence about one.
    awk -v doc="$doc" '
      /^```/ { infence = !infence; next }
      infence && /(grep|rg|find|git ls-files)/ && /\| *(head|tail)/ {
        print NR "\t" $0
      }
    ' "$doc" > "$hits"
    # Read via redirection, not a pipe: a `while` on the right of a pipe runs
    # in a subshell, so the finding count increments in a process that then
    # exits. This check reported its defect and returned 0 until that was
    # fixed -- a lint that prints a finding and exits clean is not a gate.
    while IFS=$'\t' read -r line text; do
      # A total anywhere in the same document discharges it: `wc -l`, an
      # explicit count, or a stated "N total".
      if grep -qiE 'wc -l|[0-9]+ (total|hits|matches|results)|count(ed)? [0-9]+' "$doc"; then
        continue
      fi
      note "$doc" "$line" "inventory piped through head/tail with no total anywhere in this document
    An enumeration truncated at N looks exactly like an enumeration of N.
    Count first (\`| wc -l\`), then read all of them.
      $(echo "$text" | sed 's/^[[:space:]]*//')"
    done < "$hits"
    
  done < <(find "$goal" -type f -name '*.md' \( -path '*/evidence/*' -o -name 'CP-*.md' \) 2>/dev/null)

  # ---- salvage: a retire verdict with no working-tree state ----
  while IFS= read -r doc; do
    [ -f "$doc" ] || continue
    grep -qiE 'nothing (survives|worth salvaging)|no salvage|retire (the|this) repo|archive (the|this) repo|deleted outright' "$doc" || continue
    if grep -qE 'git status|--porcelain|working tree|uncommitted' "$doc"; then
      continue
    fi
    line=$(grep -niE 'nothing (survives|worth salvaging)|no salvage|retire (the|this) repo|archive (the|this) repo|deleted outright' "$doc" | head -1 | cut -d: -f1)
    note "$doc" "$line" "a retire/archive verdict with no working-tree state recorded
    Quote \`git status --porcelain\` for the repository beside the verdict.
    A salvage assessment made from committed state alone once missed 209
    uncommitted lines holding the one artifact worth keeping."
  done < <(find "$goal" -type f -name '*.md' 2>/dev/null)

  # ---- axes: a port plan missing an inventory axis ----
  while IFS= read -r doc; do
    [ -f "$doc" ] || continue
    # An inventory plan names its own axes -- "## The four-axis inventory",
    # "### Axis 1 -- what imports it". That is a far better trigger than any
    # phrase for "this is a port plan": the originating plan never called
    # itself one, and a self-declaration can be forgotten, which is the same
    # omission this check exists to catch.
    grep -qiE '^#+ .*axis|[a-z]+-axis inventory' "$doc" || continue
    missing=""
    grep -qiE 'import' "$doc"                              || missing="$missing imports"
    grep -qiE 'prose|mention|documentation reference' "$doc" || missing="$missing prose-mentions"
    grep -qiE 'data reader|reads (its|the) data|what reads|data consumer|consumer of the data' "$doc" || missing="$missing data-readers"
    grep -qiE 'releasable|release(d|able)? component|module boundary' "$doc" || missing="$missing releasable-components"
    grep -qiE 'destination already|what the destination|already does|receiving repo' "$doc" || missing="$missing destination-already-does"
    [ -n "$missing" ] || continue
    note "$doc" "1" "port/extraction plan missing inventory axis:$missing
    Five axes, and the fifth is the one that was missed: four described what
    moves and none asked what it moves into."
  done < <(find "$goal" -type f -name '*plan*.md' 2>/dev/null)
done

echo
if [ "$findings" -gt 0 ]; then
  echo "evidence-lint: $findings finding(s)."
  exit 1
fi
echo "evidence-lint: clean."
