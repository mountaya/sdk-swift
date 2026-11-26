#!/usr/bin/env bash
# USAGE-START
# Releases sdk-swift: one tag of this repository, the version of every product, pushed to the
# repository on Entire, whose CI mirrors it to the public GitHub mirror SwiftPM resolves it from.
#
#   mise run release <version> [--yes]
#   mise run release <version> --dry-run [--skip-gate]
#
# <version> is MAJOR.MINOR.PATCH, the version ClientIdentification.version names, newer than every
# `v*` tag here and on the mirror. The release asks before it commits; --yes answers yes. The
# repository on Entire is the remote `origin`; RELEASE_ENTIRE_REMOTE names another. The mirror is
# https://github.com/mountaya/sdk-swift; RELEASE_MIRROR_URL names another to ask which tags it
# holds and to wait on, such as a stand-in for a test.
#
# --dry-run touches no git of this repository and pushes nothing: it runs every other check and
# the gate, then says what a release would do. --skip-gate leaves the gate out of a dry run, and
# is refused without one.
# USAGE-END
#
# The preflight refuses, each refusal with what to do, and runs the gate only once nothing else
# refused, since it is the longest step: no git repository; a version that is not
# MAJOR.MINOR.PATCH, already tagged here or on Entire, or not newer than the newest tag; a mirror
# that holds the version's tag or a newer one, or cannot be asked; a version other than the one
# every request names, `ClientIdentification.version`; a working tree with changes; a commit that
# is not `main` at the commit Entire's `main` is at, or no remote for Entire; a CHANGELOG.md with
# nothing to say for the version; a sibling checkout that is not clean at the commit siblings.lock
# pins; a licence text that differs from sdk-typescript's bytes, or no sdk-typescript beside this
# repository to compare with; and a gate that fails: `mise run disk:check`, then `mise run ci`,
# which holds the API baselines, the README's snippets and the licence too.
#
# Then, once it has said what it will do and been answered: the changelog's `[Unreleased]` notes
# become the version's section with today's date, in a commit "version: Release v<version>"
# that holds that change alone, unless CHANGELOG.md holds the section already; the annotated tag
# `v<version>` is made on it; `main` at that commit is pushed to Entire, then the tag, since Entire
# takes no atomic push; and the release waits until the mirror lists the tag, which the Depot
# workflow mirror.yml pushes there from Entire. No other branch is pushed and nothing else is
# committed.
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"
require_cmd git "git, which comes with Xcode's command line tools: xcode-select --install"
require_cmd awk "awk, which comes with the operating system"
require_cmd cmp "cmp, which comes with the operating system"
require_cmd mise "mise: sh .agents/setup installs it"

root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"

version=""
yes=0
dry_run=0
skip_gate=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes) yes=1 ;;
    --dry-run) dry_run=1 ;;
    --skip-gate) skip_gate=1 ;;
    -*) die "\`$1\` is no option of the release." "bash scripts/release.sh --help" ;;
    *)
      [ -z "$version" ] || die "The release takes one version, and was given \`$version\` and \`$1\`." \
        "mise run release <version>, such as: mise run release 0.1.0"
      version="$1"
      ;;
  esac
  shift
done
[ -n "$version" ] || die "The release takes the version it releases." \
  "mise run release <version>, such as: mise run release 0.1.0"
if [ "$dry_run" -eq 0 ]; then
  [ "$skip_gate" -eq 0 ] || die "--skip-gate is for a dry run alone: a release is never made from a tree the gate did not pass." \
    "Run the release without --skip-gate, or the dry run with --dry-run."
fi

entire="${RELEASE_ENTIRE_REMOTE:-origin}"
# The public, read-only mirror on GitHub, which the Depot workflow mirror.yml pushes every push of
# `main` and every release tag to, from Entire. Nothing pushes to it by hand.
mirror="${RELEASE_MIRROR_URL:-https://github.com/mountaya/sdk-swift}"
mirror="${mirror%/}"
tag="v$version"
date="$(date -u +%Y-%m-%d)"

# A repository at this root, before anything asks git about one.
if [ "$dry_run" -eq 0 ]; then
  toplevel="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -z "$toplevel" ] || [ "$(cd "$toplevel" && pwd -P)" != "$root" ]; then
    die "$root is no git repository, so there is nothing to tag." \
      "Release from a clone of sdk-swift's repository on Entire: entire repo clone /et/mountaya/sdk-swift" \
      "Or rehearse everything but git and the publishing: mise run release $version --dry-run"
  fi
fi

refusals=()
refuse() {
  refusals+=("$1")
}

# is_version <text>: MAJOR.MINOR.PATCH, each a number with no leading zero.
is_version() {
  printf '%s\n' "$1" | grep -Eq '^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)$'
}

# newer <a> <b>: whether version a comes after version b.
newer() {
  local a1 a2 a3 b1 b2 b3
  IFS=. read -r a1 a2 a3 <<<"$1"
  IFS=. read -r b1 b2 b3 <<<"$2"
  [ "$a1" -gt "$b1" ] && return 0
  [ "$a1" -lt "$b1" ] && return 1
  [ "$a2" -gt "$b2" ] && return 0
  [ "$a2" -lt "$b2" ] && return 1
  [ "$a3" -gt "$b3" ]
}

# unreleased_notes: the [Unreleased] section's text, its blank lines at either end left out.
unreleased_notes() {
  awk '
    /^## \[Unreleased\][[:space:]]*$/ { inside = 1; next }
    inside && /^## \[/ { exit }
    inside { lines[++n] = $0 }
    END {
      first = 1
      while (first <= n && lines[first] ~ /^[[:space:]]*$/) first++
      last = n
      while (last >= first && lines[last] ~ /^[[:space:]]*$/) last--
      for (i = first; i <= last; i++) print lines[i]
    }
  ' CHANGELOG.md
}

# released_section <version>: the heading of the version's own section where CHANGELOG.md holds
# one, as a release that stopped after its commit leaves it.
released_section() {
  local escaped
  escaped="$(printf '%s' "$1" | sed 's/\./\\./g')"
  grep -Ex "## \[$escaped\] - [0-9]{4}-[0-9]{2}-[0-9]{2}" CHANGELOG.md | sed -n 1p || true
}

# moved_changelog <version>: CHANGELOG.md as the release writes it, the notes under [Unreleased]
# moved to <version> and today's date; the file as it stands where it holds that section already.
moved_changelog() {
  if [ -n "$(released_section "$1")" ]; then
    cat CHANGELOG.md
    return 0
  fi
  awk -v version="$1" -v date="$date" '
    function emit(more,   first, last, i) {
      first = 1
      while (first <= n && lines[first] ~ /^[[:space:]]*$/) first++
      last = n
      while (last >= first && lines[last] ~ /^[[:space:]]*$/) last--
      print ""
      print "## [" version "] - " date
      print ""
      for (i = first; i <= last; i++) print lines[i]
      if (more) print ""
    }
    /^## \[Unreleased\][[:space:]]*$/ { print; inside = 1; next }
    inside && /^## \[/ { emit(1); inside = 0 }
    inside { lines[++n] = $0; next }
    { print }
    END { if (inside) emit(0) }
  ' CHANGELOG.md
}

# mirrored_tag: the object the mirror lists for the tag, nothing where it lists none or cannot be
# asked. A mirror asked over https never prompts for a login, so one it cannot read fails at once.
mirrored_tag() {
  GIT_TERMINAL_PROMPT=0 git ls-remote "$mirror" "refs/tags/$tag" 2>/dev/null | awk 'NR == 1 { print $1 }' || true
}

# gate <step> <command>...: one step of the gate, refused where it fails.
gate() {
  local step="$1"
  shift
  "$@" && return 0
  refuse "The gate failed at \`$step\`, so what would be released is not what passed.

  Fix: fix what it reported, commit, push, then run the release again."
  return 1
}

# Entire, asked once for its `main` and the tag.
entire_known=0
entire_error=""
entire_main=""
entire_tag=""
if [ "$dry_run" -eq 0 ] && git remote get-url "$entire" >/dev/null 2>&1; then
  entire_known=1
  if answer="$(git ls-remote "$entire" refs/heads/main "refs/tags/$tag" 2>&1)"; then
    entire_main="$(printf '%s\n' "$answer" | awk '$2 == "refs/heads/main" { print $1 }')"
    entire_tag="$(printf '%s\n' "$answer" | awk -v ref="refs/tags/$tag" '$2 == ref { print $1 }')"
  else
    entire_error="$answer"
  fi
fi

if ! is_version "$version"; then
  refuse "\`$version\` is no release version: a release is MAJOR.MINOR.PATCH, each a number with no
leading zero.

  Fix: run the release with a version such as 0.1.0."
else
  if [ "$dry_run" -eq 0 ]; then
    newest=""
    for existing in $(git tag --list 'v*'); do
      candidate="${existing#v}"
      is_version "$candidate" || continue
      if [ -z "$newest" ] || newer "$candidate" "$newest"; then
        newest="$candidate"
      fi
    done
    if git rev-parse --quiet --verify "refs/tags/$tag" >/dev/null; then
      refuse "$tag is already tagged here, on $(git rev-parse --short=12 "$tag^{commit}").

  Fix: where that release stopped before its push, push it, then wait for the mirror to list it:
  git push $entire $tag^{commit}:refs/heads/main && git push $entire refs/tags/$tag
  Otherwise release a version past $version."
    elif [ -n "$entire_tag" ]; then
      refuse "\`$entire\` already holds $tag, so $version is released.

  Fix: release a version past $version."
    elif [ -n "$newest" ] && ! newer "$version" "$newest"; then
      refuse "$version is not newer than v$newest, the newest tag, so SwiftPM would never resolve it
over the release before.

  Fix: release a version past $newest."
    fi
  fi
  # The mirror is the registry SwiftPM resolves from: it holds every released tag.
  if ! mirrored="$(GIT_TERMINAL_PROMPT=0 git ls-remote --tags --refs "$mirror" 2>&1)"; then
    refuse "The mirror, $mirror, could not be asked which tags it holds, and SwiftPM resolves every
release from there.

  Fix: reach $mirror, then run the release again."
  else
    for existing in $(printf '%s\n' "$mirrored" | sed -n 's|.*[[:space:]]refs/tags/v||p'); do
      is_version "$existing" || continue
      if [ "$existing" = "$version" ]; then
        refuse "The mirror, $mirror, already holds $tag, and a version is released once.

  Fix: release a version past $version."
        break
      elif newer "$existing" "$version"; then
        refuse "The mirror, $mirror, holds v$existing, newer than $version, so SwiftPM would never
resolve this one over it.

  Fix: release a version past $existing."
        break
      fi
    done
  fi
fi

# Every request names the package's version (`X-Mountaya-Client`), written once in the source, so
# the release is that version, or the tag and what the requests say part ways. BoundaryTests reads
# the line as this does.
identification="Sources/MountayaClient/Sending/Rules/ClientIdentification.swift"
stated="$(sed -nE 's/^[[:space:]]*static let version = "([^"]*)"[[:space:]]*$/\1/p' \
  "$identification" 2>/dev/null | head -n 1 || true)"
if [ -z "$stated" ]; then
  refuse "$identification holds no \`static let version = \"<version>\"\`, so nothing says which
version every request names.

  Fix: write \`static let version = \"$version\"\` there, commit it, then run the release again."
elif is_version "$version" && [ "$stated" != "$version" ]; then
  refuse "Every request names version $stated (\`ClientIdentification.version\`), and the release is
$version, so the tag and what the requests say would part ways.

  Fix: set \`static let version = \"$version\"\` in $identification, commit it, then run the
  release again."
fi

branch=""
if [ "$dry_run" -eq 0 ]; then
  if [ -n "$(git status --porcelain --untracked-files=normal)" ]; then
    refuse "The working tree holds changes no commit holds, so the tag would name a commit that is
not what passed the gate.

  Fix: commit or stash them (git status lists them), then run the release again."
  fi

  branch="$(git symbolic-ref --quiet --short HEAD || true)"
  if [ "$branch" != "main" ]; then
    refuse "The release stands on ${branch:-no branch}, and a release tags what is on \`main\`.

  Fix: check out \`main\` at the commit you mean to release, then run the release again."
  fi

  if [ "$entire_known" -eq 0 ]; then
    refuse "No remote named \`$entire\`, the repository on Entire, so neither \`main\` nor the tag would
reach anyone, the mirror included.

  Fix: git remote add $entire <the repository's address on Entire>, then run the release again."
  elif [ -n "$entire_error" ]; then
    refuse "Asking \`$entire\` for its \`main\` failed: $entire_error

  Fix: reach the remote, then run the release again."
  elif [ "$branch" = "main" ]; then
    head="$(git rev-parse HEAD)"
    if [ -z "$entire_main" ]; then
      refuse "\`$entire\` holds no \`main\`, so the release would stand on a history nobody else has.

  Fix: git push $entire main, then run the release again."
    elif [ "$entire_main" != "$head" ]; then
      refuse "This commit (${head:0:12}) is not the one \`$entire\`'s \`main\` is at (${entire_main:0:12}).

  Fix: push \`main\`, or check out the commit \`$entire\` holds, then run the release again."
    fi
  fi
fi

if [ ! -f CHANGELOG.md ]; then
  refuse "CHANGELOG.md is missing, so the release would say nothing of what it carries.

  Fix: write CHANGELOG.md with an \`## [Unreleased]\` section holding the notes, commit it, then run
  the release again."
elif [ -z "$(released_section "$version")" ] && [ -z "$(unreleased_notes)" ]; then
  refuse "CHANGELOG.md has no section for $version: nothing is written under \`## [Unreleased]\`.

  Fix: write what $version carries under \`## [Unreleased]\`, commit it, then run the release again."
fi

# The siblings the gate reads beside this checkout, each clean at the commit siblings.lock pins, so
# the gate runs on what CI tested this commit against and pre-commit moves no pin in the release's
# commit.
if [ "$dry_run" -eq 0 ] && ! siblings="$(sh .agents/siblings at-pins 2>&1)"; then
  refuse "A sibling beside this checkout is not clean at the commit siblings.lock pins, so the gate
would not run on what CI tested this commit against:
$(printf '%s\n' "$siblings" | sed 's/^/  /')

  Fix: do what the lines above say for each (sh .agents/siblings status shows every pin beside its
  sibling), then run the release again."
fi

typescript="$(cd .. && pwd -P)/sdk-typescript"
for text in LICENSE.txt LICENCE.fr.txt; do
  if [ ! -f "$typescript/$text" ]; then
    refuse "$typescript/$text is missing, so nothing holds $text to the licence the TypeScript
packages ship.

  Fix: clone sdk-typescript beside this repository, with: entire repo clone /et/mountaya/sdk-typescript,
  then run the release again."
  elif ! cmp -s "$text" "$typescript/$text"; then
    refuse "$text differs from sdk-typescript's, and the products ship the TypeScript packages'
licence byte for byte.

  Fix: copy sdk-typescript's $text over this one, commit it, then run the release again."
  fi
done

if [ "${#refusals[@]}" -eq 0 ]; then
  if [ "$skip_gate" -eq 1 ]; then
    warn "The gate is left out (--skip-gate): this dry run proves the checks alone."
  else
    info "Every check passed; running the gate (mise run disk:check, then mise run ci)."
    # The disk check passes under CI without looking, so it runs on its own first.
    if gate "mise run disk:check" mise run disk:check \
      && gate "mise run ci" env CI=true mise run ci; then
      ok "The gate passed."
    fi
  fi
fi

if [ "${#refusals[@]}" -gt 0 ]; then
  {
    echo ""
    echo "${PF_RED}${PF_BOLD}✗ The release of $version is refused.${PF_RESET}"
    for refusal in "${refusals[@]}"; do
      echo ""
      echo "$refusal"
    done
    echo ""
  } >&2
  exit 1
fi

if [ "$dry_run" -eq 1 ]; then
  echo ""
  ok "The dry run of $version passed."
  echo "A release would now move [Unreleased] to $version, commit it, tag $tag, push main and then"
  echo "$tag to $entire, and wait for $mirror to list $tag."
  exit 0
fi

entire_url="$(git remote get-url "$entire")"
section="$(released_section "$version")"
moved=1
[ -n "$section" ] || moved=0

# step <line> [<line>]: one numbered step of what the release does.
steps=0
step() {
  steps=$((steps + 1))
  echo "  $steps. $1"
  [ -z "${2:-}" ] || echo "     $2"
}

echo ""
echo "${PF_BOLD}The release of $version:${PF_RESET}"
if [ "$moved" -eq 0 ]; then
  step "CHANGELOG.md: the notes under [Unreleased] become [$version] - $date."
  step "A commit on main, \"version: Release $tag\", holding that change and nothing else."
else
  step "CHANGELOG.md already holds ${section#"## "}, committed: nothing to move, and no commit."
fi
step "The annotated tag $tag, on that commit."
step "main at that commit, pushed to $entire ($entire_url), then $tag."
step "A wait, up to ten minutes, until the mirror, $mirror, lists $tag:" \
  "the Depot workflow mirror.yml pushes it there from $entire."
echo ""
if [ "$yes" -eq 0 ]; then
  [ -t 0 ] || die "The release asks before it commits, and nothing can answer here." \
    "Run it from a terminal, or pass --yes once you have read what it does."
  printf 'Release %s? [y/N] ' "$version"
  read -r answer
  case "$answer" in
    y | Y | yes | Yes) ;;
    *) die "The release of $version was not made: nothing was committed, tagged or pushed." ;;
  esac
fi

if [ "$moved" -eq 0 ]; then
  moved_file="$(mktemp)"
  moved_changelog "$version" >"$moved_file"
  mv "$moved_file" CHANGELOG.md
  git add CHANGELOG.md
  if ! git commit --quiet -m "version: Release $tag"; then
    die "The commit \"version: Release $tag\" was stopped, by pre-commit as the lines above say: nothing was tagged or pushed, and CHANGELOG.md holds the moved notes, staged." \
      "Put CHANGELOG.md back as it was: git restore --staged --worktree CHANGELOG.md" \
      "Fix what pre-commit reported in a commit of its own, push it, then run the release again."
  fi
  ok "Committed CHANGELOG.md as \"version: Release $tag\"."
  section="## [$version] - $date"
fi

message="$(mktemp)"
{
  echo "sdk-swift $version"
  echo ""
  awk -v heading="$section" '
    $0 == heading { inside = 1; next }
    inside && /^## \[/ { exit }
    inside { print }
  ' CHANGELOG.md | sed '/./,$!d'
} >"$message"
git tag --annotate --cleanup=verbatim "$tag" --file "$message"
rm -f "$message"
ok "Tagged $tag on $(git rev-parse --short=12 HEAD)."

# Entire takes no atomic push, so main goes first and the tag after it: a tag on Entire then always
# names a commit its main holds, and a push that stops between the two leaves only the tag to push.
if ! git push "$entire" "HEAD:refs/heads/main"; then
  die "Pushing main to $entire failed; the commit and the tag are made here, and nothing was pushed." \
    "Once $entire is reachable: git push $entire HEAD:refs/heads/main && git push $entire refs/tags/$tag" \
    "Then wait for the mirror to list it: git ls-remote $mirror refs/tags/$tag"
fi
ok "Pushed main to $entire."
if ! git push "$entire" "refs/tags/$tag"; then
  die "Pushing $tag to $entire failed; main is pushed there, and the tag is made here alone." \
    "Once $entire is reachable: git push $entire refs/tags/$tag" \
    "Then wait for the mirror to list it: git ls-remote $mirror refs/tags/$tag"
fi
ok "Pushed $tag to $entire."

info "Waiting for the mirror, $mirror, to list $tag; mirror.yml pushes it there from $entire."
made="$(git rev-parse "refs/tags/$tag")"
listed=""
tries=0
while :; do
  listed="$(mirrored_tag)"
  [ -z "$listed" ] || break
  tries=$((tries + 1))
  [ "$tries" -lt 40 ] || break
  sleep 15
done
if [ -z "$listed" ]; then
  die "The mirror, $mirror, does not list $tag after ten minutes. The release itself is done: main and $tag are on $entire." \
    "The Depot workflow mirror.yml pushes them to the mirror: depot ci run list shows its runs, and depot ci logs <run> the one for $tag." \
    "Once it has run, git ls-remote $mirror refs/tags/$tag lists the tag; the release is not run again."
elif [ "$listed" != "$made" ]; then
  die "The mirror, $mirror, lists a $tag other than this one (${listed:0:12}, where this release tagged ${made:0:12}). The release itself is done: main and $tag are on $entire." \
    "Only mirror.yml writes to the mirror, and never by force: depot ci run list shows its runs, and depot ci logs <run> what it pushed."
fi
ok "The mirror lists $tag."

echo ""
ok "Released $version. SwiftPM resolves it from the mirror: .package(url: \"$mirror\", from: \"$version\")"
