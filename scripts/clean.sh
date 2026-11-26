#!/usr/bin/env bash
# Deletes what the builds leave behind in this repository and no longer use, so the disk it builds
# on does not fill. `mise run ci` runs it before anything else; `mise run clean` runs it alone. It
# deletes nothing outside the repository: the Linux images a toolchain no pin names any more live
# in Docker's disk, shared by every project on the machine, and `mise run clean:toolchains`, yours
# to run, lists and deletes them.
#
#   bash scripts/clean.sh <swift> <swift floor> [--all] [--dry-run]
#
# By default it deletes only what nothing builds into any more:
#   - `.build/linux-<version>`, the Linux container's build by a toolchain other than the pinned
#     one and the floor;
#   - `.build/consumer-<host>-<major.minor>`, the consumer package's build by a compiler other
#     than those two, BoundaryTests' build for each host and for the iOS simulator, and
#     `.build/trail-ios-release-<major.minor>`, the size gate's release build of Trail for an iOS
#     device, which `mise run size:check` names by the compiler it runs, so a pin that moves frees
#     it; and `.build/consumer-ios-release-<major.minor>`, whatever its compiler, the release build
#     the size gate measured before it measured Trail;
#   - `.build/platforms/<name>`, a platform build no task makes any more: the names in use are
#     read from scripts/build-platforms.sh and mise.toml, which make them;
#   - the `.build` of each package under Tests/ and Examples/, which only a resolve by hand fills:
#     the gate builds those packages into the root's `.build`, and the simulator tasks into theirs.
# `--all` deletes every build directory instead, `.build` and the packages' own, which the next
# gate builds again from nothing (about 25 GB). `--dry-run` lists what it would delete and deletes
# nothing. Every path it deletes is one under the repository's own root, which it refuses to leave.
set -euo pipefail

# shellcheck source=lib/common.sh
. "$(dirname "$0")/lib/common.sh"
answer_help "$@"

# Every path below is read from the repository's root, whatever directory it was run from.
root="$(cd "$(dirname "$0")/.." && pwd -P)"
cd "$root"

usage="usage: bash scripts/clean.sh <swift> <swift floor> [--all] [--dry-run]"
swift="${1:?$usage}"
floor="${2:?$usage}"
shift 2
all=0
dry_run=0
for argument in "$@"; do
  case "$argument" in
    --all) all=1 ;;
    --dry-run) dry_run=1 ;;
    --) ;;
    *) die "Unknown argument: $argument" "bash scripts/clean.sh --help" ;;
  esac
done

freed_kb=0

# human <kilobytes>: a size the way df and du print it to a person.
human() {
  awk -v k="$1" 'BEGIN { if (k >= 1048576) printf "%.1f GB", k / 1048576; else printf "%.0f MB", k / 1024 }'
}

# remove <path> <why>: deletes one path, or under --dry-run says it would, with its size. A path
# whose directory leads out of the repository, through `..` or a link, is refused rather than
# deleted; a link itself is deleted as a link, never what it leads to.
remove() {
  local target="$1" why="$2" kb resolved
  [ -e "$target" ] || [ -L "$target" ] || return 0
  resolved="$(cd "$(dirname "$target")" 2>/dev/null && pwd -P)/$(basename "$target")"
  case "$resolved" in
    "$root"/?*) ;;
    *) die "Refused to delete ${target}: it lies outside the repository, at ${resolved}" ;;
  esac
  kb="$(du -sk "$target" 2>/dev/null | awk '{ print $1 }')"
  freed_kb=$((freed_kb + ${kb:-0}))
  if [ "$dry_run" = 1 ]; then
    info "would delete ${target} ($(human "${kb:-0}")): ${why}"
  else
    rm -rf "$target"
    info "deleted ${target} ($(human "${kb:-0}")): ${why}"
  fi
}

# The packages under Tests/ and Examples/ with a manifest of their own, each of which a resolve
# fills a `.build` for.
nested_builds() {
  find Tests Examples -name Package.swift -not -path '*/.build/*' 2>/dev/null | while read -r manifest; do
    echo "$(dirname "$manifest")/.build"
  done
}

if [ "$all" = 1 ]; then
  remove .build "every build directory, rebuilt by the next gate"
  for nested in $(nested_builds); do
    remove "$nested" "every build directory, rebuilt by the next gate"
  done
else
  # A toolchain's major.minor is how the consumer's build directories are named.
  live_minors=" ${swift%.*} ${floor%.*} "
  live_linux=" ${swift} ${floor} "

  for directory in .build/linux-*; do
    [ -d "$directory" ] || continue
    version="${directory#.build/linux-}"
    case "$live_linux" in
      *" ${version} "*) ;;
      *) remove "$directory" "Swift ${version} is neither the pinned toolchain nor the floor" ;;
    esac
  done

  for directory in .build/consumer-* .build/trail-*; do
    [ -d "$directory" ] || continue
    case "$directory" in
      .build/consumer-ios-release-*)
        remove "$directory" "the size gate measures Trail now, in .build/trail-ios-release-<major.minor>"
        continue
        ;;
    esac
    minor="${directory##*-}"
    case "$minor" in
      [0-9]*.[0-9]*) ;;
      *) continue ;;
    esac
    case "$live_minors" in
      *" ${minor} "*) ;;
      *) remove "$directory" "a compiler at ${minor} builds nothing here any more" ;;
    esac
  done

  # The platform builds in use are the ones the platform script and the iOS tasks name.
  live_platforms=" $(sed -n "/<<'PLATFORMS'/,/^PLATFORMS$/p" scripts/build-platforms.sh | sed '1d;$d' | awk '{ print $1 }' | tr '\n' ' ')"
  live_platforms="${live_platforms}$(grep -o '\.build/platforms/[A-Za-z0-9._-]*' mise.toml | sed 's|.*/||' | tr '\n' ' ') "
  for directory in .build/platforms/*; do
    [ -d "$directory" ] || continue
    name="${directory#.build/platforms/}"
    case "$live_platforms" in
      *" ${name} "*) ;;
      *) remove "$directory" "no task builds the platform build ${name} any more" ;;
    esac
  done

  for nested in $(nested_builds); do
    remove "$nested" "only a resolve by hand fills it; the gate never reads it"
  done
fi

if [ "$freed_kb" = 0 ]; then
  ok "Nothing to delete: every build directory here is one a pin uses"
elif [ "$dry_run" = 1 ]; then
  ok "$(human "$freed_kb") would be freed"
else
  ok "$(human "$freed_kb") freed"
fi
