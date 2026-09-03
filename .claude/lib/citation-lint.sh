#!/usr/bin/env bash
# Every citation in a harness document resolves to something that exists.
#
# Usage:
#   citation-lint.sh <dir-or-file>...
#
# Two kinds of citation, both of which have already been wrong:
#
#   commits   `cadre \`b534fb27\`` -- the repository is named beside the sha,
#             so it can be resolved. An evidence trail whose commits do not
#             resolve is a trail to nowhere, and it fails silently: a reader
#             sees a plausible sha and moves on.
#
#   paths     A backticked vault-relative path. A rule "landed in" a file
#             that does not exist has not landed; a control "built at" a
#             missing test is unbuilt.
#
# Why this exists. Six of the eight defects found in two phases of the
# controls-not-advice ultragoal were a claim in one document contradicting
# another document or the code -- a row citing a landing never made, a row
# claiming coverage another row denied, a criterion whose evidence pointed
# at the wrong artifact. Every one was caught by a human cross-checking by
# hand, and none by any check. `duplicate_paragraphs_test.go` finds stale
# prose beside its correction inside one file; nothing looked outward from a
# claim to the thing it names.
#
# What this does NOT do, said rather than implied.
#
# It resolves a citation, not the claim wrapped around it. A row saying a
# control guards X, citing a test that exists and guards Y, passes here.
#
# That matters more than it sounds, and the honest accounting is this:
# **of the six defects that motivated this check, it would have caught
# none.** Every one was a claim that was wrong about an artifact that
# existed -- a row asserting coverage another row denied, a row labelled
# advice pointing at a real file, a skill teaching a format its own lint
# rejected. The cited things were all there. The semantic half is where
# those live, and it is not built.
#
# What this does catch is a fabricated or stale reference: a sha that never
# existed or was rewritten, a path that was renamed or never created. That
# is a real class -- an evidence trail whose commits do not resolve is a
# trail to nowhere, and it fails silently because a plausible sha invites no
# scrutiny -- but it is not the class that prompted the item, and claiming
# otherwise would be the exact overreach this harness keeps finding.
#
# Path checking is scoped to records under 04-projects/: evidence, ledgers,
# specs, the backlog. Skill bodies are excluded deliberately -- they
# describe procedures over files that do not exist until the procedure runs
# (`.claude/logs/loop-ledger.tsv` is appended to by the closed loop;
# content-factory's ledger is written on its first run), and flagging a
# write target as a broken read is noise that gets a check switched off.
set -uo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: citation-lint.sh <dir-or-file>..." >&2
  exit 2
fi

vault="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

repo_path() {
  case "$1" in
    cadre)        echo "$HOME/sdk/cadre" ;;
    gloop)        echo "$HOME/sdk/gloop" ;;
    recall)       echo "$HOME/sdk/recall" ;;
    cadre-kernel) echo "$HOME/sdk/cadre-kernel" ;;
    vault)        echo "$vault" ;;
    *)            echo "" ;;
  esac
}

findings=0
checked_commits=0
checked_paths=0

files=$(for target in "$@"; do
  if [ -d "$target" ]; then find "$target" -type f -name '*.md' 2>/dev/null
  elif [ -f "$target" ]; then echo "$target"
  fi
done | sort -u)

for doc in $files; do
  # ---- commit citations: a repository name beside a sha ----
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    line="${hit%%:*}"
    text="${hit#*:}"
    repo=$(printf '%s' "$text" | sed -E 's/^([a-z-]+).*/\1/')
    sha=$(printf '%s' "$text" | grep -oE '[0-9a-f]{7,40}')
    path=$(repo_path "$repo")
    [ -n "$path" ] || continue
    [ -d "$path/.git" ] || continue

    # A GitHub Actions run id is decimal and about eleven digits, so it sits
    # entirely inside [0-9a-f]{7,40} and reads as a sha to everything here.
    # That collision is not hypothetical: the harness *requires* run ids in
    # the ledger ("write the run id, not the word green"), so the two
    # citation kinds were guaranteed to meet, and this check called four
    # real run ids unresolvable commits.
    #
    # Resolving it by skipping decimals would drop real all-digit shas and,
    # worse, make a run id unverifiable by being invisible. Instead the
    # ambiguity is refused at the source: a run id has to say it is one.
    if printf '%s' "$sha" | grep -qE '^[0-9]{9,}$'; then
      printf '%s:%s  %s `%s` looks like a CI run id written as a commit citation\n' "$doc" "$line" "$repo" "$sha"
      printf '    Decimal and eleven digits is a run id, not a sha, and nothing downstream\n'
      printf '    can tell them apart. Write it as `%s validate run %s` so a reader knows\n' "$repo" "$sha"
      printf '    which artifact to open.\n'
      findings=$((findings + 1))
      continue
    fi

    checked_commits=$((checked_commits + 1))
    if ! git -C "$path" cat-file -e "${sha}^{commit}" 2>/dev/null; then
      printf '%s:%s  %s `%s` does not resolve in %s\n' "$doc" "$line" "$repo" "$sha" "$path"
      printf '    A trail whose commits do not resolve is a trail to nowhere, and it fails\n'
      printf '    silently: the sha looks plausible and a reader moves on.\n'
      findings=$((findings + 1))
    fi
  done < <(grep -noE '\b(cadre|gloop|recall|cadre-kernel|vault)(-kernel)? `[0-9a-f]{7,40}`' "$doc" 2>/dev/null | tr -d '`')

  # ---- vault-relative path citations ----
  while IFS= read -r hit; do
    [ -n "$hit" ] || continue
    line="${hit%%:*}"
    cited=$(printf '%s' "${hit#*:}" | tr -d '`')
    # Only paths anchored in a known vault directory: anything else may
    # legitimately name a file in another repository, and guessing which
    # would produce noise that gets the check switched off.
    # Records only. See the header for why skill bodies are excluded.
    case "$doc" in
      *04-projects/*) ;;
      *) continue ;;
    esac
    # Two anchorings, because harness records use both. A vault-relative path
    # resolves from the vault root; a goal-relative one -- `evidence/P1/...`,
    # which is how every traceability row cites its evidence -- resolves from
    # the directory holding the document.
    #
    # Only the first was checked at first, so the single most common citation
    # form in the harness was skipped: a spec citing a dozen evidence files
    # reported "1 path checked". A traceability row was marked `verified`
    # against a CP-5 acceptance file that did not exist, and this passed it.
    resolved=""
    case "$cited" in
      04-projects/*|.claude/*|01-daily/*|05-knowledge/*|00-inbox/*)
        resolved="$vault/$cited" ;;
      CP-*.md)
        # A bare filename in backticks is a name, not a path: a report saying
        # "see `CP-3-triage.md`" is naming a document, not locating one
        # relative to itself. Treating those as paths produced six findings
        # for files that all existed one directory away. Only a citation
        # carrying a separator is a path.
        continue ;;
      evidence/*|*/evidence/*|report.html|spec.md|STATUS.md|*-*/evidence/*)
        # Try the document's own directory, then the goal root -- an evidence
        # file citing `spec.md` means the goal's, two levels up, and a
        # traceability row citing `evidence/P1/...` means the goal's too.
        resolved="$(dirname "$doc")/$cited"
        if [ ! -e "$resolved" ]; then
          probe="$(dirname "$doc")"
          while [ "$probe" != "/" ] && [ "$probe" != "." ]; do
            if [ -f "$probe/spec.md" ]; then
              [ -e "$probe/$cited" ] && resolved="$probe/$cited"
              break
            fi
            probe="$(dirname "$probe")"
          done
        fi
        # And the projects root: a report comparing two goals cites the other
        # as `repo-consolidation/evidence/P3/...`.
        if [ ! -e "$resolved" ] && [ -e "$vault/04-projects/$cited" ]; then
          resolved="$vault/04-projects/$cited"
        fi
        ;;
      *) continue ;;
    esac
    # A template placeholder is not a citation.
    case "$cited" in
      *YYYY*|*'<'*|*'>'*) continue ;;
    esac
    # Nor is range shorthand. A report writing `CP-3v-round1..4.md` means four
    # files, not one named with dots in it -- and `..` inside a *filename* is
    # never a real path, unlike `../` as a directory step.
    case "$(basename "$cited")" in
      *..*) continue ;;
    esac
    # Nor is a path the document itself declares absent. Evidence describing
    # a falsification quotes the fake path it injected, and a check that
    # flags those is flagging the very demonstration that it works.
    if sed -n "${line}p" "$doc" | grep -qiE 'does not exist|nonexistent|no such file|deliberately absent'; then
      continue
    fi
    checked_paths=$((checked_paths + 1))
    if [ ! -e "$resolved" ]; then
      printf '%s:%s  cites %s, which does not exist\n' "$doc" "$line" "$cited"
      printf '    A rule landed in a file nobody can open has not landed; a control built at\n'
      printf '    a missing test is unbuilt.\n'
      findings=$((findings + 1))
    fi
    # Backticked paths, and bare ones in a table cell. A traceability row is
    # written `| AC-3 | P1 | evidence/P1/CP-5-acceptance.md | verified |` with
    # no backticks anywhere -- so requiring them skipped every traceability
    # citation in the harness, which is the one place a phase marks itself
    # verified against a file. One such row cited a CP-5 acceptance that had
    # never been written, and this check passed it twice.
  done < <( { grep -noE '`[A-Za-z0-9_.][A-Za-z0-9_./-]+\.(md|sh|go|py|json|ya?ml|html|tsv)`' "$doc";
              grep -noE '(^|\| )(evidence|docs)/[A-Za-z0-9_./-]+\.(md|sh|go|json|ya?ml|html|tsv)' "$doc" \
                | sed -E 's/:(\| )?/:/'; } 2>/dev/null | sort -u -t: -k1,1n -k2 )
done

echo
echo "citation-lint: $checked_commits commit citation(s), $checked_paths vault path(s) checked."
if [ "$findings" -gt 0 ]; then
  echo "citation-lint: $findings citation(s) do not resolve."
  exit 1
fi
echo "citation-lint: every citation resolves."
