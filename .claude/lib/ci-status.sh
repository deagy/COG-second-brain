#!/usr/bin/env bash
# CI status for the repositories an evidence trail makes claims about.
#
# Usage:
#   ci-status.sh <repo-dir-or-slug>...
#
# Prints one line per repository and exits non-zero unless every one of them
# has a *successful* CI run for the exact commit at HEAD.
#
# Why this exists. The repo-consolidation ultragoal recorded "full suite
# green" for a criterion whose commit had a red runner, and stayed wrong for
# nine further pushes. Three separate repositories were red at once, each for
# the same reason: a cross-repository guard, correctly built to refuse to skip
# under CI, given no way to run. Every one of them passed locally, because a
# sibling checkout that exists on a developer machine and never on a runner
# was quietly satisfying it.
#
# A local `go test` exit code is not evidence about a repository. It is
# evidence about a laptop. This turns "green" into a claim with a run id
# behind it, which is the only form of it worth writing into a ledger.
#
# Deliberately strict:
#   - a commit with no CI run is NOT green. Absence of a check is not a pass.
#   - a run still in progress is NOT green. It has not finished disagreeing.
#   - only the run for HEAD's exact sha counts. A green run on an ancestor
#     says nothing about what was pushed.
set -euo pipefail

if [ "$#" -eq 0 ]; then
  echo "usage: ci-status.sh <repo-dir-or-slug>..." >&2
  echo "  e.g. ci-status.sh ~/sdk/cadre ~/sdk/recall deagy/gloop" >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "ci-status: gh is required and not on PATH" >&2
  exit 2
fi

failures=0

for target in "$@"; do
  if [ -d "$target" ]; then
    slug=$(git -C "$target" remote get-url origin 2>/dev/null |
      sed -E 's#(git@github\.com:|https://github\.com/)##; s#\.git$##')
    sha=$(git -C "$target" rev-parse HEAD 2>/dev/null || true)
    if [ -z "${slug:-}" ] || [ -z "${sha:-}" ]; then
      printf '%-28s %s\n' "$target" "not a git checkout with a GitHub origin"
      failures=$((failures + 1))
      continue
    fi
  else
    slug="$target"
    sha=$(gh api "repos/$slug/commits/HEAD" --jq .sha 2>/dev/null || true)
    # gh writes a 404 body to *stdout*, so an unresolvable slug leaves $sha
    # holding `{"message": "Not Found"...}` -- non-empty, and therefore past
    # an emptiness check. It is then handed to `gh run list --commit`, which
    # finds nothing, and the repository is reported as having no CI run.
    #
    # Fail-closed, so it never invents a green. What it does instead is give
    # the wrong reason: a bare `cadre` where `deagy/cadre` was meant reads as
    # "this repository has no CI", and someone goes looking at the runner
    # instead of at the argument. Three repositories were reported un-green
    # that way, all three of them green.
    if ! printf '%s' "$sha" | grep -qE '^[0-9a-f]{7,40}$'; then
      printf '%-28s %s\n' "$slug" \
        "no such repository -- a slug is owner/name, or pass a checkout directory"
      failures=$((failures + 1))
      continue
    fi
  fi

  short=${sha:0:8}

  # Every run for this exact sha, newest first. --json keeps the parse honest.
  runs=$(gh run list --repo "$slug" --commit "$sha" --limit 20 \
    --json databaseId,conclusion,status,name 2>/dev/null || echo '[]')

  total=$(echo "$runs" | python3 -c 'import json,sys; print(len(json.load(sys.stdin)))' 2>/dev/null || echo 0)

  if [ "$total" = "0" ]; then
    printf '%-28s %s  %s\n' "$slug" "$short" "NO RUN — a commit with no CI is not green"
    failures=$((failures + 1))
    continue
  fi

  verdict=$(echo "$runs" | python3 -c '
import json, sys
runs = json.load(sys.stdin)
pending = [r for r in runs if r.get("status") != "completed"]
failed = [r for r in runs if r.get("status") == "completed"
          and r.get("conclusion") not in ("success", "skipped", "neutral")]
if failed:
    r = failed[0]
    print("FAILED  %s run %s (%s)" % (r["name"], r["databaseId"], r["conclusion"]))
elif pending:
    r = pending[0]
    print("PENDING %s run %s -- not finished, so not green" % (r["name"], r["databaseId"]))
else:
    print("success run %s" % ", ".join(str(r["databaseId"]) for r in runs))
')

  printf '%-28s %s  %s\n' "$slug" "$short" "$verdict"
  case "$verdict" in
    success*) ;;
    *) failures=$((failures + 1)) ;;
  esac
done

if [ "$failures" -ne 0 ]; then
  echo >&2
  echo "ci-status: $failures repository/repositories are not green at HEAD." >&2
  echo "  A phase that records 'suite green' against one of these is recording a laptop." >&2
  exit 1
fi
