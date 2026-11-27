#!/usr/bin/env bash
# USAGE-START
# Writes a release of sdk-swift into its files: `ClientIdentification.version`, the one place the
# source names the package's version, which every request sends and the release reads; the
# README's install lines, which depend on the package from that version; and the CHANGELOG's
# `[Unreleased]` notes, dated, under the version.
#
#   mise run version <X.Y.Z>
#
# It edits files alone, so an agent may run it, and run again it changes nothing. It refuses a
# version older than the newest one CHANGELOG.md dates, and a CHANGELOG.md with nothing under
# `[Unreleased]` and no section of the version's. Commit what it wrote as
# "version: Release v<X.Y.Z>" and push main: `mise run release <X.Y.Z>` tags that commit, once CI
# passed on it.
# USAGE-END
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
# shellcheck source=lib/release.sh
. "$(dirname "$0")/lib/release.sh"
answer_help "$@"
require_cmd awk "awk, which comes with the operating system"
require_cmd cmp "cmp, which comes with the operating system"
require_cmd sed "sed, which comes with the operating system"

root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"

version="${1:-}"
[ "$#" -le 1 ] || die "The version takes one argument, and was given $#." "mise run version <X.Y.Z>, such as: mise run version 0.2.0"
release_is_version "$version" || die "\`$version\` is no release version: a release is MAJOR.MINOR.PATCH, each a number with no leading zero." \
  "mise run version <X.Y.Z>, such as: mise run version 0.2.0"

# The line every request's version is read from, as scripts/release.sh and BoundaryTests read it.
identification="Sources/MountayaClient/Sending/Rules/ClientIdentification.swift"
# The README's install lines begin so, each followed by the version and its closing quote.
install='.package(url: "https://github.com/mountaya/sdk-swift", from: "'

[ -f CHANGELOG.md ] || die "CHANGELOG.md is missing, so the release would say nothing of what it carries." \
  "Write CHANGELOG.md with an \`## [Unreleased]\` section holding the notes, then run this again."
if ! release_dated CHANGELOG.md "$version" \
  && [ -z "$(awk '/^## \[Unreleased\]/ { inside = 1; next } inside && /^## \[/ { exit } inside && NF { print; exit }' CHANGELOG.md)" ]; then
  die "CHANGELOG.md has no section for $version and nothing under \`## [Unreleased]\`, so the release would say nothing of what it carries." \
    "Write what $version carries under \`## [Unreleased]\`, then run this again."
fi
# The newest version CHANGELOG.md dates, whose section heads the released ones: notes dated under
# an older version would stand above it, out of order, and every request would name a version
# older than one already released.
newest="$(sed -nE 's/^## \[v?([0-9]+\.[0-9]+\.[0-9]+)\] - [0-9]{4}-[0-9]{2}-[0-9]{2}[[:space:]]*$/\1/p' CHANGELOG.md | sed -n 1p)"
if [ -n "$newest" ] && release_newer "$newest" "$version"; then
  die "CHANGELOG.md dates $newest already, newer than $version, so the release would go behind it." \
    "mise run version <X.Y.Z> with a version past $newest."
fi

stated="$(grep -cE '^[[:space:]]*static let version = "[^"]*"[[:space:]]*$' "$identification" 2>/dev/null || true)"
[ "${stated:-0}" -eq 1 ] \
  || die "$identification holds no single \`static let version = \"<X.Y.Z>\"\` line, which every request's version is read from." \
    "Put the line back as BoundaryTests' ChangelogTests reads it, alone on its line, then run this again."
lines="$(grep -cF "$install" README.md 2>/dev/null || true)"
[ "${lines:-0}" -gt 0 ] \
  || die "README.md holds no install line, \`$install<X.Y.Z>\")\`, to name $version in." \
    "Where the install lines changed shape, change the pattern in scripts/version.sh and scripts/release.sh with them."

changed=""
# write <file> <new text's file>: the file takes the new text where it differs, its mode kept, and
# is listed as changed; it is left untouched where it does not.
write() {
  if cmp -s "$2" "$1"; then
    rm -f "$2"
    return 0
  fi
  cat "$2" >"$1"
  rm -f "$2"
  changed="$changed $1"
}

next="$(mktemp)"
sed -E "s/^([[:space:]]*static let version = \")[^\"]*(\"[[:space:]]*)$/\1$version\2/" "$identification" >"$next"
write "$identification" "$next"

next="$(mktemp)"
awk -v prefix="$install" -v version="$version" '
  {
    at = index($0, prefix)
    if (at == 0) { print; next }
    head = substr($0, 1, at + length(prefix) - 1)
    rest = substr($0, at + length(prefix))
    print head version substr(rest, index(rest, "\""))
  }
' README.md >"$next"
write README.md "$next"

next="$(mktemp)"
release_date_unreleased CHANGELOG.md "$version" >"$next"
write CHANGELOG.md "$next"

if [ -z "$changed" ]; then
  ok "sdk-swift is $version already, in ClientIdentification.version, the README's install lines and CHANGELOG.md: nothing changed."
else
  ok "sdk-swift is $version in ClientIdentification.version, the README's install lines and CHANGELOG.md, written to:$changed."
fi
echo "Commit it as \"version: Release v$version\", push main, then, once CI passed: mise run release $version"
