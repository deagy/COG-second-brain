#!/usr/bin/env bash
# Two release-hygiene properties, for the repositories an evidence trail
# makes claims about.
#
# Usage:
#   release-hygiene.sh <repo-dir-or-slug>...
#
# Checks, per repository:
#   1. It carries a LICENSE of its own.                             (AI-20)
#   2. Every git tag has a GitHub Release behind it.                (AI-19)
#   3. Every exception below still applies.
#
# Why this exists. Both defects were found by a person looking, twice, and
# both are the same shape as everything else this harness catches: a silent
# omission whose absence is indistinguishable from success.
#
# AI-19 -- recall carried v0.3.0, v0.3.1 and v0.3.2, three tags whose
# release pipeline published nothing, for two reasons at once: a tag pushed
# with the workflow's own GITHUB_TOKEN triggers no further workflow, and the
# release job lacked a checkout its fail-closed contract guard needed. A tag
# with no release looks exactly like a tag whose release you have not looked
# for yet. This is the check that would have found it without a person.
#
# AI-20 -- nothing in any of the four repositories gates on carrying a
# licence. recall runs `go-licenses`, which checks *dependency* licences and
# would not notice its own absence. The lifecycle kernel was public and
# unlicensed while cadre's installer fetched it by version.
#
# Deliberately strict about its own exceptions. A tag named below that no
# longer exists, or a licence exception for a repository that has since
# acquired one, is a FAILURE rather than a no-op. An exception list nobody
# prunes is how a guard stops guarding: it grows until it covers the next
# real defect, and every entry still reads as deliberate.
#
# Every exception carries its reason, because an exclusion outlives its
# justification invisibly otherwise -- `linux/arm64` sat excluded as "needs a
# native arm64 runner" for months after the runner arrived, and a clean-machine
# install found it by having no binary to fetch.
set -euo pipefail

# Tag-prefix patterns exempt in every repository, with their reason.
GLOBAL_TAG_PATTERN_EXCEPTIONS='
archive/*|a salvage marker, not a release: these tags exist to keep deleted work reachable
'

# Per-repository exceptions: slug|kind|subject|reason
#   kind=tag      subject is an exact tag name or a glob
#   kind=license  subject is unused
EXCEPTIONS='
deagy/cadre|tag|kernel-v*|the kernel moved to deagy/cadre-kernel and these releases were deleted so it has one release home; the tags are kept as history and not added to
deagy/cadre|tag|v0.1.1|inherited bare tag from before the component-prefixed scheme; predates cli-v*/plugin-v*/kernel-v*
deagy/cadre|tag|v0.15.0|inherited bare tag from before the component-prefixed scheme
deagy/cadre|tag|v0.16.0|inherited bare tag from before the component-prefixed scheme
deagy/cadre|tag|v1|inherited bare tag from before the component-prefixed scheme
deagy/cadre|tag|v2|inherited bare tag from before the component-prefixed scheme
deagy/cadre|tag|v6|inherited bare tag from before the component-prefixed scheme
deagy/cadre|tag|v7|inherited bare tag from before the component-prefixed scheme
deagy/recall|tag|v0.3.0|published nothing: a tag pushed with the workflow GITHUB_TOKEN triggers no workflow, and the release job lacked the checkout its contract guard needed. Both fixed before v0.3.3; kept as the history of the defect AI-19 exists for
deagy/recall|tag|v0.3.1|same defect as v0.3.0, before the tag pipeline was fixed
deagy/recall|tag|v0.3.2|same defect as v0.3.0, before the tag pipeline was fixed
deagy/gloop|tag|*|this repository publishes no releases by decision: private, one consumer, and it builds from a checkout. Its README says so in its own voice. A release nobody installs would be a claim it cannot keep
deagy/gloop|license|-|private with a single consumer and no licence claim anywhere in the repository. A repository that makes no licence claim needs no licence to be honest; one that claims a licence it does not carry is what AC-1 exists for
'

if [ "$#" -eq 0 ]; then
  echo "usage: release-hygiene.sh <repo-dir-or-slug>..." >&2
  echo "  e.g. release-hygiene.sh ~/sdk/cadre ~/sdk/recall deagy/gloop" >&2
  exit 2
fi

if ! command -v gh >/dev/null 2>&1; then
  echo "release-hygiene: gh is required and not on PATH" >&2
  exit 2
fi

failures=0
stale=0

matches_glob() { case "$1" in $2) return 0 ;; *) return 1 ;; esac; }

reason_for_tag() {
  # $1 slug, $2 tag -> prints reason on stdout, returns 0 if exempt
  local slug="$1" tag="$2" line pat reason
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    pat=${line%%|*}; reason=${line#*|}
    if matches_glob "$tag" "$pat"; then printf '%s' "$reason"; return 0; fi
  done <<< "$GLOBAL_TAG_PATTERN_EXCEPTIONS"
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in "$slug|tag|"*) ;; *) continue ;; esac
    local rest=${line#"$slug|tag|"}
    pat=${rest%%|*}; reason=${rest#*|}
    if matches_glob "$tag" "$pat"; then printf '%s' "$reason"; return 0; fi
  done <<< "$EXCEPTIONS"
  return 1
}

license_excepted() {
  local slug="$1" line
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in "$slug|license|"*) return 0 ;; esac
  done <<< "$EXCEPTIONS"
  return 1
}

for target in "$@"; do
  if [ -d "$target" ]; then
    slug=$(git -C "$target" remote get-url origin 2>/dev/null |
      sed -E 's#(git@github\.com:|https://github\.com/)##; s#\.git$##')
  else
    slug="$target"
  fi
  if [ -z "${slug:-}" ]; then
    printf '%-22s %s\n' "$target" "not a git checkout with a GitHub origin"
    failures=$((failures + 1)); continue
  fi

  tags=$(gh api "repos/$slug/tags" --paginate --jq '.[].name' 2>/dev/null || true)
  releases=$(gh api "repos/$slug/releases" --paginate --jq '.[].tag_name' 2>/dev/null || true)
  # gh writes a 404 body to *stdout*, so redirecting stderr is not enough:
  # key on the exit code and leave $license empty when there is no licence.
  license=""
  if out=$(gh api "repos/$slug/license" --jq '.license.spdx_id' 2>/dev/null); then
    license="$out"
  fi

  repo_fail=0

  # 1. LICENSE
  if [ -z "$license" ] || [ "$license" = "null" ] || [ "$license" = "NOASSERTION" ]; then
    if license_excepted "$slug"; then
      :
    else
      printf '%-22s %s\n' "$slug" "NO LICENSE -- nothing else in this repository gates on it"
      repo_fail=$((repo_fail + 1))
    fi
  else
    if license_excepted "$slug"; then
      printf '%-22s %s\n' "$slug" "STALE EXCEPTION: excused for having no licence, but now carries $license"
      stale=$((stale + 1))
    fi
  fi

  # 2. every tag has a release
  while IFS= read -r tag; do
    [ -z "$tag" ] && continue
    if printf '%s\n' "$releases" | grep -qxF "$tag"; then continue; fi
    if reason_for_tag "$slug" "$tag" >/dev/null; then continue; fi
    printf '%-22s %s\n' "$slug" "TAG WITH NO RELEASE: $tag -- indistinguishable from one whose release you have not looked for"
    repo_fail=$((repo_fail + 1))
  done <<< "$tags"

  # 3. every named tag exception still names something real
  while IFS= read -r line; do
    [ -z "$line" ] && continue
    case "$line" in "$slug|tag|"*) ;; *) continue ;; esac
    rest=${line#"$slug|tag|"}; pat=${rest%%|*}
    hit=0
    while IFS= read -r tag; do
      [ -z "$tag" ] && continue
      if matches_glob "$tag" "$pat"; then hit=1; break; fi
    done <<< "$tags"
    if [ "$hit" -eq 0 ]; then
      printf '%-22s %s\n' "$slug" "STALE EXCEPTION: no tag matches '$pat' any more"
      stale=$((stale + 1))
    fi
  done <<< "$EXCEPTIONS"

  if [ "$repo_fail" -eq 0 ]; then
    ntags=$(printf '%s\n' "$tags" | grep -c . || true)
    printf '%-22s %s\n' "$slug" "ok -- ${license:-no licence, by exception}, $ntags tag(s), every one accounted for"
  fi
  failures=$((failures + repo_fail))
done

if [ "$failures" -ne 0 ] || [ "$stale" -ne 0 ]; then
  echo >&2
  [ "$failures" -ne 0 ] && echo "release-hygiene: $failures problem(s)." >&2
  [ "$stale" -ne 0 ] && echo "release-hygiene: $stale stale exception(s). An exception list nobody prunes stops guarding." >&2
  exit 1
fi

echo
echo "release-hygiene: every repository carries a licence, and every tag has a release or a stated reason."
