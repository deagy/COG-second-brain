#!/usr/bin/env bash
# When one backlog row talks about another, they have to agree.
#
# Usage:
#   crossref-lint.sh [backlog.md]      (default: 04-projects/harness/BACKLOG.md)
#
# Three of the defects found in the controls-not-advice ultragoal were a row
# making a claim about another row that the other row contradicted, and all
# three had perfect shape:
#
#   AI-1 read `advice` while AI-11 -- the other half of the same merged item
#   -- read `control`. Two rows for one item disagreeing about whether it was
#   built, in the commit that introduced the vocabulary to prevent that.
#
#   AI-14 claimed AI-13's control covered its originating instance. AI-13's
#   own row said the opposite, and so did the evidence. The claim sat in the
#   one place a reader checking coverage would look.
#
#   AI-9 referred to "AI-2's control" after AI-2's control had been withdrawn.
#
# Every one was found by a person cross-checking by hand. `citation-lint.sh`
# resolves a reference and would have caught none of them: the rows they
# named all existed. This is the next layer -- not whether the reference
# resolves, but whether the claim wrapped around it survives contact with
# what it points at.
#
# It reaches three invariants and no further. It cannot read a sentence.
set -uo pipefail

backlog="${1:-04-projects/harness/BACKLOG.md}"
[ -f "$backlog" ] || { echo "no backlog at $backlog" >&2; exit 2; }

findings=0
rows="$(mktemp)"; trap 'rm -f "$rows"' EXIT

# id \t kind \t full row text
grep -nE '^\| *AI-[0-9]+ *\|' "$backlog" | while IFS= read -r entry; do
  line="${entry%%:*}"; text="${entry#*:}"
  id=$(printf '%s' "$text" | sed -nE 's/^\| *(AI-[0-9]+) *\|.*/\1/p')
  kind=$(printf '%s' "$text" | sed -E 's/.*\|([^|]*)\|[[:space:]]*$/\1/' | tr -d '`*' \
         | sed -E 's/^[[:space:]]*([a-z]+).*/\1/')
  printf '%s\t%s\t%s\t%s\n' "$id" "$kind" "$line" "$text"
done > "$rows"

kind_of() { awk -F'\t' -v want="$1" '$1 == want { print $2; exit }' "$rows"; }
text_of() { awk -F'\t' -v want="$1" '$1 == want { print $4; exit }' "$rows"; }

while IFS=$'\t' read -r id kind line text; do
  for ref in $(printf '%s' "$text" | grep -oE 'AI-[0-9]+' | grep -v "^${id}$" | sort -u); do
    ref_kind=$(kind_of "$ref")
    ref_text=$(text_of "$ref")
    [ -n "$ref_kind" ] || {
      printf '%s:%s  %s references %s, which is not a row in this file\n' "$backlog" "$line" "$id" "$ref"
      findings=$((findings + 1)); continue; }

    # 1. A merge is mutual, and both halves share a disposition.
    if printf '%s' "$text" | grep -qiE "merged with $ref\b"; then
      if ! printf '%s' "$ref_text" | grep -qiE "merged with $id\b"; then
        printf '%s:%s  %s says it is merged with %s; %s does not say so\n' "$backlog" "$line" "$id" "$ref" "$ref"
        printf '    A merge recorded on one side only leaves the other row free to drift.\n'
        findings=$((findings + 1))
      fi
      if [ "$kind" != "$ref_kind" ]; then
        printf '%s:%s  %s (%s) is merged with %s (%s) — one item, two dispositions\n' \
          "$backlog" "$line" "$id" "$kind" "$ref" "$ref_kind"
        printf '    AI-1 read advice while AI-11 read control, for the same merged item, in the\n'
        printf '    commit that introduced the vocabulary to prevent exactly that.\n'
        findings=$((findings + 1))
      fi
    fi

    # 2. A claim about another row's disposition must match it.
    for claimed in control advice landed; do
      if printf '%s' "$text" | grep -qiE "$ref'?s? (own )?$claimed\b|$ref is (a|an) $claimed\b"; then
        if [ "$ref_kind" != "$claimed" ]; then
          printf '%s:%s  %s calls %s a %s; %s is dispositioned %s\n' \
            "$backlog" "$line" "$id" "$ref" "$claimed" "$ref" "$ref_kind"
          printf '    A reference to a disposition that has since changed reads as current.\n'
          findings=$((findings + 1))
        fi
      fi
    done

    # 3. A coverage claim must not be denied by the row it names.
    if printf '%s' "$text" | grep -qiE "$ref (covers|closes|supersedes)\b"; then
      if printf '%s' "$ref_text" | grep -qiE 'does \*?\*?not\*?\*? cover|narrower than|guards less'; then
        printf '%s:%s  %s says %s covers it; %s says it does not\n' "$backlog" "$line" "$id" "$ref" "$ref"
        printf '    This is where a reader checking coverage looks, and it was wrong once.\n'
        findings=$((findings + 1))
      fi
    fi
  done
done < "$rows"

echo
if [ "$findings" -gt 0 ]; then
  echo "crossref-lint: $findings cross-reference(s) disagree."
  exit 1
fi
echo "crossref-lint: every cross-reference agrees with the row it names."
