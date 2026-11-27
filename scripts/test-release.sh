#!/usr/bin/env bash
# USAGE-START
# Tests scripts/version.sh and scripts/release.sh against fakes, with no network, no Xcode and no
# registry, in a scratch workspace it deletes after: a copy of the files the two scripts read, in a
# git repository of its own, beside an `ai` and a `schemas` at the commits its siblings.lock pins
# and an `sdk-typescript` holding the licence texts; a bare repository as Entire, whose hooks log
# what it is pushed and feed a bare repository as the mirror, as mirror.yml does; and, first on
# PATH, a depot that lists one CI run of the status a file holds, a mise that logs each task it is
# asked to run, in order, and an xcrun that lists the simulators a file holds.
#
#   bash scripts/test-release.sh
#
# It runs on macOS and on Linux, where CI runs it (`mise run test:release`, in `ci:linux`), and
# touches no git of this repository: it copies the files, and commits and pushes in the copy.
# USAGE-END
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"
require_cmd git "git, which comes with Xcode's command line tools: xcode-select --install"
require_cmd awk "awk, which comes with the operating system"
require_cmd cksum "cksum, which comes with the operating system"
require_cmd sed "sed, which comes with the operating system"

root="$(cd "$(dirname "$0")/.." && pwd -P)"
WS="$(cd "$(mktemp -d)" && pwd -P)"
trap 'rm -rf "$WS"' EXIT
FAKES="$WS/fakes"
EVENTS="$WS/events.log"
DEPOT_LOG="$WS/depot.log"
mkdir -p "$FAKES/bin"
: >"$EVENTS"

# git as a test's, whatever this machine's or CI's own configuration says: an identity for the
# commits and the tags, no signing, no hooks but the fixture's.
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL="$WS/gitconfig" GIT_TERMINAL_PROMPT=0
unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_COMMON_DIR GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
printf '[user]\n\tname = test\n\temail = test@example.com\n[init]\n\tdefaultBranch = main\n[commit]\n\tgpgSign = false\n[tag]\n\tgpgSign = false\n' >"$GIT_CONFIG_GLOBAL"

passed=0
failed=0
# report <case> <yes or no> [<what was seen>]: one case, and what was seen where it failed.
report() {
  if [ "$2" = yes ]; then
    passed=$((passed + 1))
    ok "$1"
  else
    failed=$((failed + 1))
    echo "${PF_RED}✗${PF_RESET} $1"
    [ -z "${3:-}" ] || printf '%s\n' "$3" | sed 's/^/    /'
  fi
}
# holds <text> <string>: whether the text holds the string, as it is written. No pipe, so no
# early exit of a reader cuts the writer short under pipefail.
holds() {
  case "$1" in
    *"$2"*) return 0 ;;
  esac
  return 1
}

# depot, as release_ci asks it: CI's run, the push of main, of the status $FAKES/ci holds (finished
# where it holds none), whichever commit is asked, listed after a tag's push that failed, which
# release_ci must pass over; `none` lists no run.
cat >"$FAKES/bin/depot" <<FAKE
#!/bin/sh
printf '%s\n' "\$*" >>"$DEPOT_LOG"
status=\$(cat "$FAKES/ci" 2>/dev/null || echo finished)
[ "\$status" = none ] && { echo '[]'; exit 0; }
printf '[{"run_id": "run_tag", "status": "failed", "trigger": "push", "ref": "refs/tags/v0.0.1"}, {"run_id": "run_1", "status": "%s", "trigger": "push", "ref": "refs/heads/main"}]\n' "\$status"
FAKE
# mise, as the release runs it: each `mise run <task>` logged in order, with CI and the tags the
# clone holds as it starts. The task fails where $FAKES/fail-<task> exists, and leaves a file in the
# tree where $FAKES/dirty-<task> does, its colons written as dashes.
cat >"$FAKES/bin/mise" <<FAKE
#!/bin/sh
[ "\$1" = run ] || { echo "the fake mise runs tasks alone, and was asked: \$*" >&2; exit 2; }
name=\$(printf '%s' "\$2" | tr ':' '-')
printf 'mise run %s CI=%s tags=%s\n' "\$2" "\${CI:-}" "\$(git tag --list | tr '\n' ' ' | sed 's/ \$//')" >>"$EVENTS"
[ ! -e "$FAKES/fail-\$name" ] || { echo "\$2 failed, as the test asked" >&2; exit 1; }
[ ! -e "$FAKES/dirty-\$name" ] || : >"left-by-\$name"
exit 0
FAKE
# xcrun, as the release asks it: the simulators $FAKES/simulators lists, and a failure where it is
# missing, as on a machine without Xcode.
cat >"$FAKES/bin/xcrun" <<FAKE
#!/bin/sh
[ "\$1 \$2 \$3" = "simctl list devices" ] || { echo "the fake xcrun lists simulators alone, and was asked: \$*" >&2; exit 2; }
[ -f "$FAKES/simulators" ] || { echo 'xcrun: error: unable to find utility "simctl"' >&2; exit 72; }
cat "$FAKES/simulators"
FAKE
chmod +x "$FAKES/bin/depot" "$FAKES/bin/mise" "$FAKES/bin/xcrun"

# Entire, whose pushes are logged and refused where $FAKES/entire-refuses exists, and the mirror as
# mirror.yml keeps it: every tag and `main` Entire receives reach it, unless the mirror is held.
git init -q --bare -b main "$WS/entire.git"
git init -q --bare -b main "$WS/mirror.git"
cat >"$WS/entire.git/hooks/pre-receive" <<HOOK
#!/bin/sh
verb=receives
[ ! -e "$FAKES/entire-refuses" ] || verb=refuses
while read -r old new ref; do printf 'entire %s %s\n' "\$verb" "\$ref" >>"$EVENTS"; done
[ "\$verb" = receives ]
HOOK
cat >"$WS/entire.git/hooks/post-receive" <<HOOK
#!/bin/sh
[ -e "$FAKES/mirror-held" ] && exit 0
git push -q "$WS/mirror.git" 'refs/tags/*:refs/tags/*' 'refs/heads/main:refs/heads/main' 2>/dev/null
exit 0
HOOK
cat >"$WS/mirror.git/hooks/pre-receive" <<HOOK
#!/bin/sh
while read -r old new ref; do printf 'mirror receives %s\n' "\$ref" >>"$EVENTS"; done
HOOK
chmod +x "$WS/entire.git/hooks/pre-receive" "$WS/entire.git/hooks/post-receive" "$WS/mirror.git/hooks/pre-receive"

# The siblings, each at its first commit, and sdk-typescript's licence texts, this repository's.
for name in ai schemas; do
  mkdir -p "$WS/$name"
  git -C "$WS/$name" init -q -b main
  printf '%s, as the release test stands it up\n' "$name" >"$WS/$name/README.md"
  git -C "$WS/$name" add -A
  git -C "$WS/$name" commit -q -m "$name: First"
done
mkdir -p "$WS/sdk-typescript"
cp "$root/LICENSE.txt" "$root/LICENCE.fr.txt" "$WS/sdk-typescript/"

# The clone: the files the two scripts read, as they stand here, with nothing under the changelog's
# [Unreleased], and a lock pinning the siblings above.
REL="$WS/sdk-swift"
identification="Sources/MountayaClient/Sending/Rules/ClientIdentification.swift"
install='.package(url: "https://github.com/mountaya/sdk-swift", from: "'
for path in scripts .agents/siblings mise.toml README.md LICENSE.txt LICENCE.fr.txt "$identification"; do
  mkdir -p "$REL/$(dirname "$path")"
  cp -R "$root/$path" "$REL/$path"
done
awk '/^## \[Unreleased\]/ { print; print ""; inside = 1; next } inside && /^## \[/ { inside = 0 } !inside { print }' \
  "$root/CHANGELOG.md" >"$REL/CHANGELOG.md"
{
  # shellcheck disable=SC2016 # the backticks are the header's own, as .agents/siblings writes it
  printf '%s\n' '# The sibling commits CI tests this repository against. Written by `sh .agents/siblings pin`.'
  printf 'ai %s\n' "$(git -C "$WS/ai" rev-parse HEAD)"
  printf 'schemas %s\n' "$(git -C "$WS/schemas" rev-parse HEAD)"
} >"$REL/siblings.lock"
R() { git -C "$REL" "$@"; }
# note <line>: a line under the changelog's [Unreleased], committed and pushed as a change is.
note() {
  awk -v line="$1" '{ print } /^## \[Unreleased\]/ { print ""; print "### Fixed"; print ""; print line }' \
    "$REL/CHANGELOG.md" >"$WS/changelog"
  cat "$WS/changelog" >"$REL/CHANGELOG.md"
  R add -A
  R commit -q -m "docs: The notes of the next release"
  R push -q origin main
}
# commit_version <version>: the version's commit, as the person makes it, pushed.
commit_version() {
  R add -A
  R commit -q -m "version: Release v$1"
  R push -q origin main
}

CURRENT="$(sed -nE 's/^[[:space:]]*static let version = "([^"]*)".*$/\1/p' "$REL/$identification" | sed -n 1p)"
V="$(printf '%s\n' "$CURRENT" | awk -F. '{ print $1 "." $2 "." $3 + 1 }')"
V2="$(printf '%s\n' "$V" | awk -F. '{ print $1 "." $2 "." $3 + 1 }')"
TODAY="$(date -u +%Y-%m-%d)"
INSTALLS="$(grep -cF "$install" "$REL/README.md" || true)"
SIMULATOR="$(sed -n 's/^ios_simulator = "\([^"]*\)".*$/\1/p' "$REL/mise.toml" | sed -n 1p)"
RUNTIME="$(sed -n 's/^ios_runtime = "\([^"]*\)".*$/\1/p' "$REL/mise.toml" | sed -n 1p)"

# The release before, tagged and pushed, which the mirror holds.
R init -q -b main
R remote add origin "$WS/entire.git"
R add -A
R commit -q -m "feat: The release before"
R tag --annotate "v$CURRENT" -m "sdk-swift $CURRENT"
R push -q origin main "refs/tags/v$CURRENT" 2>/dev/null

# run_version <argument>...: scripts/version.sh in the clone, its output in $out and its exit status
# in $rc.
run_version() {
  rc=0
  out="$(cd "$REL" && bash scripts/version.sh "$@" </dev/null 2>&1)" || rc=$?
}
# run_release <argument>...: scripts/release.sh in the clone, against the fakes, with no terminal
# and no CI in its environment; its output in $out and its exit status in $rc.
run_release() {
  rc=0
  # As a person runs it: these tests may run in an agent's shell, which the release refuses.
  out="$(cd "$REL" && env -u CI -u RELEASE_ENTIRE_REMOTE -u CLAUDECODE PATH="$FAKES/bin:$PATH" RELEASE_MIRROR_URL="$WS/mirror.git" \
    RELEASE_POLL_SECONDS=1 RELEASE_WAIT_SECONDS=2 bash scripts/release.sh "$@" </dev/null 2>&1)" || rc=$?
}
# sums: the files `mise run version` writes, as they stand.
sums() { (cd "$REL" && cksum "$identification" README.md CHANGELOG.md); }
# simulators <state>: what xcrun lists, the simulator the device suites run on in <state>, or not
# at all where <state> is empty, beside a namesake and a runtime that are not its own, both booted.
simulators() {
  {
    echo '== Devices =='
    echo '-- iOS 1.0 --'
    echo "    $SIMULATOR (OTHER-RUNTIME) (Booted) "
    echo "-- iOS $RUNTIME --"
    echo "    $SIMULATOR Max (OTHER-DEVICE) (Booted) "
    [ -z "$1" ] || echo "    $SIMULATOR (TEST-DEVICE) ($1) "
    echo "-- watchOS $RUNTIME --"
  } >"$FAKES/simulators"
}
# events: what happened since the log was last emptied, one line each, joined by |.
events() { tr '\n' '|' <"$EVENTS"; }

echo
echo "scripts/version.sh: writes the release into the files, and nothing else"

run_version 1.2
report 'a version that is not MAJOR.MINOR.PATCH is refused' "$([ "$rc" -eq 1 ] && holds "$out" 'is no release version' && echo yes || echo no)" "exit $rc: $out"

before="$(sums)"
run_version "$V"
report 'nothing under [Unreleased] and no section of the version is refused, and nothing is written' "$([ "$rc" -eq 1 ] && holds "$out" "nothing under \`## [Unreleased]\`" && [ "$(sums)" = "$before" ] && echo yes || echo no)" "exit $rc: $out"

note "- What the test release carries."
head="$(R rev-parse HEAD)"
run_version "$V"
stated="$(sed -nE 's/^[[:space:]]*static let version = "([^"]*)".*$/\1/p' "$REL/$identification")"
headings="$(grep '^## ' "$REL/CHANGELOG.md" | sed -n '1,2p' | tr '\n' '|')"
unreleased="$(awk '/^## \[Unreleased\]/ { inside = 1; next } inside && /^## \[/ { exit } inside && NF { print }' "$REL/CHANGELOG.md")"
dated="$(awk -v heading="## [$V] - $TODAY" '$0 == heading { inside = 1; next } inside && /^## \[/ { exit } inside { print }' "$REL/CHANGELOG.md")"
report 'it writes the version into ClientIdentification.version' "$([ "$rc" -eq 0 ] && [ "$stated" = "$V" ] && echo yes || echo no)" "exit $rc: $out; stated: $stated"
report "and into every one of the README's $INSTALLS install lines" "$([ "$INSTALLS" -gt 0 ] && [ "$(grep -cF "${install}$V\"" "$REL/README.md")" = "$INSTALLS" ] && echo yes || echo no)" "$(grep -F "$install" "$REL/README.md")"
report "and moves the [Unreleased] notes under the version and today's date, an empty [Unreleased] above them" "$([ "$headings" = "## [Unreleased]|## [$V] - $TODAY|" ] && [ -z "$unreleased" ] && holds "$dated" '- What the test release carries.' && holds "$dated" '### Fixed' && echo yes || echo no)" "headings: $headings; unreleased: $unreleased; dated: $dated"
report 'it changes those three files alone, and makes no commit, stages nothing and tags nothing' "$([ "$(R rev-parse HEAD)" = "$head" ] && R diff --cached --quiet && [ "$(R tag --list | tr '\n' ' ')" = "v$CURRENT " ] && [ "$(R status --porcelain | awk '{ print $2 }' | sort | tr '\n' ' ')" = "CHANGELOG.md README.md $identification " ] && holds "$out" "Commit it as \"version: Release v$V\"" && echo yes || echo no)" "$(R status --porcelain) $out"

before="$(sums)"
run_version "$V"
report 'run again, it changes nothing' "$([ "$rc" -eq 0 ] && [ "$(sums)" = "$before" ] && holds "$out" 'nothing changed' && echo yes || echo no)" "exit $rc: $out"

run_version "$CURRENT"
report 'a version older than the newest one CHANGELOG.md dates is refused, and nothing is written' "$([ "$rc" -eq 1 ] && holds "$out" "CHANGELOG.md dates $V already, newer than $CURRENT" && [ "$(sums)" = "$before" ] && echo yes || echo no)" "exit $rc: $out"

commit_version "$V"
HEAD="$(R rev-parse HEAD)"

echo
echo "scripts/release.sh: tags the pushed commit CI passed, and resumes"
simulators Booted
: >"$EVENTS"

run_release "$V" --credentials
report 'release --credentials says the release needs none, and checks nothing else' "$([ "$rc" -eq 0 ] && printf '%s' "$out" | grep -q 'needs no credential' && echo yes || echo no)" "exit $rc: $out"
run_release "$V" --check
report '--check passes on the pushed version commit CI passed, and runs, tags and pushes nothing' "$([ "$rc" -eq 0 ] && holds "$out" 'Every check passed' && holds "$out" "CI=true mise run ci:local on ${HEAD:0:12}" && [ -z "$(R tag --list "v$V")" ] && [ -z "$(git -C "$WS/entire.git" tag --list "v$V")" ] && [ ! -s "$EVENTS" ] && grep -qF -- "--sha $HEAD" "$DEPOT_LOG" && echo yes || echo no)" "exit $rc: $out $(events)"

run_release "$V" --dry-run
report '--dry-run is gone, and the refusal names --check' "$([ "$rc" -eq 1 ] && holds "$out" 'is no option of the release any more' && holds "$out" "mise run release <X.Y.Z> --check" && echo yes || echo no)" "exit $rc: $out"

run_release 9.9.9 --check
report 'a version the files do not state is refused for each of them at once, with the command that writes them' "$([ "$rc" -eq 1 ] && holds "$out" "Every request names version $V" && holds "$out" "README.md's install lines name another version than 9.9.9" && holds "$out" 'CHANGELOG.md has no dated section for 9.9.9' && holds "$out" 'mise run version 9.9.9' && [ "$(printf '%s\n' "$out" | grep -c 'is refused')" = 1 ] && echo yes || echo no)" "exit $rc: $out"

printf 'failed\n' >"$FAKES/ci"
run_release "$V" --check
report 'a commit CI failed on is refused, naming the run to read' "$([ "$rc" -eq 1 ] && holds "$out" 'CI failed on' && holds "$out" 'depot ci logs run_1' && echo yes || echo no)" "exit $rc: $out"
printf 'none\n' >"$FAKES/ci"
run_release "$V" --check
report 'and a commit CI never ran on' "$([ "$rc" -eq 1 ] && holds "$out" 'CI never ran on' && echo yes || echo no)" "exit $rc: $out"
rm -f "$FAKES/ci"

: >"$REL/stray"
run_release "$V" --check
report 'a tree with changes no commit holds is refused' "$([ "$rc" -eq 1 ] && holds "$out" 'The working tree holds changes no commit holds' && echo yes || echo no)" "exit $rc: $out"
rm -f "$REL/stray"

R commit -q --allow-empty -m 'fix: Not pushed'
run_release "$V" --check
report "a commit Entire's main is not at is refused" "$([ "$rc" -eq 1 ] && holds "$out" "is not the one \`origin\`'s main is at" && echo yes || echo no)" "exit $rc: $out"
R push -q origin main 2>/dev/null
HEAD="$(R rev-parse HEAD)"

: >"$WS/schemas/draft.md"
run_release "$V" --check
report 'a sibling that is not clean at its pin is refused, as at-pins names it' "$([ "$rc" -eq 1 ] && holds "$out" 'is not clean at the commit siblings.lock pins' && holds "$out" '../schemas has uncommitted or untracked files' && echo yes || echo no)" "exit $rc: $out"
rm -f "$WS/schemas/draft.md"

printf 'an edit\n' >>"$WS/sdk-typescript/LICENSE.txt"
run_release "$V" --check
report "a licence text other than sdk-typescript's is refused" "$([ "$rc" -eq 1 ] && holds "$out" "LICENSE.txt differs from sdk-typescript's" && echo yes || echo no)" "exit $rc: $out"
cp "$root/LICENSE.txt" "$WS/sdk-typescript/LICENSE.txt"

simulators Shutdown
run_release "$V" --check
report 'while ci:local has not passed, the simulator the device suites run on not booted is refused, with the command that boots it' "$([ "$rc" -eq 1 ] && holds "$out" "The simulator ci:local runs the device suites on, $SIMULATOR on iOS $RUNTIME, is not booted" && holds "$out" 'xcrun simctl boot TEST-DEVICE' && echo yes || echo no)" "exit $rc: $out"
simulators ""
run_release "$V" --check
report 'and none of its name at its runtime, a namesake or another runtime booted' "$([ "$rc" -eq 1 ] && holds "$out" "No $SIMULATOR on iOS $RUNTIME is among the simulators" && echo yes || echo no)" "exit $rc: $out"
rm -f "$FAKES/simulators"
run_release "$V" --check
report 'and an xcrun that cannot list the simulators' "$([ "$rc" -eq 1 ] && holds "$out" 'xcrun cannot list the iOS simulators here' && echo yes || echo no)" "exit $rc: $out"
simulators Booted

: >"$EVENTS"
run_release "$V"
report 'without a terminal or --yes the release asks, and stops before it runs anything' "$([ "$rc" -eq 1 ] && holds "$out" 'nothing can answer here' && [ -z "$(R tag --list "v$V")" ] && [ ! -s "$EVENTS" ] && echo yes || echo no)" "exit $rc: $out $(events)"

main="$(git -C "$WS/entire.git" rev-parse main)"
commits="$(R rev-list --count HEAD)"
: >"$EVENTS"
run_release "$V" --yes
expected="mise run disk:check CI= tags=v$CURRENT|mise run ci:local CI=true tags=v$CURRENT|entire receives refs/tags/v$V|mirror receives refs/tags/v$V|"
report 'a release runs disk:check and ci:local (under CI), tags, pushes the tag to Entire, and the mirror lists it, in that order' "$([ "$rc" -eq 0 ] && [ "$(events)" = "$expected" ] && holds "$out" 'The mirror lists' && echo yes || echo no)" "exit $rc: $out
seen:     $(events)
expected: $expected"
report 'its last line names what was released and where SwiftPM resolves it from' "$(printf '%s\n' "$out" | tail -n 1 | grep -qF "Released sdk-swift $V: SwiftPM resolves it from the mirror, .package(url: \"$WS/mirror.git\", from: \"$V\")" && echo yes || echo no)" "$(printf '%s\n' "$out" | tail -n 1)"
report 'the tag is annotated, on the commit, named sdk-swift <version>, noted with its CHANGELOG.md section, headings kept' "$([ "$(R cat-file -t "v$V")" = tag ] && [ "$(R rev-parse "v$V^{commit}")" = "$HEAD" ] && [ "$(R tag -l --format='%(contents:subject)' "v$V")" = "sdk-swift $V" ] && R tag -l --format='%(contents:body)' "v$V" | grep -qx -- '- What the test release carries.' && R tag -l --format='%(contents:body)' "v$V" | grep -qx '### Fixed' && echo yes || echo no)" "$(R tag -l --format='%(contents)' "v$V")"
report 'Entire and the mirror hold the tag as it is here' "$([ "$(git -C "$WS/entire.git" rev-parse "refs/tags/v$V")" = "$(R rev-parse "refs/tags/v$V")" ] && [ "$(git -C "$WS/mirror.git" rev-parse "refs/tags/v$V")" = "$(R rev-parse "refs/tags/v$V")" ] && echo yes || echo no)"
report "it makes no commit and pushes no main" "$([ "$(R rev-parse HEAD)" = "$HEAD" ] && [ "$(R rev-list --count HEAD)" = "$commits" ] && [ "$(git -C "$WS/entire.git" rev-parse main)" = "$main" ] && ! holds "$(events)" 'refs/heads/' && echo yes || echo no)" "$(events)"
report 'and leaves no lock behind' "$([ ! -e "$REL/.git/mountaya/release.lock" ] && echo yes || echo no)"

: >"$EVENTS"
run_release "$V" --yes
report 'run again once released, it runs nothing, tags nothing and pushes nothing, and finds the mirror listing it' "$([ "$rc" -eq 0 ] && [ ! -s "$EVENTS" ] && holds "$out" "ci:local passed here on ${HEAD:0:12} already: not run again" && holds "$out" "v$V is tagged here already" && holds "$out" "origin holds v$V already" && holds "$out" 'The mirror lists' && echo yes || echo no)" "exit $rc: $out $(events)"

note "- What the second test release carries."
run_version "$V2"
commit_version "$V2"
HEAD="$(R rev-parse HEAD)"
main="$(git -C "$WS/entire.git" rev-parse main)"
# The tags the clone holds now, as git lists them, in byte order, and the two tasks a release runs
# before it tags, as the fake mise logs them.
tags="$(printf 'v%s\nv%s\n' "$CURRENT" "$V" | LC_ALL=C sort | tr '\n' ' ' | sed 's/ $//')"
ran="mise run disk:check CI= tags=$tags|mise run ci:local CI=true tags=$tags|"
refused="${ran}entire refuses refs/tags/v$V2|"

touch "$FAKES/fail-ci-local"
: >"$EVENTS"
run_release "$V2" --yes
report 'ci:local failing stops the release before the tag, and nothing is recorded as passed' "$([ "$rc" -eq 1 ] && holds "$out" "ci:local failed on ${HEAD:0:12}" && [ "$(events)" = "$ran" ] && [ -z "$(R tag --list "v$V2")" ] && [ ! -e "$REL/.git/mountaya/release/ci-local-$HEAD" ] && echo yes || echo no)" "exit $rc: $out $(events)"
report 'and leaves no lock behind' "$([ ! -e "$REL/.git/mountaya/release.lock" ] && echo yes || echo no)"
rm -f "$FAKES/fail-ci-local"

touch "$FAKES/dirty-ci-local"
run_release "$V2" --yes
report 'ci:local leaving changes in the tree stops the release before the tag, naming them' "$([ "$rc" -eq 1 ] && holds "$out" 'ci:local passed and left changes in the tree' && holds "$out" 'left-by-ci-local' && [ -z "$(R tag --list "v$V2")" ] && [ ! -e "$REL/.git/mountaya/release/ci-local-$HEAD" ] && echo yes || echo no)" "exit $rc: $out"
rm -f "$FAKES/dirty-ci-local" "$REL/left-by-ci-local"

touch "$FAKES/entire-refuses"
: >"$EVENTS"
run_release "$V2" --yes
report 'a tag push Entire refuses stops the release after the tag, ci:local recorded as passed' "$([ "$rc" -eq 1 ] && holds "$out" "Pushing v$V2 to origin failed" && [ "$(events)" = "$refused" ] && [ -n "$(R tag --list "v$V2")" ] && [ -z "$(git -C "$WS/entire.git" tag --list "v$V2")" ] && [ -e "$REL/.git/mountaya/release/ci-local-$HEAD" ] && echo yes || echo no)" "exit $rc: $out $(events)"
rm -f "$FAKES/entire-refuses"

simulators Shutdown
touch "$FAKES/mirror-held"
: >"$EVENTS"
run_release "$V2" --yes
report 'run again, with no simulator booted, it skips ci:local and the device check, keeps the tag and pushes it alone' "$([ "$rc" -eq 1 ] && holds "$out" "ci:local passed here on ${HEAD:0:12} already: not run again" && holds "$out" "v$V2 is tagged here already" && [ "$(events)" = "entire receives refs/tags/v$V2|" ] && [ "$(git -C "$WS/entire.git" rev-parse "refs/tags/v$V2")" = "$(R rev-parse "refs/tags/v$V2")" ] && echo yes || echo no)" "exit $rc: $out $(events)"
report 'and a mirror that never lists it stops the release, the tag on Entire' "$(holds "$out" "does not list v$V2" && [ -z "$(git -C "$WS/mirror.git" tag --list "v$V2")" ] && echo yes || echo no)" "$out"
rm -f "$FAKES/mirror-held"

git -C "$WS/entire.git" push -q "$WS/mirror.git" 'refs/tags/*:refs/tags/*' 2>/dev/null
: >"$EVENTS"
run_release "$V2" --yes
report 'run again once the mirror caught up, it only waits for the mirror, and finishes' "$([ "$rc" -eq 0 ] && [ ! -s "$EVENTS" ] && holds "$out" "origin holds v$V2 already" && holds "$out" "The mirror lists v$V2" && holds "$out" "Released sdk-swift $V2" && echo yes || echo no)" "exit $rc: $out $(events)"
report 'across the stops and the runs again, no commit and no push of main' "$([ "$(R rev-parse HEAD)" = "$HEAD" ] && [ "$(git -C "$WS/entire.git" rev-parse main)" = "$main" ] && echo yes || echo no)"

echo
echo "$passed passed, $failed failed"
[ "$failed" -eq 0 ]
