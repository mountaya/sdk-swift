#!/usr/bin/env bash
# USAGE-START
# Releases sdk-swift: the annotated tag v<X.Y.Z> on the commit CI passed, noted with its
# CHANGELOG.md section, pushed to the repository on Entire, then the wait for the public mirror on
# GitHub, which SwiftPM resolves every release from and where mirror.yml makes its GitHub Release.
# The tag is the publish: it versions the five products together, and no registry holds them but
# the mirror.
#
#   mise run release <X.Y.Z> [--yes]
#   mise run release <X.Y.Z> --check
#   mise run release <X.Y.Z> --credentials
#
# <X.Y.Z> is the version `ClientIdentification.version` and the README's install lines name, with
# a dated CHANGELOG.md section (`mise run version <X.Y.Z>` writes all three), past the newest `v*`
# tag here, on Entire and on the mirror. The release runs from `main`, clean, at the commit
# Entire's `main` is at, on which CI finished green, every sibling clean at its pin. CI runs the
# Linux part of the gate; the release runs the rest, `mise run ci:local` (Xcode's builds, the
# simulator's suites, the app's size), once per commit, before it tags. It asks before it does
# anything; --yes answers yes. --check runs every check, says what a release would do, and changes
# nothing. --credentials checks the credentials a release needs: none, for this repository. Run again after a stop, it resumes: ci:local passed on the commit, and the tag made here,
# on Entire or on the mirror, are each taken as done. It makes no commit and pushes no branch. The
# repository on Entire is the remote `origin`; RELEASE_ENTIRE_REMOTE names another, and
# RELEASE_MIRROR_URL another mirror, for a test.
# USAGE-END
#
# The checks refuse, all of them told together and each with what to do: what release_checks
# refuses (no clean `main` at the commit Entire's `main` is at, a tag here, on Entire or on the
# mirror other than on this commit, a version not newer than every `v*` tag, no green CI run on
# the commit); a version other than the one every request names, `ClientIdentification.version`,
# or than the README's install lines; no dated CHANGELOG.md section for it; a sibling not clean at
# the commit siblings.lock pins; a licence text that differs from sdk-typescript's bytes; and,
# while ci:local has not passed on the commit, no simulator booted of the one the device suites
# run on. Then, once it has said what it will do and been answered: `mise run disk:check` and
# `CI=true mise run ci:local`, unless ci:local passed here on the commit already; the tag, unless
# it is here already; its push alone to Entire, unless Entire holds it; and the wait, ten minutes
# at most, until the mirror lists it.
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
# shellcheck source=lib/release.sh
. "$(dirname "$0")/lib/release.sh"
answer_help "$@"
require_cmd git "git, which comes with Xcode's command line tools: xcode-select --install"
require_cmd awk "awk, which comes with the operating system"
require_cmd cmp "cmp, which comes with the operating system"
require_cmd sed "sed, which comes with the operating system"
require_cmd mise "mise: sh .agents/setup installs it"

root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"

version=""
yes=0
check=0
credentials=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --yes) yes=1 ;;
    --check) check=1 ;;
    --credentials) credentials=1 ;;
    --dry-run | --skip-gate)
      die "\`$1\` is no option of the release any more: CI's green run on the commit is the gate, and --check runs every check and changes nothing." \
        "mise run release <X.Y.Z> --check"
      ;;
    -*) die "\`$1\` is no option of the release." "bash scripts/release.sh --help" ;;
    *)
      [ -z "$version" ] || die "The release takes one version, and was given \`$version\` and \`$1\`." "mise run release <X.Y.Z>"
      version="$1"
      ;;
  esac
  shift
done
[ -n "$version" ] || die "The release takes the version it releases." "mise run release <X.Y.Z>, such as: mise run release 0.2.0"
entire="${RELEASE_ENTIRE_REMOTE:-origin}"
tag="v$version"
if [ "$credentials" -eq 1 ]; then
  ok "A release of sdk-swift needs no credential beyond Entire's login: the tag is its publish."
  exit 0
fi
# What the person runs to put the version in the files, and what follows it, which most refusals
# end on.
rewrite="mise run version $version, commit it as \"version: Release $tag\", push main, then run the
  release again once CI passed."

release_checks "$entire" "$version"
short="$(printf '%s' "$release_head" | cut -c1-12)"

if release_is_version "$version"; then
  # Every request names the package's version (`X-Mountaya-Client`), written once in the source,
  # so the release is that version, or the tag and what the requests say part ways. BoundaryTests
  # reads the line as this does.
  identification="Sources/MountayaClient/Sending/Rules/ClientIdentification.swift"
  stated="$(sed -nE 's/^[[:space:]]*static let version = "([^"]*)"[[:space:]]*$/\1/p' "$identification" 2>/dev/null | sed -n 1p || true)"
  if [ -z "$stated" ]; then
    release_refuse "$identification holds no \`static let version = \"<X.Y.Z>\"\`, so nothing says which
version every request names.

  Fix: $rewrite"
  elif [ "$stated" != "$version" ]; then
    release_refuse "Every request names version $stated (\`ClientIdentification.version\`), and the release is
$version, so the tag and what the requests say would part ways.

  Fix: $rewrite"
  fi

  # The README's install lines depend on the package from the release they were written against,
  # as `mise run version` writes them.
  install='.package(url: "https://github.com/mountaya/sdk-swift", from: "'
  named="$(awk -v prefix="$install" '
    {
      at = index($0, prefix)
      if (at == 0) next
      rest = substr($0, at + length(prefix))
      print FNR ": " substr(rest, 1, index(rest, "\"") - 1)
    }
  ' README.md 2>/dev/null || true)"
  stale="$(printf '%s\n' "$named" | awk -v version="$version" 'NF && $2 != version { print "  README.md:" $0 }')"
  if [ -z "$named" ]; then
    release_refuse "README.md holds no install line, \`$install$version\")\`, so a reader would not know
which release to depend on.

  Fix: $rewrite"
  elif [ -n "$stale" ]; then
    release_refuse "README.md's install lines name another version than $version, the one each line's
number names after it:
$stale

  Fix: $rewrite"
  fi

  if [ ! -f CHANGELOG.md ]; then
    release_refuse "CHANGELOG.md is missing, so the release would say nothing of what it carries.

  Fix: write CHANGELOG.md with an \`## [Unreleased]\` section holding the notes, then $rewrite"
  elif ! release_dated CHANGELOG.md "$version"; then
    release_refuse "CHANGELOG.md has no dated section for $version, so the tag would say nothing of what it
carries.

  Fix: $rewrite"
  fi
fi

# The siblings the gate reads beside this checkout, each clean at the commit siblings.lock pins, so
# ci:local runs on what CI tested this commit against.
if ! siblings="$(sh .agents/siblings at-pins 2>&1)"; then
  release_refuse "A sibling beside this checkout is not clean at the commit siblings.lock pins, so ci:local
would not run on what CI tested this commit against:
$(printf '%s\n' "$siblings" | sed 's/^/  /')

  Fix: do what the lines above say for each (sh .agents/siblings status shows every pin beside its
  sibling), then run the release again."
fi

typescript="$(cd .. && pwd -P)/sdk-typescript"
for text in LICENSE.txt LICENCE.fr.txt; do
  if [ ! -f "$typescript/$text" ]; then
    release_refuse "$typescript/$text is missing, so nothing holds $text to the licence the TypeScript
packages ship.

  Fix: clone sdk-typescript beside this repository, with: entire repo clone /et/mountaya/sdk-typescript,
  then run the release again."
  elif ! cmp -s "$text" "$typescript/$text"; then
    release_refuse "$text differs from sdk-typescript's, and the products ship the TypeScript packages'
licence byte for byte.

  Fix: copy sdk-typescript's $text over this one, commit it, push main, then run the release again
  once CI passed."
  fi
done

# The device suites (`mise run test:device`, which ci:local runs) run on the simulator mise.toml
# names, at the iOS runtime it names, so it is booted before ci:local starts, which builds for half
# an hour first. Once ci:local passed on the commit, nothing the release does needs it.
if ! release_ran ci-local "$release_head"; then
  simulator="$(sed -n 's/^ios_simulator = "\([^"]*\)".*$/\1/p' mise.toml | sed -n 1p)"
  runtime="$(sed -n 's/^ios_runtime = "\([^"]*\)".*$/\1/p' mise.toml | sed -n 1p)"
  if ! has_cmd xcrun || ! simulators="$(xcrun simctl list devices available 2>/dev/null)"; then
    release_refuse "xcrun cannot list the iOS simulators here, and ci:local builds for Apple's platforms and
runs the device suites on the simulator, which Xcode alone runs, on macOS.

  Fix: run the release on a Mac with the Xcode mise.toml names (mise run toolchain:check says
  whether it is the one selected), then run the release again."
  else
    # `    <name> (<udid>) (<state>)`, under the line `-- iOS <runtime> --`.
    # The first of that name alone, read to the end, so the list is never cut short under pipefail.
    device="$(printf '%s\n' "$simulators" | awk -v section="-- iOS $runtime --" -v name="$simulator" '
      /^-- / { line = $0; sub(/[[:space:]]+$/, "", line); inside = (line == section); next }
      inside && !found {
        line = $0
        sub(/^[[:space:]]+/, "", line)
        if (index(line, name " (") != 1) next
        rest = substr(line, length(name) + 3)
        state = "shutdown"
        if (index(rest, "(Booted)") > 0) state = "booted"
        print substr(rest, 1, index(rest, ")") - 1) " " state
        found = 1
      }
    ')"
    if [ -z "$device" ]; then
      release_refuse "No $simulator on iOS $runtime is among the simulators Xcode offers here, and ci:local runs
the device suites on it (mise run test:device).

  Fix: install iOS $runtime (Xcode, Settings, Components) and add an $simulator on it (Xcode,
  Window, Devices and Simulators), then run the release again."
    elif [ "${device#* }" != booted ]; then
      release_refuse "The simulator ci:local runs the device suites on, $simulator on iOS $runtime, is not booted.

  Fix: boot it (xcrun simctl boot ${device%% *}), then run the release again."
    fi
  fi
fi

release_refused "sdk-swift $version"

# Where each step stands, read from the clone and the remotes, so a release run again says what is
# left of it.
ran=0
release_ran ci-local "$release_head" && ran=1
here_tag="$(git rev-parse -q --verify "refs/tags/$tag" 2>/dev/null || true)"
entire_tag="$(release_remote_tag "$entire" "$tag")"

echo ""
echo "${PF_BOLD}The release of sdk-swift $version:${PF_RESET}"
if [ "$ran" -eq 1 ]; then
  echo "  1. ci:local passed here on $short already: not run again."
else
  echo "  1. mise run disk:check, then CI=true mise run ci:local on $short: the part of the gate CI cannot"
  echo "     run, Xcode's builds, the simulator's suites and the app's size."
fi
if [ -n "$here_tag" ]; then
  echo "  2. $tag is tagged here already, on $short: kept."
else
  echo "  2. The annotated tag $tag on $short, noted with its CHANGELOG.md section."
fi
if [ -n "$entire_tag" ]; then
  echo "  3. $entire holds $tag already: nothing to push."
else
  echo "  3. $tag pushed alone to $entire ($(git remote get-url "$entire")): main is there already."
fi
echo "  4. A wait until the mirror, $RELEASE_MIRROR, lists it: mirror.yml pushes it there and makes its"
echo "     GitHub Release, and SwiftPM resolves the release from there."
echo ""
if [ "$check" -eq 1 ]; then
  ok "Every check passed: nothing was run, tagged or pushed."
  exit 0
fi
release_confirm "sdk-swift $version" "$yes"

release_lock
if [ "$ran" -eq 1 ]; then
  ok "ci:local passed here on $short already: not run again."
else
  info "The part of the gate CI cannot run: mise run disk:check, then CI=true mise run ci:local."
  # The disk check passes under CI without looking, so it runs on its own first.
  mise run disk:check || die "The disk check stopped the release before ci:local: nothing was tagged or pushed." \
    "Free what it names, then run the release again."
  CI=true mise run ci:local || die "ci:local failed on $short, so CI's pass is not the whole gate's: nothing was tagged or pushed." \
    "Fix what it reported in a commit of its own, push main, then run the release again once CI passed on it."
  # What passed is the commit as it stands, so a gate that changed the tree passed on something
  # else.
  left="$(git status --porcelain --untracked-files=normal)"
  [ -z "$left" ] || die "ci:local passed and left changes in the tree, so what passed is not the commit alone: nothing was tagged or pushed.
$(printf '%s\n' "$left" | sed 's/^/  /')" \
    "Read what changed (git status): commit what belongs in a commit of its own and push main, or set the rest aside, then run the release again."
  release_record ci-local "$release_head"
  ok "ci:local passed on $short."
fi

notes="$(mktemp)"
release_notes CHANGELOG.md "$version" >"$notes"
release_tag "$tag" "sdk-swift $version" "$notes"
rm -f "$notes"
release_push_tag "$entire" "$tag"
release_wait_mirror "$tag"

echo ""
ok "Released sdk-swift $version: SwiftPM resolves it from the mirror, .package(url: \"$RELEASE_MIRROR\", from: \"$version\"), and its GitHub Release is $RELEASE_MIRROR/releases/tag/$tag"
